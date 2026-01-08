# 🛡️ Obsidian OS v2.0 HARDENED - Security Features

**Release Date**: 2026-01-08  
**Security Level**: HARDENED  
**Base**: Debian 12 (Bookworm)

---

## 🔥 Security Overview

Obsidian 2.0 HARDENED transforms a standard Debian base into a security-first operating system, implementing defense-in-depth principles inspired by Tails, Whonix, Kicksecure, and industry best practices.

---

## 🛡️ Implemented Security Features

### 1. Kernel Hardening (`/etc/sysctl.d/99-obsidian-hardening.conf`)

| Protection | Setting | Purpose |
|------------|---------|---------|
| **ASLR** | `kernel.randomize_va_space = 2` | Randomize memory layout |
| **Pointer Restriction** | `kernel.kptr_restrict = 2` | Hide kernel pointers |
| **Ptrace Scope** | `kernel.yama.ptrace_scope = 2` | Prevent debugging attacks |
| **Dmesg Restrict** | `kernel.dmesg_restrict = 1` | Restrict kernel logs |
| **SysRq Disable** | `kernel.sysrq = 0` | Disable magic keys |
| **Core Dumps** | `fs.suid_dumpable = 0` | No SUID core dumps |
| **BPF Hardening** | `net.core.bpf_jit_harden = 2` | Harden BPF JIT |
| **Perf Paranoid** | `kernel.perf_event_paranoid = 3` | Restrict perf events |

### 2. Network Security

| Protection | Setting | Purpose |
|------------|---------|---------|
| **Reverse Path Filter** | `net.ipv4.conf.all.rp_filter = 1` | Anti-spoofing |
| **SYN Cookies** | `net.ipv4.tcp_syncookies = 1` | SYN flood protection |
| **ICMP Redirects** | Disabled | Prevent MITM |
| **Source Routing** | Disabled | Block source routing attacks |
| **Martian Logging** | Enabled | Log suspicious packets |
| **IP Forwarding** | Disabled | Not a router |

### 3. Firewall (nftables)

- **Default Policy**: DROP all incoming
- **Stateful Inspection**: Only established/related allowed
- **Rate Limiting**: 100 connections/second max
- **ICMP Protection**: Rate-limited ping responses
- **Logging**: All dropped packets logged
- **Blocklist Support**: IP-based blocking capability

### 4. Intrusion Prevention

| Tool | Purpose | Status |
|------|---------|--------|
| **Fail2ban** | Auto-ban brute force attackers | ✅ Installed & Enabled |
| **AppArmor** | Mandatory Access Control | ✅ Active with profiles |
| **Auditd** | System call auditing | ✅ Installed |
| **rkhunter** | Rootkit detection | ✅ Installed |
| **chkrootkit** | Rootkit detection | ✅ Installed |

### 5. Application Sandboxing

| Tool | Purpose | Status |
|------|---------|--------|
| **Firejail** | Application isolation | ✅ Installed |
| **AppArmor Profiles** | Per-app restrictions | ✅ 50+ profiles |
| **libpam-tmpdir** | Private /tmp per session | ✅ Enabled |

### 6. Privacy & Anti-Forensics

| Tool | Purpose | Status |
|------|---------|--------|
| **MAC Spoofing** | Randomize MAC on connect | ✅ Auto on boot |
| **Memory Wipe** | Clear RAM on shutdown | ✅ Enabled |
| **Secure-delete** | Secure file deletion (srm, sfill, sdmem, sswap) | ✅ Installed |
| **BleachBit** | System cleaner with shredding | ✅ Installed |

### 7. Filesystem Protection

| Protection | Setting | Purpose |
|------------|---------|---------|
| **Hardlink Protection** | `fs.protected_hardlinks = 1` | Prevent hardlink attacks |
| **Symlink Protection** | `fs.protected_symlinks = 1` | Prevent symlink attacks |
| **FIFO Protection** | `fs.protected_fifos = 2` | Protect named pipes |
| **Regular File Protection** | `fs.protected_regular = 2` | Protect regular files |

---

## 📦 Security Packages Installed

```
Core Security:
├── fail2ban          - Intrusion prevention
├── firejail          - Application sandboxing
├── apparmor          - Mandatory Access Control
├── apparmor-profiles - Pre-built MAC profiles
├── apparmor-profiles-extra
├── auditd            - System auditing
├── nftables          - Modern firewall

Detection & Scanning:
├── rkhunter          - Rootkit detection
├── chkrootkit        - Rootkit detection
├── debsums           - Package integrity verification

Privacy & Anti-Forensics:
├── macchanger        - MAC address randomization
├── secure-delete     - Secure file deletion suite
├── bleachbit         - System cleaner with shredding

System Hardening:
├── libpam-tmpdir     - Private /tmp directories
├── needrestart       - Service restart notifications
├── apt-listbugs      - Security bug tracking
└── apt-listchanges   - Package change notifications
```

---

## 🚀 Quick Security Commands

### Sandbox an Application
```bash
firejail firefox
firejail --private --net=none suspicious-app
```

### Secure Delete a File
```bash
srm -vz sensitive-file.txt
```

### Wipe Free Space
```bash
sfill -v /home/user/
```

### Check for Rootkits
```bash
sudo rkhunter --check
sudo chkrootkit
```

### View Firewall Status
```bash
sudo nft list ruleset
```

### View Fail2ban Status
```bash
sudo fail2ban-client status
```

### Randomize MAC Address
```bash
sudo macchanger -r eth0
```

---

## 🔒 Default Security Posture

| Aspect | Status | Details |
|--------|--------|---------|
| **Incoming Connections** | 🔴 BLOCKED | All dropped by default |
| **Outgoing Connections** | 🟢 ALLOWED | Unrestricted outbound |
| **SSH** | 🔴 DISABLED | No SSH server by default |
| **Root Login** | 🔴 RESTRICTED | Console only |
| **Firewall** | 🟢 ACTIVE | nftables with DROP policy |
| **AppArmor** | 🟢 ENFORCING | MAC enabled |
| **Fail2ban** | 🟢 ACTIVE | SSH/auth protection |
| **Memory Wipe** | 🟢 ENABLED | On shutdown |
| **MAC Spoofing** | 🟢 AUTO | On network connect |

---

## 📊 Security Comparison

| Feature | Standard Debian | Obsidian 2.0 HARDENED |
|---------|-----------------|----------------------|
| Kernel Hardening | ❌ | ✅ 20+ sysctl settings |
| Firewall | ❌ Empty | ✅ Restrictive policy |
| Fail2ban | ❌ | ✅ |
| AppArmor Profiles | Minimal | ✅ 50+ profiles |
| Firejail | ❌ | ✅ |
| MAC Spoofing | ❌ | ✅ Automatic |
| Memory Wipe | ❌ | ✅ On shutdown |
| Anti-forensics | ❌ | ✅ secure-delete suite |
| Rootkit Detection | ❌ | ✅ rkhunter + chkrootkit |

---

## ⚠️ Security Limitations

1. **Not Amnesic**: Unlike Tails, Obsidian persists data. Use encrypted partitions for sensitive data.
2. **No Tor by Default**: Network traffic is not anonymized. Install tor/torsocks if needed.
3. **Hardware Trust**: Cannot protect against compromised firmware/BIOS.
4. **User Responsibility**: Security tools must be used correctly.

---

## 🔧 Customization

### Enable Stricter DNS (Force Encrypted Only)
Edit `/etc/nftables.conf` and uncomment:
```
udp dport 53 reject with icmp type admin-prohibited
tcp dport 53 reject with tcp reset
```

### Add IP to Blocklist
```bash
sudo nft add element inet obsidian_firewall blocklist { 1.2.3.4 }
```

### Disable Memory Wipe (Faster Shutdown)
```bash
sudo systemctl disable memory-wipe.service
```

---

## 📚 Further Hardening (Optional)

1. **Full Disk Encryption**: Use LUKS during installation
2. **Tor Integration**: `apt install tor torsocks`
3. **Encrypted DNS**: `apt install stubby` or `dnscrypt-proxy`
4. **AIDE**: File integrity monitoring
5. **Lynis**: Security auditing tool

---

**Obsidian 2.0 HARDENED** — *Forged in Molten Steel, Armored for Security*
