# Phase0 — Core Runtime System

## Why
Phase0 exists to provide a **deterministic, reproducible, and self-verifying foundation** for all higher-level automation phases.  
It removes environmental uncertainty by guaranteeing that each execution context begins from the same verified baseline.

The goal is simple: **no runtime drift**.  
Every process, feature, or module that runs inside this system can rely on the same validated environment, regardless of host, platform, or user.

---

## What
Phase0 is a minimal **PowerShell bootstrap and orchestration layer**.  
It provides:
- **Script integrity validation** through hash manifests.  
- **Dependency management** and environment initialization (`logs`, `temp`, `Templates`).  
- **Cross-version compatibility** by enforcing PowerShell 7 execution.  
- **Out-of-process execution** with PID control, timeout, and auto kill-scripts.  
- **Self-healing regeneration** through the container system.  
- **Git-based synchronization** for version alignment.  

The system is domain-free and acts purely as infrastructure for later phases such as Phase1 (feature modules, network probes, telemetry, etc.).

---

## When
Phase0 runs **before any application logic or domain features**.  
It is the first and lowest layer in the execution chain:

