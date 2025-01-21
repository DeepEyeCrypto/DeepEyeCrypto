#!/data/data/com.termux/files/usr/bin/bash

#########################################################################
#
# Termux GUI Setup Script
#
#########################################################################

# Color codes for output
R="$(printf '\033[1;31m')"
G="$(printf '\033[1;32m')"
Y="$(printf '\033[1;33m')"
B="$(printf '\033[1;34m')"
C="$(printf '\033[1;36m')"
W="$(printf '\033[0m')"
BOLD="$(printf '\033[1m')"

# Constants for paths
TERMUX_DESKTOP_PATH="$PREFIX/etc/termux-desktop"
CONFIG_FILE="$TERMUX_DESKTOP_PATH/configuration.conf"
LOG_FILE="$HOME/termux-desktop.log"

# Initialize log file and start logging
function debug() {
    exec > >(tee -a "$LOG_FILE") 2>&1
}

# Print banner
function banner() {
    clear
    printf "%s############################################################\n" "$C"
    printf "%s#                                                          #\n" "$C"
    printf "%s#  ▀█▀ █▀▀ █▀█ █▀▄▀█ █ █ ▀▄▀   █▀▄ █▀▀ █▀ █▄▀ ▀█▀ █▀█ █▀█  #\n" "$C"
    printf "%s#   █  ██▄ █▀▄ █   █ █▄█ █ █   █▄▀ ██▄ ▄█ █ █  █  █▄█ █▀▀  #\n" "$C"
    printf "%s#                                                          #\n" "$C"
    printf "%s######################### Termux Gui #######################%s\n" "$C" "$W"
    echo " "
}

# Check if the script is running on Termux
function check_termux() {
    if [[ $HOME != *termux* ]]; then
        echo "${R}[${R}☓${R}]${R}${BOLD}Please run it inside termux${W}"
        exit 1
    fi
}

#########################################################################
#
# Shortcut Functions
#
#########################################################################

# Centralized logging function
function log_message() {
    local type="$1"
    shift
    local message="$@"
    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    local call_stack=""

    for ((i = 1; i < ${#FUNCNAME[@]}; i++)); do
        if [[ -n "${FUNCNAME[$i]}" ]]; then
            call_stack+="${FUNCNAME[$i]} -> "
        fi
    done

    # Remove the trailing " -> "
    call_stack="${call_stack::-4}"

    # Print the logs in a structured way
    {
        echo "========== $timestamp under ${call_stack:-main} =========="
        echo "$type: $message"
        echo "========================================"
    } >> "$LOG_FILE"
}

# Print success message
function print_success() {
    local msg="$1"
    echo "${R}[${G}✓${R}]${G} $msg${W}"
    log_message "SUCCESS" "$msg"
}

# Print failure message
function print_failed() {
    local msg="$1"
    echo "${R}[${R}☓${R}]${R} $msg${W}"
    log_message "FAILED" "$msg"
}

# Print warning message
function print_warn() {
    local msg="$1"
    echo "${R}[${Y}!${R}]${Y} $msg${W}"
    log_message "WARNING" "$msg"
}

# Wait for keypress
function wait_for_keypress() {
    read -n1 -s -r -p "${R}[${C}-${R}]${G} Press any key to continue...${W}"
    echo
}

# Check and create directory if it does not exist
function check_and_create_directory() {
    if [[ ! -d "$1" ]]; then
        mkdir -p "$1"
        log_message "INFO" "Created directory: $1"
    fi
}

# Check and delete files or directories
function check_and_delete() {
    for files_folders in "$@"; do
        for file in $files_folders; do
            if [[ -e "$file" ]]; then
                if [[ -d "$file" ]]; then
                    rm -rf "$file" >/dev/null 2>&1
                elif [[ -f "$file" ]]; then
                    rm "$file" >/dev/null 2>&1
                fi
                log_message "INFO" "Deleted: $file"
            fi
        done
    done
}

# Check and backup files or directories
function check_and_backup() {
    for files_folders in "$@"; do
        for file in $files_folders; do
            if [[ -e "$file" ]]; then
                local date_str
                date_str=$(date +"%d-%m-%Y")
                local backup="${file}-${date_str}.bak"
                if [[ -e "$backup" ]]; then
                    echo "${R}[${C}-${R}]${G} Backup file ${C}${backup} ${G}already exists${W}"
                    echo
                else
                    echo "${R}[${C}-${R}]${G} Backing up file ${C}$file${W}"
                    mv "$file" "$backup"
                    log_message "INFO" "Backup: $file to $backup"
                fi
            fi
        done
    done
}

# Download file with retry mechanism
function download_file() {
    local dest="$1"
    local url="$2"
    log_message "INFO" "Destination: $dest"
    log_message "INFO" "URL: $url"
    if [[ -z "$dest" ]]; then
        wget --tries=5 --timeout=15 --retry-connrefused "$url"
    else
        wget --tries=5 --timeout=15 --retry-connrefused -O "$dest" "$url"
    fi

    # Check if the file was downloaded successfully
    if [[ -f "$dest" || -f "$(basename "$url")" ]]; then
        print_success "Successfully downloaded the file"
    else
        print_failed "Failed to download the file, retrying..."
        if [[ -z "$dest" ]]; then
            wget --tries=5 --timeout=15 --retry-connrefused "$url"
        else
            wget --tries=5 --timeout=15 --retry-connrefused -O "$dest" "$url"
        fi

        # Final check
        if [[ -f "$dest" || -f "$(basename "$url")" ]]; then
            print_success "Successfully downloaded the file after retry"
        else
            print_failed "Failed to download the file after retry"
            exit 1
        fi
    fi
}

# Find a backup file which ends with a number pattern and restore it
function check_and_restore() {
    local target_path="$1"
    local dir
    local base_name

    dir=$(dirname "$target_path")
    base_name=$(basename "$target_path")

    local latest_backup
    latest_backup=$(find "$dir" -maxdepth 1 -type f -name "$base_name-[0-9][0-9]-[0-9][0-9]-[0-9][0-9][0-9][0-9].bak" 2>/dev/null | sort | tail -n 1)

    if [[ -z "$latest_backup" ]]; then
        print_failed "No backup file found for ${target_path}."
        echo
        return 1
    fi

    if [[ -e "$target_path" ]]; then
        print_failed "Original file or directory ${target_path} already exists."
        echo
    else
        mv "$latest_backup" "$target_path"
        print_success "Restored ${latest_backup} to ${target_path}"
        echo
    fi
    log_message "INFO" "Restored: $target_path from $latest_backup"
}

# Detect package manager
function detect_package_manager() {
    source "/data/data/com.termux/files/usr/bin/termux-setup-package-manager"
    if [[ "$TERMUX_APP_PACKAGE_MANAGER" == "apt" ]]; then
        PACKAGE_MANAGER="apt"
    elif [[ "$TERMUX_APP_PACKAGE_MANAGER" == "pacman" ]]; then
        PACKAGE_MANAGER="pacman"
    else
        print_failed "Could not detect your package manager, switching to pkg"
        PACKAGE_MANAGER="pkg"
    fi
    log_message "INFO" "Package manager: $PACKAGE_MANAGER"
}

# Install package and check if it is installed
function package_install_and_check() {
    local packs_list=("$@")
    for package_name in "${packs_list[@]}"; do
        echo "${R}[${C}-${R}]${G}${BOLD} Processing package: ${C}$package_name ${W}"

        if [[ "$PACKAGE_MANAGER" == "pacman" ]]; then
            if pacman -Qi "$package_name" >/dev/null 2>&1; then
                log_message "INFO" "$package_name already exists"
                continue
            fi

            if [[ $package_name == *"*"* ]]; then
                echo "${R}[${C}-${R}]${C} Processing wildcard pattern: $package_name ${W}"
                log_message "INFO" "Processing wildcard pattern: $package_name"
                packages=$(pacman -Ssq "${package_name%*}" 2>/dev/null)
                for pkgs in $packages; do
                    echo "${R}[${C}-${R}]${G}${BOLD} Installing matched package: ${C}$pkgs ${W}"
                    pacman -Sy --noconfirm --overwrite '*' "$pkgs"
                done
            else
                pacman -Sy --noconfirm --overwrite '*' "$package_name"
            fi

        else
            if [[ $package_name == *"*"* ]]; then
                echo "${R}[${C}-${R}]${C} Processing wildcard pattern: $package_name ${W}"
                log_message "INFO" "Processing wildcard pattern: $package_name"
                packages_by_name=$(apt-cache search "${package_name%*}" | awk '/^${package_name}/ {print $1}')
                packages_by_description=$(apt-cache search "${package_name%*}" | grep -Ei "\\b${package_name%*}\\b" | awk '{print $1}')
                packages=$(echo -e "${packages_by_name}\n${packages_by_description}" | sort -u)
                for pkgs in $packages; do
                    echo "${R}[${C}-${R}]${G}${BOLD} Installing matched package: ${C}$pkgs ${W}"
                    if dpkg -s "$pkgs" >/dev/null 2>&1; then
                        log_message "INFO" "$pkgs already exists"
                        pkg reinstall "$pkgs" -y
                    else
                        pkg install "$pkgs" -y
                    fi
                done
            else
                if dpkg -s "$package_name" >/dev/null 2>&1; then
                    log_message "INFO" "$package_name already exists"
                    pkg reinstall "$package_name" -y
                else
                    pkg install "$package_name" -y
                fi
            fi
        fi

        # Check installation success
        if [ $? -ne 0 ]; then
            echo "${R}[${C}-${R}]${G}${BOLD} Error detected during installation of: ${C}$package_name ${W}"
            log_message "ERROR" "Error detected during installation of: $package_name"
            if [[ "$PACKAGE_MANAGER" == "pacman" ]]; then
                pacman -Sy --overwrite '*' "$package_name"
                pacman -Sy --noconfirm "$package_name"
            else
                apt --fix-broken install -y
                dpkg --configure -a
                pkg install "$package_name" -y
            fi
        fi

        # Final verification
        if [[ $package_name != *"*"* ]]; then
            if [[ "$PACKAGE_MANAGER" == "pacman" ]]; then
                if pacman -Qi "$package_name" >/dev/null 2>&1; then
                    print_success "$package_name installed successfully"
                else
                    print_failed "$package_name installation failed"
                fi
            else
                if dpkg -s "$package_name" >/dev/null 2>&1; then
                    print_success "$package_name installed successfully"
                else
                    print_failed "$package_name installation failed"
                fi
            fi
        fi
    done
    echo ""
    log_message "INFO" "Package list: ${packs_list[*]}"
}

# Remove package if it is installed
function package_check_and_remove() {
    local packs_list=("$@")
    for package_name in "${packs_list[@]}"; do
        echo "${R}[${C}-${R}]${G}${BOLD} Processing package: ${C}$package_name ${W}"

        if [[ $package_name == *"*"* ]]; then
            echo "${R}[${C}-${R}]${C} Processing wildcard pattern: $package_name ${W}"
            log_message "INFO" "Processing wildcard pattern: $package_name"
            if [[ "$PACKAGE_MANAGER" == "pacman" ]]; then
                packages=$(pacman -Qq | grep -E "${package_name//\*/.*}")
            else
                packages=$(dpkg --get-selections | awk '{print $1}' | grep -E "${package_name//\*/.*}")
            fi

            for pkg in $packages; do
                echo "${R}[${C}-${R}]${G}${BOLD} Removing matched package: ${C}$pkg ${W}"
                if [[ "$PACKAGE_MANAGER" == "pacman" ]]; then
                    if pacman -Qi "$pkg" >/dev/null 2>&1; then
                        pacman -Rnds --noconfirm "$pkg"
                        if [ $? -eq 0 ]; then
                            print_success "$pkg removed successfully"
                            log_message "INFO" "Removed: $pkg"
                        else
                            print_failed "Failed to remove $pkg"
                        fi
                    fi
                else
                    if dpkg -s "$pkg" >/dev/null 2>&1; then
                        apt autoremove "$pkg" -y
                        if [ $? -eq 0 ]; then
                            print_success "$pkg removed successfully"
                            log_message "INFO" "Removed: $pkg"
                        else
                            print_failed "Failed to remove $pkg"
                        fi
                    fi
                fi
            done
        else
            if [[ "$PACKAGE_MANAGER" == "pacman" ]]; then
                if pacman -Qi "$package_name" >/dev/null 2>&1; then
                    echo "${R}[${C}-${R}]${G}${BOLD} Removing package: ${C}$package_name ${W}"
                    pacman -Rnds --noconfirm "$package_name"
                    if [ $? -eq 0 ]; then
                        print_success "$package_name removed successfully"
                        log_message "INFO" "Removed: $package_name"
                    else
                        print_failed "Failed to remove $package_name"
                    fi
                fi
            else
                if dpkg -s "$package_name" >/dev/null 2>&1; then
                    echo "${R}[${C}-${R}]${G}${BOLD} Removing package: ${C}$package_name ${W}"
                    apt autoremove "$package_name" -y
                    if [ $? -eq 0 ]; then
                        print_success "$package_name removed successfully"
                        log_message "INFO" "Removed: $package_name"
                    else
                        print_failed "Failed to remove $package_name"
                    fi
                fi
            fi
        fi
    done
    echo ""
    log_message "INFO" "Processed: $package_name"
}

# Get file name number
function get_file_name_number() {
    current_file=$(basename "$0")
    folder_name="${current_file%.sh}"
    theme_number=$(echo "$folder_name" | grep -oE '[1-9][0-9]*')
    log_message "INFO" "Theme number: $theme_number"
}

# Extract zip file with progress
function extract_zip_with_progress() {
    local archive="$1"
    local target_dir="$2"

    # Check if the archive file exists
    if [[ ! -f "$archive" ]]; then
        print_failed "$archive doesn't exist"
        return 1
    fi

    local total_files
    total_files=$(unzip -l "$archive" | grep -c -E '^\s+[0-9]+')

    if [[ "$total_files" -eq 0 ]]; then
        print_failed "No files found in the archive"
        return 1
    fi

    echo "Total files to extract: $total_files"
    local extracted_files=0
    unzip -o "$archive" -d "$target_dir" | while read -r line; do
        if [[ "$line" =~ inflating: ]]; then
            ((extracted_files++))
            progress=$((extracted_files * 100 / total_files))
            echo -ne "${G}Extracting: ${C}$progress% ($extracted_files/$total_files) \r${W}"
        fi
    done
    print_success "${archive} Extraction complete!"
}

# Extract archive based on its type
function extract_archive() {
    local archive="$1"
    if [[ ! -f "$archive" ]]; then
        print_failed "$archive doesn't exist"
        return 1
    fi

    local total_size
    total_size=$(stat -c '%s' "$archive")

    case "$archive" in
        *.tar.gz|*.tgz)
            print_success "Extracting ${C}$archive"
            pv -s "$total_size" -p -r "$archive" | tar xzf - || { print_failed "Failed to extract ${C}$archive"; return 1; }
            ;;
        *.tar.xz)
            print_success "Extracting ${C}$archive"
            pv -s "$total_size" -p -r "$archive" | tar xJf - || { print_failed "Failed to extract ${C}$archive"; return 1; }
            ;;
        *.tar.bz2|*.tbz2)
            print_success "Extracting ${C}$archive"
            pv -s "$total_size" -p -r "$archive" | tar xjf - || { print_failed "Failed to extract ${C}$archive"; return 1; }
            ;;
        *.tar)
            print_success "Extracting ${C}$archive"
            pv -s "$total_size" -p -r "$archive" | tar xf - || { print_failed "Failed to extract ${C}$archive"; return 1; }
            ;;
        *.bz2)
            print_success "Extracting ${C}$archive"
            pv -s "$total_size" -p -r "$archive" | bunzip2 > "${archive%.bz2}"
