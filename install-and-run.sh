#!/usr/bin/env bash
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
    
    mkdir -p "$HOME/vps123"
    cd "$HOME/vps123"
    
    if [ ! -d ".idx" ]; then
        echo -e "${G}📁 Creating .idx directory...${N}"
        mkdir .idx
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
        echo -e "${R}👉 Now click 'REBUILD ENVIRONMENT' in the bottom popup!${N}"
    else
        echo -e "${Y}ℹ️  IDX configuration already exists.${N}"
    fi
    echo
    read -p "Press Enter to return to menu..."
}

download_manager() {
    INSTALL_DIR="$HOME/.deniztech-vm"
    VM_DIR="$HOME/vms"
    mkdir -p "$INSTALL_DIR"
    mkdir -p "$VM_DIR"

    # Skip sudo if in cloud environment to avoid "command not found"
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
    chmod +x "$INSTALL_DIR/vm-manager.sh"
    
    echo "$LATEST_RELEASE" > "$INSTALL_DIR/version.txt"

    if ! grep -q "alias vmmanager=" "$HOME/.bashrc"; then
        echo "alias vmmanager='$INSTALL_DIR/vm-manager.sh'" >> "$HOME/.bashrc"
    fi

    echo -e "${G}✅ Success! Run 'source ~/.bashrc' then 'vmmanager'${N}"
    read -p "Press Enter to return to menu..."
}

# Main Menu
while true; do
    clear
    print_jishnu_logo
    echo -e "1) 📥 DOWNLOAD VM-MANAGER"
    echo -e "2) 🔧 INSTALL TOOL FOR GOOGLE IDX"
    echo -e "0) 🚪 EXIT"
    echo
    read -p "Select an option: " choice

    case $choice in
        1) download_manager ;;
        2) idx_setup ;;
        0) exit 0 ;;
        *) echo -e "${R}Invalid choice${N}"; sleep 1 ;;
    esac
done
