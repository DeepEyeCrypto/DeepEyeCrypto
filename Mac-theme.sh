#!/bin/bash

#########################################################################
#
# Unified Theming Script with macOS Support
# Optimized for Lightweight Performance
#
#########################################################################

# Color Variables
R='\033[1;31m'
C='\033[1;36m'
Y='\033[1;33m'
G='\033[1;32m'
W='\033[1;37m'
BOLD='\033[1m'
NC='\033[0m'

# Configuration Variables
current_path=$(pwd)
icons_folder="$HOME/.icons"
themes_folder="$HOME/.themes"
de_name=""  # Will be detected/set elsewhere in main script
mac_theme=false

#########################################################################
# Core Theming Functions
#########################################################################

function install_font_for_style() {
    local style_number="$1"
    echo "${R}[${C}-${R}]${G} Installing Fonts...${W}"
    check_and_create_directory "$HOME/.fonts"
    
    if $mac_theme; then
        download_and_extract "https://github.com/supermarin/YosemiteSanFranciscoFont/archive/master.tar.gz" \
            "$HOME/.fonts" \
            --wildcards "*.ttf"
    else
        download_and_extract "https://raw.githubusercontent.com/sabamdarif/termux-desktop/setup-files/${de_name}/look_${style_number}/font.tar.gz" \
            "$HOME/.fonts"
    fi
    
    fc-cache -f >/dev/null 2>&1
}

function theme_installer() {
    log_info "Starting theme installation" "Theme: $style_name"
    banner
    
    # Lightweight dependency check
    local required_tools="curl tar"
    for tool in $required_tools; do
        if ! command -v "$tool" >/dev/null; then
            print_failed "Missing required tool: $tool"
            exit 1
        fi
    done

    if $mac_theme; then
        install_macos_specific_deps
        install_macos_theme
        configure_macos_layout
    else
        echo "${R}[${C}-${R}]${G}${BOLD} Configuring Theme: ${C}${style_name}${W}"
        [[ "$de_name" =~ ^(xfce|openbox)$ ]] && \
        package_install_and_check "gnome-themes-extra gtk2-engines-murrine"

        # Wallpaper installation with cache
        local wallpaper_dir="$PREFIX/share/backgrounds"
        check_and_create_directory "$wallpaper_dir"
        [ ! -f "$wallpaper_dir/${style_answer}_installed" ] && \
            download_and_extract "https://.../wallpaper.tar.gz" "$wallpaper_dir" && \
            touch "$wallpaper_dir/${style_answer}_installed"

        # Icon installation with checksum
        local icon_url="https://.../icon.tar.gz"
        local icon_checksum=$(curl -sL "${icon_url}.md5")
        [ "$(md5sum "$icons_folder/icon.tar.gz" 2>/dev/null)" != "$icon_checksum" ] && \
            download_and_extract "$icon_url" "$icons_folder"

        # Theme installation
        [ ! -d "$themes_folder/${style_answer}" ] && \
            download_and_extract "https://.../theme.tar.gz" "$themes_folder"
    fi

    # Common Configuration
    check_and_create_directory "$HOME/.config"
    set_config_dir

    local config_target="$HOME/.config/"
    [[ "$de_name" == "openbox" ]] && config_target="$HOME"
    
    download_and_extract "https://.../config.tar.gz" "$config_target" || \
        log_error "Config installation failed"

    log_info "Theme installation completed successfully"
}

#########################################################################
# macOS Theme Components
#########################################################################

function install_macos_specific_deps() {
    package_install_and_check "plank feh rofi picom"
    
    # macOS-like cursor
    check_and_create_directory "$HOME/.icons"
    download_and_extract "https://github.com/keeferrourke/la-capitaine-icon-theme/archive/master.tar.gz" \
        "$HOME/.icons" \
        --strip-components=1 \
        --wildcards "*/La-Capitaine/*"
}

function configure_macos_layout() {
    # macOS-style dock
    check_and_create_directory "$HOME/.config/plank"
    download_and_extract "https://raw.githubusercontent.com/sabamdarif/termux-desktop/setup-files/macOS/dock.tar.gz" \
        "$HOME/.config/plank"

    # Window controls configuration
    [[ "$de_name" == "xfce" ]] && \
        xfconf-query -c xfwm4 -p /general/button_layout -n -t string -s "CMH|"
}

function install_macos_theme() {
    # GTK Theme
    download_and_extract "https://github.com/B00merang-Project/macOS-Sierra/archive/master.tar.gz" \
        "$themes_folder" \
        --strip-components=1
        
    # Wallpapers
    download_and_extract "https://github.com/sabamdarif/macOS-backgrounds/archive/main.tar.gz" \
        "$PREFIX/share/backgrounds/macOS" \
        --strip-components=1
        
    # Theme Application
    if [[ "$de_name" == "xfce" ]]; then
        xfconf-query -c xsettings -p /Net/ThemeName -s "macOS-Sierra"
        xfconf-query -c xsettings -p /Net/IconThemeName -s "La-Capitaine"
    fi
}

#########################################################################
# Theme Selection & Configuration
#########################################################################

function questions_theme_select() {
    local owner="sabamdarif"
    local repo="termux-desktop"
    local main_folder="setup-files/$de_name"
    local branch="setup-files"

    check_and_delete "${current_path}/styles.md"
    download_file "${current_path}/styles.md" "https://.../${de_name}_styles.md"

    banner
    echo "${R}[${C}-${R}]${G} Style previews: ${C}https://github.com/sabamdarif/termux-desktop/wiki/Style-Previews${W}"
    echo "${R}[${C}-${R}]${G} Special themes:"
    echo "${Y} 99. macOS Monterey Style${W}"

    subfolder_count_value=$(count_subfolders "$owner" "$repo" "$main_folder" "$branch")

    while true; do
        read -r -t 30 -p "${R}[${C}-${R}]${Y} Style (${subfolder_count_value}/99): ${W}" style_answer || {
            echo -e "\n${R}Timeout, using default 1${W}"
            style_answer=1
            break
        }

        if [[ "$style_answer" == "99" ]]; then
            style_name="macOS Monterey"
            mac_theme=true
            break
        elif [[ "$style_answer" =~ ^[0-9]+$ ]] && [[ "$style_answer" -le "$subfolder_count_value" ]]; then
            style_name=$(grep -oP "^## $style_answer\..+?$" styles.md | sed -e "s/^## $style_answer\. //")
            break
        else
            print_failed "Invalid selection"
        fi
    done
}

function set_config_dir() {
    if $mac_theme; then
        config_dirs=("docky" "rofi" "plank")
    else
        case "$de_name" in
            "xfce")     config_dirs=(xfce4 rofi) ;;
            "lxqt")     config_dirs=(lxqt pcmanfm-qt) ;;
            "openbox") config_dirs=(openbox rofi) ;;
            "mate")     config_dirs=(caja) ;;
            *)          config_dirs=() ;;
        esac
    fi
}

#########################################################################
# Main Execution Flow
#########################################################################

function setup_theme() {
    if [[ "$style_answer" == "99" ]] || [[ ${style_answer} =~ ^[1-9][0-9]*$ ]]; then
        banner
        echo "${R}[${C}-${R}]${G}${BOLD} Installing ${mac_theme:+macOS }Style: ${C}${style_name}${W}"
        theme_installer
        additional_required_steps
    else
        print_failed "Invalid style selection"
        exit 1
    fi
}

# Helper functions (download_and_extract, check_and_create_directory, etc.)
# should be implemented here with error handling and logging
