#!/bin/bash

# Guided Debian Server Setup Script

# Ensure script is run as root
if [ "$(id -u)" -ne 0 ]; then
    echo "This script must be run as root."
    exit 1
fi

echo "Welcome to the Debian Server Setup Script"

# Set Hostname
while true; do
    read -p "Enter the desired hostname: " hostname
    if [[ -n "$hostname" ]]; then
        hostnamectl set-hostname "$hostname"
        echo "Hostname set to $hostname"
        
        # Update /etc/hosts to reflect the new hostname
        if grep -q "127.0.1.1" /etc/hosts; then
            sed -i "s/^127.0.1.1.*/127.0.1.1 $hostname/" /etc/hosts
        else
            echo "127.0.1.1 $hostname" >> /etc/hosts
        fi
        echo "Updated /etc/hosts with hostname $hostname"
        break
    else
        echo "Hostname cannot be empty. Please try again."
    fi
done

# Set Timezone with Filtering
while true; do
    read -p "Enter part of your timezone (e.g., 'Europe' or 'Berlin') and press Enter: " tz_search
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
        timedatectl set-timezone "$timezone"
        echo "Timezone set to $timezone"
        break
    else
        echo "Invalid selection. Please try again."
    fi
done

# Set Locale with Filtering
while true; do
    read -p "Enter part of your preferred locale (e.g., 'en' or 'de') and press Enter: " locale_search
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
    if [[ "$locale_number" =~ ^[0-9]+$ ]] && [ "$locale_number" -ge 1 ] && [ "$locale_number" -le "${#matching_locales[@]}" ]; then
        locale="${matching_locales[$((locale_number-1))]}"
        sed -i "s/^# *$locale UTF-8/$locale UTF-8/" /etc/locale.gen
        locale-gen
        update-locale LANG=$locale
        echo "Locale set to $locale"
        break
    else
        echo "Invalid selection. Please try again."
    fi
done

# Change SSH Port
read -p "Enter new SSH port (default: 22): " ssh_port
ssh_port=${ssh_port:-22}
sed -i "s/^#Port 22/Port $ssh_port/" /etc/ssh/sshd_config
echo "SSH port set to $ssh_port"

# Option to install Endlessh as SSH honeypot on port 22
read -p "Would you like to install Endlessh to act as an SSH honeypot on port 22? (y/n): " install_endlessh
if [[ "$install_endlessh" =~ ^[Yy]$ ]]; then
    echo "Installing Endlessh..."
    apt install -y endlessh

    # Configure Endlessh to listen on port 22
    cat > /etc/endlessh/config <<EOF
Port 22
Delay 10000
MaxLineLength 32
LogLevel 1
EOF

    systemctl enable --now endlessh
    echo "Endlessh installed and configured to listen on port 22."
fi

# Option to install Essential Packages
read -p "Would you like to install essential system packages? (y/n): " install_packages
if [[ "$install_packages" =~ ^[Yy]$ ]]; then
    echo "Installing essential packages..."
    apt update
    apt install -y sudo curl wget ntp htop unattended-upgrades
    echo "Essential packages installed."
fi

# Install Docker
echo "Checking system architecture..."
arch=$(dpkg --print-architecture)
if [[ "$arch" == "amd64" || "$arch" == "arm64" || "$arch" == "armhf" ]]; then
    echo "Installing Docker..."
    apt install -y apt-transport-https ca-certificates curl gnupg
    curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
    echo "deb [arch=$arch signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/debian $(lsb_release -cs) stable" \
        | tee /etc/apt/sources.list.d/docker.list > /dev/null
    apt update
    apt install -y docker-ce docker-ce-cli containerd.io
    systemctl enable --now docker
    echo "Docker installed successfully."
else
    echo "Unsupported architecture: $arch. Skipping Docker installation."
fi

# Final Setup Summary
echo -e "\n\033[1;32m=== Setup Complete ===\033[0m"
echo -e "\033[1;34mHostname:\033[0m $hostname"
echo -e "\033[1;34mTimezone:\033[0m $timezone"
echo -e "\033[1;34mLocale:\033[0m $locale"
echo -e "\033[1;34mSSH Port:\033[0m $ssh_port"
echo -e "\033[1;34mEndlessh Installed:\033[0m $(if systemctl is-active --quiet endlessh; then echo "Yes (listening on port 22)"; else echo "No"; fi)"
echo -e "\033[1;34mEssential Packages Installed:\033[0m $([[ "$install_packages" =~ ^[Yy]$ ]] && echo "Yes" || echo "No")"
echo -e "\033[1;34mDocker Installed:\033[0m $(if systemctl is-active --quiet docker; then echo "Yes"; else echo "No"; fi)"

# Prompt for Reboot
read -p "Setup is complete. A reboot is recommended. Reboot now? (y/n): " reboot_now
if [[ "$reboot_now" =~ ^[Yy]$ ]]; then
    echo "Rebooting system..."
    reboot
else
    echo "Setup complete. Please reboot your system manually for all changes to take effect."
fi