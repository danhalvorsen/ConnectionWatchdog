# CHANGELOG — Phase0 Core Runtime

**Repository:** ConnectionWatchdog  
**Branch:** `main`  
**Status:** Stable / Locked  

---

## [v0.1.0] — 2025-10-21  
### Core Architecture
- Introduced deterministic PowerShell runtime layer for reproducible automation.  
- Added `Phase0.All.ps1` — main controller orchestrating features and enforcing PowerShell 7 execution.  
- Added `Dependencies.ps1` — environment initializer for `logs`, `temp`, and `Templates` directories.  
- Added `Assert.ps1` — lightweight assertion and diagnostic framework (`Assert-True`, `Assert-Path`, `Assert-WriteAccess`).  
- Added `Process-Handling.ps1` — out-of-process execution engine with PID management, timeout, and auto kill-script generation.  
- Added `Dummy.ps1` — placeholder feature verifying orchestration flow.  
- Added `Phase0.Bootstrap.ps1` — smart bootstrapper with upward `.git` discovery and branch auto-pull (`main` default).  
- Added `Phase0.GitSync.ps1` — repository synchronization and logging to `logs/git-sync.log`.  
- Added `Phase0.Container.ps1` — self-extracting generator to recreate the complete Phase0 structure.  
- Added `Verify-Phase0Dependencies.ps1` — dependency integrity and hash reporting.  
- Added `Publish-Phase0.ps1` — packaging helper for internal distribution.  

### Utility and Support
- Added auto-generated `kill-job-<id>.ps1` for controlled process termination.  
- Introduced `results/` and `logs/` folders for runtime artifacts.  
- Added `.gitignore` template excluding runtime outputs (`logs`, `temp`, `kill-job-*.ps1`, `phase0.hash.json`).  

### Integrity and Verification
- Implemented automatic restart under PowerShell 7 for cross-platform consistency.  
- Added runtime dependency validation and fatal assertion handling.  
- Introduced prototype for SHA-256 hash manifest verification.  

### Design Principles
- 100 % ASCII-safe for cross-machine reproducibility.  
- Domain-free: Phase0 provides only orchestration infrastructure.  
- Self-healing through container and bootstrap regeneration.  
- Open/Closed: designed for future feature expansion (Phase1 modules).  

---

## [Planned v0.2.0]
*(Future incremental milestone — released when the next phase is integrated)*

### Utility Pack
- `Phase0.Generate-HashManifest.ps1` — generate cryptographic fingerprints of core scripts.  
- `Phase0.Verify-HashManifest.ps1` — verify script hashes against manifest.  
- `Phase0.Log-Rotate.ps1` — prune old logs automatically.  

### Networking Baseline
- `Phase0.Network-Probe.ps1` — ICMP + TCP reachability checks.  
- Integration hook for `Phase1.TcpChecker` (Seq logging).  

### Security Enhancements
- Optional signature verification for core scripts.  
- Environment fingerprinting (machine, OS, PowerShell version).  

---

### Summary
Phase0 establishes a minimal, deterministic, self-verifying runtime foundation.  
It is considered locked for changes except verified security and maintenance updates.  
Future development continues in higher-phase modules (Phase1 and beyond).
