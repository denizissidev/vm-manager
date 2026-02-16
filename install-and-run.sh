#!/usr/bin/env bash
set -e

echo "╔════════════════════════════════════════════════════════════╗"
echo "║          DenizTech VM Manager - Auto Installer             ║"
echo "║             (Cloud & Local Environment Support)            ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

# Detection for Google IDX / Nix environments
IS_IDX=false
if [ -n "${IDX_WORKSPACE_ID:-}" ] || [ -d "/etc/nix" ]; then
    IS_IDX=true
fi

if [ "$EUID\" -eq 0 ]; then 
    echo "⚠️  Please do not run this script as root!"
    exit 1
fi

echo "📦 Step 1/5: Installing dependencies..."

if [ "$IS_IDX" = true ]; then
    echo "✨ Google IDX/Nix environment detected."
    echo "ℹ️  Skipping 'sudo apt' as it is not supported in this environment."
    echo "💡 Note: You must use the 'Setup Google IDX' option (i) inside the script"
    echo "   to install QEMU and other tools via your dev.nix file."
else
    echo "🏠 Local Linux environment detected. Requiring sudo..."
    if command -v apt-get &> /dev/null; then
        sudo apt update
        sudo apt install -y qemu-system qemu-utils cloud-image-utils wget lsof curl
    else
        echo "⚠️  Package manager not supported automatically. Please ensure qemu and wget are installed."
    fi
fi

echo ""
echo "🔍 Step 2/5: Verifying installations..."
all_good=true
for cmd in wget qemu-img lsof curl; do
    if command -v "$cmd" &> /dev/null; then
        echo "  ✓ $cmd"
    else
        echo "  ✗ $cmd NOT FOUND"
        all_good=false
    fi
done

# In IDX, qemu-system and cloud-localds might be missing until dev.nix is rebuilt
if [ "$IS_IDX" = false ] && ! command -v qemu-system-x86_64 &> /dev/null; then
    all_good=false
fi

if [ "$all_good\" = false ] && [ "$IS_IDX" = false ]; then
    echo "❌ Some critical dependencies are missing. Please install them manually."
    exit 1
fi

echo ""
echo "📂 Step 3/5: Setting up directories..."
INSTALL_DIR="$HOME/.deniztech-vm"
VM_DIR="$HOME/vms"
mkdir -p "$INSTALL_DIR"
mkdir -p "$VM_DIR"
echo "  ✓ Directories created"

echo ""
echo "📥 Step 4/5: Downloading/Updating VM Manager..."
GITHUB_REPO="denizissidev/vm-manager"
LATEST_RELEASE=$(curl -s "https://api.github.com/repos/$GITHUB_REPO/releases/latest" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/' || echo "v1.0.0")

# If local file exists, move it to install dir, otherwise download
if [ -f "vm-manager.sh" ]; then
    cp "vm-manager.sh" "$INSTALL_DIR/vm-manager.sh"
    echo "  ✓ Used local vm-manager.sh"
else
    echo "  🌐 Downloading $LATEST_RELEASE..."
    curl -sL "https://raw.githubusercontent.com/$GITHUB_REPO/main/vm-manager.sh" -o "$INSTALL_DIR/vm-manager.sh"
fi

echo "$LATEST_RELEASE" > "$INSTALL_DIR/version.txt"
chmod +x "$INSTALL_DIR/vm-manager.sh"
echo "  ✓ VM Manager prepared successfully"

echo ""
echo "🔧 Step 5/5: Setting up 'vmmanager' command..."

# Setup Alias in .bashrc
if ! grep -q "alias vmmanager=" "$HOME/.bashrc" 2>/dev/null; then
    echo "" >> "$HOME/.bashrc"
    echo "# DenizTech VM Manager" >> "$HOME/.bashrc"
    echo "alias vmmanager='$INSTALL_DIR/vm-manager.sh'" >> "$HOME/.bashrc"
    echo "  ✓ Added 'vmmanager' alias to .bashrc"
else
    echo "  ℹ️  'vmmanager' alias already exists"
fi

# Try to create symlink only if writeable (usually fails in IDX, which is why we use alias)
if [ -w "/usr/local/bin" ]; then
    sudo ln -sf "$INSTALL_DIR/vm-manager.sh" /usr/local/bin/vmmanager 2>/dev/null || true
fi

echo ""
echo "╔════════════════════════════════════════════════════════════╗"
echo "║               🎉 Installation Complete!                    ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""
echo "✅ Installed to: $INSTALL_DIR"
if [ "$IS_IDX" = true ]; then
    echo "⚠️  IMPORTANT: Run 'source ~/.bashrc' then type 'vmmanager'"
    echo "⚠️  Inside the script, select option 'i' to fix your IDX environment."
else
    echo "🚀 Run 'source ~/.bashrc' then type 'vmmanager' to start!"
fi
