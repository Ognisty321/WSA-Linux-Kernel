# Security Policy

## Scope

This policy covers the WSA x86_64 ReSukiSU + SUSFS + KPM kernel maintained at [Ognisty321/WSA-Linux-Kernel](https://github.com/Ognisty321/WSA-Linux-Kernel) and its companion ReSukiSU fork at [Ognisty321/ReSukiSU](https://github.com/Ognisty321/ReSukiSU).

Issues in upstream Linux, upstream KernelSU, upstream ReSukiSU or upstream SUSFS that are not specific to this WSA x86_64 port should be reported to those projects.

## Supported Versions

Security fixes target the current `main` branch and the latest release listed in the WSA kernel release page. Older local build artifacts are supported only when the issue reproduces on current `main` or the latest release.

## Reporting a Vulnerability

If you believe you have found a security vulnerability in this kernel or KPM port, please do not open a public issue. Instead:

1. Open a private security advisory at <https://github.com/Ognisty321/WSA-Linux-Kernel/security/advisories/new>.
2. Include a clear description, a minimal reproduction, the kernel SHA256 you tested and the WSA version.
3. Include `ksud kpm doctor --json`, `ksud kpm audit --json`, `adb shell uname -a` and the relevant `dmesg` lines when possible.
4. Include the Windows build, Memory Integrity state, ReSukiSU submodule commit and whether `/data/adb/kpm.disabled` exists.
5. Allow a reasonable time for a fix before any public disclosure.

## What Is In Scope

1. Memory corruption, use after free, out of bounds, double free in the KPM loader and hook backend.
2. Privilege escalation paths in the supercall / `ksud kpm` interface.
3. KPM loader parser bugs reachable from a crafted `.kpm` file.
4. Hook restore correctness bugs that can leave kernel text in an inconsistent state.
5. Userspace command bugs that report success after a kernel-side KPM failure.
6. Boot-time KPM autoload failures that bypass `/data/adb/kpm.disabled` recovery behavior.

## What Is Out Of Scope

1. Issues that require a malicious actor with existing root and kernel write access.
2. Vendor specific Android driver bugs not present in WSA.
3. Issues in upstream projects not patched by this fork.
4. Issues that depend on Memory Integrity being explicitly disabled on the host.
