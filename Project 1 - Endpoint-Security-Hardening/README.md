<div align="center">

# 🔐 Project 1: Endpoint System Hardening & Security Baseline

**CIS Benchmarks Implementation | Windows 11 | Defensive Cybersecurity**

![Platform](https://img.shields.io/badge/Platform-Windows%2011-blue?style=for-the-badge&logo=windows)
![Standard](https://img.shields.io/badge/Standard-CIS%20Benchmarks-red?style=for-the-badge)
![Status](https://img.shields.io/badge/Status-Completed-brightgreen?style=for-the-badge)
![Language](https://img.shields.io/badge/Script-PowerShell-blue?style=for-the-badge&logo=powershell)
![Type](https://img.shields.io/badge/Type-Security%20Hardening-orange?style=for-the-badge)

> **Internship Project** · Endpoint Security · Configuration Hardening · CIS Compliance · Risk Reduction

</div>

---

## 📋 Table of Contents

- [Overview](#overview)
- [Features](#features)
- [Technologies Used](#technologies-used)
- [CIS Controls Mapped](#cis-controls-mapped)
- [Folder Structure](#folder-structure)
- [Hardening Steps Implemented](#hardening-steps-implemented)
- [Risk Reduction Summary](#risk-reduction-summary)
- [Usage](#usage)
- [Evidence Screenshots](#evidence-screenshots)
- [Learning Outcomes](#learning-outcomes)
- [Author](#author)

---

## 🧭 Overview

This project implements a complete **Endpoint Security Baseline** on a Windows 11 workstation following the **Center for Internet Security (CIS) Benchmarks**. The goal is to reduce the system's attack surface, enforce strict access controls, enable security monitoring, and verify the hardened state through before/after scan comparisons.

This project was completed as part of a **Defensive Cybersecurity Internship** and covers:
- Pre-hardening system assessment
- Firewall configuration and network boundary protection
- Access control and credential policy enforcement
- Unnecessary service elimination
- Remote access restriction
- Security event logging and monitoring
- System patch verification
- Post-hardening compliance verification

---

## ✨ Features

| Feature | Description |
|---|---|
| 🔥 **Firewall Hardening** | Windows Defender Firewall enabled across Domain, Private, and Public profiles with default inbound blocking |
| 🔑 **Password Policy Enforcement** | Minimum 12-character length and 5-attempt account lockout threshold applied |
| 🛑 **Service Minimization** | RemoteRegistry service stopped and disabled to block lateral movement |
| 🖥️ **RDP Lockdown** | Remote Desktop connections explicitly denied via registry configuration |
| 📋 **Audit Logging** | Logon/Logoff success and failure events configured for Security Event Log capture |
| 🔄 **Patch Verification** | Windows Update and Microsoft Defender Antivirus definitions verified current |
| 📊 **Scan Comparison** | Pre- and post-hardening TCP port scans recorded and compared |
| 📄 **Professional Report** | Executive-grade PDF security baseline report with evidence screenshots |
| ⚙️ **Automated Scripts** | PowerShell hardening and verification scripts for repeatable deployment |

---

## 🛠️ Technologies Used

| Technology | Purpose |
|---|---|
| **PowerShell 5.1+** | System configuration, service management, auditing |
| **Windows Defender Firewall** | Network boundary protection |
| **Windows Security Event Log** | Authentication and audit event collection |
| **auditpol.exe** | Granular audit policy configuration |
| **net accounts** | Local password and lockout policy enforcement |
| **Windows Registry** | RDP access control configuration |
| **Python 3 + python-docx** | Professional report generation |
| **Python 3 + reportlab** | PDF report generation with embedded evidence |

---

## 🗺️ CIS Controls Mapped

| CIS Control | Title | Implemented By |
|---|---|---|
| **CIS 4.1** | Establish & Maintain Secure Configuration | Firewall rules, RDP lockdown, service minimization |
| **CIS 5.2** | Use Unique Passwords | 12-char minimum + account lockout policy |
| **CIS 8.1** | Establish & Maintain Audit Log Management | auditpol Logon/Logoff success & failure events |
| **CIS 9.1** | Associate Active Ports with Asset Inventory | Pre & post TCP port scan comparison |
| **CIS 12.1** | Ensure Network Infrastructure is Up-to-Date | Windows Update & Defender definitions verified |

---

## 📁 Folder Structure

```
Project 1 - Endpoint-Security-Hardening/
│
├── 📄 README.md                          ← You are here
├── 📄 CHANGELOG.md                       ← Version history
├── 📄 .gitignore                         ← Git exclusions
│
├── 📂 configs/
│   ├── hardening_helper.ps1              ← Full automated hardening script (Run as Admin)
│   └── verify_hardening.ps1             ← Read-only audit/verification script
│
├── 📂 scans/
│   ├── before_scan_results.txt           ← Pre-hardening TCP port baseline scan
│   └── after_scan_results.txt           ← Post-hardening TCP port verification scan
│
├── 📂 screenshots/
│   ├── step1_pre_hardening_ports.png     ← Initial port assessment evidence
│   ├── step2_firewall_status.png         ← Firewall configuration evidence
│   ├── step3_password_policy.png         ← Password policy enforcement evidence
│   ├── step4_disabled_services.png       ← Service minimization evidence
│   ├── step5_secure_remote_access.png    ← RDP lockdown evidence
│   ├── step6_audit_policies.png          ← Audit policy configuration evidence
│   ├── step7_windows_update.png          ← Patch verification evidence
│   └── step8_post_hardening_ports.png   ← Post-hardening scan evidence
│
├── 📂 reports/
│   ├── System_Hardening_Security_Baseline_Report.pdf  ← Executive PDF report
│   ├── system_hardening_report.md        ← Markdown version of report
│   └── generate_docx_report.py          ← DOCX report builder script
│
└── 📂 docs/
    ├── threat_model.md                   ← Attack surface & threat model
    └── nist_csf_mapping.md              ← NIST CSF + CIS alignment matrix
```

---

## 🔒 Hardening Steps Implemented

### Step 1 — Pre-Hardening System Assessment
Captured the initial state of the system — listening TCP ports, active services, and firewall profile status — before applying any hardening configurations.

**Key Findings (Pre-Hardening):**
- Port 135 (RPC) exposed on all interfaces
- Port 445 (SMB) exposed on all interfaces  
- Port 139 (NetBIOS) exposed on LAN interface (192.168.1.10)
- RemoteRegistry service: Running and Enabled
- RDP: Allowed (fDenyTSConnections = 0)

### Step 2 — Firewall Configuration
```powershell
Set-NetFirewallProfile -Profile Domain,Public,Private -Enabled True
Set-NetFirewallProfile -Profile Domain,Public,Private -DefaultInboundAction Block
```

### Step 3 — Password Policy Enforcement
```powershell
net accounts /minpwlen:12
net accounts /lockoutthreshold:5
net accounts /lockoutduration:30
```

### Step 4 — Service Minimization
```powershell
Set-Service -Name RemoteRegistry -StartupType Disabled
Stop-Service -Name RemoteRegistry -Force
```

### Step 5 — RDP Hardening
```powershell
Set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server' `
    -Name "fDenyTSConnections" -Value 1
```

### Step 6 — Security Auditing
```powershell
auditpol /set /category:"Logon/Logoff" /success:enable /failure:enable
auditpol /set /category:"Account Management" /success:enable /failure:enable
auditpol /set /category:"Privilege Use" /success:enable /failure:enable
```

### Step 7 — Patch Verification
Verified Windows Update status via Settings UI and confirmed Microsoft Defender Antivirus Security Intelligence update (KB2267602 v1.453.248.0) installed.

### Step 8 — Post-Hardening Verification
Re-ran TCP port scan to confirm attack surface reduction. Firewall now actively drops inbound unsolicited connections. RemoteRegistry and RDP lateral movement paths eliminated.

---

## 📉 Risk Reduction Summary

| Threat Vector | Pre-Hardening | Post-Hardening | Reduction |
|---|---|---|---|
| Brute Force Attacks | 🔴 HIGH | 🟢 LOW | ✅ Mitigated |
| Unauthorized Remote Exploit | 🔴 HIGH | 🟢 LOW | ✅ Mitigated |
| Lateral Movement (Registry) | 🟡 MEDIUM | 🟢 LOW | ✅ Mitigated |
| Undetected Host Compromise | 🔴 HIGH | 🟢 LOW | ✅ Mitigated |
| Unpatched Vulnerabilities | 🟡 MEDIUM | 🟢 LOW | ✅ Mitigated |

---

## ⚙️ Usage

### Run Full Hardening (Administrator Required)
```powershell
# Open PowerShell as Administrator, then run:
.\configs\hardening_helper.ps1
```

### Run Read-Only Audit Verification
```powershell
# Checks current state without making any changes
.\configs\verify_hardening.ps1
```

### Regenerate PDF Report
```powershell
python reports\generate_docx_report.py
```

> ⚠️ **Warning**: `hardening_helper.ps1` makes live system changes. Always test in a non-production environment first.

---

## 🖼️ Evidence Screenshots

All evidence screenshots are stored in `screenshots/` and embedded in the executive PDF report located at `reports/System_Hardening_Security_Baseline_Report.pdf`.

---

## 🎓 Learning Outcomes

Through this project, the following skills were demonstrated:

- **Windows Security Hardening** — Applying CIS Benchmark controls to a real Windows 11 endpoint
- **PowerShell Scripting** — Writing administrative automation scripts for security configuration
- **Risk Assessment** — Identifying and quantifying threats before/after a hardening process
- **Security Documentation** — Producing executive-grade compliance reports and technical write-ups
- **Audit Policy Configuration** — Configuring Windows audit policies for security event collection
- **Network Analysis** — Performing TCP port scans and interpreting results in a security context
- **Framework Alignment** — Mapping applied controls to CIS Controls v8 and NIST CSF standards

---

## 👤 Author

**Abdul Rahman**  
*Cybersecurity Intern | Endpoint Security | Defensive Security*

- 🔗 GitHub: [github.com/abdxl](https://github.com/abdxl)
- 📧 Internship Project — Defensive Cybersecurity Track

---

<div align="center">

*This project was completed as part of a Defensive Cybersecurity Internship.*  
*All configurations were applied to a controlled Windows 11 test environment.*

</div>
