# 🔥 Obsidian OS v1.0 - Forged in Molten Steel 💎

**A Debian-based Linux distribution with custom VALYRIAN-Molten-Steel theming**

[![Version](https://img.shields.io/badge/version-1.0-orange.svg)](https://github.com/obsidian-os)
[![Base](https://img.shields.io/badge/base-Debian%2012-red.svg)](https://www.debian.org/)
[![Desktop](https://img.shields.io/badge/desktop-XFCE4-blue.svg)](https://xfce.org/)
[![License](https://img.shields.io/badge/license-GPL--3.0-green.svg)](LICENSE)

---

## 📋 Table of Contents

- [Overview](#overview)
- [Features](#features)
- [Screenshots](#screenshots)
- [Download](#download)
- [System Requirements](#system-requirements)
- [Installation](#installation)
- [Testing](#testing)
- [Customization](#customization)
- [Build Information](#build-information)
- [Documentation](#documentation)
- [Changelog](#changelog)
- [Contributing](#contributing)
- [License](#license)

---

## 🌟 Overview

**Obsidian OS** is a custom Linux distribution forged from Debian 12 (Bookworm) with extensive visual and functional customizations. Designed with a unique volcanic/forge aesthetic, it features the **VALYRIAN-Molten-Steel** theme throughout the entire system.

### Key Highlights

- 🎨 **Custom VALYRIAN Theme** - Ember orange, steel gray, and cosmic blue color palette
- ⚡ **Plymouth Boot Splash** - 4-phase molten steel animation
- 💻 **Enhanced Terminal** - Custom prompt with forge-themed aliases
- 🔐 **Themed Login Screen** - LightDM with Obsidian branding
- 🖥️ **XFCE Desktop** - Lightweight, fast, and fully customized
- 🔥 **Forge Identity** - Completely rebranded from base distribution

---

## ✨ Features

### Visual & Branding

- **Plymouth Boot Splash**: "Obsidian Forge" 4-phase animation
  - Phase 1: Ember glow (fade-in)
  - Phase 2: Hammer strikes (sparks)
  - Phase 3: Meteor forge (intense heat)
  - Phase 4: Diamond crystallization (logo forms)

- **Custom GTK Theme**: VALYRIAN-Molten-Steel
  - Dark background with ember accents
  - Consistent across GTK 2.0, 3.0, and 4.0
  - Window decorations with forge styling

- **Icon Theme**: Obsidian-Icons
  - Custom icon set
  - Ember-tinted system icons
  - No Debian/Ubuntu branding

- **Wallpapers**: Forge-themed backgrounds
  - Login wallpaper: Molten steel imagery
  - Desktop wallpaper: Obsidian crystal themes

### Terminal Enhancements

- **Custom Bash Prompt**:
  ```
  🔥 user@obsidian ~/path
  💎 $ 
  ```

- **Forge Aliases**:
  - `forge` - Display ASCII logo + system info
  - `forge-info` - System banner
  - `ember` - Launch htop system monitor
  - `anvil` - System update command
  - `temper` - Temperature monitoring
  - `colors` - Display color palette

- **Enhanced Syntax Highlighting**:
  - Directories: Ember orange
  - Executables: Ember glow
  - Symlinks: Cosmic blue
  - grep highlights: Ember orange

- **Custom Xfce Terminal**:
  - 85% transparent deep black background
  - Steel gray foreground
  - Ember orange block cursor
  - 10,000 line scrollback

### Login & Lock Screen

- **LightDM Greeter**:
  - VALYRIAN-Molten-Steel theme
  - Custom forge wallpaper
  - Obsidian diamond logo as user avatar
  - Message: "Forged in molten steel."

- **Screen Locker**:
  - light-locker integration
  - Auto-lock on suspend
  - Consistent theme with login screen
  - "Obsidian Vault" protection concept

### System Identity

- **OS Name**: Obsidian (not Debian)
- **Version**: 1.0
- **Tagline**: "Forged in Molten Steel"
- **User Account**: obsidian (not debian-live)
- **Boot Menu**: "Start Obsidian OS"

### Login Messages

**Console Banner** (`/etc/issue`):
```
Obsidian 1.0 — Forged in molten steel
```

**Message of the Day** (`/etc/motd`):
```
▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄
  ██░▄▄░█▀▄▄▀█░▄▄█░▄▄▀█▀▄▄▀██░▄▄▀█▀▄▀█░▄▄░█▀▄▄▀█
  ██░▀▀░██░▀░█▄▄▀█░██░██░▀░██░██░██░█░█▀▀░██░▀░█
  ██░███▄▄██▄█▄▄▄█▄██▄▄▄██▄██▄██▄█▄▄██░▀▀▀▄▄██▄█
   ▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀
   
           ⚡ Forged in Molten Steel ⚡
                  Version 1.0
                  
   🔥 Type 'forge' for system info
   💎 Type 'colors' to see the theme palette
```

---

## 📸 Screenshots

> **Note**: Screenshots to be added after Windows VM testing

- Boot menu (ISOLINUX)
- Plymouth splash animation
- LightDM login screen
- XFCE desktop with terminal
- Application menu
- System settings

---

## 💾 Download

### Current Release: v1.1 (Custom Kernel)

**File**: `Obsidian-v1.1-Rebranded-20260106-1356.iso`

| Property | Value |
|----------|-------|
| **Size** | 4.7 GB |
| **Format** | ISO 9660 (hybrid) |
| **Bootable** | BIOS + UEFI |
| **USB Compatible** | Yes (hybrid ISO) |
| **Kernel** | 6.1.158-obsidian-obsidian (Custom) |
| **Release Date** | 2026-01-06 |
| **Build Time** | 13:56 UTC |

**MD5 Checksum**: `0968e2a909060b2b24757c2364b53191`

**Download**:
- **GitHub Release**: [v1.1](https://github.com/reapercanuk39/Obsidian/releases/tag/v1.1)
- **Note**: ISO exceeds GitHub's 2GB limit - contact for download link

### Previous Release: v1.0

**File**: `Obsidian-v1.0-Forged-20260105-2150.iso` (1.4 GB)
- **GitHub Release**: [v1.0](https://github.com/reapercanuk39/Obsidian/releases/tag/v1.0)
- Stock Debian kernel (6.1.0-41-amd64)

### Verification

```bash
# Verify download integrity
md5sum -c Obsidian-v1.0-Forged-20260105-2150.iso.md5

# Or check manually
md5sum Obsidian-v1.0-Forged-20260105-2150.iso
```

---

## 💻 System Requirements

### Minimum Requirements

| Component | Specification |
|-----------|--------------|
| **CPU** | x86_64 (64-bit) processor |
| **RAM** | 2 GB |
| **Storage** | N/A (Live CD) or 20 GB (installation) |
| **Graphics** | Any (safe mode available) |
| **Boot** | BIOS or UEFI |

### Recommended Requirements

| Component | Specification |
|-----------|--------------|
| **CPU** | Dual-core x86_64 @ 2.0 GHz+ |
| **RAM** | 4 GB or more |
| **Storage** | 40 GB+ for comfortable installation |
| **Graphics** | Hardware acceleration support |
| **Network** | Ethernet or Wi-Fi for updates |

### Virtual Machine Recommendations

**VirtualBox / VMware / QEMU**:
- Memory: 4096 MB
- CPUs: 2 cores
- Video Memory: 128 MB
- Graphics: VMSVGA or VirtIO
- 3D Acceleration: Enabled (for Plymouth)

---

## 🚀 Installation

### Option 1: Live System (No Installation)

1. **Download ISO** from mirrors above
2. **Burn to USB** using one of:
   - Linux: `dd if=Obsidian-*.iso of=/dev/sdX bs=4M status=progress`
   - Windows: [Rufus](https://rufus.ie/) or [Etcher](https://www.balena.io/etcher/)
   - macOS: [Etcher](https://www.balena.io/etcher/)
3. **Boot from USB**:
   - Restart computer
   - Enter BIOS/UEFI boot menu (usually F12, F2, or Del)
   - Select USB drive
4. **Select "Start Obsidian OS"** from boot menu
5. **Wait for desktop** (~60-90 seconds)
6. **Login**:
   - Username: `obsidian` (or select from list)
   - Password: (none) - just press Enter

### Option 2: Installation to Disk

**Coming soon**: Installer integration in progress

Manual installation steps will be documented in future release.

### Option 3: Virtual Machine

See **[Testing](#testing)** section below for detailed VM setup instructions.

---

## 🧪 Testing

### Quick Test (Virtual Machine)

Obsidian OS includes test scripts for all major platforms:

#### Windows (VirtualBox)

**Automated Method**:
1. Download `test-windows-virtualbox.bat`
2. Edit `ISO_PATH` in the script
3. Double-click to run
4. VM auto-creates and starts

**Manual Method**: See [WINDOWS-VM-TEST-GUIDE.md](WINDOWS-VM-TEST-GUIDE.md)

#### Linux (QEMU/KVM)

```bash
# Quick boot test
qemu-system-x86_64 -cdrom Obsidian-*.iso -m 4096 -boot d -enable-kvm

# With VNC (for graphical test)
./test-boot-graphical.sh
```

#### macOS (VirtualBox)

```bash
# Run test script
chmod +x test-macos-virtualbox.sh
./test-macos-virtualbox.sh
```

### Testing Checklist

- [ ] ISO boots successfully
- [ ] Plymouth splash displays (or text boot)
- [ ] LightDM login screen appears
- [ ] Desktop loads with Obsidian theme
- [ ] Terminal shows custom 🔥💎 prompt
- [ ] Aliases work: `forge`, `ember`, `colors`
- [ ] No Debian/Ubuntu branding visible
- [ ] Applications launch correctly

For detailed testing instructions, see:
- [WINDOWS-VM-TEST-GUIDE.md](WINDOWS-VM-TEST-GUIDE.md)
- [CROSS-PLATFORM-TEST-RESULTS.md](CROSS-PLATFORM-TEST-RESULTS.md)

---

## 🎨 Customization

### Color Palette

The VALYRIAN-Molten-Steel theme uses this color scheme:

| Color Name | Hex Code | RGB | Usage |
|-----------|----------|-----|-------|
| Deep Black | `#090809` | 9, 8, 9 | Backgrounds, terminals |
| Steel Gray | `#CCCCCC` | 204, 204, 204 | Text, foreground |
| Ember Orange | `#FF7A1A` | 255, 122, 26 | Accents, highlights |
| Ember Glow | `#FFA347` | 255, 163, 71 | Bold text, active elements |
| Dark Ember | `#903B15` | 144, 59, 21 | Shadows, dark accents |
| Cosmic Blue | `#3E4F61` | 62, 79, 97 | Paths, links, secondary |
| Ice Blue | `#6E94B7` | 110, 148, 183 | Bright highlights |

### Terminal Aliases

Built-in forge-themed commands:

```bash
forge         # Display ASCII logo + system info
forge-info    # Show system banner
ember         # Launch htop (system monitor)
anvil         # System update command
temper        # Show CPU/system temperatures
colors        # Display the VALYRIAN color palette
quench        # Quick system info
```

### Customizing Your Setup

**Change Wallpaper**:
```bash
# Desktop wallpaper
cp your-wallpaper.jpg ~/.config/wallpaper.jpg
xfconf-query -c xfce4-desktop -p /backdrop/screen0/monitor0/image-path -s ~/.config/wallpaper.jpg
```

**Modify Terminal Colors**:
```bash
# Edit Xfce Terminal config
nano ~/.config/xfce4/terminal/terminalrc
```

**Add Custom Aliases**:
```bash
# Edit bashrc
nano ~/.bashrc

# Add your aliases
alias mycommand='echo "Hello Obsidian!"'

# Reload
source ~/.bashrc
```

---

## 🏗️ Build Information

### Build System

**Base Distribution**: Debian 12 (Bookworm)  
**Build Method**: Debootstrap + chroot customization  
**ISO Creation**: xorriso (mkisofs mode)  
**Compression**: XZ (squashfs)

### Build Statistics

| Metric | Value |
|--------|-------|
| **Build Date** | 2026-01-05 21:50 UTC |
| **Rootfs Size** | 3.8 GB (uncompressed) |
| **Squashfs Size** | 1.3 GB (compressed) |
| **ISO Size** | 1.4 GB |
| **Compression Ratio** | 66% reduction |
| **Inodes** | 99,615 |
| **Total Packages** | 1,200+ |
| **Build Time** | ~10 minutes |

### Components

**Desktop Environment**: XFCE4 4.18  
**Display Manager**: LightDM  
**Boot Splash**: Plymouth  
**Window Manager**: XFWM4  
**File Manager**: Thunar  
**Terminal**: Xfce Terminal  
**Text Editor**: Mousepad, nano, vim  
**Web Browser**: Firefox ESR (if included)

### Kernel

**Version (v1.1)**: 6.1.158-obsidian-obsidian (Custom Obsidian Kernel)  
**Version (v1.0)**: 6.1.0-41-amd64 (Stock Debian Kernel)  
**Type**: SMP PREEMPT_DYNAMIC  
**Build**: Compiled from source with full Obsidian branding  
**Hostname**: obsidian (default)  
**Signature**: #obsidian

---

## 📚 Documentation

### User Guides

- **[WINDOWS-VM-TEST-GUIDE.md](WINDOWS-VM-TEST-GUIDE.md)** - Complete Windows testing guide
- **[CROSS-PLATFORM-TEST-RESULTS.md](CROSS-PLATFORM-TEST-RESULTS.md)** - Multi-platform test results

### Technical Documentation

- **[BUILD-COMPLETE-SUMMARY.md](BUILD-COMPLETE-SUMMARY.md)** - Build process details
- **[BOOT-FIX-COMPLETE.md](BOOT-FIX-COMPLETE.md)** - Boot error resolution
- **[FINAL-SCAN-AND-TEST-REPORT.md](FINAL-SCAN-AND-TEST-REPORT.md)** - Comprehensive scan report
- **[ADDITIONAL-REBRANDING-OPPORTUNITIES.md](ADDITIONAL-REBRANDING-OPPORTUNITIES.md)** - Further customization options

### Developer Guides

- **[CASPER-TO-OBSIDIAN-MIGRATION.md](CASPER-TO-OBSIDIAN-MIGRATION.md)** - Live system migration notes
- **[CUSTOM-KERNEL-INSTALLATION.md](CUSTOM-KERNEL-INSTALLATION.md)** - Building custom kernel
- **[OBSIDIAN-REBRANDING-ROADMAP.md](OBSIDIAN-REBRANDING-ROADMAP.md)** - Rebranding strategy

### Asset Documentation

- **[VALYRIAN-ICONS-IMPLEMENTATION.md](VALYRIAN-ICONS-IMPLEMENTATION.md)** - Icon theme notes

---

## 📝 Changelog

### v1.1 (2026-01-06) - "Custom Obsidian Kernel"

**Major Update: Fully Rebranded Kernel**

#### Added
- ✨ **Custom Obsidian Kernel 6.1.158-obsidian-obsidian** compiled from source
- ✨ Kernel branding: `#obsidian SMP PREEMPT_DYNAMIC`
- ✨ Custom default hostname: `obsidian`
- ✨ Full module set for maximum hardware compatibility
- ✨ Kernel config with `CONFIG_LOCALVERSION="-obsidian"`

#### Changed
- 🔄 Kernel from stock Debian (6.1.0-41-amd64) to custom Obsidian (6.1.158-obsidian-obsidian)
- 🔄 Removed all Debian kernel maintainer references
- 🔄 ISO size increased to 4.7 GB (from 1.4 GB) due to complete module set
- 🔄 Initramfs rebuilt for new kernel

#### Technical
- 📦 Kernel: 6.1.158-obsidian-obsidian
- 📦 Compiled: GCC 12.2.0
- 📦 Build: Safe & compatible mode (all modules included)
- 📦 ISO Size: 4.7 GB
- 📦 Build Date: 2026-01-06 13:56 UTC
- 📦 Build Time: ~2.5 hours (2-core system)

---

### v1.0 (2026-01-05) - "Forged in Molten Steel"

**Initial Release**

#### Added
- ✨ Custom VALYRIAN-Molten-Steel GTK theme
- ✨ Plymouth "Obsidian Forge" 4-phase boot animation
- ✨ Custom terminal prompt with 🔥 and 💎 emoji
- ✨ 6 forge-themed bash aliases (forge, ember, anvil, temper, colors, quench)
- ✨ LightDM themed login screen
- ✨ Custom ASCII art logo and MOTD
- ✨ Obsidian wallpapers (login and desktop)
- ✨ Enhanced syntax highlighting (directories, executables, grep)
- ✨ Xfce Terminal custom color scheme
- ✨ light-locker screen locking integration

#### Changed
- 🔄 Renamed /casper to /obsidian (live system directory)
- 🔄 OS name from "Debian" to "Obsidian"
- 🔄 User account from generic to "obsidian"
- 🔄 Boot menu entry to "Start Obsidian OS"
- 🔄 Login banners to Obsidian branding
- 🔄 System identity in /etc/os-release

#### Removed
- ❌ All Debian logos and pixmaps
- ❌ All Ubuntu branding references
- ❌ Default Debian desktop configurations

#### Fixed
- 🐛 Initramfs unpacking error (regenerated with mkinitramfs)
- 🐛 Kernel panic on boot (proper cpio format)
- 🐛 Boot path references (/casper → /obsidian)

#### Technical
- 📦 Base: Debian 12 (Bookworm)
- 📦 Kernel: 6.1.0-41-amd64
- 📦 Desktop: XFCE 4.18
- 📦 ISO Size: 1.4 GB
- 📦 Build Date: 2026-01-05 21:50 UTC

---

## 🤝 Contributing

Contributions are welcome! Please follow these guidelines:

### Reporting Issues

1. Check existing issues first
2. Provide system information (OS, hardware, VM details)
3. Include error messages and logs
4. Screenshots help (especially for visual issues)

### Feature Requests

- Open an issue with `[Feature Request]` prefix
- Describe the feature and use case
- Consider if it fits the "forge" theme

### Code Contributions

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Test your changes thoroughly
4. Document your changes
5. Submit a pull request

### Theme Contributions

- Follow VALYRIAN color palette
- Maintain ember/steel aesthetic
- Test on clean system
- Provide before/after screenshots

---

## 📜 License

Obsidian OS is released under the **GNU General Public License v3.0**.

See [LICENSE](LICENSE) file for details.

### Component Licenses

- **Debian**: Various open-source licenses
- **XFCE**: GPL v2+
- **Plymouth**: GPL v2+
- **Custom Themes**: GPL v3.0
- **Documentation**: CC-BY-SA 4.0

---

## 🙏 Acknowledgments

### Based On
- **Debian Project** - Stable foundation
- **XFCE Community** - Lightweight desktop
- **Plymouth Project** - Boot splash framework

### Inspiration
- Volcanic/forge aesthetic
- Game of Thrones (Valyrian steel)
- Blacksmithing and metalwork

### Tools Used
- debootstrap - System bootstrap
- chroot - System customization
- squashfs-tools - Filesystem compression
- xorriso - ISO creation
- QEMU/KVM - Testing platform

---

## 📞 Support & Contact

### Community
- **Forum**: [Coming soon]
- **Discord**: [Coming soon]
- **IRC**: [Coming soon]

### Development
- **GitHub**: [Repository]
- **Issue Tracker**: [GitHub Issues]
- **Wiki**: [Coming soon]

### Social Media
- **Twitter**: [Coming soon]
- **Reddit**: [r/ObsidianOS] (Coming soon)
- **YouTube**: [Coming soon]

---

## 🗺️ Roadmap

### v1.1 (Planned)

- [ ] Installer integration (Calamares)
- [ ] Additional Plymouth themes
- [ ] More wallpapers
- [ ] Steam integration
- [ ] Development tools pre-installed
- [ ] Network manager improvements

### v2.0 (Future)

- [ ] Custom Obsidian kernel
- [ ] Custom package repository
- [ ] Obsidian-specific applications
- [ ] Hardware-optimized builds
- [ ] Performance tuning
- [ ] Advanced theming options

### Long-term Vision

- Self-hosted package mirrors
- Custom application suite
- Gaming optimizations
- Developer edition
- Security-hardened edition
- Server edition

---

## 📊 Statistics

**Project Started**: 2026-01-04  
**Current Version**: 1.0  
**Total Commits**: [TBD]  
**Contributors**: [TBD]  
**Downloads**: [TBD]  
**Stars**: ⭐ [GitHub]

---

## 🔥 The Forge Philosophy

> "Just as blacksmiths forge steel in fire, we forge software with passion. Every line of code, every pixel, every configuration is carefully crafted and tempered. Obsidian OS is not just built—it is **forged**."

**Our Values**:
- 🔥 **Craftsmanship** - Attention to detail
- 💎 **Quality** - Stable and reliable
- ⚡ **Performance** - Fast and efficient
- 🎨 **Aesthetics** - Beautiful and consistent
- 🤝 **Community** - Open and welcoming

---

## ⚠️ Disclaimer

Obsidian OS is provided "as-is" without warranty of any kind. Use at your own risk.

This is an independent distribution based on Debian. It is not affiliated with or endorsed by the Debian Project.

---

## 📖 Quick Links

- **Download**: [Release Page](#download)
- **Installation**: [Installation Guide](#installation)
- **Testing**: [Test Guide](WINDOWS-VM-TEST-GUIDE.md)
- **Documentation**: [Docs Folder](#documentation)
- **Issues**: [GitHub Issues]
- **Contribute**: [Contributing](#contributing)

---

<div align="center">

## 🔥 Obsidian OS - Forged in Molten Steel 💎

**Version 1.0** | **Released: 2026-01-05**

[![Download](https://img.shields.io/badge/Download-ISO-orange.svg)](#download)
[![Documentation](https://img.shields.io/badge/Docs-Available-blue.svg)](#documentation)
[![License](https://img.shields.io/badge/License-GPL--3.0-green.svg)](LICENSE)

---

*"From fire and code, a new OS is born."*

---

**Made with 🔥 and ⚡ by the Obsidian OS Community**

</div>
