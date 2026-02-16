#!/usr/bin/env bash
set -e

echo "╔════════════════════════════════════════════════════════════╗"
echo "║          DenizTech VM Manager - Auto Installer             ║"
echo "║                  with Auto-Update Support                  ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

if [ "$EUID" -eq 0 ]; then 
    echo "⚠️  Please do not run this script as root!"
    echo "💡 Run it as a normal user: bash install-and-run.sh"
    exit 1
fi

echo "📦 Step 1/5: Installing dependencies..."
echo "This will require sudo password..."
echo ""

sudo apt update
sudo apt install -y qemu-system qemu-utils cloud-image-utils wget lsof curl

echo ""
echo "✅ Dependencies installed!"
echo ""

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
    echo "❌ Some dependencies failed to install."
    exit 1
fi

echo ""
echo "✅ All dependencies verified!"
echo ""

echo "⚙️  Step 3/5: Setting up directories..."
INSTALL_DIR="$HOME/.deniztech-vm"
VM_DIR="$HOME/vms"

mkdir -p "$INSTALL_DIR"
mkdir -p "$VM_DIR"

echo "  ✓ Installation directory: $INSTALL_DIR"
echo "  ✓ VM storage directory: $VM_DIR"
echo ""

echo "🌐 Step 4/5: Downloading latest VM Manager from GitHub..."

GITHUB_REPO="denizissidev/vm-manager"
LATEST_RELEASE=$(curl -s "https://api.github.com/repos/$GITHUB_REPO/releases/latest" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')

if [ -z "$LATEST_RELEASE" ] || [ "$LATEST_RELEASE" == "null" ]; then
    echo "  ℹ️  Using direct download from main branch..."
    curl -sL "https://raw.githubusercontent.com/$GITHUB_REPO/main/vm-manager.sh" -o "$INSTALL_DIR/vm-manager.sh.tmp"
    VERSION="main"
else
    echo "  ℹ️  Latest version: $LATEST_RELEASE"
    curl -sL "https://github.com/$GITHUB_REPO/releases/download/$LATEST_RELEASE/vm-manager.sh" -o "$INSTALL_DIR/vm-manager.sh.tmp" 2>/dev/null || \
    curl -sL "https://raw.githubusercontent.com/$GITHUB_REPO/main/vm-manager.sh" -o "$INSTALL_DIR/vm-manager.sh.tmp"
    VERSION="$LATEST_RELEASE"
fi

# Fix line endings automatically (CRLF → LF)
echo "  🔧 Fixing line endings (Windows → Unix)..."
sed 's/\r$//' "$INSTALL_DIR/vm-manager.sh.tmp" > "$INSTALL_DIR/vm-manager.sh"
rm -f "$INSTALL_DIR/vm-manager.sh.tmp"

# Ensure it's executable
chmod +x "$INSTALL_DIR/vm-manager.sh"

# Save version
echo "$VERSION" > "$INSTALL_DIR/version.txt"

# Verify the file is now correct
if head -1 "$INSTALL_DIR/vm-manager.sh" | grep -q $'bash\r'; then
    echo "  ⚠️  Line ending fix failed, trying alternative method..."
    tr -d '\r' < "$INSTALL_DIR/vm-manager.sh" > "$INSTALL_DIR/vm-manager.sh.fixed"
    mv "$INSTALL_DIR/vm-manager.sh.fixed" "$INSTALL_DIR/vm-manager.sh"
    chmod +x "$INSTALL_DIR/vm-manager.sh"
fi

echo "  ✓ VM Manager downloaded and fixed successfully"
echo ""

echo "🔧 Step 5/5: Setting up global 'vmmanager' command..."

if ! grep -q "alias vmmanager=" "$HOME/.bashrc" 2>/dev/null; then
    echo "" >> "$HOME/.bashrc"
    echo "# DenizTech VM Manager" >> "$HOME/.bashrc"
    echo "alias vmmanager='$INSTALL_DIR/vm-manager.sh'" >> "$HOME/.bashrc"
    echo "  ✓ Added 'vmmanager' command to .bashrc"
else
    # Update existing alias to ensure it points to correct location
    sed -i "s|alias vmmanager=.*|alias vmmanager='$INSTALL_DIR/vm-manager.sh'|g" "$HOME/.bashrc"
    echo "  ✓ Updated 'vmmanager' command in .bashrc"
fi

# Try to create system-wide command (optional, no sudo prompt)
if [ -w "/usr/local/bin" ]; then
    ln -sf "$INSTALL_DIR/vm-manager.sh" /usr/local/bin/vmmanager 2>/dev/null || true
fi

echo ""
echo "╔════════════════════════════════════════════════════════════╗"
echo "║               🎉 Installation Complete!                    ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""
echo "✅ VM Manager installed to: $INSTALL_DIR"
echo "✅ VM storage location: $VM_DIR"
echo "✅ Line endings fixed automatically"
echo ""

# Automatically source .bashrc for current session
echo "🔄 Loading vmmanager command for current session..."
source "$HOME/.bashrc"

echo "✅ 'vmmanager' command is now available!"
echo ""
echo "🚀 You can now run VM Manager from anywhere with:"
echo "   • vmmanager"
echo ""

# Verify installation
echo "📝 Verifying installation..."
if command -v vmmanager &> /dev/null; then
    echo "  ✅ 'vmmanager' command is working!"
else
    echo "  ⚠️  Creating alias for current session..."
    alias vmmanager="$INSTALL_DIR/vm-manager.sh"
fi

echo ""
read -p "🎯 Would you like to start VM Manager now? (y/N): " start_now
if [[ "$start_now" =~ ^[Yy]$ ]]; then
    clear
    exec "$INSTALL_DIR/vm-manager.sh"
fi

echo ""
echo "💡 Tip: Just type 'vmmanager' anytime to launch the VM Manager!"
