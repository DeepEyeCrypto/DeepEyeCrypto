#!/bin/bash

# ┌───────────────────────────────────┐
# │        Auto Theme Installer       │
# │  macOS-like Themes for Linux DEs  │
# │      With Symbolic Link Setup     │
# └───────────────────────────────────┘

# Configuration
BASE_URL="https://raw.githubusercontent.com/sabamdarif/termux-desktop/setup-files/setup-files"
CUSTOM_CONFIG_DIR="$HOME/dotfiles"  # Your custom configs location
TEMP_DIR="/tmp/auto-theme-installer"
LOG_FILE="$HOME/theme_install.log"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Dependencies
REQUIRED_PKGS=("wget" "tar" "git" "fc-cache" "gtk-update-icon-cache")

# ┌───────────────────────────────────┐
# │          Core Functions           │
# └───────────────────────────────────┘

init_environment() {
    mkdir -p "$TEMP_DIR"
    echo -e "${BLUE}[INFO]${NC} Initializing installation..." | tee -a "$LOG_FILE"
    
    # Clean previous installations
    find "$TEMP_DIR" -mindepth 1 -delete 2>/dev/null
}

detect_de() {
    local de=""
    if [ -n "$XDG_CURRENT_DESKTOP" ]; then
        de=$(echo "$XDG_CURRENT_DESKTOP" | tr '[:upper:]' '[:lower:]')
    else
        de=$(ps -e | grep -E -i "xfce|kde|gnome|mate|lxqt|openbox" | awk '{print $4}' | tr '[:upper:]' '[:lower:]' | uniq)
    fi

    case "$de" in
        *xfce*) echo "xfce" ;;
        *openbox*) echo "openbox" ;;
        *lxqt*) echo "lxqt" ;;
        *mate*) echo "mate" ;;
        *) echo "unknown" ;;
    esac
}

install_dependencies() {
    echo -e "${BLUE}[INFO]${NC} Checking dependencies..." | tee -a "$LOG_FILE"
    
    for pkg in "${REQUIRED_PKGS[@]}"; do
        if ! command -v "$pkg" &>/dev/null; then
            echo -e "${YELLOW}[WARN]${NC} Installing missing dependency: $pkg" | tee -a "$LOG_FILE"
            pkg install -y "$pkg" || {
                echo -e "${RED}[ERROR]${NC} Failed to install $pkg" | tee -a "$LOG_FILE"
                exit 1
            }
        fi
    done
}

fetch_styles() {
    local de="$1"
    echo -e "${BLUE}[INFO]${NC} Fetching available styles for $de..." | tee -a "$LOG_FILE"
    
    wget -q "$BASE_URL/${de}_styles.md" -O "$TEMP_DIR/styles.md" || {
        echo -e "${RED}[ERROR]${NC} Failed to fetch styles list" | tee -a "$LOG_FILE"
        exit 1
    }

    mapfile -t STYLES < <(grep -oP '## \K\d+\..+' "$TEMP_DIR/styles.md")
    STYLE_COUNT=${#STYLES[@]}
}

select_style() {
    echo -e "\n${GREEN}Available styles:${NC}"
    for ((i=0; i<${#STYLES[@]}; i++)); do
        echo -e "${BLUE}$((i+1)).${NC} ${STYLES[$i]}"
    done

    while true; do
        echo -ne "\n${YELLOW}Select style (1-$STYLE_COUNT): ${NC}"
        read -r choice
        if [[ "$choice" =~ ^[0-9]+$ ]] && ((choice >= 1 && choice <= STYLE_COUNT)); then
            SELECTED_STYLE="$choice"
            STYLE_NAME="${STYLES[$((choice-1))]#*. }"
            break
        else
            echo -e "${RED}Invalid selection! Try again.${NC}"
        fi
    done
}

download_assets() {
    local de="$1"
    local style="$2"
    local asset_type="$3"
    local target_dir="$4"

    echo -e "${BLUE}[INFO]${NC} Downloading $asset_type..." | tee -a "$LOG_FILE"
    wget -q "$BASE_URL/$de/look_$style/${asset_type}.tar.gz" -O "$TEMP_DIR/${asset_type}.tar.gz" || {
        echo -e "${RED}[ERROR]${NC} Failed to download $asset_type" | tee -a "$LOG_FILE"
        return 1
    }

    mkdir -p "$target_dir"
    tar -xzf "$TEMP_DIR/${asset_type}.tar.gz" -C "$target_dir" 2>/dev/null || {
        echo -e "${RED}[ERROR]${NC} Failed to extract $asset_type" | tee -a "$LOG_FILE"
        return 1
    }
}

link_configs() {
    local de="$1"
    local style="$2"
    local source_dir="$CUSTOM_CONFIG_DIR/${de}_look_${style}"
    
    echo -e "${BLUE}[INFO]${NC} Creating symbolic links..." | tee -a "$LOG_FILE"
    
    # Define config directories based on DE
    case "$de" in
        "xfce") config_dirs=(autostart xfce4 rofi) ;;
        "openbox") config_dirs=(openbox rofi) ;;
        "lxqt") config_dirs=(lxqt pcmanfm-qt) ;;
        "mate") config_dirs=(caja mate) ;;
        *) echo -e "${RED}[ERROR]${NC} Unsupported DE!" | tee -a "$LOG_FILE"; exit 1 ;;
    esac

    for dir in "${config_dirs[@]}"; do
        local target_path
        [ "$de" = "openbox" ] && target_path="$HOME/$dir" || target_path="$HOME/.config/$dir"
        
        # Backup existing config
        if [ -e "$target_path" ]; then
            mv "$target_path" "${target_path}.bak" 2>/dev/null
            echo -e "${YELLOW}[BACKUP]${NC} Created backup: ${target_path}.bak" | tee -a "$LOG_FILE"
        fi

        # Create symlink
        if [ -d "$source_dir/$dir" ]; then
            ln -sf "$source_dir/$dir" "$target_path"
            echo -e "${GREEN}[LINK]${NC} Created: $source_dir/$dir → $target_path" | tee -a "$LOG_FILE"
        else
            echo -e "${RED}[ERROR]${NC} Missing config: $source_dir/$dir" | tee -a "$LOG_FILE"
        fi
    done
}

# ┌───────────────────────────────────┐
# │         Main Execution           │
# └───────────────────────────────────┘

main() {
    init_environment
    
    # Detect Desktop Environment
    DE_NAME=$(detect_de)
    [ "$DE_NAME" = "unknown" ] && {
        echo -e "${RED}[ERROR]${NC} Could not detect desktop environment!" | tee -a "$LOG_FILE"
        exit 1
    }
    echo -e "${GREEN}[STATUS]${NC} Detected DE: $DE_NAME" | tee -a "$LOG_FILE"

    install_dependencies
    fetch_styles "$DE_NAME"
    select_style

    echo -e "\n${BLUE}───────────────────────────────${NC}"
    echo -e "${GREEN}Starting installation for:${NC}"
    echo -e " • Desktop: ${BLUE}$DE_NAME${NC}"
    echo -e " • Style: ${BLUE}$SELECTED_STYLE. $STYLE_NAME${NC}"
    echo -e "${BLUE}───────────────────────────────${NC}\n"

    # Download core assets
    declare -A ASSETS=(
        ["font"]="$HOME/.fonts"
        ["icon"]="$HOME/.icons"
        ["theme"]="$HOME/.themes"
        ["wallpaper"]="/usr/share/backgrounds"
    )

    for asset in "${!ASSETS[@]}"; do
        download_assets "$DE_NAME" "$SELECTED_STYLE" "$asset" "${ASSETS[$asset]}" || {
            echo -e "${RED}[ERROR]${NC} Aborting installation!" | tee -a "$LOG_FILE"
            exit 1
        }
    done

    # Symbolic link configuration
    link_configs "$DE_NAME" "$SELECTED_STYLE"

    # Post-installation
    echo -e "\n${GREEN}[SUCCESS]${NC} Installation completed!" | tee -a "$LOG_FILE"
    echo -e " • View full log: ${BLUE}$LOG_FILE${NC}"
    echo -e " • Restart your desktop environment to apply changes\n"

    # Cleanup
    rm -rf "$TEMP_DIR"
}

# Start main process
main
