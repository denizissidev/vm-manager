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
    echo "                    POWERED BY DENIZTECHHH          "
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
    unzip openssh git qemu_kvm sudo cdrkit cloud-utils qemu
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
    clear
    print_jishnu_logo
    echo "📦 Step 1/5: Installing dependencies..."
    
    # --- SUDO BYPASS FOR CLOUD SHELLS ---
    if [ -d "/etc/nix" ] || [ -n "${IDX_WORKSPACE_ID:-}" ]; then
        echo -e "${Y}ℹ️  Cloud environment detected. Skipping 'sudo apt' to prevent errors.${N}"
        echo -e "${Y}ℹ️  Make sure you ran Option 2 and Rebuilt first.${N}"
    else
        echo "This will require sudo password..."
        sudo apt update
        sudo apt install -y qemu-system qemu-utils cloud-image-utils wget lsof curl
    fi

    echo ""
    echo "🔍 Step 2/5: Verifying installations..."
    all_good=true
    for cmd in qemu-img wget lsof curl; do
        if command -v "$cmd" &> /dev/null; then
            echo "  ✓ $cmd"
        else
            echo "  ✗ $cmd NOT FOUND"
            all_good=false
        fi
    done

    if [ "$all_good" = false ] && [ ! -d "/etc/nix" ]; then
        echo "❌ Some dependencies failed to install."
        exit 1
    fi

    echo "⚙️  Step 3/5: Setting up directories..."
    INSTALL_DIR="$HOME/.deniztech-vm"
    VM_DIR="$HOME/vms"
    mkdir -p "$INSTALL_DIR"
    mkdir -p "$VM_DIR"

    echo "🌐 Step 4/5: Downloading latest VM Manager from GitHub..."
    GITHUB_REPO="denizissidev/vm-manager"
    LATEST_RELEASE=$(curl -s "https://api.github.com/repos/$GITHUB_REPO/releases/latest" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')

    if [ -z "$LATEST_RELEASE" ] || [ "$LATEST_RELEASE" == "null" ]; then
        curl -sL "https://raw.githubusercontent.com/$GITHUB_REPO/main/vm-manager.sh" -o "$INSTALL_DIR/vm-manager.sh.tmp"
        VERSION="main"
    else
        curl -sL "https://raw.githubusercontent.com/$GITHUB_REPO/main/vm-manager.sh" -o "$INSTALL_DIR/vm-manager.sh.tmp"
        VERSION="$LATEST_RELEASE"
    fi

    sed 's/\r$//' "$INSTALL_DIR/vm-manager.sh.tmp" > "$INSTALL_DIR/vm-manager.sh"
    rm -f "$INSTALL_DIR/vm-manager.sh.tmp"
    chmod +x "$INSTALL_DIR/vm-manager.sh"
    echo "$VERSION" > "$INSTALL_DIR/version.txt"

    echo "🔧 Step 5/5: Setting up global 'vmmanager' command..."
    if ! grep -q "alias vmmanager=" "$HOME/.bashrc" 2>/dev/null; then
        echo -e "\n# DenizTech VM Manager\nalias vmmanager='$INSTALL_DIR/vm-manager.sh'" >> "$HOME/.bashrc"
    fi

    echo -e "${G}✅ Success! VM Manager is ready.${N}"
    echo -e "${Y}👉 Run 'source ~/.bashrc' then 'vmmanager' after exiting.${N}"
    read -p "Press Enter to return to menu..."
}

# --- MAIN MENU LOOP ---
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
        *) echo -e "${R}Invalid option${N}"; sleep 1 ;;
    esac
done
