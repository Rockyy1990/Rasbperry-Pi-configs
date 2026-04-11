#!/bin/bash

################################################################################
# APT Management Tool
# Interaktives Menü für Paketmanagement und Systemverwaltung
# Version: 1.1
################################################################################

# Farben definieren
readonly COLOR_ORANGE='\033[38;5;214m'
readonly COLOR_RED='\033[0;31m'
readonly COLOR_GREEN='\033[0;32m'
readonly COLOR_YELLOW='\033[1;33m'
readonly COLOR_BLUE='\033[0;34m'
readonly COLOR_CYAN='\033[0;36m'
readonly COLOR_RESET='\033[0m'
readonly COLOR_BOLD='\033[1m'

# Variablen
LOG_FILE="/tmp/apt_manager.log"
readonly MAX_LOG_SIZE=5242880  # 5 MB

################################################################################
# Hilfsfunktionen
################################################################################

# Fehler beenden
die() {
    echo -e "${COLOR_RED}[✗ FEHLER]${COLOR_RESET} $*" >&2
    exit 1
}

# Erfolgsmeldung
success() {
    echo -e "${COLOR_GREEN}[✓ OK]${COLOR_RESET} $*"
}

# Infomeldung
info() {
    echo -e "${COLOR_CYAN}[ℹ INFO]${COLOR_RESET} $*"
}

# Warnmeldung
warning() {
    echo -e "${COLOR_YELLOW}[⚠ WARNUNG]${COLOR_RESET} $*"
}

# Log-Rotation
rotate_log() {
    if [[ -f "$LOG_FILE" ]] && (( $(stat -c%s "$LOG_FILE" 2>/dev/null || echo 0) > MAX_LOG_SIZE )); then
        mv "$LOG_FILE" "${LOG_FILE}.old"
        info "Log-Datei rotiert"
    fi
}

# Header anzeigen
show_header() {
    clear
    echo -e "${COLOR_ORANGE}${COLOR_BOLD}"
    echo "════════════════════════════════════════════════════════════"
    echo "                    APT VERWALTUNG"
    echo "════════════════════════════════════════════════════════════"
    echo -e "${COLOR_RESET}"
}

# Menü anzeigen
show_menu() {
    show_header
    echo -e "${COLOR_ORANGE}${COLOR_BOLD}SYSTEMVERWALTUNG${COLOR_RESET}"
    echo " 1. apt update"
    echo " 2. apt upgrade -y"
    echo " 3. apt dist-upgrade -y"
    echo " 4. apt autoremove -y"
    echo " 5. apt autoclean"
    echo ""
    echo -e "${COLOR_ORANGE}${COLOR_BOLD}PAKETVERWALTUNG${COLOR_RESET}"
    echo " 6. apt install"
    echo " 7. apt remove"
    echo " 8. apt search"
    echo ""
    echo -e "${COLOR_ORANGE}${COLOR_BOLD}KONFIGURATION${COLOR_RESET}"
    echo " 9. apt config (nano)"
    echo "10. apt sources (nano)"
    echo "11. Defekte Pakete reparieren"
    echo ""
    echo -e "${COLOR_ORANGE}${COLOR_BOLD}SYSTEM${COLOR_RESET}"
    echo "12. Systeminformationen"
    echo "13. System neustarten"
    echo "14. Beenden"
    echo ""
    echo "════════════════════════════════════════════════════════════"
}

# Passwort-Check (sudo Zugriff)
check_sudo() {
    if ! sudo -n true 2>/dev/null; then
        echo -e "${COLOR_YELLOW}Bitte geben Sie Ihr Passwort ein:${COLOR_RESET}"
        sudo -v || die "Passwort ungültig oder sudo nicht verfügbar!"
    fi
}

# Bestätigung verlangen
confirm() {
    local prompt="$1"
    local response
    echo -ne "${COLOR_YELLOW}${prompt}${COLOR_RESET} [j/N]: "
    read -r response
    [[ "$response" =~ ^[jJ]$ ]]
}

# Pause mit Aufforderung
pause_menu() {
    echo ""
    echo -ne "${COLOR_CYAN}Drücke ENTER zum Fortfahren...${COLOR_RESET}"
    read -r
}

################################################################################
# APT Funktionen
################################################################################

# 1. APT Update
apt_update() {
    show_header
    info "Starte apt update..."
    sudo apt update 2>&1 | tee -a "$LOG_FILE"
    if [[ ${PIPESTATUS[0]} -eq 0 ]]; then
        success "apt update abgeschlossen"
    else
        warning "apt update mit Warnungen abgeschlossen"
    fi
    pause_menu
}

# 2. APT Upgrade
apt_upgrade() {
    show_header
    if confirm "Möchtest du ein apt upgrade durchführen?"; then
        info "Starte apt upgrade..."
        sudo apt upgrade -y 2>&1 | tee -a "$LOG_FILE"
        if [[ ${PIPESTATUS[0]} -eq 0 ]]; then
            success "apt upgrade abgeschlossen"
        else
            warning "apt upgrade mit Fehlern abgeschlossen"
        fi
    else
        warning "Vorgang abgebrochen"
    fi
    pause_menu
}

# 3. APT Dist-Upgrade
apt_dist_upgrade() {
    show_header
    warning "Dist-Upgrade kann Pakete ändern/entfernen!"
    if confirm "Möchtest du ein apt dist-upgrade durchführen?"; then
        info "Starte apt dist-upgrade..."
        sudo apt dist-upgrade -y 2>&1 | tee -a "$LOG_FILE"
        if [[ ${PIPESTATUS[0]} -eq 0 ]]; then
            success "apt dist-upgrade abgeschlossen"
        else
            warning "apt dist-upgrade mit Fehlern abgeschlossen"
        fi
    else
        warning "Vorgang abgebrochen"
    fi
    pause_menu
}

# 4. APT Autoremove
apt_autoremove() {
    show_header
    info "Starte apt autoremove..."
    sudo apt autoremove -y 2>&1 | tee -a "$LOG_FILE"
    if [[ ${PIPESTATUS[0]} -eq 0 ]]; then
        success "apt autoremove abgeschlossen"
    else
        warning "apt autoremove mit Meldungen abgeschlossen"
    fi
    pause_menu
}

# 5. APT Autoclean
apt_autoclean() {
    show_header
    info "Starte apt autoclean..."
    sudo apt autoclean 2>&1 | tee -a "$LOG_FILE"
    if [[ ${PIPESTATUS[0]} -eq 0 ]]; then
        success "apt autoclean abgeschlossen"
    else
        warning "apt autoclean mit Meldungen abgeschlossen"
    fi
    pause_menu
}

# 6. APT Install
apt_install() {
    show_header
    echo -ne "${COLOR_CYAN}Paketname eingeben (durch Leerzeichen getrennt): ${COLOR_RESET}"
    local input
    read -r input

    if [[ -z "$input" ]]; then
        warning "Keine Pakete eingegeben"
        pause_menu
        return
    fi

    local -a packages
    read -ra packages <<< "$input"

    if confirm "Möchtest du folgende Pakete installieren: ${packages[*]}?"; then
        info "Starte Installation..."
        sudo apt install -y "${packages[@]}" 2>&1 | tee -a "$LOG_FILE"
        if [[ ${PIPESTATUS[0]} -eq 0 ]]; then
            success "Installation abgeschlossen"
        else
            warning "Installation mit Fehlern abgeschlossen"
        fi
    else
        warning "Installation abgebrochen"
    fi
    pause_menu
}

# 7. APT Remove
apt_remove() {
    show_header
    echo -ne "${COLOR_CYAN}Paketname eingeben (durch Leerzeichen getrennt): ${COLOR_RESET}"
    local input
    read -r input

    if [[ -z "$input" ]]; then
        warning "Keine Pakete eingegeben"
        pause_menu
        return
    fi

    local -a packages
    read -ra packages <<< "$input"

    warning "Entfernen von Paketen kann Abhängigkeiten beeinflussen!"
    if confirm "Möchtest du folgende Pakete entfernen: ${packages[*]}?"; then
        info "Starte Entfernung..."
        sudo apt remove -y "${packages[@]}" 2>&1 | tee -a "$LOG_FILE"
        if [[ ${PIPESTATUS[0]} -eq 0 ]]; then
            success "Entfernung abgeschlossen"
        else
            warning "Entfernung mit Fehlern abgeschlossen"
        fi
    else
        warning "Entfernung abgebrochen"
    fi
    pause_menu
}

# 8. APT Search
apt_search() {
    show_header
    echo -ne "${COLOR_CYAN}Suchbegriff eingeben: ${COLOR_RESET}"
    local search_term
    read -r search_term

    if [[ -z "$search_term" ]]; then
        warning "Kein Suchbegriff eingegeben"
        pause_menu
        return
    fi

    info "Suche nach: $search_term"
    echo ""

    apt search "$search_term" 2>/dev/null | while IFS= read -r line; do
        if [[ "$line" == *"/"* ]]; then
            echo -e "${COLOR_GREEN}${line}${COLOR_RESET}"
        else
            echo "$line"
        fi
    done

    echo ""
    success "Suche abgeschlossen"
    pause_menu
}

# 9. APT Config (Nano)
apt_config() {
    show_header
    local config_file="/etc/apt/apt.conf.d/99custom"
    info "Öffne apt.conf mit nano..."
    echo ""

    if [[ ! -f "$config_file" ]]; then
        warning "Datei existiert nicht, erstelle neue Datei: $config_file"
    fi

    sudo nano "$config_file"
    success "apt.conf bearbeitet"
    pause_menu
}

# 10. APT Sources (Nano)
apt_sources() {
    show_header
    info "Öffne Paketquellen mit nano..."
    echo ""
    warning "Vorsicht: Falsche Einstellungen können apt beschädigen!"

    # Moderne Systeme nutzen sources.list.d/
    if [[ -d /etc/apt/sources.list.d/ ]] && ls /etc/apt/sources.list.d/*.list &>/dev/null; then
        info "Verfügbare Dateien in sources.list.d/:"
        ls -1 /etc/apt/sources.list.d/*.list 2>/dev/null
        echo ""
        echo -ne "${COLOR_CYAN}Datei auswählen (leer = sources.list): ${COLOR_RESET}"
        local chosen
        read -r chosen
        if [[ -n "$chosen" && -f "$chosen" ]]; then
            sudo nano "$chosen"
        else
            sudo nano /etc/apt/sources.list
        fi
    else
        sudo nano /etc/apt/sources.list
    fi

    success "Paketquellen bearbeitet"
    pause_menu
}

# 11. Defekte Pakete reparieren
repair_packages() {
    show_header
    info "Repariere defekte Paketabhängigkeiten..."
    echo ""

    info "Führe apt --fix-broken install aus..."
    sudo apt --fix-broken install -y 2>&1 | tee -a "$LOG_FILE"

    if [[ ${PIPESTATUS[0]} -eq 0 ]]; then
        success "Paketabhängigkeiten repariert"
    else
        warning "Reparatur mit Problemen abgeschlossen"
        echo ""
        info "Versuche dpkg --configure -a..."
        sudo dpkg --configure -a 2>&1 | tee -a "$LOG_FILE"
    fi
    pause_menu
}

# 12. Systeminformationen
show_system_info() {
    show_header
    echo -e "${COLOR_BLUE}${COLOR_BOLD}SYSTEMINFORMATIONEN${COLOR_RESET}"
    echo "════════════════════════════════════════════════════════════"

    echo -e "\n${COLOR_CYAN}Kernel:${COLOR_RESET}"
    uname -a

    echo -e "\n${COLOR_CYAN}CPU:${COLOR_RESET}"
    lscpu | grep -E "Model name|CPU\(s\)|Cores|Threads"

    echo -e "\n${COLOR_CYAN}GPU:${COLOR_RESET}"
    if command -v lspci &>/dev/null; then
        lspci | grep -E "VGA|3D"
    else
        echo "lspci nicht installiert"
    fi

    echo -e "\n${COLOR_CYAN}RAM:${COLOR_RESET}"
    free -h | head -2

    echo -e "\n${COLOR_CYAN}Festplatten:${COLOR_RESET}"
    df -h --total 2>/dev/null | grep -E "^/dev|^Gesamt|^total"

    echo -e "\n${COLOR_CYAN}Aktive Dienste (Top 15):${COLOR_RESET}"
    systemctl list-units --type=service --state=running --no-pager | head -17

    echo ""
    echo "════════════════════════════════════════════════════════════"
    pause_menu
}

# 13. System neustarten
system_reboot() {
    show_header
    warning "Das System wird neu gestartet!"

    if confirm "Möchtest du das System wirklich neu starten?"; then
        echo ""
        echo -e "${COLOR_YELLOW}System wird in 10 Sekunden neu gestartet...${COLOR_RESET}"
        for i in {10..1}; do
            echo -ne "\r${COLOR_RED}${i}${COLOR_RESET} "
            sleep 1
        done
        echo ""
        sudo reboot
    else
        warning "Neustart abgebrochen"
        pause_menu
    fi
}

# 14. Beenden
exit_script() {
    show_header
    echo -e "${COLOR_GREEN}Auf Wiedersehen!${COLOR_RESET}"
    echo ""
    exit 0
}

################################################################################
# Hauptprogramm
################################################################################

main() {
    rotate_log
    check_sudo

    while true; do
        show_menu
        echo -ne "${COLOR_ORANGE}Wähle eine Option (1-14): ${COLOR_RESET}"
        read -r choice

        case "$choice" in
            1)  apt_update ;;
            2)  apt_upgrade ;;
            3)  apt_dist_upgrade ;;
            4)  apt_autoremove ;;
            5)  apt_autoclean ;;
            6)  apt_install ;;
            7)  apt_remove ;;
            8)  apt_search ;;
            9)  apt_config ;;
            10) apt_sources ;;
            11) repair_packages ;;
            12) show_system_info ;;
            13) system_reboot ;;
            14) exit_script ;;
            *)  warning "Ungültige Eingabe: $choice" && sleep 1 ;;
        esac
    done
}

main "$@"
