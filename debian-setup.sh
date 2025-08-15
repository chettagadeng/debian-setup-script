#!/bin/bash

# Guided Debian Server Setup Script with Dry Run Mode

# Dry run flag
DRY_RUN=false

# Check for --dry-run flag
for arg in "$@"; do
    if [[ "$arg" == "--dry-run" ]]; then
        DRY_RUN=true
        echo -e "\033[1;33mDry run mode enabled. No commands will be executed.\033[0m"
    fi
done

# Helper function to run or echo commands
run_cmd() {
    if $DRY_RUN; then
        echo "[DRY RUN] $*"
    else
        eval "$@"
    fi
}

# Ensure script is run as root
if [ "$(id -u)" -ne 0 ]; then
    echo "This script must be run as root."
    exit 1
fi

echo "Welcome to the Debian Server Setup Script"

# --- Update & Upgrade at the beginning ---
echo -e "\n\033[1;34mUpdating package lists and upgrading installed packages...\033[0m"
run_cmd apt-get update
run_cmd apt-get upgrade -y
echo -e "\033[1;32mSystem update & upgrade complete.\033[0m\n"

# Set Hostname
while true; do
    read -p "Enter the desired hostname: " hostname
    if [[ -n "$hostname" ]]; then
        run_cmd hostnamectl set-hostname "$hostname"
        echo "Hostname set to $hostname"
        
        if grep -q "127.0.1.1" /etc/hosts; then
            run_cmd sed -i "s/^127.0.1.1.*/127.0.1.1 $hostname/" /etc/hosts
        else
            run_cmd "echo '127.0.1.1 $hostname' >> /etc/hosts"
        fi
        echo "Updated /etc/hosts with hostname $hostname"
        break
    else
        echo "Hostname cannot be empty. Please try again."
    fi
done

# Set Timezone with Filtering
while true; do
    read -p "Enter part of your timezone (e.g., 'Europe' or 'Berlin'): " tz_search
    matching_timezones=($(timedatectl list-timezones | grep -i "$tz_search"))
    
    if [ ${#matching_timezones[@]} -eq 0 ]; then
        echo "No matching timezones found. Try again."
        continue
    fi

    echo "Matching timezones:"
    for i in "${!matching_timezones[@]}"; do
        echo "$((i+1))) ${matching_timezones[i]}"
    done

    read -p "Enter the number of your desired timezone: " tz_number
    if [[ "$tz_number" =~ ^[0-9]+$ ]] && [ "$tz_number" -ge 1 ] && [ "$tz_number" -le "${#matching_timezones[@]}" ]; then
        timezone="${matching_timezones[$((tz_number-1))]}"
        run_cmd timedatectl set-timezone "$timezone"
        echo "Timezone set to $timezone"
        break
    else
        echo "Invalid selection. Please try again."
    fi
done

# Set Locale with Filtering
while true; do
    read -p "Enter part of your preferred locale (e.g., 'en' or 'de'): " locale_search
    matching_locales=($(locale -a | grep -i "$locale_search" | grep -E 'utf8|UTF-8'))

    if [ ${#matching_locales[@]} -eq 0 ]; then
        echo "No matching locales found. Try again."
        continue
    fi

    echo "Matching locales:"
    for i in "${!matching_locales[@]}"; do
        echo "$((i+1))) ${matching_locales[i]}"
    done

    read -p "Enter the number of your desired locale: " locale_number
    if [[ "$locale_number" =~ ^[0-9]+$ ]] && [ "$locale_number" -ge 1 ] && [ "$locale_number" -le "${#matching_locales[@]}" ]]; then
        locale="${matching_locales[$((locale_number-1))]}"
        run_cmd sed -i "s/^# *$locale UTF-8/$locale UTF-8/" /etc/locale.gen
        run_cmd locale-gen
        run_cmd update-locale LANG=$locale
        echo "Locale set to $locale"
        break
    else
        echo "Invalid selection. Please try again."
    fi
done

# Change SSH Port
read -p "Enter new SSH port (default: 22): " ssh_port
ssh_port=${ssh_port:-22}
run_cmd sed -i "s/^#Port 22/Port $ssh_port/" /etc/ssh/sshd_config
echo "SSH port set to $ssh_port"

# Option to install Endlessh as SSH honeypot on port 22
read -p "Would you like to install Endlessh as SSH honeypot on port 22? (y/n): " install_endlessh
if [[ "$install_endlessh" =~ ^[Yy]$ ]]; then
    echo "Installing Endlessh..."
    run_cmd apt install -y endlessh

    if ! $DRY_RUN; then
        cat > /etc/endlessh/config <<EOF
Port 22
Delay 10000
MaxLineLength 32
LogLevel 1
EOF
    else
        echo "[DRY RUN] Writing Endlessh config to /etc/endlessh/config"
    fi

    run_cmd systemctl enable --now endlessh
    echo "Endlessh installed and configured."
fi

# Option to install Essential Packages
read -p "Install essential system packages (curl, htop, etc)? (y/n): " install_packages
if [[ "$install_packages" =~ ^[Yy]$ ]]; then
    echo "Installing essential packages..."
    run_cmd apt update
    run_cmd apt install -y sudo curl wget ntp htop unattended-upgrades
    echo "Essential packages installed."
fi

# Install Docker
echo "Checking system architecture..."
arch=$(dpkg --print-architecture)
if [[ "$arch" == "amd64" || "$arch" == "arm64" || "$arch" == "armhf" ]]; then
    echo "Installing Docker..."
    run_cmd apt install -y apt-transport-https ca-certificates curl gnupg
    run_cmd curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

    if ! $DRY_RUN; then
        echo "deb [arch=$arch signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/debian $(lsb_release -cs) stable" \
            | tee /etc/apt/sources.list.d/docker.list > /dev/null
    else
        echo "[DRY RUN] Adding Docker repo for arch $arch"
    fi

    run_cmd apt update
    run_cmd apt install -y docker-ce docker-ce-cli containerd.io
    run_cmd systemctl enable --now docker
    echo "Docker installed."
else
    echo "Unsupported architecture: $arch. Skipping Docker installation."
fi

# MOTD script setup
read -p "Would you like to install a system status MOTD script? (y/n): " install_motd
if [[ "$install_motd" =~ ^[Yy]$ ]]; then
    if ! $DRY_RUN; then
        cat > /etc/profile.d/motd.sh <<'EOF'
#!/bin/bash
hostname=$(hostname)
debian_version=$(cat /etc/debian_version)
ip_address=$(hostname -I | cut -d ' ' -f 1)
uptime=$(uptime -p)
current_time=$(date +"%Y-%m-%d %H:%M:%S")
disk_usage=$(df -h / | awk 'NR==2 {print "Usage: "$5"\tTotal: "$2"\tUsed: "$3"\tFree: "$4}')

echo -e "\033[1;32m=== System Status ===\033[0m"
echo -e "\033[1;34mHostname:\033[0m $hostname (Debian $debian_version)"
echo -e "\033[1;34mIP Address:\033[0m $ip_address"
echo -e "\033[1;34mUptime:\033[0m $uptime"
echo -e "\033[1;34mCurrent Time:\033[0m $current_time"
echo -e "\033[1;34mDisk Usage:\033[0m $disk_usage"
EOF
        run_cmd chmod +x /etc/profile.d/motd.sh
    else
        echo "[DRY RUN] Writing MOTD script to /etc/profile.d/motd.sh"
    fi
    echo "MOTD script setup complete."
fi

# Final Setup Summary
echo -e "\n\033[1;32m=== Setup Complete ===\033[0m"
echo -e "\033[1;34mHostname:\033[0m $hostname"
echo -e "\033[1;34mTimezone:\033[0m $timezone"
echo -e "\033[1;34mLocale:\033[0m $locale"
echo -e "\033[1;34mSSH Port:\033[0m $ssh_port"
echo -e "\033[1;34mEndlessh Installed:\033[0m $(if systemctl is-active --quiet endlessh; then echo "Yes"; else echo "No"; fi)"
echo -e "\033[1;34mEssential Packages Installed:\033[0m $([[ "$install_packages" =~ ^[Yy]$ ]] && echo "Yes" || echo "No")"
echo -e "\033[1;34mDocker Installed:\033[0m $(if systemctl is-active --quiet docker; then echo "Yes"; else echo "No"; fi)"
echo -e "\033[1;34mMOTD Installed:\033[0m $([[ "$install_motd" =~ ^[Yy]$ ]] && echo "Yes" || echo "No")"

# Reboot Prompt
if $DRY_RUN; then
    echo -e "\n[DRY RUN] Skipping reboot prompt."
else
    read -p "Setup is complete. A reboot is recommended. Reboot now? (y/n): " reboot_now
    if [[ "$reboot_now" =~ ^[Yy]$ ]]; then
        echo "Rebooting system..."
        run_cmd reboot
    else
        echo "Setup complete. Please reboot manually."
    fi
fi