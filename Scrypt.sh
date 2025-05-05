#!/bin/bash

# ===== GLOBAL VARIABLES =====
USE_GUM=false
VERBOSE=false
BROWSER="chromium"
FULL_INSTALL=false
INSTALL_TYPE=""
XFCE_VERSION=""
BROWSER_CHOICE=""
INSTALL_THEME=false
INSTALL_ICONS=false
INSTALL_WALLPAPERS=false
INSTALL_CURSORS=false
SELECTED_THEME="WhiteSur"
SELECTED_ICON_THEME="WhiteSur"
SELECTED_WALLPAPER="Monterey.jpg"
SELECTED_THEMES=()
SELECTED_ICON_THEMES=()

# ===== ANSI COLORS =====
COLOR_BLUE='\033[38;5;33m'
COLOR_GREEN='\033[38;5;82m'
COLOR_GOLD='\033[38;5;220m'
COLOR_RED='\033[38;5;196m'
COLOR_RESET='\033[0m'

# ===== REDIRECTION HANDLING =====
[ "$VERBOSE" = false ] && REDIRECT=">/dev/null 2>&1" || REDIRECT=""

# ===== ARGUMENTS PARSING =====
while [[ $# -gt 0 ]]; do
  case "$1" in
    --gum|-g)
      USE_GUM=true
      shift
      ;;
    --verbose|-v)
      VERBOSE=true
      REDIRECT=""
      shift
      ;;
    --browser|-b)
      BROWSER="$2"
      shift 2
      ;;
    --version=*)
      INSTALL_TYPE="${1#*=}"
      shift
      ;;
    --full)
      FULL_INSTALL=true
      XFCE_VERSION="recommandée"
      BROWSER_CHOICE="chromium"
      INSTALL_THEME=true
      INSTALL_ICONS=true
      INSTALL_WALLPAPERS=true
      INSTALL_CURSORS=true
      SELECTED_THEMES=("WhiteSur")
      SELECTED_THEME="WhiteSur-Dark"
      SELECTED_ICON_THEME="WhiteSur"
      SELECTED_WALLPAPER="WhiteSur.jpg"
      shift
      ;;
    --help|-h)
      show_help
      exit 0
      ;;
    *)
      break
      ;;
  esac
done

# ===== GUM FUNCTIONS =====
gum_confirm() {
#!/bin/bash

# ===== GLOBAL VARIABLES =====
USE_GUM=false
VERBOSE=false
BROWSER="chromium"
FULL_INSTALL=false
INSTALL_TYPE=""
WALLPAPER_URL="https://raw.githubusercontent.com/vinceliuice/WhiteSur-wallpapers/main/monterey.jpg"
DEFAULT_WALLPAPER="monterey.jpg"

# ===== ANSI COLORS =====
COLOR_GREEN='\033[38;5;82m'
COLOR_GOLD='\033[38;5;220m'
COLOR_RESET='\033[0m'

# ===== REDIRECTION HANDLING =====
[ "$VERBOSE" = false ] && REDIRECT=">/dev/null 2>&1" || REDIRECT=""

# ===== ARGUMENT PARSING =====
while [[ $# -gt 0 ]]; do
  case "$1" in
    --full)
      FULL_INSTALL=true
      INSTALL_TYPE="recommandée"
      BROWSER="chromium"
      INSTALL_THEME=true
      INSTALL_ICONS=true
      INSTALL_WALLPAPERS=true
      INSTALL_CURSORS=true
      SELECTED_THEME="WhiteSur-Dark"
      SELECTED_ICON_THEME="WhiteSur-dark"
      SELECTED_WALLPAPER="$DEFAULT_WALLPAPER"
      shift
      ;;
    *)
      echo -e "${COLOR_RED}Unknown option: $1${COLOR_RESET}"
      exit 1
      ;;
  esac
done

# ===== WALLPAPER INSTALLATION =====
install_wallpaper() {
  echo -e "${COLOR_GOLD}Installing default wallpaper...${COLOR_RESET}"
  mkdir -p /data/data/com.termux/files/usr/share/backgrounds/
  wget -q "$WALLPAPER_URL" -O "/data/data/com.termux/files/usr/share/backgrounds/$DEFAULT_WALLPAPER"
}

# ===== AUTOMATED CONFIGURATION =====
configure_xfce() {
  local CONFIG_DIR="$HOME/.config/xfce4/xfconf/xfce-perchannel-xml"
  mkdir -p "$CONFIG_DIR"

  # Desktop Configuration
  cat > "$CONFIG_DIR/xfce4-desktop.xml" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<channel name="xfce4-desktop" version="1.0">
  <property name="backdrop" type="empty">
    <property name="screen0" type="empty">
      <property name="monitorHDMI-1" type="empty">
        <property name="workspace0" type="empty">
          <property name="last-image" type="string" value="/data/data/com.termux/files/usr/share/backgrounds/$DEFAULT_WALLPAPER"/>
          <property name="image-style" type="int" value="5"/>
        </property>
      </property>
    </property>
  </property>
</channel>
EOF

  # Apply all configurations
  chmod 644 "$CONFIG_DIR"/*.xml 2>/dev/null
}

# ===== FULLY AUTOMATED INSTALL =====
full_install() {
  echo -e "${COLOR_GOLD}Starting fully automated installation...${COLOR_RESET}"
  
  # Update packages
  pkg update -y $REDIRECT
  pkg install -y xfce4 xfce4-terminal $REDIRECT
  
  # Install dependencies
  pkg install -y wget unzip $REDIRECT
  
  # Install wallpaper
  install_wallpaper
  
  # Configure XFCE
  configure_xfce
  
  echo -e "${COLOR_GREEN}Automated installation completed successfully!${COLOR_RESET}"
  echo -e "Start XFCE with: ${COLOR_GOLD}startxfce4${COLOR_RESET}"
}

# ===== MAIN EXECUTION =====
if $FULL_INSTALL; then
  full_install
else
  echo -e "${COLOR_RED}Use --full for automated installation${COLOR_RESET}"
  exit 1
fi
