#!/bin/bash
set -e

GITHUB_RAW_URL="https://raw.githubusercontent.com/denizissidev/vm-manager/main/vm-manager.sh"
VERSION_URL="https://raw.githubusercontent.com/denizissidev/vm-manager/main/VERSION"
INSTALL_DIR="$HOME/.deniztech-vm"
VM_DATA_DIR="$HOME/vms"

echo "╔════════════════════════════════════════════════════════════╗"
echo "║          DenizTech VM Manager - Auto Installer             ║"
echo "║                  with Auto-Update Support                  ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

# Check if running as root
if [ "$EUID" -eq 0 ]; then 
    echo "⚠️  Please do not run this script as root!"
    echo "💡 Run it as a normal user: ./install-and-run.sh"
    exit 1
fi

# Step 1: Install dependencies
echo "📦 Step 1/5: Installing dependencies..."
echo "This will require sudo password..."
echo ""

sudo apt update
sudo apt install -y qemu-system qemu-utils cloud-image-utils wget lsof curl

echo ""
echo "✅ Dependencies installed!"
echo ""

# Step 2: Verify installations
echo "🔍 Step 2/5: Verifying installations..."
all_good=true
for cmd in qemu-system-x86_64 wget cloud-localds qemu-img lsof curl; do
    if command -v "$cmd" &> /dev/null; then
        echo "  ✓ $cmd"
    else
        echo "  ✗ $cmd NOT FOUND"
        all_good=false
    fi
done

if [ "$all_good" = false ]; then
    echo ""
    echo "❌ Some dependencies failed to install. Please check the errors above."
    exit 1
fi

echo ""
echo "✅ All dependencies verified!"
echo ""

# Step 3: Create directories
echo "⚙️  Step 3/5: Setting up directories..."
mkdir -p "$INSTALL_DIR"
mkdir -p "$VM_DATA_DIR"
echo "  ✓ Installation directory: $INSTALL_DIR"
echo "  ✓ VM storage directory: $VM_DATA_DIR"
echo ""

# Step 4: Download latest vm-manager from GitHub
echo "🌐 Step 4/5: Downloading latest VM Manager from GitHub..."
if wget -q "$GITHUB_RAW_URL" -O "$INSTALL_DIR/vm-manager.sh"; then
    chmod +x "$INSTALL_DIR/vm-manager.sh"
    echo "  ✓ VM Manager downloaded successfully"
    
    # Download version file
    if wget -q "$VERSION_URL" -O "$INSTALL_DIR/VERSION" 2>/dev/null; then
        echo "  ✓ Version file downloaded"
    else
        echo "1.0.0" > "$INSTALL_DIR/VERSION"
        echo "  ℹ️  Created default version file"
    fi
else
    echo ""
    echo "❌ Failed to download VM Manager from GitHub"
    echo "💡 Check your internet connection or repository URL"
    exit 1
fi

echo ""

# Step 5: Setup global command
echo "🔧 Step 5/5: Setting up global 'vmmanager' command..."

# Check if alias already exists
if grep -q "alias vmmanager=" "$HOME/.bashrc" 2>/dev/null; then
    echo "  ℹ️  Command already configured in .bashrc"
else
    # Add alias to .bashrc
    cat >> "$HOME/.bashrc" << 'ALIAS_EOF'

# DenizTech VM Manager - Global Command
alias vmmanager='$HOME/.deniztech-vm/vm-manager.sh'
ALIAS_EOF
    echo "  ✓ Added 'vmmanager' command to .bashrc"
fi

# Also check .zshrc for zsh users
if [ -f "$HOME/.zshrc" ]; then
    if grep -q "alias vmmanager=" "$HOME/.zshrc" 2>/dev/null; then
        echo "  ℹ️  Command already configured in .zshrc"
    else
        cat >> "$HOME/.zshrc" << 'ALIAS_EOF'

# DenizTech VM Manager - Global Command
alias vmmanager='$HOME/.deniztech-vm/vm-manager.sh'
ALIAS_EOF
        echo "  ✓ Added 'vmmanager' command to .zshrc"
    fi
fi

# Create symlink for immediate use without reloading shell
sudo ln -sf "$INSTALL_DIR/vm-manager.sh" /usr/local/bin/vmmanager 2>/dev/null || {
    echo "  ⚠️  Could not create system-wide link (no sudo access)"
    echo "  💡 You can still use: $INSTALL_DIR/vm-manager.sh"
}

echo ""
echo "╔════════════════════════════════════════════════════════════╗"
echo "║               🎉 Installation Complete!                    ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""
echo "✅ VM Manager installed to: $INSTALL_DIR"
echo "✅ VM storage location: $VM_DATA_DIR"
echo ""
echo "🚀 You can now run VM Manager with any of these commands:"
echo "   • vmmanager           (after reopening terminal)"
echo "   • $INSTALL_DIR/vm-manager.sh"
echo ""
echo "📝 Note: Type 'vmmanager' from any directory after reopening your terminal"
echo ""

read -p "🎯 Would you like to start VM Manager now? (y/N): " start_now
if [[ "$start_now" =~ ^[Yy]$ ]]; then
    echo ""
    exec "$INSTALL_DIR/vm-manager.sh"
else
    echo ""
    echo "💡 When ready, just type: vmmanager"
    echo ""
fi