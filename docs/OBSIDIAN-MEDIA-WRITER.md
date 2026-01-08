# Obsidian Media Writer - Fork & Rebranding Guide

This document provides comprehensive instructions for forking and rebranding Fedora Media Writer into **Obsidian Media Writer** - a custom USB ISO flashing tool for Obsidian OS.

## Overview

**Source Project:** [FedoraQt/MediaWriter](https://github.com/FedoraQt/MediaWriter)  
**License:** GPL-2.0 and LGPL-2.0  
**Technology:** C++ with Qt6/QML  
**Platforms:** Windows, macOS, Linux (Flatpak)

## Table of Contents

1. [Repository Setup](#1-repository-setup)
2. [Files to Modify](#2-files-to-modify)
3. [Branding Changes](#3-branding-changes)
4. [ISO Source Configuration](#4-iso-source-configuration)
5. [Asset Replacement](#5-asset-replacement)
6. [Build Instructions](#6-build-instructions)
7. [Packaging](#7-packaging)
8. [Distribution](#8-distribution)

---

## 1. Repository Setup

### Fork the Repository

```bash
# Using GitHub CLI
gh repo fork FedoraQt/MediaWriter --clone --remote --remote-name upstream

# Or manually on GitHub:
# 1. Go to https://github.com/FedoraQt/MediaWriter
# 2. Click "Fork"
# 3. Rename to "ObsidianMediaWriter"

# Clone your fork
git clone https://github.com/reapercanuk39/ObsidianMediaWriter.git
cd ObsidianMediaWriter
```

---

## 2. Files to Modify

### Critical Files (Must Change)

| File | Purpose | Changes Required |
|------|---------|------------------|
| `src/app/main.cpp` | Application entry point | Organization name, app name, desktop file ID |
| `src/app/utilities.h` | Release URL configuration | Change `releasesUrl` default |
| `src/app/data/assets/metadata.json` | Product definitions | Replace with Obsidian OS entry |
| `src/app/data/assets/releases.json` | Offline release data | Replace with Obsidian ISO info |
| `src/app/assets.qrc` | Asset references | Update logo references |
| `CMakeLists.txt` | Build configuration | Project name, version |
| `src/app/CMakeLists.txt` | App build config | Target name, install paths |

### Desktop & Metadata Files

| File | Purpose |
|------|---------|
| `src/app/data/org.fedoraproject.MediaWriter.desktop.in` | Linux .desktop file |
| `src/app/data/org.fedoraproject.MediaWriter.metainfo.xml.in` | AppStream metadata |
| `src/app/data/Info.plist` | macOS app metadata |
| `src/app/data/windows.manifest` | Windows app manifest |
| `src/app/data/windows.rc` | Windows resource file |

### Icon & Logo Files

| Directory | Contents |
|-----------|----------|
| `src/app/data/icons/` | Application icons (various sizes) |
| `src/app/data/assets/logos/` | Product logos (64x64, 256x256) |
| `src/app/data/assets/*.svg` | UI graphics |

---

## 3. Branding Changes

### 3.1 main.cpp Changes

**Location:** `src/app/main.cpp`

```cpp
// BEFORE:
QApplication::setOrganizationDomain("fedoraproject.org");
QApplication::setOrganizationName("fedoraproject.org");
QApplication::setApplicationName("MediaWriter");
QGuiApplication::setDesktopFileName("org.fedoraproject.MediaWriter");

// AFTER:
QApplication::setOrganizationDomain("obsidian-os.org");
QApplication::setOrganizationName("Obsidian Project");
QApplication::setApplicationName("Obsidian Media Writer");
QGuiApplication::setDesktopFileName("org.obsidian.MediaWriter");
```

### 3.2 utilities.h Changes

**Location:** `src/app/utilities.h`

```cpp
// BEFORE:
QString releasesUrl{"https://fedoraproject.org/releases.json"};

// AFTER:
// For static release (just Obsidian), we can use a self-hosted JSON or embedded data
QString releasesUrl{"https://raw.githubusercontent.com/reapercanuk39/Obsidian/main/releases.json"};
```

### 3.3 CMakeLists.txt Changes

**Location:** `CMakeLists.txt`

```cmake
# BEFORE:
project(MediaWriter VERSION 5.2.2 LANGUAGES CXX)

# AFTER:
project(ObsidianMediaWriter VERSION 1.0.0 LANGUAGES CXX)
```

### 3.4 Desktop File Changes

**Rename:** `org.fedoraproject.MediaWriter.desktop.in` → `org.obsidian.MediaWriter.desktop.in`

```ini
[Desktop Entry]
Name=Obsidian Media Writer
GenericName=Obsidian OS Installation Media Writer
Comment=Write Obsidian OS to USB drives
Exec=obsidian-media-writer
Icon=org.obsidian.MediaWriter
Terminal=false
Type=Application
Categories=System;Utility;
Keywords=usb;flash;live;install;obsidian;
```

---

## 4. ISO Source Configuration

### 4.1 Simplify metadata.json

**Location:** `src/app/data/assets/metadata.json`

Replace entire contents with:

```json
[
    {
        "subvariant": "obsidian",
        "category": "product",
        "name": "Obsidian OS",
        "summary": "A security-hardened Linux distribution based on Debian 12.",
        "icon": "qrc:/logos/obsidian",
        "screenshots": [],
        "description": [
            "<p>",
            "Obsidian OS is a security-focused Linux distribution designed to be the most secure operating system on the planet.",
            "</p><h3>",
            "Security Features",
            "</h3><p>",
            "<ul>",
            "<li>Kernel hardening with 25+ sysctl security settings</li>",
            "<li>DROP-all firewall policy with nftables</li>",
            "<li>MAC address spoofing on network connect</li>",
            "<li>Memory wiping on shutdown</li>",
            "<li>AppArmor mandatory access control</li>",
            "<li>Fail2ban intrusion prevention</li>",
            "<li>Firejail application sandboxing</li>",
            "<li>Secure-delete tools for data destruction</li>",
            "</ul>",
            "</p><h3>",
            "Privacy First",
            "</h3><p>",
            "Built for users who need maximum privacy and security, including journalists, activists, security researchers, and privacy-conscious individuals.",
            "</p>"
        ]
    }
]
```

### 4.2 Create releases.json

**Location:** `src/app/data/assets/releases.json`

```json
[
    {
        "version": "2.0",
        "arch": "x86_64",
        "link": "https://github.com/reapercanuk39/Obsidian/releases/download/v2.0/Obsidian-2.0-HARDENED.iso",
        "variant": "Obsidian",
        "subvariant": "obsidian",
        "sha256": "",
        "size": "1508073472"
    }
]
```

**Note:** Get the actual SHA256 and size:
```bash
sha256sum Obsidian-2.0-HARDENED.iso
stat -c%s Obsidian-2.0-HARDENED.iso
```

### 4.3 Create GitHub-hosted releases.json

For dynamic updates, host a `releases.json` at:
`https://raw.githubusercontent.com/reapercanuk39/Obsidian/main/releases.json`

This allows updating ISO versions without rebuilding the app.

---

## 5. Asset Replacement

### 5.1 Application Icons

Create icons in these sizes:
- 16x16
- 22x22
- 24x24
- 32x32
- 48x48
- 64x64
- 128x128
- 256x256
- 512x512

**Locations:**
- `src/app/data/icons/hicolor/` - Linux icons
- `src/app/data/assets/obsidian.ico` - Windows icon
- `src/app/data/assets/obsidian.icns` - macOS icon

### 5.2 Product Logos

Create Obsidian OS logos:
- `src/app/data/assets/logos/png/64x64/obsidian-logo.png`
- `src/app/data/assets/logos/png/256x256/obsidian-logo.png`

### 5.3 Update assets.qrc

**Location:** `src/app/assets.qrc`

Replace with minimal version:

```xml
<RCC>
    <qresource prefix="/logos">
        <file alias="placeholder64">data/assets/logos/png/64x64/obsidian-logo.png</file>
        <file alias="folder64">data/assets/logos/png/64x64/icon_folder.png</file>
        <file alias="obsidian64">data/assets/logos/png/64x64/obsidian-logo.png</file>
        <file alias="placeholder">data/assets/logos/png/256x256/obsidian-logo.png</file>
        <file alias="folder">data/assets/logos/png/256x256/icon_folder.png</file>
        <file alias="obsidian">data/assets/logos/png/256x256/obsidian-logo.png</file>
    </qresource>
    <qresource prefix="/">
        <file alias="metadata.json">data/assets/metadata.json</file>
        <file alias="releases.json">data/assets/releases.json</file>
        <file alias="downloadPageImage">data/assets/8-download.svg</file>
        <file alias="mainPageImage">data/assets/1-source.svg</file>
    </qresource>
</RCC>
```

---

## 6. Build Instructions

### 6.1 Dependencies

**Linux (Debian/Ubuntu):**
```bash
sudo apt install build-essential cmake qt6-base-dev qt6-declarative-dev \
    qt6-svg-dev libkf6solid-dev libisomd5sum-dev gettext
```

**Fedora:**
```bash
sudo dnf install cmake gcc-c++ qt6-qtbase-devel qt6-qtdeclarative-devel \
    qt6-qtsvg-devel kf6-solid-devel isomd5sum-devel gettext
```

**macOS:**
```bash
brew install cmake qt@6
```

**Windows:**
- Install Qt 6.x from qt.io
- Install CMake
- Use MSVC or MinGW

### 6.2 Build Commands

```bash
# Clone the fork
git clone https://github.com/reapercanuk39/ObsidianMediaWriter.git
cd ObsidianMediaWriter

# Create build directory
mkdir build && cd build

# Configure
cmake -DCMAKE_BUILD_TYPE=Release ..

# Build
cmake --build . --parallel

# Run
./src/app/obsidian-media-writer
```

### 6.3 Build Options

```cmake
# Custom options in CMakeLists.txt
option(BUILD_TESTING "Build tests" OFF)
option(FLATPAK "Build for Flatpak" OFF)
```

---

## 7. Packaging

### 7.1 Linux - AppImage

```bash
# Install linuxdeploy
wget https://github.com/linuxdeploy/linuxdeploy/releases/download/continuous/linuxdeploy-x86_64.AppImage
chmod +x linuxdeploy-x86_64.AppImage

# Create AppImage
./linuxdeploy-x86_64.AppImage --appdir AppDir \
    --executable build/src/app/obsidian-media-writer \
    --desktop-file src/app/data/org.obsidian.MediaWriter.desktop \
    --icon-file src/app/data/icons/hicolor/256x256/apps/org.obsidian.MediaWriter.png \
    --output appimage
```

### 7.2 Linux - Flatpak

**Create:** `dist/flatpak/org.obsidian.MediaWriter.yaml`

```yaml
app-id: org.obsidian.MediaWriter
runtime: org.kde.Platform
runtime-version: '6.7'
sdk: org.kde.Sdk
command: obsidian-media-writer
finish-args:
  - --share=network
  - --socket=wayland
  - --socket=fallback-x11
  - --device=all
modules:
  - name: obsidian-media-writer
    buildsystem: cmake-ninja
    sources:
      - type: git
        url: https://github.com/reapercanuk39/ObsidianMediaWriter.git
        tag: v1.0.0
```

### 7.3 Windows - Installer

Use the existing `dist/win/` scripts with modifications:

1. Update `dist/win/mediawriter.nsi` → `obsidian-media-writer.nsi`
2. Change installer name and branding
3. Build with NSIS

### 7.4 macOS - DMG

Use the existing `dist/mac/` scripts:

1. Update `build-dmg.sh` with new app name
2. Update `Info.plist` with Obsidian branding
3. Build universal binary for Intel + Apple Silicon

---

## 8. Distribution

### 8.1 GitHub Releases

Create releases with:
- `ObsidianMediaWriter-1.0.0-linux.AppImage`
- `ObsidianMediaWriter-1.0.0-windows.exe`
- `ObsidianMediaWriter-1.0.0-macos.dmg`
- Source code archives

### 8.2 Website Integration

Add download links to Obsidian project README:

```markdown
## Download Obsidian Media Writer

- [Windows Installer](https://github.com/reapercanuk39/ObsidianMediaWriter/releases/latest)
- [macOS DMG](https://github.com/reapercanuk39/ObsidianMediaWriter/releases/latest)
- [Linux AppImage](https://github.com/reapercanuk39/ObsidianMediaWriter/releases/latest)
```

### 8.3 Flathub Submission

Once stable, submit to Flathub:
1. Fork https://github.com/flathub/flathub
2. Add `org.obsidian.MediaWriter.yaml`
3. Submit pull request

---

## Code Changes Summary

### Minimal Required Changes

1. **main.cpp** - Organization and app names
2. **utilities.h** - Release URL
3. **metadata.json** - Single Obsidian entry
4. **releases.json** - Obsidian ISO info
5. **CMakeLists.txt** - Project name/version
6. **Desktop files** - Rename and rebrand
7. **Icons** - Replace all with Obsidian icons

### Optional Enhancements

1. **Remove Fedora-specific spins/labs** - Simplify to single product
2. **Custom color theme** - Modify QML for Obsidian colors
3. **About dialog** - Update credits and links
4. **User-agent** - Change HTTP user-agent string

---

## Testing Checklist

- [ ] App launches correctly
- [ ] Obsidian OS appears as the only option
- [ ] ISO download works from GitHub releases
- [ ] USB drive detection works
- [ ] Writing to USB completes successfully
- [ ] Verification passes
- [ ] Custom ISO selection works

---

## License Compliance

Fedora Media Writer is licensed under **GPL-2.0** and **LGPL-2.0**.

**Requirements:**
1. Keep original copyright notices
2. Include license files
3. Provide source code access
4. Document modifications

**Recommended:** Add to README:
```markdown
Obsidian Media Writer is based on [Fedora Media Writer](https://github.com/FedoraQt/MediaWriter)
and is licensed under GPL-2.0.
```

---

## Useful Links

- **Upstream:** https://github.com/FedoraQt/MediaWriter
- **Qt6 Docs:** https://doc.qt.io/qt-6/
- **CMake Docs:** https://cmake.org/documentation/
- **AppImage:** https://appimage.org/
- **Flatpak:** https://flatpak.org/

---

*Document created: Session 2.0 - Obsidian OS Security Hardening*
*Last updated: After v2.0 HARDENED release*
