# Changelog

All notable changes to Project 1 — Endpoint System Hardening & Security Baseline are documented in this file.

Format follows [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

---

## [v1.0.0] — 2026-06-05 — Initial Release

### Added
- Complete CIS Benchmarks security hardening baseline applied to Windows 11 Home workstation
- Pre-hardening TCP port scan and system security assessment (Step 1)
- Windows Defender Firewall enabled across all profiles with default inbound block (Step 2)
- Password policy enforced — 12 character minimum length, 5-attempt lockout threshold (Step 3)
- RemoteRegistry service stopped and permanently disabled (Step 4)
- Remote Desktop Protocol (RDP) denied via registry configuration (Step 5)
- Security audit policies enabled — Logon/Logoff, Account Management, Privilege Use (Step 6)
- Windows Update and Microsoft Defender definitions verified as current (Step 7)
- Post-hardening TCP port verification scan completed (Step 8)
- Evidence screenshots captured for all 8 hardening steps
- Executive-grade PDF security baseline report generated
- `hardening_helper.ps1` — PowerShell automation script for repeatable deployment
- `verify_hardening.ps1` — Read-only compliance audit and verification script
- `before_scan_results.txt` — Annotated pre-hardening port scan with risk classification
- `after_scan_results.txt` — Post-hardening verification with compliance delta comparison
- `docs/threat_model.md` — Structured threat model and attack surface mapping
- `docs/nist_csf_mapping.md` — NIST CSF + CIS Controls v8 alignment matrix
- `README.md` — Professional GitHub-quality project documentation
- `.gitignore` — Standard exclusion file for Windows/PowerShell/Python projects

### Security Controls Applied
- CIS Control 4.1 — Secure endpoint configuration
- CIS Control 5.2 — Password length and lockout enforcement
- CIS Control 8.1 — Audit log management
- CIS Control 9.1 — Network port inventory and mapping
- CIS Control 12.1 — Patch and definition management

### Compliance Status
- **Overall**: ✅ CIS Benchmarks Baseline — FULLY COMPLIANT
- **Verification**: All 8 hardening steps verified with evidence screenshots
- **Documentation**: Executive PDF report produced and archived

---

## [v0.1.0] — 2026-06-03 — Project Initialization

### Added
- Internship PDF requirements reviewed and analysed
- Project folder structure initialized
- Initial scope and objectives defined
- CIS Benchmarks Windows 11 reference consulted
