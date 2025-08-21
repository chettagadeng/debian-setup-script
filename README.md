# 🚀 Enhanced Debian Server Setup Script

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Shell Script](https://img.shields.io/badge/Shell-Bash-green.svg)](https://www.gnu.org/software/bash/)
[![Debian](https://img.shields.io/badge/OS-Debian%2011%2B-red.svg)](https://www.debian.org/)

A comprehensive, interactive Debian server setup script with enhanced security, error handling, and safety features. Perfect for quickly configuring new servers with essential packages, security hardening, and Docker installation.

## ✨ Features

### 🔧 Core Configuration

- **Interactive hostname setup** with `/etc/hosts` management
- **Timezone configuration** with intelligent filtering and selection
- **Locale setup** with UTF-8 validation
- **SSH port customization** with safe restart handling

### 🔒 Security & Hardening

- **Endlessh SSH honeypot** installation (optional)
- **SSH configuration validation** before applying changes
- **Automatic security updates** via unattended-upgrades
- **Safe SSH service handling** prevents remote lockouts

### 📦 Package Management

- **Essential packages** installation (sudo, curl, wget, htop, ntp)
- **Docker CE installation** with official repository and GPG verification
- **Architecture detection** (amd64, arm64, armhf supported)
- **Modern Docker Compose** plugin included

### 🛡️ Safety & Reliability

- **Comprehensive logging** to `/var/log/debian-setup.log`
- **Automatic backups** of all modified configuration files
- **Dry run mode** for testing without making changes
- **Error handling** with graceful failure recovery
- **SSH connection detection** prevents disconnection during setup

### 🎨 User Experience

- **Color-coded output** for better readability
- **Enhanced MOTD script** with system status display
- **Progress indicators** and clear status messages
- **Help system** with usage instructions

## 🚀 Quick Start

### One-Line Installation

```bash
wget https://raw.githubusercontent.com/Snake16547/debian-setup-script/main/debian-setup.sh && chmod +x debian-setup.sh && ./debian-setup.sh
```

### Test First (Recommended)

```bash
wget https://raw.githubusercontent.com/Snake16547/debian-setup-script/main/debian-setup.sh && chmod +x debian-setup.sh && ./debian-setup.sh --dry-run
```

## 📋 Usage

### Basic Usage

```bash
sudo ./debian-setup.sh
```

### Available Options

```bash
./debian-setup.sh [OPTIONS]

Options:
  --dry-run    Show what would be executed without making changes
  --help, -h   Show help message and exit
```

### System Requirements

- Debian 11+ (Bullseye or newer)
- Root access (script will check automatically)
- Internet connection for package downloads

## 🔧 What Gets Configured

### System Settings

- ✅ Hostname and `/etc/hosts` configuration
- ✅ Timezone setup with interactive selection
- ✅ Locale configuration (UTF-8 locales only)
- ✅ System package updates and upgrades

### Security Configuration

- ✅ SSH port customization (with safe restart handling)
- ✅ Optional Endlessh honeypot on port 22
- ✅ Automatic security updates configuration
- ✅ Essential security packages installation

### Optional Components

- ✅ Docker CE with official repository setup
- ✅ Docker Compose plugin and build tools
- ✅ Enhanced system status MOTD script
- ✅ Development and monitoring tools (htop, curl, wget)

## 🛡️ Safety Features

### SSH Protection

The script intelligently detects SSH connections and prevents service interruptions:

```bash
# Safe for remote execution
ssh user@server
sudo ./debian-setup.sh  # Won't disconnect you!
```

- **Connection detection**: Automatically detects SSH sessions
- **Deferred restart**: SSH service changes applied after reboot
- **Configuration validation**: Tests SSH config before applying
- **Backup & restore**: Automatic rollback on configuration errors

### Error Handling

- **Strict error checking**: Script stops on critical failures
- **Comprehensive logging**: All operations logged with timestamps
- **File backups**: Original configurations saved to `/root/debian-setup-backups`
- **Graceful degradation**: Continues when possible, fails safely when not

## 📊 Example Output

```bash
🚀 Welcome to the Enhanced Debian Server Setup Script v2.0

[INFO] Updating package lists and upgrading installed packages...
[SUCCESS] System update and upgrade complete

Enter the desired hostname: myserver
[SUCCESS] Hostname set to myserver

Enter part of your timezone (e.g., 'Europe' or 'Berlin'): europe
Matching timezones:
1) Europe/London
2) Europe/Berlin
3) Europe/Paris
Enter the number of your desired timezone: 2
[SUCCESS] Timezone set to Europe/Berlin

⚠️  SSH connection detected. SSH service restart will be deferred.
[SUCCESS] SSH port configured to 2222

=== Setup Complete ===
Hostname: myserver
Timezone: Europe/Berlin
SSH Port: 2222
Docker Status: Active
Log File: /var/log/debian-setup.log
```

## 📝 Interactive Prompts

The script will ask for your preferences on:

1. **Hostname**: Server identification
1. **Timezone**: Geographic location for time settings
1. **Locale**: Language and character encoding
1. **SSH Port**: Security through port change
1. **Endlessh**: SSH honeypot installation
1. **Packages**: Essential system tools
1. **Docker**: Container platform installation
1. **MOTD**: System status display script

## 🗂️ File Locations

```
/var/log/debian-setup.log              # Execution log
/root/debian-setup-backups/            # Configuration backups
/etc/profile.d/motd.sh                 # MOTD script
/etc/endlessh/config                   # Endlessh configuration
/etc/apt/apt.conf.d/20auto-upgrades    # Auto-update settings
```

## 🤝 Contributing

Contributions are welcome! Here’s how you can help:

1. **Fork** the repository
1. **Create** a feature branch (`git checkout -b feature/amazing-feature`)
1. **Test** your changes with `--dry-run`
1. **Commit** your changes (`git commit -m 'Add amazing feature'`)
1. **Push** to the branch (`git push origin feature/amazing-feature`)
1. **Open** a Pull Request

### Development Guidelines

- Test all changes with `--dry-run` mode
- Maintain backward compatibility
- Add appropriate error handling
- Update documentation for new features
- Follow existing code style and patterns

## 🐛 Troubleshooting

### Common Issues

**Script fails with permission error**

```bash
# Solution: Run as root
sudo ./debian-setup.sh
```

**SSH connection lost during setup**

```bash
# This shouldn't happen with v2.0, but if it does:
# Connect via console/KVM and check:
sudo systemctl status ssh
sudo journalctl -u ssh
```

**Docker installation fails**

```bash
# Check architecture support:
dpkg --print-architecture
# Supported: amd64, arm64, armhf
```

**Locale not found**

```bash
# Check available locales:
cat /usr/share/i18n/SUPPORTED | grep -i en_US
```

### Log Analysis

```bash
# View full execution log
sudo tail -f /var/log/debian-setup.log

# Check for errors
sudo grep ERROR /var/log/debian-setup.log

# View configuration backups
ls -la /root/debian-setup-backups/
```

## 📄 License

This project is licensed under the MIT License - see the <LICENSE> file for details.

## 🙏 Acknowledgments

- Original concept and development by [Snake16547](https://github.com/Snake16547)
- Enhanced with security improvements and error handling
- Inspired by best practices from the Debian community
- Built for system administrators who value reliability and security

## 🔗 Links

- [Docker Official Documentation](https://docs.docker.com/)
- [Debian Administrator’s Handbook](https://debian-handbook.info/)
- [SSH Security Best Practices](https://www.ssh.com/academy/ssh/security)
- [Endlessh - SSH Tarpit](https://github.com/skeeto/endlessh)

-----

**Made with ❤️ for the Debian community**

> 💡 **Pro Tip**: Always test with `--dry-run` first, especially on production servers!