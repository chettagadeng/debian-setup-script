# debian-setup-script
Guided Debian Server Setup Script

Usage:
    
    wget https://raw.githubusercontent.com/Snake16547/debian-setup-script/refs/heads/main/debian-setup.sh && sudo chmod +x debian-setup.sh && ./debian-setup.sh
    
Features:

✅ Interactive prompts for hostname with /etc/hosts, timezone, locale, and SSH port

✅ Optional install for endlessh

✅ Essential packages installation (sudo, curl, wget, ntp, htop, unattended-upgrades)

✅ Optional MOTD script for server insights

✅ Docker installation from the official repository, based on system architecture
