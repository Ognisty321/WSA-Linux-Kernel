# Install Guide for Windows

This guide covers installing the released kernel binary into an unpacked WSA (Windows Subsystem for Android) package.

## Prerequisites

1. Windows 11 with WSA installed and previously working at least once.
2. An unpacked WSA package directory that contains `AppxManifest.xml` and `Tools\kernel`. If WSA was installed from the Microsoft Store, you need to unpack the appx with a tool like `MagiskOnWSALocal` or use a community WSA build that ships unpacked.
3. PowerShell running as Administrator.
4. Optional: Memory Integrity (HVCI) turned off on the Windows host for first install. See [FAQ.md](FAQ.md) for steps and rationale.

## Steps

### 1. Download the kernel

Open the [latest release](https://github.com/Ognisty321/WSA-Linux-Kernel/releases/latest) and download the kernel asset.

### 2. Verify the SHA256

```powershell
Get-FileHash "C:\Path\To\Downloaded\kernel" -Algorithm SHA256
```

The value must match the one in the release notes.

### 3. Stop WSA

```powershell
WsaClient.exe /shutdown
```

You can also turn WSA off from the Windows Subsystem for Android settings panel.

### 4. Backup the current kernel

Replace `C:\Path\To\WSA` with the directory that contains your unpacked WSA `AppxManifest.xml`.

```powershell
$WsaDir = "C:\Path\To\WSA"
Copy-Item -Force "$WsaDir\Tools\kernel" "$WsaDir\Tools\kernel.backup"
```

### 5. Replace the kernel

```powershell
$NewKernel = "C:\Path\To\Downloaded\kernel"
Copy-Item -Force $NewKernel "$WsaDir\Tools\kernel"
```

### 6. Re-register WSA

```powershell
Add-AppxPackage -ForceApplicationShutdown -ForceUpdateFromAnyVersion -Register "$WsaDir\AppxManifest.xml"
```

### 7. Boot WSA and verify

```powershell
adb connect 127.0.0.1:58526
adb shell uname -a
```

Expected output contains:

```text
WSA-ReSukiSU+
```

### 8. Verify KPM is running

In ReSukiSU Manager the KPM Version field should read:

```text
Supported (ReSukiSU-x86_64-KPM-loader/0.20)
```

Or from `adb`:

```powershell
adb shell su -c "ksud kpm version"
```

Expected for the published `v0.21` binary:

```text
ReSukiSU-x86_64-KPM-loader/0.20
```

For a local `main` source build, use the `kpm_loader=` value in the sidecar manifest; current source builds report `ReSukiSU-x86_64-KPM-loader/0.21`.

For full runtime diagnostics:

```powershell
adb shell su -c "ksud kpm doctor --json"
```

This reports loader reachability, loaded module count, safe mode state and `/data/adb/kpm` directory hardening.

## Rollback

If WSA does not boot or behaves badly:

```powershell
WsaClient.exe /shutdown
$WsaDir = "C:\Path\To\WSA"
Copy-Item -Force "$WsaDir\Tools\kernel.backup" "$WsaDir\Tools\kernel"
Add-AppxPackage -ForceApplicationShutdown -ForceUpdateFromAnyVersion -Register "$WsaDir\AppxManifest.xml"
```

## Manager Library Override

ReSukiSU Manager ships a `libksud.so` that needs an x86_64 path for the `kpm` subcommand. The shipped Manager already covers this on most installs. Before publishing or pinning a Manager APK for WSA x86_64, verify it from the repo root:

```bash
KernelSU/scripts/check-manager-kpm-x86.sh /path/to/ReSukiSU-Manager.apk
```

If after a Manager update the KPM Version field shows `Unsupported`, see [FAQ.md](FAQ.md#resukisu-manager-shows-unsupported-after-a-manager-update).

## Troubleshooting

1. `WsaClient.exe is not recognized`. Make sure WSA is installed and the WSA Tools directory is on `PATH`, or call it from its install location.
2. `Add-AppxPackage` fails with sideload disabled. Enable Developer Mode in Windows settings.
3. WSA boots but `adb` cannot connect. Run `adb kill-server` and `adb start-server`, then reconnect.
4. KPM shows `Unsupported`. Disable Memory Integrity on the host, reboot, then verify again.
