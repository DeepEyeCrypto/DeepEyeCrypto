#!/bin/bash

#------------------------------------------------------------------------------
# GLOBAL VARIABLES
#------------------------------------------------------------------------------
# Interactive interface with gum
USE_GUM=false

# Initial configuration
EXECUTE_INITIAL_CONFIG=true

# Detailed output
VERBOSE=false

# Variables for Debian PRoot
PROOT_USERNAME=""
PROOT_PASSWORD=""

#------------------------------------------------------------------------------
# SELECTORS OF MODULES
#------------------------------------------------------------------------------
# Shell selection
SHELL_CHOICE=false

# Additional packages installation
PACKAGES_CHOICE=false

# Custom fonts installation
FONT_CHOICE=false

# XFCE environment installation
XFCE_CHOICE=false

# Debian Proot installation
PROOT_CHOICE=false

# Termux-X11 installation
X11_CHOICE=false

# Full installation without interactions
FULL_INSTALL=false

# Use gum for interactions
ONLY_GUM=true

#------------------------------------------------------------------------------
# CONFIGURATION FILES
#------------------------------------------------------------------------------
BASHRC="$HOME/.bashrc"
ZSHRC="$HOME/.zshrc"
FISHRC="$HOME/.config/fish/config.fish"

#------------------------------------------------------------------------------
# DISPLAY COLORS
#------------------------------------------------------------------------------
COLOR_BLUE='\033[38;5;33m'    # Information
COLOR_GREEN='\033[38;5;82m'   # Success
COLOR_GOLD='\033[38;5;220m'   # Warning
COLOR_RED='\033[38;5;196m'    # Error
COLOR_RESET='\033[0m'         # Reset

#------------------------------------------------------------------------------
# REDIRECTION
#------------------------------------------------------------------------------
if [ "$VERBOSE" = false ]; then
    REDIRECT="> /dev/null 2>&1"
else
    REDIRECT=""
fi

#------------------------------------------------------------------------------
# DISPLAY HELP
#------------------------------------------------------------------------------
show_help() {
    clear
    echo "OhMyTermux Help"
    echo 
    echo "Usage: $0 [OPTIONS] [username] [password]"
    echo "Options:"
    echo "  --gum | -g        Use gum for the user interface"
    echo "  --verbose | -v    Display detailed outputs"
    echo "  --shell | -sh     Install shell module"
    echo "  --package | -pk   Install packages module"
    echo "  --font | -f       Install font module"
    echo "  --xfce | -x       Install XFCE module"
    echo "  --proot | -pr     Install Debian PRoot module"
    echo "  --x11             Install Termux-X11 module"
    echo "  --skip            Skip initial configuration"
    echo "  --uninstall       Uninstall Debian Proot"
    echo "  --full            Install all modules without confirmation"
    echo "  --help | -h       Display this help message"
    echo
    echo "Examples:"
    echo "  $0 --gum                     # Interactive installation with gum"
    echo "  $0 --full user pass          # Complete installation with credentials"
}

#------------------------------------------------------------------------------
# ARGUMENTS MANAGEMENT
#------------------------------------------------------------------------------
for ARG in "$@"; do
    case $ARG in
        --gum|-g)
            USE_GUM=true
            shift
            ;;
        --shell|-sh)
            SHELL_CHOICE=true
            ONLY_GUM=false
            shift
            ;;
        --package|-pk)
            PACKAGES_CHOICE=true
            ONLY_GUM=false
            shift
            ;;
        --font|-f)
            FONT_CHOICE=true
            ONLY_GUM=false
            shift
            ;;
        --xfce|-x)
            XFCE_CHOICE=true
            ONLY_GUM=false
            shift
            ;;
        --proot|-pr)
            PROOT_CHOICE=true
            ONLY_GUM=false
            shift
            ;;
        --x11)
            X11_CHOICE=true
            ONLY_GUM=false
            shift
            ;;
        --skip)
            EXECUTE_INITIAL_CONFIG=false
            shift
            ;;
        --uninstall)
            uninstall_proot
            exit 0
            ;;
        --verbose|-v)
            VERBOSE=true
            REDIRECT=""
            shift
            ;;
        --full)
            FULL_INSTALL=true
            SHELL_CHOICE=true
            PACKAGES_CHOICE=true
            FONT_CHOICE=true
            XFCE_CHOICE=true
            PROOT_CHOICE=true
            X11_CHOICE=true
            SCRIPT_CHOICE=true
            ONLY_GUM=false
            shift
            ;;
        --help|-h)
            show_help
            exit 0
            ;;
        *)
            # Get the username and password if provided
            if [ -z "$PROOT_USERNAME" ]; then
                PROOT_USERNAME="$ARG"
                shift
            elif [ -z "$PROOT_PASSWORD" ]; then
                PROOT_PASSWORD="$ARG"
                shift
            else
                break
            fi
            ;;
    esac
done

# If in FULL_INSTALL mode and credentials are not provided, ask for them
if $FULL_INSTALL; then
    if [ -z "$PROOT_USERNAME" ]; then
        if $USE_GUM; then
            PROOT_USERNAME=$(gum input --placeholder "Enter the username for Debian PRoot")
        else
            printf "${COLOR_BLUE}Enter the username for Debian PRoot: ${COLOR_RESET}"
            read -r PROOT_USERNAME
        fi
    fi
    
    if [ -z "$PROOT_PASSWORD" ]; then
        while true; do
            if $USE_GUM; then
                PROOT_PASSWORD=$(gum input --password --prompt "Password: " --placeholder "Enter a password")
                PASSWORD_CONFIRM=$(gum input --password --prompt "Confirm password: " --placeholder "Confirm the password")
            else
                printf "${COLOR_BLUE}Enter a password: ${COLOR_RESET}"
                read -r -s PROOT_PASSWORD
                echo
                printf "${COLOR_BLUE}Confirm the password: ${COLOR_RESET}"
                read -r -s PASSWORD_CONFIRM
                echo
            fi

            if [ "$PROOT_PASSWORD" = "$PASSWORD_CONFIRM" ]; then
                break
            else
                if $USE_GUM; then
                    gum style --foreground 196 "Passwords do not match. Please try again."
                else
                    echo -e "${COLOR_RED}Passwords do not match. Please try again.${COLOR_RESET}"
                fi
            fi
        done
    fi
fi

# Activate all modules if --gum is the only argument
if $ONLY_GUM; then
    SHELL_CHOICE=true
    PACKAGES_CHOICE=true
    FONT_CHOICE=true
    XFCE_CHOICE=true
    PROOT_CHOICE=true
    X11_CHOICE=true
    SCRIPT_CHOICE=true
fi

#------------------------------------------------------------------------------
# INFORMATION MESSAGES
#------------------------------------------------------------------------------
info_msg() {
    if $USE_GUM; then
        gum style "${1//$'\n'/ }" --foreground 33
    else
        echo -e "${COLOR_BLUE}$1${COLOR_RESET}"
    fi
}

#------------------------------------------------------------------------------
# SUCCESS MESSAGES
#------------------------------------------------------------------------------
success_msg() {
    if $USE_GUM; then
        gum style "${1//$'\n'/ }" --foreground 82
    else
        echo -e "${COLOR_GREEN}$1${COLOR_RESET}"
    fi
}

#------------------------------------------------------------------------------
# ERROR MESSAGES
#------------------------------------------------------------------------------
error_msg() {
    if $USE_GUM; then
        gum style "${1//$'\n'/ }" --foreground 196
    else
        echo -e "${COLOR_RED}$1${COLOR_RESET}"
    fi
}

#------------------------------------------------------------------------------
# TITLE MESSAGES
#------------------------------------------------------------------------------
title_msg() {
    if $USE_GUM; then
        gum style "${1//$'\n'/ }" --foreground 220 --bold
    else
        echo -e "\n${COLOR_GOLD}\033[1m$1\033[0m${COLOR_RESET}"
    fi
}

#------------------------------------------------------------------------------
# SUBTITLE MESSAGES
#------------------------------------------------------------------------------
subtitle_msg() {
    if $USE_GUM; then
        gum style "${1//$'\n'/ }" --foreground 33 --bold
    else
        echo -e "\n${COLOR_BLUE}\033[1m$1\033[0m${COLOR_RESET}"
    fi
}

#------------------------------------------------------------------------------
# ERROR LOGGING
#------------------------------------------------------------------------------
log_error() {
    local ERROR_MSG="$1"
    local USERNAME=$(whoami)
    local HOSTNAME=$(hostname)
    local CWD=$(pwd)
    echo "[$(date +'%d/%m/%Y %H:%M:%S')] ERROR: $ERROR_MSG | User: $USERNAME | Machine: $HOSTNAME | Directory: $CWD" >> "$HOME/.config/OhMyTermux/install.log"
}

#------------------------------------------------------------------------------
# DYNAMIC DISPLAY OF COMMAND RESULTS
#------------------------------------------------------------------------------
execute_command() {
    local COMMAND="$1"
    local INFO_MSG="$2"
    local SUCCESS_MSG="✓ $INFO_MSG"
    local ERROR_MSG="✗ $INFO_MSG"
    local ERROR_DETAILS

    if $USE_GUM; then
        if gum spin --spinner.foreground="33" --title.foreground="33" --spinner dot --title "$INFO_MSG" -- bash -c "$COMMAND $REDIRECT"; then
            gum style "$SUCCESS_MSG" --foreground 82
        else
            ERROR_DETAILS="Command: $COMMAND, Redirect: $REDIRECT, Time: $(date +'%d/%m/%Y %H:%M:%S')"
            gum style "$ERROR_MSG" --foreground 196
            log_error "$ERROR_DETAILS"
            return 1
        fi
    else
        tput sc
        info_msg "$INFO_MSG"
        
        if eval "$COMMAND $REDIRECT"; then
            tput rc
            tput el
            success_msg "$SUCCESS_MSG"
        else
            tput rc
            tput el
            ERROR_DETAILS="Command: $COMMAND, Redirect: $REDIRECT, Time: $(date +'%d/%m/%Y %H:%M:%S')"
            error_msg "$ERROR_MSG"
            log_error "$ERROR_DETAILS"
            return 1
        fi
    fi
}

#------------------------------------------------------------------------------
# GUM CONFIRMATION
#------------------------------------------------------------------------------
gum_confirm() {
    local PROMPT="$1"
    if $FULL_INSTALL; then
        return 0 
    else
        gum confirm --affirmative "Yes" --negative "No" --prompt.foreground="33" --selected.background="33" --selected.foreground="0" "$PROMPT"
    fi
}

#------------------------------------------------------------------------------
# GUM UNIQUE SELECTION
#------------------------------------------------------------------------------
gum_choose() {
    local PROMPT="$1"
    shift
    local SELECTED=""
    local OPTIONS=()
    local HEIGHT=10

    while [[ $# -gt 0 ]]; do
        case $1 in
            --selected=*)
                SELECTED="${1#*=}"
                ;;
            --height=*)
                HEIGHT="${1#*=}"
                ;;
            *)
                OPTIONS+=("$1")
                ;;
        esac
        shift
    done

    if $FULL_INSTALL; then
        if [ -n "$SELECTED" ]; then
            echo "$SELECTED"
        else
            # Return the first option by default
            echo "${OPTIONS[0]}"
        fi
    else
        gum choose --selected.foreground="33" --header.foreground="33" --cursor.foreground="33" --height="$HEIGHT" --header="$PROMPT" --selected="$SELECTED" "${OPTIONS[@]}"
    fi
}

#------------------------------------------------------------------------------
# GUM MULTIPLE SELECTION
#------------------------------------------------------------------------------
gum_choose_multi() {
    local PROMPT="$1"
    shift
    local SELECTED=""
    local OPTIONS=()
    local HEIGHT=10

    while [[ $# -gt 0 ]]; do
        case $1 in
            --selected=*)
                SELECTED="${1#*=}"
                ;;
            --height=*)
                HEIGHT="${1#*=}"
                ;;
            *)
                OPTIONS+=("$1")
                ;;
        esac
        shift
    done

    if $FULL_INSTALL; then
        if [ -n "$SELECTED" ]; then
            echo "$SELECTED"
        else
            echo "${OPTIONS[@]}"
        fi
    else
        gum choose --no-limit --selected.foreground="33" --header.foreground="33" --cursor.foreground="33" --height="$HEIGHT" --header="$PROMPT" --selected="$SELECTED" "${OPTIONS[@]}"
    fi
}

#------------------------------------------------------------------------------
# TEXT MODE BANNER
#------------------------------------------------------------------------------
bash_banner() {
    clear
    local BANNER="
╔════════════════════════════════════════╗
║                                        ║
║                OHMYTERMUX              ║
║                                        ║
╚════════════════════════════════════════╝"

    echo -e "${COLOR_BLUE}${BANNER}${COLOR_RESET}\n"
}

#------------------------------------------------------------------------------
# GUM INSTALLATION
#------------------------------------------------------------------------------
check_and_install_gum() {
    if $USE_GUM && ! command -v gum &> /dev/null; then
        bash_banner
        echo -e "${COLOR_BLUE}Installing gum...${COLOR_RESET}"
        pkg update -y > /dev/null 2>&1 && pkg install gum -y > /dev/null 2>&1
    fi
}

check_and_install_gum

#------------------------------------------------------------------------------
# ERROR MANAGEMENT
#------------------------------------------------------------------------------
finish() {
    local RET=$?
    if [ ${RET} -ne 0 ] && [ ${RET} -ne 130 ]; then
        echo
        if $USE_GUM; then
            gum style --foreground 196 "ERROR: OhMyTermux installation failed."
        else
            echo -e "${COLOR_RED}ERROR: OhMyTermux installation failed.${COLOR_RESET}"
        fi
        echo -e "${COLOR_BLUE}Please refer to the error message(s) above.${COLOR_RESET}"
    fi
}

trap finish EXIT

#------------------------------------------------------------------------------
# GRAPHIC BANNER
#------------------------------------------------------------------------------
show_banner() {
    clear
    if $USE_GUM; then
        gum style \
            --foreground 33 \
            --border-foreground 33 \
            --border double \
            --align center \
            --width 42 \
            --margin "1 1 1 0" \
            "" "OHMYTERMUX" ""
    else
        bash_banner
    fi
}

#------------------------------------------------------------------------------
# FILE BACKUP
#------------------------------------------------------------------------------
create_backups() {
    local BACKUP_DIR="$HOME/.config/OhMyTermux/backups"
    
    # Create the backup directory
    execute_command "mkdir -p \"$BACKUP_DIR\"" "Creating backup directory"

    # List of files to backup
    local FILES_TO_BACKUP=(
        "$HOME/.bashrc"
        "$HOME/.termux/colors.properties"
        "$HOME/.termux/termux.properties"
        "$HOME/.termux/font.ttf"
    )

    # Copy files to backup directory
    for FILE in "${FILES_TO_BACKUP[@]}"; do
        if [ -f "$FILE" ]; then
            execute_command "cp \"$FILE\" \"$BACKUP_DIR/\"" "Backing up $(basename "$FILE")"
        fi
    done
}

#------------------------------------------------------------------------------
# COMMON ALIAS CONFIGURATION
#------------------------------------------------------------------------------
common_alias() {
    # Create the centralized alias file
    if [ ! -d "$HOME/.config/OhMyTermux" ]; then
        execute_command "mkdir -p \"$HOME/.config/OhMyTermux\"" "Creating configuration folder"
    fi

    ALIASES_FILE="$HOME/.config/OhMyTermux/aliases"

    cat > "$ALIASES_FILE" << 'EOL'
# Navigation
alias ..="cd .."
alias ...="cd ../.."
alias ....="cd ../../.."
alias .....="cd ../../../.."

# Basic commands
alias h="history"
alias q="exit"
alias c="clear"
alias md="mkdir"
alias rm="rm -rf"
alias s="source"
alias n="nano"
alias cm="chmod +x"

# Configuration
alias bashrc="nano $HOME/.bashrc"
alias zshrc="nano $HOME/.zshrc"
alias aliases="nano $HOME/.config/OhMyTermux/aliases"
alias help="cat $HOME/.config/OhMyTermux/help.md"

# Git
alias g="git"
alias gs="git status"
alias ga="git add"
alias gc="git commit -m"
alias gp="git push"
alias gl="git pull"
alias gd="git diff"
alias gb="git branch"
alias gco="git checkout"
alias gcl="git clone"
alias push="git pull && git add . && git commit -m 'mobile push' && git push"

# Termux
alias termux="termux-reload-settings"
alias storage="termux-setup-storage"
alias share="termux-share"
alias open="termux-open"
alias url="termux-open-url"
alias clip="termux-clipboard-set"
alias notification="termux-notification"
alias vibrate="termux-vibrate"
alias battery="termux-battery-status"
alias torch="termux-torch"
alias volume="termux-volume"
alias wifi="termux-wifi-connectioninfo"
alias tts="termux-tts-speak"
alias call="termux-telephony-call"
alias contact="termux-contact-list"
alias sms="termux-sms-send"
alias location="termux-location"

EOL

    # Add sourcing to .bashrc
    echo -e "\n# Source custom aliases\n[ -f \"$ALIASES_FILE\" ] && . \"$ALIASES_FILE\"" >> "$BASHRC"
}

#------------------------------------------------------------------------------
# DOWNLOAD AND EXECUTE FUNCTION
#------------------------------------------------------------------------------
download_and_execute() {
    local URL="$1"
    local SCRIPT_NAME=$(basename "$URL")
    local DESCRIPTION="${2:-$SCRIPT_NAME}"
    shift 2
    local EXEC_ARGS="$@"

    # Check if file exists and delete it
    [ -f "$SCRIPT_NAME" ] && rm "$SCRIPT_NAME"

    # Download with curl
    if ! curl -L -o "$SCRIPT_NAME" "$URL" 2>/dev/null; then
        error_msg "Failed to download $DESCRIPTION script"
        return 1
    fi

    # Check if file was downloaded
    if [ ! -f "$SCRIPT_NAME" ]; then
        error_msg "File $SCRIPT_NAME was not created"
        return 1
    fi

    # Make script executable
    if ! chmod +x "$SCRIPT_NAME"; then
        error_msg "Failed to make $DESCRIPTION script executable"
        return 1
    fi

    # Execute script with arguments
    if ! ./"$SCRIPT_NAME" $EXEC_ARGS; then
        error_msg "Error executing $DESCRIPTION script"
        return 1
    fi

    return 0
}

#------------------------------------------------------------------------------
# REPOSITORY CHANGE
#------------------------------------------------------------------------------
change_repo() {
    show_banner
    if $USE_GUM; then
        if gum_confirm "Change repository mirror?"; then
            termux-change-repo
        fi
    else    
        printf "${COLOR_BLUE}Change repository mirror? (Y/n): ${COLOR_RESET}"
        read -r -e -p "" -i "y" CHOICE
        [[ "$CHOICE" =~ ^[yY]$ ]] && termux-change-repo
    fi
}

#------------------------------------------------------------------------------
# STORAGE CONFIGURATION
#------------------------------------------------------------------------------
setup_storage() {
    if [ ! -d "$HOME/storage" ]; then
        show_banner
        if $USE_GUM; then
            if gum_confirm "Allow storage access?"; then
                termux-setup-storage
            fi
        else
            printf "${COLOR_BLUE}Allow storage access? (Y/n): ${COLOR_RESET}"
            read -r -e -p "" -i "n" CHOICE
            [[ "$CHOICE" =~ ^[yY]$ ]] && termux-setup-storage
        fi
    fi
}

#------------------------------------------------------------------------------
# TERMUX CONFIGURATION
#------------------------------------------------------------------------------
configure_termux() {
    title_msg "❯ Termux configuration"
    # Backup existing files
    create_backups
    TERMUX_DIR="$HOME/.termux"
    
    # Colors.properties configuration
    FILE_PATH="$TERMUX_DIR/colors.properties"
    if [ ! -f "$
