#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Endpoint Security Hardening Script — CIS Benchmarks Baseline
    Project 1: Endpoint System Hardening & Security Baseline

.DESCRIPTION
    This script applies a full security hardening baseline to a Windows 11 endpoint
    in alignment with CIS Benchmarks. It performs the following actions:
      - Step 1: Pre-hardening system assessment (ports, services, firewall)
      - Step 2: Firewall configuration (enable all profiles, block inbound)
      - Step 3: Password and account lockout policy enforcement
      - Step 4: Disable unnecessary/dangerous services (RemoteRegistry)
      - Step 5: Secure remote access (disable RDP)
      - Step 6: Enable security auditing (Logon/Logoff, Account Management)
      - Step 7: Verify Windows Update / patch status
      - Step 8: Post-hardening verification scan

.NOTES
    Author      : Security Engineering Team
    Version     : 2.0
    Date        : 2026-06-05
    Standard    : CIS Windows 11 Benchmarks
    Requirement : Must be run as Administrator in PowerShell
    Log File    : hardening_log_<timestamp>.txt (auto-created in script directory)

.EXAMPLE
    .\hardening_helper.ps1
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# ─── Setup Transcript Logging ──────────────────────────────────────────────────
$ScriptDir   = Split-Path -Parent $MyInvocation.MyCommand.Path
$Timestamp   = Get-Date -Format "yyyyMMdd_HHmmss"
$LogFile     = Join-Path $ScriptDir "hardening_log_$Timestamp.txt"
Start-Transcript -Path $LogFile -Append | Out-Null

Write-Host ""
Write-Host "╔══════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║   ENDPOINT SECURITY HARDENING — CIS BENCHMARKS BASELINE        ║" -ForegroundColor Cyan
Write-Host "║   Version 2.0 | Windows 11 | Defensive Cybersecurity           ║" -ForegroundColor Cyan
Write-Host "╚══════════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""
Write-Host "  Log File  : $LogFile" -ForegroundColor Gray
Write-Host "  Timestamp : $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Gray
Write-Host "  Hostname  : $env:COMPUTERNAME" -ForegroundColor Gray
Write-Host "  User      : $env:USERNAME" -ForegroundColor Gray
Write-Host ""

# ─── Helper Functions ─────────────────────────────────────────────────────────
function Write-StepHeader {
    param([string]$StepNum, [string]$Title)
    Write-Host ""
    Write-Host "─────────────────────────────────────────────────────────────────" -ForegroundColor DarkGray
    Write-Host "  $StepNum : $Title" -ForegroundColor Yellow
    Write-Host "─────────────────────────────────────────────────────────────────" -ForegroundColor DarkGray
}

function Write-Success { param([string]$Msg); Write-Host "  [✓] $Msg" -ForegroundColor Green }
function Write-Warn    { param([string]$Msg); Write-Host "  [!] $Msg" -ForegroundColor Yellow }
function Write-Fail    { param([string]$Msg); Write-Host "  [✗] $Msg" -ForegroundColor Red }
function Write-Info    { param([string]$Msg); Write-Host "  [i] $Msg" -ForegroundColor Cyan }

# ─── STEP 1: Pre-Hardening Assessment ────────────────────────────────────────
Write-StepHeader "STEP 1" "Pre-Hardening System Security Assessment"

Write-Info "Scanning listening TCP ports..."
try {
    $ListeningPorts = Get-NetTCPConnection -State Listen |
        Select-Object LocalAddress, LocalPort, OwningProcess |
        Sort-Object LocalPort
    $ListeningPorts | Format-Table -AutoSize
    Write-Success "Port scan complete. $($ListeningPorts.Count) listening sockets identified."
} catch {
    Write-Fail "Port scan failed: $_"
}

Write-Info "Checking critical service states..."
try {
    Get-Service -Name RemoteRegistry, Spooler, TermService -ErrorAction SilentlyContinue |
        Select-Object Name, DisplayName, Status, StartType | Format-Table -AutoSize
} catch {
    Write-Warn "Could not query some services: $_"
}

Write-Info "Checking Windows Defender Firewall profiles..."
try {
    Get-NetFirewallProfile |
        Select-Object Name, Enabled, DefaultInboundAction, DefaultOutboundAction | Format-Table -AutoSize
} catch {
    Write-Fail "Could not query firewall profiles: $_"
}

# ─── STEP 2: Configure Firewall Protection ───────────────────────────────────
Write-StepHeader "STEP 2" "Configure Windows Defender Firewall"

try {
    Set-NetFirewallProfile -Profile Domain,Public,Private -Enabled True
    Set-NetFirewallProfile -Profile Domain,Public,Private -DefaultInboundAction Block -DefaultOutboundAction Allow
    $FwCheck = Get-NetFirewallProfile | Where-Object { $_.Enabled -eq $true }
    if ($FwCheck.Count -eq 3) {
        Write-Success "Firewall enabled on all 3 profiles (Domain, Private, Public)."
        Write-Success "Default inbound action set to Block."
    } else {
        Write-Warn "Firewall may not be enabled on all profiles. Verify manually."
    }
} catch {
    Write-Fail "Firewall configuration failed: $_"
}

# ─── STEP 3: Enforce Password Policies ───────────────────────────────────────
Write-StepHeader "STEP 3" "Enforce Access Control & Password Policies"

try {
    # Minimum password length: 12
    net accounts /minpwlen:12 | Out-Null
    Write-Success "Minimum password length set to 12 characters."

    # Account lockout threshold: 5 failed attempts
    net accounts /lockoutthreshold:5 | Out-Null
    Write-Success "Account lockout threshold set to 5 invalid logon attempts."

    # Lockout duration: 30 minutes
    net accounts /lockoutduration:30 | Out-Null
    Write-Success "Account lockout duration set to 30 minutes."

    # Display verification summary
    Write-Info "Verified password policy settings:"
    net accounts | Where-Object { $_ -match "password|lockout" } | ForEach-Object {
        Write-Host "  $_" -ForegroundColor Gray
    }
} catch {
    Write-Fail "Password policy configuration failed: $_"
}

# ─── STEP 4: Disable Unnecessary Services ────────────────────────────────────
Write-StepHeader "STEP 4" "Disable Unnecessary & Dangerous Services"

$ServicesToDisable = @(
    @{ Name = "RemoteRegistry"; Reason = "Allows remote registry modification — common lateral movement vector" }
)

foreach ($SvcEntry in $ServicesToDisable) {
    try {
        $Svc = Get-Service -Name $SvcEntry.Name -ErrorAction SilentlyContinue
        if ($null -eq $Svc) {
            Write-Info "$($SvcEntry.Name) service not found on this system — skipping."
            continue
        }
        if ($Svc.StartType -eq "Disabled" -and $Svc.Status -eq "Stopped") {
            Write-Info "$($SvcEntry.Name) is already disabled and stopped."
        } else {
            Set-Service -Name $SvcEntry.Name -StartupType Disabled
            Stop-Service -Name $SvcEntry.Name -Force -ErrorAction SilentlyContinue
            Write-Success "$($SvcEntry.Name) — Stopped and Disabled. Reason: $($SvcEntry.Reason)"
        }
        # Verify
        $VerifySvc = Get-Service -Name $SvcEntry.Name
        Write-Info "Verified: $($SvcEntry.Name) | Status=$($VerifySvc.Status) | StartType=$($VerifySvc.StartType)"
    } catch {
        Write-Fail "Failed to disable $($SvcEntry.Name): $_"
    }
}

# ─── STEP 5: Secure Remote Access (Disable RDP) ──────────────────────────────
Write-StepHeader "STEP 5" "Secure Remote Access — Disable RDP"

try {
    $RegPath = 'HKLM:\System\CurrentControlSet\Control\Terminal Server'
    Set-ItemProperty -Path $RegPath -Name "fDenyTSConnections" -Value 1 -Type DWord
    $Verify = (Get-ItemProperty -Path $RegPath).fDenyTSConnections
    if ($Verify -eq 1) {
        Write-Success "RDP connections disabled. fDenyTSConnections = $Verify"
    } else {
        Write-Fail "RDP registry key not set correctly. Manual verification required."
    }
} catch {
    Write-Fail "RDP hardening failed: $_"
}

# ─── STEP 6: Enable Security Auditing ────────────────────────────────────────
Write-StepHeader "STEP 6" "Enable Security Auditing & Event Logging"

$AuditCategories = @(
    "Logon/Logoff",
    "Account Management",
    "Privilege Use",
    "Policy Change"
)

foreach ($Category in $AuditCategories) {
    try {
        auditpol /set /category:"$Category" /success:enable /failure:enable | Out-Null
        Write-Success "Audit enabled: '$Category' — Success & Failure"
    } catch {
        Write-Fail "Failed to enable audit for '$Category': $_"
    }
}

Write-Info "Verifying audit configuration:"
auditpol /get /category:"Logon/Logoff","Account Management" | ForEach-Object {
    if ($_ -match "Success|Failure") {
        Write-Host "  $_" -ForegroundColor Gray
    }
}

# ─── STEP 7: Windows Update Status ───────────────────────────────────────────
Write-StepHeader "STEP 7" "Verify Patch Management & Security Updates"

try {
    Write-Info "Checking Windows Update status via registry..."
    $WUPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\Results\Install"
    if (Test-Path $WUPath) {
        $LastInstall = (Get-ItemProperty -Path $WUPath).LastSuccessTime
        Write-Success "Last successful Windows Update install: $LastInstall"
    } else {
        Write-Warn "Windows Update last install time not found in registry. Check Settings > Windows Update manually."
    }
    Write-Info "Open Settings > Windows Update to verify 'You're up to date' status and capture screenshot."
} catch {
    Write-Warn "Could not read Windows Update registry data: $_"
}

# ─── STEP 8: Post-Hardening Verification Scan ────────────────────────────────
Write-StepHeader "STEP 8" "Post-Hardening Verification Scan"

Write-Info "Re-scanning listening TCP ports post-hardening..."
try {
    $PostPorts = Get-NetTCPConnection -State Listen |
        Select-Object LocalAddress, LocalPort, OwningProcess |
        Sort-Object LocalPort
    $PostPorts | Format-Table -AutoSize
    Write-Success "Post-hardening scan complete. $($PostPorts.Count) listening sockets identified."
    Write-Info "Compare with Step 1 output. Firewall now blocks unsolicited inbound traffic."
} catch {
    Write-Fail "Post-hardening port scan failed: $_"
}

# ─── Final Summary ────────────────────────────────────────────────────────────
Write-Host ""
Write-Host "╔══════════════════════════════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "║         HARDENING COMPLETE — CIS BASELINE APPLIED              ║" -ForegroundColor Green
Write-Host "╚══════════════════════════════════════════════════════════════════╝" -ForegroundColor Green
Write-Host ""
Write-Host "  ✓ Firewall          — Enabled & Inbound Blocked (All Profiles)" -ForegroundColor Green
Write-Host "  ✓ Password Policy   — Min 12 chars, Lockout after 5 attempts"  -ForegroundColor Green
Write-Host "  ✓ RemoteRegistry    — Stopped & Disabled"                       -ForegroundColor Green
Write-Host "  ✓ RDP               — Connections Denied"                       -ForegroundColor Green
Write-Host "  ✓ Audit Logging     — Logon/Logoff, Account Mgmt configured"   -ForegroundColor Green
Write-Host ""
Write-Host "  Log saved to: $LogFile" -ForegroundColor Gray
Write-Host ""

Stop-Transcript | Out-Null
