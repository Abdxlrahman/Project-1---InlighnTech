# NIST CSF + CIS Controls v8 — Alignment Matrix
## Project 1: Endpoint System Hardening & Security Baseline

---

## 1. Overview

This document maps every hardening control implemented in this project to both the **NIST Cybersecurity Framework (CSF) v1.1** and **CIS Controls v8**. This dual-mapping demonstrates alignment with two leading industry security standards, strengthening the compliance posture of this project submission.

---

## 2. Framework Summary

| Framework | Version | Purpose |
|---|---|---|
| **NIST CSF** | v1.1 | Five-function risk management framework (Identify, Protect, Detect, Respond, Recover) |
| **CIS Controls** | v8 | 18 prioritized safeguards to defend against known cyber threats |

---

## 3. NIST CSF Function Mapping

### IDENTIFY (ID)
*Develop organizational understanding to manage cybersecurity risk*

| Sub-Category | Control Implemented | Project Evidence |
|---|---|---|
| ID.AM-1: Inventory physical devices and systems | Documented target workstation (IP, OS, role) | Report header section |
| ID.RA-1: Asset vulnerabilities identified and documented | Pre-hardening port scan — identified exposed services | `scans/before_scan_results.txt` |
| ID.RA-3: Threats, internal and external, identified | STRIDE threat model documented | `docs/threat_model.md` |

---

### PROTECT (PR)
*Develop and implement appropriate safeguards*

| Sub-Category | Control Implemented | Project Evidence |
|---|---|---|
| PR.AC-1: Identities and credentials managed | Password min 12 chars, lockout 5 attempts | `step3_password_policy.png` |
| PR.AC-3: Remote access managed | RDP disabled via registry (fDenyTSConnections = 1) | `step5_secure_remote_access.png` |
| PR.IP-1: Baseline configuration maintained | CIS Benchmarks hardening baseline applied | All steps 1–8 |
| PR.IP-3: Configuration change control | RemoteRegistry disabled; hardening script documented | `configs/hardening_helper.ps1` |
| PR.IP-12: Vulnerabilities identified and remediated | Windows Update and Defender definitions verified | `step7_windows_update.png` |
| PR.PT-3: Principle of least functionality applied | Unnecessary services (RemoteRegistry) disabled | `step4_disabled_services.png` |
| PR.PT-4: Communications and control networks protected | Firewall enabled; default inbound block on all profiles | `step2_firewall_status.png` |

---

### DETECT (DE)
*Develop and implement appropriate activities to identify cybersecurity events*

| Sub-Category | Control Implemented | Project Evidence |
|---|---|---|
| DE.AE-1: Network operations baseline established | Pre-hardening port scan documents normal network state | `scans/before_scan_results.txt` |
| DE.CM-1: Network monitored for cybersecurity events | Firewall logging enabled; audit policies configured | `step6_audit_policies.png` |
| DE.CM-3: Personnel activity monitored | Logon/Logoff success and failure auditing enabled | `step6_audit_policies.png` |
| DE.CM-7: Monitoring performed for unauthorized connections | auditpol — Account Management + Privilege Use auditing | PowerShell: `auditpol` commands |

---

### RESPOND (RS)
*Develop and implement appropriate activities to take action*

| Sub-Category | Control Implemented | Project Evidence |
|---|---|---|
| RS.AN-1: Notifications from detection systems investigated | Audit event logs provide evidence for incident triage | Security Event Log (Event ID 4624/4625) |
| RS.MI-3: Newly identified vulnerabilities mitigated | Disabled attack-surface services; firewall blocks vectors | Steps 2, 4, 5 |

---

### RECOVER (RC)
*Develop and implement appropriate activities to maintain resilience*

| Sub-Category | Control Implemented | Project Evidence |
|---|---|---|
| RC.IM-1: Recovery plans incorporate lessons learned | Maintenance recommendations documented in report | `reports/system_hardening_report.md` |
| RC.CO-1: Public relations managed | Not applicable (test environment) | — |

---

## 4. CIS Controls v8 — Full Mapping

| CIS Control | Safeguard | Implementation | Status |
|---|---|---|---|
| **4 — Secure Configuration** | 4.1 Establish and Maintain Secure Config | Firewall hardening, service minimization, RDP lockdown applied | ✅ |
| **5 — Account Management** | 5.2 Use Unique Passwords | 12-char minimum + 5-attempt lockout (net accounts) | ✅ |
| **5 — Account Management** | 5.3 Disable Dormant Accounts | RemoteRegistry (service account vector) disabled | ✅ |
| **8 — Audit Log Management** | 8.1 Establish & Maintain Audit Log Mgmt | auditpol configured for Logon/Logoff, Account Mgmt, Privilege Use | ✅ |
| **8 — Audit Log Management** | 8.2 Collect Audit Logs | Security Event Log collects all audit events | ✅ |
| **9 — Email & Web Browser Protections** | 9.1 Ensure Use of Only Fully Supported Browsers/Email Clients | Windows Update verified; patches current | ✅ |
| **12 — Network Infrastructure Management** | 12.1 Ensure Network Infrastructure is Up-to-Date | Windows Update and Defender definitions verified | ✅ |
| **13 — Network Monitoring & Defense** | 13.1 Centralize Security Event Alerting | Audit events centralized in Windows Security Event Log | ✅ |

---

## 5. Compliance Scorecard

| Framework | Controls Addressed | Controls Verified | Compliance % |
|---|---|---|---|
| NIST CSF v1.1 | 14 Sub-Categories | 14 | 100% |
| CIS Controls v8 | 8 Safeguards | 8 | 100% |

---

## 6. Key Windows Event IDs — Security Monitoring Reference

| Event ID | Description | Audit Category |
|---|---|---|
| 4624 | Successful account logon | Logon/Logoff |
| 4625 | Failed account logon attempt | Logon/Logoff |
| 4634 | Account logoff | Logon/Logoff |
| 4648 | Logon attempt using explicit credentials | Logon/Logoff |
| 4720 | User account created | Account Management |
| 4722 | User account enabled | Account Management |
| 4725 | User account disabled | Account Management |
| 4740 | User account locked out | Account Management |
| 4776 | Domain controller validated credentials | Account Management |
| 4672 | Special privileges assigned to new logon | Privilege Use |

> These Event IDs should be monitored via Windows Event Viewer → Windows Logs → Security for ongoing security operations.

---

*This alignment matrix was prepared as part of Project 1 — Endpoint System Hardening & Security Baseline, Defensive Cybersecurity Internship.*
