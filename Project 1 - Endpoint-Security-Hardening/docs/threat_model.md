# Threat Model — Endpoint System Hardening
## CIS Benchmarks | Project 1 | Defensive Cybersecurity

---

## 1. Overview

This document presents the structured threat model for the Windows 11 target workstation prior to and following CIS Benchmarks hardening. The threat model identifies the attack surface, relevant threat actors, attack vectors, and the mitigating controls applied.

**System Under Review**: Windows 11 Home workstation  
**IP Address**: 192.168.1.10  
**Environment**: Internal network (LAN-connected, no DMZ)  
**Assessment Date**: June 5, 2026

---

## 2. Asset Identification

| Asset | Description | Criticality |
|---|---|---|
| Windows 11 Workstation | Primary endpoint under assessment | HIGH |
| Local User Accounts | Authentication credentials stored on endpoint | HIGH |
| Windows Registry | System configuration store — controls security state | HIGH |
| Security Event Logs | Audit trail for incident investigation | MEDIUM |
| Network Interfaces | IPv4 (192.168.1.10) + IPv6 (::) — dual stack | MEDIUM |
| Installed Services | RemoteRegistry, Spooler, TermService | MEDIUM |

---

## 3. Threat Actor Profiles

| Actor Type | Motivation | Capability | Likelihood |
|---|---|---|---|
| **External Opportunistic Attacker** | Data theft, ransomware deployment | Low–Medium (automated scanners) | HIGH on internet-facing hosts |
| **Insider Threat** | Unauthorized privilege escalation | Medium (knows internal network) | MEDIUM |
| **Lateral Movement Actor** | Pivoting through compromised network host | Medium–High | MEDIUM |
| **Automated Malware / Worm** | Self-propagation via SMB/RPC | Low (script-based) | HIGH without hardening |

---

## 4. Attack Surface Map (Pre-Hardening)

```
                   ┌─────────────────────────────────┐
  EXTERNAL/LAN ──▶ │  192.168.1.10 — Windows 11      │
                   │                                  │
                   │  Port 135/TCP (RPC)    ← OPEN    │  ← MS03-026 class exploits
                   │  Port 139/TCP (NetBIOS)← OPEN    │  ← NBNS Poisoning / SMB relay
                   │  Port 445/TCP (SMB)    ← OPEN    │  ← EternalBlue (CVE-2017-0144)
                   │  RemoteRegistry SVC    ← RUNNING │  ← Remote registry modification
                   │  RDP (3389)            ← UNKNOWN │  ← Unauthorized remote access
                   │  No Audit Policies     ← ACTIVE  │  ← Undetected compromise
                   │  Weak Password Policy  ← DEFAULT │  ← Brute force / credential stuffing
                   └─────────────────────────────────┘
```

---

## 5. STRIDE Threat Analysis

### T1 — Spoofing (Authentication Bypass)

| Field | Detail |
|---|---|
| **Threat** | Attacker performs brute force against local user accounts |
| **Attack Vector** | Network (RDP if enabled) or physical access |
| **Pre-Hardening Risk** | HIGH — no lockout policy, default password requirements |
| **Control Applied** | 12-character minimum password, 5-attempt lockout (net accounts) |
| **Post-Hardening Risk** | LOW |
| **CIS Mapping** | CIS Control 5.2 |

---

### T2 — Tampering (Unauthorized Configuration Changes)

| Field | Detail |
|---|---|
| **Threat** | Attacker leverages RemoteRegistry to modify system settings remotely |
| **Attack Vector** | Network — RemoteRegistry service accessible on LAN |
| **Pre-Hardening Risk** | MEDIUM — service running and reachable |
| **Control Applied** | RemoteRegistry stopped and startup type set to Disabled |
| **Post-Hardening Risk** | LOW |
| **CIS Mapping** | CIS Control 4.1 |

---

### T3 — Repudiation (Undetected Malicious Activity)

| Field | Detail |
|---|---|
| **Threat** | Attacker performs unauthorized logon; no evidence recorded |
| **Attack Vector** | Any — logon events not captured without audit policies |
| **Pre-Hardening Risk** | HIGH — default Windows audit policies are minimal |
| **Control Applied** | auditpol configured: Logon/Logoff, Account Management, Privilege Use — Success & Failure |
| **Post-Hardening Risk** | LOW |
| **CIS Mapping** | CIS Control 8.1 |

---

### T4 — Information Disclosure (Data Leakage via SMB/NetBIOS)

| Field | Detail |
|---|---|
| **Threat** | Attacker enumerates shares, usernames, or OS info via SMB / NetBIOS |
| **Attack Vector** | Port 445 (SMB) or 139 (NetBIOS) — exposed on all interfaces |
| **Pre-Hardening Risk** | MEDIUM — ports listening, potential for null session enumeration |
| **Control Applied** | Windows Defender Firewall inbound block applied on all profiles |
| **Post-Hardening Risk** | LOW — firewall drops all inbound unsolicited connections |
| **CIS Mapping** | CIS Control 4.1, 9.1 |

---

### T5 — Denial of Service (System Crash via RPC Exploits)

| Field | Detail |
|---|---|
| **Threat** | Malformed RPC packets crash the RPC service (MS03-026 class) |
| **Attack Vector** | Port 135/TCP — RPC Endpoint Mapper exposed on all interfaces |
| **Pre-Hardening Risk** | MEDIUM — historical high-severity vector |
| **Control Applied** | Firewall inbound block; Windows Update verified current |
| **Post-Hardening Risk** | LOW |
| **CIS Mapping** | CIS Control 4.1, 12.1 |

---

### T6 — Elevation of Privilege (Lateral Movement via RDP)

| Field | Detail |
|---|---|
| **Threat** | Attacker with stolen credentials uses RDP for full GUI remote access |
| **Attack Vector** | Port 3389/TCP (if enabled) over network |
| **Pre-Hardening Risk** | MEDIUM–HIGH — RDP state unverified before hardening |
| **Control Applied** | fDenyTSConnections registry key set to 1 (deny all RDP) |
| **Post-Hardening Risk** | LOW — registry blocks all incoming Remote Desktop sessions |
| **CIS Mapping** | CIS Control 4.1 |

---

## 6. Attack Path Diagram (Pre-Hardening Scenario)

```
Attacker (LAN)
     │
     ├─▶ Scan target: nmap 192.168.1.10
     │      → Port 445 OPEN, Port 135 OPEN, Port 139 OPEN
     │
     ├─▶ SMB Exploit (EternalBlue / CVE-2017-0144)
     │      → Gain SYSTEM-level code execution
     │
     ├─▶ RemoteRegistry pivot
     │      → Modify HKLM keys to persist backdoor
     │
     ├─▶ Disable security tools via registry
     │      → Disable Windows Defender, audit logs
     │
     └─▶ Establish persistence / Data exfiltration
            → No audit trail recorded (audit policies off)
            → No lockout protection on accounts
```

---

## 7. Residual Risk Assessment (Post-Hardening)

| Threat | Residual Risk | Justification |
|---|---|---|
| Brute Force | LOW | Lockout after 5 attempts; 12-char minimum |
| SMB Exploit | LOW | Firewall blocks all inbound; patches current |
| RDP Abuse | NEGLIGIBLE | Registry denies all connections |
| RemoteRegistry Abuse | NEGLIGIBLE | Service stopped and disabled |
| Undetected Compromise | LOW | Full audit logging active |
| Zero-Day Exploit | MEDIUM | Cannot be fully mitigated; requires ongoing monitoring |

---

## 8. Threat Model Conclusion

The endpoint has been systematically hardened against the most prevalent attack vectors targeting Windows workstations. The CIS Benchmarks baseline controls address all identified STRIDE threat categories. The remaining residual risk (zero-day) is inherent to any software-based system and is mitigated through ongoing patch management and audit log monitoring.
