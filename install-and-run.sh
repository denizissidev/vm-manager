#!/usr/bin/env bash
# Finalized DenizTech Installer for Cloud & Local Environments
set -e

# Colors
R='\033[1;31m'
G='\033[1;32m'
Y='\033[1;33m'
W='\033[1;37m'
C='\033[1;36m'
N='\033[0m'

print_jishnu_logo() {
    echo -e "${C}"
    echo "========================================================================"
    echo "                       _ _     _                 "
    echo "                      | (_)   | |                "
    echo "                      | |_ ___| |__  _ __  _   _ "
    echo "                  _   | | / __| '_ \| '_ \| | | |"
    echo "                 | |__| | \__ \ | | | | | | |_| |"
    echo "                  \____/|_|___/_| |_|_| |_|\__,_|"
    echo "                                                  "
    echo "                    POWERED BY DENIZTECH          "
    echo "========================================================================"
    echo -e "${N}"
}

idx_setup() {
    clear
    print_jishnu_logo
    echo -e "${R}╔══════════════════════════════════════════════════════════╗${N}"
    echo -e "${R}║${W}              IDX DEVELOPMENT TOOL SETUP               ${R}║${N}"
    echo -e "${R}╚══════════════════════════════════════════════════════════╝${N}\n"
    
    echo -e "${Y}🧹 Cleaning up old files...${N}"
    cd "$HOME"
    rm -rf myapp flutter 2>/dev/null || true
    
    # Target the workspace folder shown in your logs
    mkdir -p "$HOME/vps123"
    cd "$HOME/vps123"
    
    echo -e "${G}📁 Creating .idx directory...${N}"
    mkdir -p .idx
    cd .idx
    
    echo -e "${C}📝 Creating dev.nix configuration...${N}"
    cat <<EOF > dev.nix
{ pkgs, ... }: {
  channel = "stable-24.05";
  packages = with pkgs; [
    unzip
    openssh
    git
    qemu_kvm
    sudo
    cdrkit
    cloud-utils
    qemu
  ];
  idx = {
    workspace = {
      onCreate = { };
      onStart = { };
    };
  };
}
EOF
    echo -e "${G}✅ IDX TOOL SETUP COMPLETE!${N}"
    echo -e "${R}👉 IMPORTANT: Click 'REBUILD ENVIRONMENT' in the popup!${N}"
    echo
    read -p "Press Enter to return to menu..."
}

download_manager() {
    echo -e "${Y}📦 Initializing Installation...${N}"
    INSTALL_DIR="$HOME/.deniztech-vm"
    mkdir -p "$INSTALL_DIR"
    mkdir -p "$HOME/vms"

    # Bypass sudo for IDX/Nix environments
    if [ -d "/etc/nix" ] || [ -n "${IDX_WORKSPACE_ID:-}" ]; then
        echo -e "${Y}ℹ️  Cloud environment detected. Skipping system sudo apt.${N}"
    else
        echo -e "${C}📥 Installing dependencies...${N}"
        sudo apt update && sudo apt install -y qemu-system qemu-utils cloud-image-utils wget lsof curl || true
    fi

    GITHUB_REPO="denizissidev/vm-manager"
    LATEST_RELEASE=$(curl -s "https://api.github.com/repos/$GITHUB_REPO/releases/latest" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/' || echo "v1.0.0")

    echo -e "${C}🌐 Downloading VM Manager $LATEST_RELEASE...${N}"
    curl -sL "https://raw.githubusercontent.com/$GITHUB_REPO/main/vm-manager.sh" -o "$INSTALL_DIR/vm-manager.sh"
    
    # Fix potential Windows line endings on the downloaded file
    sed -i 's/\r$//' "$INSTALL_DIR/vm-manager.sh"
    chmod +x "$INSTALL_DIR/vm-manager.sh"
    
    echo "$LATEST_RELEASE" > "$INSTALL_DIR/version.txt"

    # Add alias to .bashrc if not exists
    if ! grep -q "alias vmmanager=" "$HOME/.bashrc"; then
        echo -e "\n# DenizTech VM Manager\nalias vmmanager='$INSTALL_DIR/vm-manager.sh'" >> "$HOME/.bashrc"
    fi

    echo -e "${G}✅ Success! VM Manager is ready.${N}"
    echo -e "${Y}👉 Run 'source ~/.bashrc' then type 'vmmanager' to start.${N}"
    read -p "Press Enter to return to menu..."
}

# Main Loop
while true; do
    clear
    print_jishnu_logo
    echo -e "${W}1) 📥 DOWNLOAD VM-MANAGER${N}"
    echo -e "${W}2) 🔧 INSTALL TOOL FOR GOOGLE IDX${N}"
    echo -e "${W}0) 🚪 EXIT${N}"
    echo
    read -p "Select an option: " choice

    case $choice in
        1) download_manager ;;
        2) idx_setup ;;
        0) exit 0 ;;
        *) echo -e "${R}Invalid choice${N}"; sleep 1 ;;
    esac
done
