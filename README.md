# 🛡️ Obsidian OS v2.1 FORTRESS

> **Forged in Molten Steel, Armored for Security**

[![Download Obsidian OS](https://img.shields.io/badge/Download-Obsidian%202.1%20FORTRESS-FF7A1A?style=for-the-badge&logo=linux&logoColor=white)](https://github.com/reapercanuk39/Obsidian/releases/latest)
[![Security](https://img.shields.io/badge/Security-HARDENED-green?style=for-the-badge&logo=shield&logoColor=white)](docs/SECURITY-FEATURES.md)
[![License](https://img.shields.io/badge/License-GPL--3.0-blue?style=for-the-badge)](LICENSE)

---

## 🔥 What is Obsidian OS?

Obsidian OS is a **security-hardened Linux distribution** based on Debian 12 (Bookworm), designed for users who demand maximum protection without sacrificing usability.

### Key Features

| Feature | Description |
|---------|-------------|
| 🛡️ **Kernel Hardening** | 25+ sysctl settings for maximum kernel protection |
| 🔥 **Firewall** | nftables with DROP-all policy, rate limiting |
| 🚫 **Intrusion Prevention** | Fail2ban auto-bans attackers |
| 📦 **App Sandboxing** | Firejail isolates risky applications |
| 🔒 **AppArmor** | 55+ MAC profiles for application confinement |
| 🎭 **MAC Spoofing** | Automatic MAC randomization on boot |
| 🧹 **Memory Wipe** | RAM cleared on shutdown |
| 🔍 **Rootkit Detection** | rkhunter + chkrootkit included |
| 🗑️ **Secure Delete** | Full anti-forensics suite |

---

## 📥 Download

### Latest Release: v2.1 FORTRESS (Installer Edition)

| File | Size | MD5 |
|------|------|-----|
| [Obsidian-2.1-FORTRESS.iso](https://github.com/reapercanuk39/Obsidian/releases/download/v2.1/Obsidian-2.1-FORTRESS.iso) | 1.3 GB | `6a1803d3a37565646bce2ea5ae141880` |

**[⬇️ Download from GitHub Releases](https://github.com/reapercanuk39/Obsidian/releases/latest)**

---

## 🚀 Quick Start

### Option A: Install to USB SSD (Recommended)

1. **Burn ISO to a small USB** (8GB+ test USB)
2. **Boot from the test USB**
3. **At boot menu, select "Install Obsidian OS to USB SSD"**
   - Or click "Install Obsidian OS" on the desktop
4. **Select your target drive** (e.g., 256GB USB SSD)
5. **Complete installation** and boot from your SSD

This gives you a **fully installed OS** with:
- ✅ Full persistence (all changes saved)
- ✅ Faster boot (no live decompression)
- ✅ Hardware detection for your machine
- ✅ Normal package updates

### Option B: Live Boot (No Installation)

### 1. Download & Verify
```bash
# Download ISO
wget https://github.com/reapercanuk39/Obsidian/releases/download/v2.1/Obsidian-2.1-FORTRESS.iso

# Verify checksum
echo "6a1803d3a37565646bce2ea5ae141880  Obsidian-2.1-FORTRESS.iso" | md5sum -c
```

### 2. Create Bootable USB

**Windows (Rufus)**:
1. Download [Rufus](https://rufus.ie/)
2. Select your USB drive
3. Select `Obsidian-2.1-FORTRESS.iso`
4. ⚠️ Choose **DD Image mode** when prompted
5. Click START

**Linux**:
```bash
sudo dd if=Obsidian-2.1-FORTRESS.iso of=/dev/sdX bs=4M status=progress conv=fsync
```

### 3. Boot & Login

| Credential | Value |
|------------|-------|
| Username | `obsidian` |
| Password | `toor` |

---

## 🛡️ Security Features

Obsidian 2.1 FORTRESS implements defense-in-depth security:

### Kernel Hardening
- Full ASLR (`kernel.randomize_va_space = 2`)
- Kernel pointer hiding (`kernel.kptr_restrict = 2`)
- Ptrace restrictions (`kernel.yama.ptrace_scope = 2`)
- SYN flood protection (`net.ipv4.tcp_syncookies = 1`)
- Anti-spoofing (`net.ipv4.conf.all.rp_filter = 1`)
- And 20+ more hardening settings

### Network Security
- nftables firewall with DROP-all incoming policy
- Rate limiting (100 connections/second)
- ICMP flood protection
- Stateful connection tracking
- Blocklist support

### Application Security
- **Firejail**: Sandbox any application
- **AppArmor**: 55+ mandatory access control profiles
- **Fail2ban**: Auto-ban brute force attackers
- **Auditd**: System call auditing

### Privacy & Anti-Forensics
- **MAC Spoofing**: Automatic on network connect
- **Memory Wipe**: RAM cleared on shutdown
- **Secure-delete**: `srm`, `sfill`, `sdmem`, `sswap`
- **BleachBit**: System cleaning with shredding

📖 **[Full Security Documentation](docs/SECURITY-FEATURES.md)**

---

## 📊 Comparison

| Feature | Standard Debian | Obsidian 2.1 |
|---------|-----------------|--------------|
| Kernel Hardening | ❌ | ✅ 25+ settings |
| Firewall | ❌ Empty | ✅ DROP policy |
| Fail2ban | ❌ | ✅ |
| AppArmor Profiles | 5 | 55+ |
| Firejail | ❌ | ✅ |
| MAC Spoofing | ❌ | ✅ Auto |
| Memory Wipe | ❌ | ✅ |
| Rootkit Detection | ❌ | ✅ |

---

## 🔧 Quick Commands

```bash
# Sandbox Firefox
firejail firefox

# Secure delete a file
srm -vz sensitive-file.txt

# Check for rootkits
sudo rkhunter --check

# View firewall status
sudo nft list ruleset

# View blocked IPs
sudo fail2ban-client status
```

---

## 📚 Documentation

> **Note**: Please read all documentation files in the `docs/` folder for complete information.

- [Changelog](docs/CHANGELOG.md)
- [Development Notes](docs/DEV-NOTES.md)
- [USB SSD Installation Guide](docs/USB-SSD-GUIDE.md)

---

## ⚠️ Important Notes

1. **Change Default Password**: First thing after install!
2. **Not Amnesic**: Data persists. Use disk encryption for sensitive data.
3. **No Tor by Default**: Install `tor` and `torsocks` if needed.

---

## 🏗️ Building from Source

```bash
# Clone repository
git clone https://github.com/reapercanuk39/Obsidian.git
cd Obsidian

# Build ISO
./scripts/rebuild-iso.sh

# Test in QEMU
qemu-system-x86_64 -cdrom Obsidian-2.1-FORTRESS.iso -m 4096 -enable-kvm
```

---

## 📄 License

This project is licensed under the GPL-3.0 License - see [LICENSE](LICENSE) for details.

---

## 🙏 Credits

- Based on Debian GNU/Linux
- Security research from Tails, Whonix, Kicksecure, Qubes OS
- XFCE Desktop Environment
- Papirus Icon Theme

---

**Obsidian OS** — *Security Without Compromise*
