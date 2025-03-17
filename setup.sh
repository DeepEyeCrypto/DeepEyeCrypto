#!/bin/bash

# Auto-Installer Creator Script (FIXED VERSION)
set -e

# Define script content
SCRIPT_CONTENT='#!/bin/bash

# Termux XFCE Desktop Setup Script
set -e

echo -e "\n\033[1;32mStarting system update...\033[0m"
pkg update -y && pkg upgrade -y

echo -e "\n\033[1;32mSetting up storage...\033[0m"
termux-setup-storage

echo -e "\n\033[1;32mInstalling X11 repository...\033[0m"
pkg install x11-repo -y

echo -e "\n\033[1;32mInstalling Termux-X11...\033[0m"
pkg install termux-x11-nightly -y

echo -e "\n\033[1;32mSetting up PulseAudio...\033[0m"
pkg install pulseaudio -y

echo -e "\n\033[1;32mInstalling XFCE Desktop Environment...\033[0m"
pkg install xfce4 -y

echo -e "\n\033[1;32mAdding TUR repository...\033[0m"
pkg install tur-repo -y

echo -e "\n\033[1;32mInstalling applications...\033[0m"
pkg install firefox code-oss chromium git wget -y

echo -e "\n\033[1;32mDownloading DeepEyeCrypto setup...\033[0m"
cd ~
wget -q https://github.com/DeepEyeCrypto/DeepEyeCrypto/raw/refs/heads/main/DeepEyeCrypto.sh
chmod +x DeepEyeCrypto.sh

echo -e "\n\033[1;32mInstallation complete! Starting final setup...\033[0m"
bash ~/DeepEyeCrypto.sh

echo -e "\n\033[1;32mAll tasks completed!\033[0m"

#########################################################################
#
# Theming Section
#
#########################################################################

function install_font_for_style() {
    local style_number="$1"
    echo "${R}[${C}-${R}]${G} Installing Fonts...${W}"
    check_and_create_directory "$HOME/.fonts"
    download_and_extract "https://raw.githubusercontent.com/sabamdarif/termux-desktop/refs/heads/setup-files/setup-files/$de_name/look_${style_number}/font.tar.gz" "$HOME/.fonts"
    fc-cache -f
    cd "$HOME" || return
}

function theme_installer() {
    log_info "Starting theme installation" "Theme: $style_name"
    banner
    echo "${R}[${C}-${R}]${G}${BOLD} Configuring Theme: ${C}${style_name}${W}"
    echo

    if [[ "$de_name" == "xfce" ]] || [[ "$de_name" == "openbox" ]]; then
        package_install_and_check "gnome-themes-extra gtk2-engines-murrine"
    fi

    # Install wallpapers
    banner
    echo "${R}[${C}-${R}]${G}${BOLD} Configuring Wallpapers...${W}"
    check_and_create_directory "$PREFIX/share/backgrounds"
    download_and_extract "https://raw.githubusercontent.com/sabamdarif/termux-desktop/refs/heads/setup-files/setup-files/${de_name}/look_${style_answer}/wallpaper.tar.gz" "$PREFIX/share/backgrounds/"

    # Install icons
    banner
    check_and_create_directory "$icons_folder"
    download_and_extract "https://raw.githubusercontent.com/sabamdarif/termux-desktop/refs/heads/setup-files/setup-files/${de_name}/look_${style_answer}/icon.tar.gz" "$icons_folder"

    # Create icon caches
    if [[ "$de_name" == "xfce" ]]; then
        local icons_themes_names
        icons_themes_names=$(ls "$icons_folder")
        local icons_theme
        for icons_theme in $icons_themes_names; do
            if [[ -d "$icons_folder/$icons_theme" ]]; then
                echo "${R}[${C}-${R}]${G} Creating icon cache...${W}"
                gtk-update-icon-cache -f -t "$icons_folder/$icons_theme"
            fi
        done
    fi

    # Install themes
    echo "${R}[${C}-${R}]${G}${BOLD} Installing Theme...${W}"
    check_and_create_directory "$themes_folder"
    download_and_extract "https://raw.githubusercontent.com/sabamdarif/termux-desktop/refs/heads/setup-files/setup-files/${de_name}/look_${style_answer}/theme.tar.gz" "$themes_folder"

    # Install config files
    echo "${R}[${C}-${R}]${G} Making Additional Configuration...${W}"
    check_and_create_directory "$HOME/.config"
    set_config_dir

    for the_config_dir in "${config_dirs[@]}"; do
        check_and_delete "$HOME/.config/$the_config_dir"
    done

    if [[ "$de_name" == "openbox" ]]; then
        download_and_extract "https://raw.githubusercontent.com/sabamdarif/termux-desktop/refs/heads/setup-files/setup-files/${de_name}/look_${style_answer}/config.tar.gz" "$HOME"
    else
        download_and_extract "https://raw.githubusercontent.com/sabamdarif/termux-desktop/refs/heads/setup-files/setup-files/${de_name}/look_${style_answer}/config.tar.gz" "$HOME/.config/"
    fi

    if [ $? -ne 0 ]; then
        log_error "Theme installation failed" "Theme: $style_name"
    else
        log_info "Theme installation completed successfully"
    fi
}

function questions_theme_select() {
    local owner="sabamdarif"
    local repo="termux-desktop"
    local main_folder="setup-files/$de_name"
    local branch="setup-files"

    # Style selection logic
    cd "$HOME" || return
    echo "${R}[${C}-${R}]${G} Downloading list of available styles...${W}"
    check_and_delete "${current_path}/styles.md"
    download_file "${current_path}/styles.md" "https://raw.githubusercontent.com/sabamdarif/termux-desktop/refs/heads/main/${de_name}_styles.md"

    banner

    subfolder_count_value=$(count_subfolders "$owner" "$repo" "$main_folder" "$branch" 2>/dev/null)

    if [[ -n "$subfolder_count_value" ]]; then
        echo "${R}[${C}-${R}]${G} Number of available custom styles for $de_name is: ${C}${subfolder_count_value}${W}"
        echo
        grep -oP '## \d+\..+?(?=(\n## \d+\.|\Z))' styles.md | while read -r style; do
            echo "${Y}${style#### }${W}"
        done

        while true; do
            echo
            read -r -p "${R}[${C}-${R}]${Y} Type number of the style: ${W}" style_answer
            if [[ "$style_answer" =~ ^[0-9]+$ ]] && [[ "$style_answer" -le "$subfolder_count_value" ]]; then
                style_name=$(grep -oP "^## $style_answer\..+?(?=(\n## \d+\.|\Z))" "${current_path}/styles.md" | sed -e "s/^## $style_answer\. //")
                break
            else
                print_failed "Invalid style number"
            fi
        done

        check_and_delete "${current_path}/styles.md"
    else
        print_failed "Failed to get style information"
        exit 1
    fi
}

function setup_theme() {
    if [[ ${style_answer} =~ ^[1-9][0-9]*$ ]]; then
        banner
        echo "${R}[${C}-${R}]${G}${BOLD} Installing $de_name Style: ${C}${style_answer}${W}"
        theme_installer
        additional_required_steps
    else
        print_failed "Invalid style selection"
        exit 1
    fi
}

function set_config_dir() {
    case "$de_name" in
        "xfce") config_dirs=(autostart cairo-dock eww picom dconf gtk-3.0 Mousepad pulse Thunar menu ristretto rofi xfce4) ;;
        "lxqt") config_dirs=(fontconfig gtk-3.0 lxqt pcmanfm-qt QtProject.conf glib-2.0 Kvantum openbox qterminal.org) ;;
        "openbox") config_dirs=(dconf gedit Kvantum openbox pulse rofi xfce4 enchant gtk-3.0 mimeapps.list polybar QtProject.conf Thunar) ;;
        "mate") config_dirs=(caja dconf galculator gtk-3.0 Kvantum lximage-qt menus Mousepad pavucontrol.ini xfce4) ;;
    esac
}

echo -e "\n\033[1;36mCreating installation script...\033[0m"
[ -f ~/setup.sh ] && mv ~/setup.sh ~/setup.sh.bak

cat <<EOF > ~/setup.sh
$SCRIPT_CONTENT
EOF

chmod +x ~/setup.sh

# Create shortcut
echo -e "\033[1;36mCreating shortcut...\033[0m"
mkdir -p ~/bin
ln -sf ~/setup.sh ~/bin/setup

echo -e "\n\033[1;32mAutomation setup complete!\033[0m"
echo -e "You can now run:\n\n\033[1m./setup.sh\033[0m \nor \033[1msetup\033[0m\n"

# Start confirmation
read -p "Start installation now? (y/N) " -n 1 -r
[[ $REPLY =~ ^[Yy]$ ]] && exec ~/setup.sh
