#!/usr/bin/env bash
# DenizTech VM-Manager Installer - Cloud & Local Version
set -e

# Colors
R='\033[1;31m'
G='\033[1;32m'
Y='\033[1;33m'
W='\033[1;37m'
C='\033[1;36m'
N='\033[0m'

# Paths
INSTALL_DIR="$HOME/.deniztech-vm"
VERSION_FILE="$INSTALL_DIR/version.txt"
GITHUB_REPO="denizissidev/vm-manager"

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
    
    echo -e "${Y}🧹 Cleaning up environment...${N}"
    cd "$HOME"
    rm -rf myapp flutter 2>/dev/null || true
    
    mkdir -p "$HOME/vps123"
    cd "$HOME/vps123"
    
    echo -e "${G}📁 Creating .idx configuration...${N}"
    mkdir -p .idx
    
    cat <<EOF > .idx/dev.nix
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
    echo -e "${R}👉 IMPORTANT: Click 'REBUILD ENVIRONMENT' in the bottom popup!${N}"
    echo
    read -p "Press Enter to return to menu..."
}

download_manager() {
    echo -e "${Y}🔍 Checking GitHub for the latest version...${N}"
    mkdir -p "$INSTALL_DIR"
    mkdir -p "$HOME/vms"

    # THE GITHUB VERSION CHECKER GANG
    LATEST_RELEASE=$(curl -s "https://api.github.com/repos/$GITHUB_REPO/releases/latest" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/' || echo "v1.0.0")
    
    if [ -z "$LATEST_RELEASE" ]; then
        echo -e "${R}❌ Could not connect to GitHub. Using fallback version v1.0.0${N}"
        LATEST_RELEASE="v1.0.0"
    fi

    # Bypass sudo apt for Google IDX/Nix
    if [ -d "/etc/nix" ] || [ -n "${IDX_WORKSPACE_ID:-}" ]; then
        echo -e "${Y}ℹ️  IDX detected. Skipping 'sudo apt' (Use Option 2 instead).${N}"
    else
        echo -e "${C}📥 Installing local dependencies...${N}"
        sudo apt update && sudo apt install -y qemu-system qemu-utils cloud-image-utils wget lsof curl || true
    fi

    echo -e "${C}🌐 Downloading VM Manager $LATEST_RELEASE...${N}"
    curl -sL "https://raw.githubusercontent.com/$GITHUB_REPO/main/vm-manager.sh" -o "$INSTALL_DIR/vm-manager.sh"
    
    # CRITICAL: Fix line endings so the script actually runs
    sed -i 's/\r$//' "$INSTALL_DIR/vm-manager.sh"
    chmod +x "$INSTALL_DIR/vm-manager.sh"
    
    # Save the version for the internal updater
    echo "$LATEST_RELEASE" > "$VERSION_FILE"

    # SETUP THE ALIAS
    if ! grep -q "alias vmmanager=" "$HOME/.bashrc"; then
        echo -e "\n# DenizTech VM Manager\nalias vmmanager='$INSTALL_DIR/vm-manager.sh'" >> "$HOME/.bashrc"
        echo -e "${G}✅ Alias 'vmmanager' added to .bashrc${N}"
    fi

    echo -e "${G}✅ Success! VM Manager $LATEST_RELEASE downloaded.${N}"
    echo -e "${Y}👉 ACTION REQUIRED: Type 'source ~/.bashrc' after exiting.${N}"
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
        0) 
            echo -e "${G}Cleaning up and exiting...${N}"
            echo -e "${Y}Don't forget to run: source ~/.bashrc${N}"
            exit 0 
            ;;
        *) echo -e "${R}Invalid choice${N}"; sleep 1 ;;
    esac
done
