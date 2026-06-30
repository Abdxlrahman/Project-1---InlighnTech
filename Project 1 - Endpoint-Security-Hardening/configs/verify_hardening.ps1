#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Endpoint Hardening Verification Script — Read-Only Audit Mode
    Project 1: Endpoint System Hardening & Security Baseline

.DESCRIPTION
    This is a NON-DESTRUCTIVE, read-only compliance verification script.
    It checks the current state of all hardening controls WITHOUT making any changes.
    Use this script to:
      - Verify hardening was applied correctly after running hardening_helper.ps1
      - Perform periodic compliance audits
      - Generate a compliance status report for documentation

.NOTES
    Author      : Security Engineering Team
    Version     : 1.0
    Date        : 2026-06-05
    Standard    : CIS Windows 11 Benchmarks
    Mode        : READ-ONLY — No system changes are made

.EXAMPLE
    .\verify_hardening.ps1
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = "Continue"

$ScriptDir  = Split-Path -Parent $MyInvocation.MyCommand.Path
$Timestamp  = Get-Date -Format "yyyyMMdd_HHmmss"
$LogFile    = Join-Path $ScriptDir "verify_log_$Timestamp.txt"
Start-Transcript -Path $LogFile -Append | Out-Null

# ─── Helper Functions ─────────────────────────────────────────────────────────
function Write-Check {
    param([string]$Label, [bool]$Passed, [string]$Detail = "")
    if ($Passed) {
        Write-Host "  [PASS] $Label" -ForegroundColor Green
    } else {
        Write-Host "  [FAIL] $Label" -ForegroundColor Red
    }
    if ($Detail) { Write-Host "         $Detail" -ForegroundColor Gray }
}

function Write-SectionHeader {
    param([string]$Title)
    Write-Host ""
    Write-Host "  ════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host "  $Title" -ForegroundColor Cyan
    Write-Host "  ════════════════════════════════════════════" -ForegroundColor Cyan
}

$PassCount = 0
$FailCount = 0
$Checks    = @()

function Add-Result {
    param([string]$Control, [bool]$Passed, [string]$Detail)
    $script:Checks += [PSCustomObject]@{
        CISControl  = $Control
        Result      = if ($Passed) { "PASS" } else { "FAIL" }
        Detail      = $Detail
    }
    if ($Passed) { $script:PassCount++ } else { $script:FailCount++ }
}

# ─── Header ───────────────────────────────────────────────────────────────────
Write-Host ""
Write-Host "╔══════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║   HARDENING VERIFICATION — READ-ONLY COMPLIANCE AUDIT          ║" -ForegroundColor Cyan
Write-Host "║   CIS Benchmarks | Windows 11 | Endpoint Security              ║" -ForegroundColor Cyan
Write-Host "╚══════════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""
Write-Host "  Hostname    : $env:COMPUTERNAME" -ForegroundColor Gray
Write-Host "  Audited By  : $env:USERNAME" -ForegroundColor Gray
Write-Host "  Audit Time  : $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Gray
Write-Host "  Log File    : $LogFile" -ForegroundColor Gray

# ─── CHECK 1: Firewall Status ─────────────────────────────────────────────────
Write-SectionHeader "CIS 4.1 — Firewall Profile Verification"

try {
    $Profiles = Get-NetFirewallProfile
    foreach ($Profile in $Profiles) {
        $IsEnabled  = ($Profile.Enabled -eq $true)
        $IsBlocking = ($Profile.DefaultInboundAction -eq "Block")
        $Label      = "[$($Profile.Name)] Firewall Enabled"
        Write-Check -Label $Label -Passed $IsEnabled -Detail "Enabled=$($Profile.Enabled)"
        Add-Result "CIS 4.1 - Firewall ($($Profile.Name))" $IsEnabled "Enabled=$($Profile.Enabled)"

        Write-Check -Label "[$($Profile.Name)] Default Inbound = Block" -Passed $IsBlocking `
            -Detail "DefaultInboundAction=$($Profile.DefaultInboundAction)"
        Add-Result "CIS 4.1 - Inbound Block ($($Profile.Name))" $IsBlocking `
            "DefaultInboundAction=$($Profile.DefaultInboundAction)"
    }
} catch {
    Write-Host "  [ERROR] Could not query firewall profiles: $_" -ForegroundColor Red
}

# ─── CHECK 2: Password Policy ─────────────────────────────────────────────────
Write-SectionHeader "CIS 5.2 — Password & Lockout Policy Verification"

try {
    $Accounts = net accounts
    $MinPwLen    = ($Accounts | Select-String "Minimum password length").ToString().Trim() -replace ".*:\s*", ""
    $LockoutThre = ($Accounts | Select-String "Lockout threshold").ToString().Trim() -replace ".*:\s*", ""

    $PwLenOk  = ([int]$MinPwLen -ge 12)
    $LockOk   = ($LockoutThre -ne "Never" -and [int]$LockoutThre -le 5 -and [int]$LockoutThre -ge 1)

    Write-Check "Minimum password length >= 12" $PwLenOk "Current: $MinPwLen characters"
    Add-Result "CIS 5.2 - Password Length" $PwLenOk "Length: $MinPwLen"

    Write-Check "Account lockout threshold <= 5" $LockOk "Current: $LockoutThre attempts"
    Add-Result "CIS 5.2 - Lockout Threshold" $LockOk "Threshold: $LockoutThre"
} catch {
    Write-Host "  [ERROR] Could not read password policy: $_" -ForegroundColor Red
}

# ─── CHECK 3: RemoteRegistry Service ─────────────────────────────────────────
Write-SectionHeader "CIS 4.1 — Unnecessary Service Verification (RemoteRegistry)"

try {
    $Svc = Get-Service -Name RemoteRegistry -ErrorAction SilentlyContinue
    if ($null -eq $Svc) {
        Write-Check "RemoteRegistry service absent (optimal)" $true "Service not installed"
        Add-Result "CIS 4.1 - RemoteRegistry Absent" $true "Not installed"
    } else {
        $IsStopped   = ($Svc.Status -eq "Stopped")
        $IsDisabled  = ($Svc.StartType -eq "Disabled")

        Write-Check "RemoteRegistry service Stopped" $IsStopped "Status: $($Svc.Status)"
        Add-Result "CIS 4.1 - RemoteRegistry Stopped" $IsStopped "Status: $($Svc.Status)"

        Write-Check "RemoteRegistry service Disabled" $IsDisabled "StartType: $($Svc.StartType)"
        Add-Result "CIS 4.1 - RemoteRegistry Disabled" $IsDisabled "StartType: $($Svc.StartType)"
    }
} catch {
    Write-Host "  [ERROR] Could not verify RemoteRegistry: $_" -ForegroundColor Red
}

# ─── CHECK 4: RDP State ───────────────────────────────────────────────────────
Write-SectionHeader "CIS 4.1 — Remote Desktop Protocol (RDP) State"

try {
    $RegPath   = 'HKLM:\System\CurrentControlSet\Control\Terminal Server'
    $RDPValue  = (Get-ItemProperty -Path $RegPath -Name "fDenyTSConnections").fDenyTSConnections
    $RDPDenied = ($RDPValue -eq 1)

    Write-Check "RDP Connections Denied (fDenyTSConnections = 1)" $RDPDenied "Current value: $RDPValue"
    Add-Result "CIS 4.1 - RDP Disabled" $RDPDenied "fDenyTSConnections = $RDPValue"
} catch {
    Write-Host "  [ERROR] Could not read RDP registry key: $_" -ForegroundColor Red
}

# ─── CHECK 5: Audit Policies ──────────────────────────────────────────────────
Write-SectionHeader "CIS 8.1 — Security Audit Policy Verification"

try {
    $AuditOutput     = auditpol /get /category:"Logon/Logoff" 2>&1
    $LogonLine       = $AuditOutput | Select-String "Logon\s+Success and Failure"
    $LogonConfigured = ($null -ne $LogonLine)

    Write-Check "Logon/Logoff audit — Success & Failure enabled" $LogonConfigured `
        "$(if ($LogonLine) { $LogonLine.ToString().Trim() } else { 'Not configured' })"
    Add-Result "CIS 8.1 - Audit Logon/Logoff" $LogonConfigured `
        "$(if ($LogonLine) { 'Configured' } else { 'Not configured' })"
} catch {
    Write-Host "  [ERROR] Could not verify audit policies: $_" -ForegroundColor Red
}

# ─── CHECK 6: Listening Port Summary ─────────────────────────────────────────
Write-SectionHeader "CIS 9.1 — Active Listening Port Inventory"

try {
    $Ports = Get-NetTCPConnection -State Listen | Select-Object LocalAddress, LocalPort | Sort-Object LocalPort
    Write-Host "  Active listening ports:" -ForegroundColor Gray
    $Ports | ForEach-Object {
        $Risk = switch ($_.LocalPort) {
            23    { "HIGH — Telnet (unencrypted)" }
            21    { "HIGH — FTP (unencrypted)" }
            3389  { "HIGH — RDP" }
            445   { "MEDIUM — SMB" }
            135   { "MEDIUM — RPC" }
            139   { "MEDIUM — NetBIOS" }
            default { "INFO" }
        }
        $Color = if ($Risk -like "HIGH*") { "Red" } elseif ($Risk -like "MEDIUM*") { "Yellow" } else { "Gray" }
        Write-Host ("  Port {0,5} | {1,-20} | {2}" -f $_.LocalPort, $_.LocalAddress, $Risk) -ForegroundColor $Color
    }
    Add-Result "CIS 9.1 - Port Inventory" $true "$($Ports.Count) ports identified"
} catch {
    Write-Host "  [ERROR] Could not scan listening ports: $_" -ForegroundColor Red
}

# ─── FINAL COMPLIANCE SUMMARY ─────────────────────────────────────────────────
Write-Host ""
Write-Host "╔══════════════════════════════════════════════════════════════════╗" -ForegroundColor White
Write-Host "║                   COMPLIANCE SUMMARY                           ║" -ForegroundColor White
Write-Host "╠══════════════════════════════════════════════════════════════════╣" -ForegroundColor White

$Total = $PassCount + $FailCount
$Score = if ($Total -gt 0) { [int](($PassCount / $Total) * 100) } else { 0 }

Write-Host ("║  PASS  : {0,3}  |  FAIL : {1,3}  |  SCORE : {2,3}%  |  Total: {3,3}  ║" -f $PassCount, $FailCount, $Score, $Total) -ForegroundColor $(if ($Score -ge 80) { "Green" } elseif ($Score -ge 60) { "Yellow" } else { "Red" })
Write-Host "╚══════════════════════════════════════════════════════════════════╝" -ForegroundColor White
Write-Host ""
Write-Host "  Compliance Table:" -ForegroundColor Gray
$Checks | Format-Table CISControl, Result, Detail -AutoSize
Write-Host ""
Write-Host "  Log saved to: $LogFile" -ForegroundColor Gray

Stop-Transcript | Out-Null
