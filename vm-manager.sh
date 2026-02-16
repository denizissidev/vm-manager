#!binbash
set -euo pipefail

# =============================
# DenizTech VM Manager v2.0
# Modern Multi-VM Management System
# With Auto-Update Feature
# =============================

# Version info
CURRENT_VERSION=2.0.0
GITHUB_VERSION_URL=httpsraw.githubusercontent.comdenizissidevvm-managermainVERSION
GITHUB_SCRIPT_URL=httpsraw.githubusercontent.comdenizissidevvm-managermainvm-manager.sh
INSTALL_DIR=$HOME.deniztech-vm
INSTALLER_SCRIPT=$INSTALL_DIRinstall-and-run.sh
INSTALLER_URL=httpsraw.githubusercontent.comdenizissidevvm-managermaininstall-and-run.sh

# Function to check for updates
check_for_updates() {
    if ! command -v curl & devnull; then
        return 0
    fi
    
    # Try to fetch latest version
    local latest_version=$(curl -s $GITHUB_VERSION_URL 2devnull  tr -d '[space]')
    
    if [[ -z $latest_version ]]; then
        return 0
    fi
    
    # Compare versions
    if [[ $latest_version != $CURRENT_VERSION ]]; then
        echo 
        print_status INFO 🆕 New version available $latest_version (current $CURRENT_VERSION)
        echo 
        read -p $(print_status INPUT Would you like to update now (yN) ) update_choice
        
        if [[ $update_choice =~ ^[Yy]$ ]]; then
            perform_auto_update
        else
            print_status INFO Update skipped. You can update later by running vmmanager --update
        fi
    fi
}

# Function to perform auto-update
perform_auto_update() {
    echo 
    print_status PROCESS Starting auto-update process...
    echo ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    
    # Save current VM directory path
    local vm_backup=$VM_DIR
    
    print_status INFO Backing up VM configuration...
    print_status INFO Your VMs in $vm_backup will be preserved
    
    # Download installer
    print_status PROCESS Downloading latest installer...
    mkdir -p $INSTALL_DIR
    
    if wget -q $INSTALLER_URL -O $INSTALLER_SCRIPT; then
        chmod +x $INSTALLER_SCRIPT
        print_status SUCCESS Installer downloaded
    else
        print_status ERROR Failed to download installer
        return 1
    fi
    
    # Download new version
    print_status PROCESS Downloading latest VM Manager...
    if wget -q $GITHUB_SCRIPT_URL -O $INSTALL_DIRvm-manager.sh.new; then
        chmod +x $INSTALL_DIRvm-manager.sh.new
        print_status SUCCESS New version downloaded
    else
        print_status ERROR Failed to download new version
        return 1
    fi
    
    # Download new version number
    if wget -q $GITHUB_VERSION_URL -O $INSTALL_DIRVERSION.new; then
        mv $INSTALL_DIRVERSION.new $INSTALL_DIRVERSION
    fi
    
    # Replace old with new
    print_status PROCESS Installing new version...
    mv $INSTALL_DIRvm-manager.sh.new $INSTALL_DIRvm-manager.sh
    chmod +x $INSTALL_DIRvm-manager.sh
    
    print_status SUCCESS Update completed successfully!
    print_status INFO All your VMs have been preserved
    echo 
    print_status INFO Restarting VM Manager with new version...
    echo 
    
    sleep 2
    
    # Restart with new version
    exec $INSTALL_DIRvm-manager.sh
}

# Function to display modern header
display_header() {
    clear
    cat  EOF
╔══════════════════════════════════════════════════════════════════════╗
║                                                                      ║
║    ██████╗ ███████╗███╗   ██╗██╗███████╗████████╗███████╗ ██████╗██╗║
║    ██╔══██╗██╔════╝████╗  ██║██║╚══███╔╝╚══██╔══╝██╔════╝██╔════╝██║║
║    ██║  ██║█████╗  ██╔██╗ ██║██║  ███╔╝    ██║   █████╗  ██║     ██║║
║    ██║  ██║██╔══╝  ██║╚██╗██║██║ ███╔╝     ██║   ██╔══╝  ██║     ██║║
║    ██████╔╝███████╗██║ ╚████║██║███████╗   ██║   ███████╗╚██████╗██║║
║    ╚═════╝ ╚══════╝╚═╝  ╚═══╝╚═╝╚══════╝   ╚═╝   ╚══════╝ ╚═════╝╚═╝║
║                                                                      ║
║              🚀 Advanced Virtual Machine Management System          ║
║                        Powered by DenizTech                          ║
║                           Version v$CURRENT_VERSION                           ║
╚══════════════════════════════════════════════════════════════════════╝
EOF
    echo
}

# Function to display colored output with modern emojis
print_status() {
    local type=$1
    local message=$2
    
    case $type in
        INFO) echo -e 033[1;36m ℹ️  033[1;97m[INFO]033[0m $message ;;
        WARN) echo -e 033[1;33m ⚠️  033[1;93m[WARN]033[0m $message ;;
        ERROR) echo -e 033[1;31m ❌ 033[1;91m[ERROR]033[0m $message ;;
        SUCCESS) echo -e 033[1;32m ✅ 033[1;92m[SUCCESS]033[0m $message ;;
        INPUT) echo -ne 033[1;35m 🎯 033[1;95m[INPUT]033[0m $message ;;
        PROCESS) echo -e 033[1;34m ⚙️  033[1;94m[PROCESS]033[0m $message ;;
        ) echo [$type] $message ;;
    esac
}

# Function to check if image file is locked
check_image_lock() {
    local img_file=$1
    local vm_name=$2
    
    # Check if QEMU is already using this image
    if lsof $img_file 2devnull  grep -q qemu-system; then
        print_status WARN Image file $img_file is already in use by another QEMU process
        
        # Find the process ID
        local pid=$(lsof $img_file 2devnull  grep qemu-system  awk '{print $2}'  head -1)
        if [[ -n $pid ]]; then
            print_status INFO Process ID using the image $pid
            
            # Check if it's our own VM
            if ps -p $pid -o cmd=  grep -q $vm_name; then
                print_status INFO This appears to be the same VM already running
                read -p $(print_status INPUT Kill existing process and restart (yN) ) kill_choice
                if [[ $kill_choice =~ ^[Yy]$ ]]; then
                    kill $pid
                    sleep 2
                    if kill -0 $pid 2devnull; then
                        kill -9 $pid
                        print_status WARN Forcefully terminated process $pid
                    fi
                    return 0
                else
                    return 1
                fi
            else
                print_status ERROR Another QEMU instance is using this image
                return 1
            fi
        fi
        return 1
    fi
    
    # Check for lock files
    local lock_file=${img_file}.lock
    if [[ -f $lock_file ]]; then
        print_status WARN Lock file found $lock_file
        
        # Check if lock file is stale (older than 5 minutes)
        if [[ $(find $lock_file -mmin +5 2devnull) ]]; then
            print_status WARN Lock file appears stale (older than 5 minutes)
            read -p $(print_status INPUT Remove stale lock file (yN) ) remove_lock
            if [[ $remove_lock =~ ^[Yy]$ ]]; then
                rm -f $lock_file
                print_status SUCCESS Removed stale lock file
                return 0
            else
                return 1
            fi
        fi
        return 1
    fi
    return 0
}

# Function to validate input
validate_input() {
    local type=$1
    local value=$2
    
    case $type in
        number)
            if ! [[ $value =~ ^[0-9]+$ ]]; then
                print_status ERROR Must be a number
                return 1
            fi
            ;;
        size)
            if ! [[ $value =~ ^[0-9]+[GgMm]$ ]]; then
                print_status ERROR Must be a size with unit (e.g., 100G, 512M)
                return 1
            fi
            ;;
        port)
            if ! [[ $value =~ ^[0-9]+$ ]]  [ $value -lt 23 ]  [ $value -gt 65535 ]; then
                print_status ERROR Must be a valid port number (23-65535)
                return 1
            fi
            ;;
        name)
            if ! [[ $value =~ ^[a-zA-Z0-9_-]+$ ]]; then
                print_status ERROR VM name can only contain letters, numbers, hyphens, and underscores
                return 1
            fi
            ;;
        username)
            if ! [[ $value =~ ^[a-z_][a-z0-9_-]$ ]]; then
                print_status ERROR Username must start with a letter or underscore
                return 1
            fi
            ;;
    esac
    return 0
}

# Function to check dependencies
check_dependencies() {
    local deps=(qemu-system-x86_64 wget cloud-localds qemu-img lsof)
    local missing_deps=()
    
    print_status PROCESS Checking system dependencies...
    
    for dep in ${deps[@]}; do
        if ! command -v $dep & devnull; then
            missing_deps+=($dep)
        fi
    done
    
    if [ ${#missing_deps[@]} -ne 0 ]; then
        print_status ERROR Missing dependencies ${missing_deps[]}
        print_status INFO Run the installer sudo apt install qemu-system cloud-image-utils wget lsof
        exit 1
    fi
    
    print_status SUCCESS All dependencies are installed
}

# Function to cleanup temporary files
cleanup() {
    if [ -f user-data ]; then rm -f user-data; fi
    if [ -f meta-data ]; then rm -f meta-data; fi
}

# Function to get all VM configurations
get_vm_list() {
    find $VM_DIR -name .conf -exec basename {} .conf ; 2devnull  sort
}

# Function to load VM configuration
load_vm_config() {
    local vm_name=$1
    local config_file=$VM_DIR$vm_name.conf
    
    if [[ -f $config_file ]]; then
        # Clear previous variables
        unset VM_NAME OS_TYPE CODENAME IMG_URL HOSTNAME USERNAME PASSWORD
        unset DISK_SIZE MEMORY CPUS SSH_PORT GUI_MODE PORT_FORWARDS IMG_FILE SEED_FILE CREATED
        
        source $config_file
        return 0
    else
        print_status ERROR Configuration for VM '$vm_name' not found
        return 1
    fi
}

# Function to save VM configuration
save_vm_config() {
    local config_file=$VM_DIR$VM_NAME.conf
    
    cat  $config_file EOF
VM_NAME=$VM_NAME
OS_TYPE=$OS_TYPE
CODENAME=$CODENAME
IMG_URL=$IMG_URL
HOSTNAME=$HOSTNAME
USERNAME=$USERNAME
PASSWORD=$PASSWORD
DISK_SIZE=$DISK_SIZE
MEMORY=$MEMORY
CPUS=$CPUS
SSH_PORT=$SSH_PORT
GUI_MODE=$GUI_MODE
PORT_FORWARDS=$PORT_FORWARDS
IMG_FILE=$IMG_FILE
SEED_FILE=$SEED_FILE
CREATED=$CREATED
EOF
    
    print_status SUCCESS Configuration saved to $config_file
}

# Function to create new VM
create_new_vm() {
    echo 
    print_status PROCESS Creating a new Virtual Machine
    echo ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    
    # OS Selection
    print_status INFO Available Operating Systems
    echo 
    local os_options=()
    local i=1
    for os in ${!OS_OPTIONS[@]}; do
        echo   $(tput bold)$i)$(tput sgr0) 🐧 $os
        os_options[$i]=$os
        ((i++))
    done
    echo 
    
    while true; do
        read -p $(print_status INPUT Select OS (1-${#OS_OPTIONS[@]}) ) choice
        if [[ $choice =~ ^[0-9]+$ ]] && [ $choice -ge 1 ] && [ $choice -le ${#OS_OPTIONS[@]} ]; then
            local os=${os_options[$choice]}
            IFS='' read -r OS_TYPE CODENAME IMG_URL DEFAULT_HOSTNAME DEFAULT_USERNAME DEFAULT_PASSWORD  ${OS_OPTIONS[$os]}
            print_status SUCCESS Selected $os
            break
        else
            print_status ERROR Invalid selection. Try again.
        fi
    done

    echo 
    echo ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    print_status PROCESS VM Configuration
    echo ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    echo 

    # Custom Inputs with validation
    while true; do
        read -p $(print_status INPUT VM name (default $DEFAULT_HOSTNAME) ) VM_NAME
        VM_NAME=${VM_NAME-$DEFAULT_HOSTNAME}
        if validate_input name $VM_NAME; then
            # Check if VM name already exists
            if [[ -f $VM_DIR$VM_NAME.conf ]]; then
                print_status ERROR VM with name '$VM_NAME' already exists
            else
                break
            fi
        fi
    done

    while true; do
        read -p $(print_status INPUT Hostname (default $VM_NAME) ) HOSTNAME
        HOSTNAME=${HOSTNAME-$VM_NAME}
        if validate_input name $HOSTNAME; then
            break
        fi
    done

    while true; do
        read -p $(print_status INPUT Username (default $DEFAULT_USERNAME) ) USERNAME
        USERNAME=${USERNAME-$DEFAULT_USERNAME}
        if validate_input username $USERNAME; then
            break
        fi
    done

    while true; do
        read -s -p $(print_status INPUT Password (default $DEFAULT_PASSWORD) ) PASSWORD
        PASSWORD=${PASSWORD-$DEFAULT_PASSWORD}
        echo
        if [ -n $PASSWORD ]; then
            break
        else
            print_status ERROR Password cannot be empty
        fi
    done

    while true; do
        read -p $(print_status INPUT Disk size (default 20G) ) DISK_SIZE
        DISK_SIZE=${DISK_SIZE-20G}
        if validate_input size $DISK_SIZE; then
            break
        fi
    done

    while true; do
        read -p $(print_status INPUT Memory in MB (default 2048) ) MEMORY
        MEMORY=${MEMORY-2048}
        if validate_input number $MEMORY; then
            break
        fi
    done

    while true; do
        read -p $(print_status INPUT CPU cores (default 2) ) CPUS
        CPUS=${CPUS-2}
        if validate_input number $CPUS; then
            break
        fi
    done

    while true; do
        read -p $(print_status INPUT SSH Port (default 2222) ) SSH_PORT
        SSH_PORT=${SSH_PORT-2222}
        if validate_input port $SSH_PORT; then
            # Check if port is already in use
            if ss -tln 2devnull  grep -q $SSH_PORT ; then
                print_status ERROR Port $SSH_PORT is already in use
            else
                break
            fi
        fi
    done

    while true; do
        read -p $(print_status INPUT Enable GUI mode (yn, default n) ) gui_input
        GUI_MODE=false
        gui_input=${gui_input-n}
        if [[ $gui_input =~ ^[Yy]$ ]]; then 
            GUI_MODE=true
            break
        elif [[ $gui_input =~ ^[Nn]$ ]]; then
            break
        else
            print_status ERROR Please answer y or n
        fi
    done

    # Additional network options
    read -p $(print_status INPUT Additional port forwards (e.g., 808080, leave empty for none) ) PORT_FORWARDS

    IMG_FILE=$VM_DIR$VM_NAME.img
    SEED_FILE=$VM_DIR$VM_NAME-seed.iso
    CREATED=$(date '+%Y-%m-%d %H%M%S')

    echo 
    # Download and setup VM image
    setup_vm_image
    
    # Save configuration
    save_vm_config
    
    echo 
    print_status SUCCESS VM '$VM_NAME' created successfully!
    echo 
}

# Function to setup VM image
setup_vm_image() {
    print_status PROCESS Downloading and preparing VM image...
    echo 
    
    # Create VM directory if it doesn't exist
    mkdir -p $VM_DIR
    
    # Check if image already exists
    if [[ -f $IMG_FILE ]]; then
        print_status INFO Image file already exists. Skipping download.
    else
        print_status INFO Downloading image from cloud...
        if ! wget --progress=barforce $IMG_URL -O $IMG_FILE.tmp; then
            print_status ERROR Failed to download image from $IMG_URL
            exit 1
        fi
        mv $IMG_FILE.tmp $IMG_FILE
        print_status SUCCESS Image downloaded successfully
    fi
    
    # Resize the disk image if needed
    print_status PROCESS Configuring disk size to $DISK_SIZE...
    if ! qemu-img resize $IMG_FILE $DISK_SIZE 2devnull; then
        print_status WARN Failed to resize disk image. Creating new image...
        rm -f $IMG_FILE
        qemu-img create -f qcow2 -F qcow2 -b $IMG_FILE $IMG_FILE.tmp $DISK_SIZE 2devnull  
        qemu-img create -f qcow2 $IMG_FILE $DISK_SIZE
        if [ -f $IMG_FILE.tmp ]; then
            mv $IMG_FILE.tmp $IMG_FILE
        fi
    fi

    # cloud-init configuration
    print_status PROCESS Generating cloud-init configuration...
    cat  user-data EOF
#cloud-config
hostname $HOSTNAME
ssh_pwauth true
disable_root false
users
  - name $USERNAME
    sudo ALL=(ALL) NOPASSWDALL
    shell binbash
    password $(openssl passwd -6 $PASSWORD  tr -d 'n')
chpasswd
  list 
    root$PASSWORD
    $USERNAME$PASSWORD
  expire false
EOF

    cat  meta-data EOF
instance-id iid-$VM_NAME
local-hostname $HOSTNAME
EOF

    if ! cloud-localds $SEED_FILE user-data meta-data; then
        print_status ERROR Failed to create cloud-init seed image
        exit 1
    fi
    
    print_status SUCCESS VM image configured successfully
    echo 
    print_status INFO Login credentials → Username $USERNAME  Password $PASSWORD
    print_status INFO SSH access → ssh -p $SSH_PORT $USERNAME@localhost
}

# Function to start a VM
start_vm() {
    local v