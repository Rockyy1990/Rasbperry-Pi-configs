#!/usr/bin/env bash
# dateimanager.sh – CLI-Dateimanager für Raspberry Pi 5 Server
# Version: 2.0 | Datum: 2026-03-29

# ─── Farben ───────────────────────────────────────────────────────────────────
ORANGE="\e[38;5;208m"
BOLD="\e[1m"
RESET="\e[0m"
RED="\e[31m"
GREEN="\e[32m"
CYAN="\e[36m"
YELLOW="\e[33m"
DIM="\e[2m"

# ─── Zustand ──────────────────────────────────────────────────────────────────
CWD="$HOME"
USE_SUDO=false

# ─── Hilfsfunktionen ─────────────────────────────────────────────────────────

err()  { echo -e "\n${RED}✗ Fehler:${RESET} $*"; }
info() { echo -e "${GREEN}✔ $*${RESET}"; }
warn() { echo -e "${YELLOW}⚠  $*${RESET}"; }

# Sudo-Wrapper – führt Befehl mit oder ohne sudo aus
run() {
    if [[ "$USE_SUDO" == true ]]; then
        sudo "$@"
    else
        "$@"
    fi
}

# Ja/Nein-Bestätigung, gibt 0 bei Ja zurück
confirm() {
    local resp
    read -rp "$(echo -e "${YELLOW}${1:-Fortfahren?} (j/N): ${RESET}")" resp
    [[ "$resp" =~ ^[jJyY]$ ]]
}

# Eingabe pausieren
pause() {
    echo
    read -rp "$(echo -e "${DIM}[Enter] zum Fortfahren...${RESET}")" _
}

# Pfad einlesen mit Tilde-Expansion und optionalem Standardwert
read_path() {
    local prompt="$1" default="${2:-}" input
    if [[ -n "$default" ]]; then
        read -rp "$(echo -e "${CYAN}${prompt} [${default}]: ${RESET}")" input
        input="${input:-$default}"
    else
        read -rp "$(echo -e "${CYAN}${prompt}: ${RESET}")" input
    fi
    # Tilde expandieren
    printf '%s' "${input/#\~/$HOME}"
}

# Sudo-Modus ein-/ausschalten
toggle_sudo() {
    if [[ "$USE_SUDO" == true ]]; then
        USE_SUDO=false
        info "Sudo-Modus deaktiviert."
    else
        if sudo -v 2>/dev/null; then
            USE_SUDO=true
            info "Sudo-Modus aktiviert."
        else
            err "Sudo-Rechte nicht verfügbar oder Authentifizierung fehlgeschlagen."
        fi
    fi
}

# Sicherstellen, dass übergeordnetes Verzeichnis existiert
ensure_parent_dir() {
    local path="$1"
    local dir
    dir="$(dirname -- "$path")"
    if [[ ! -d "$dir" ]]; then
        confirm "Verzeichnis '$dir' existiert nicht. Anlegen?" || { info "Abgebrochen."; return 1; }
        run mkdir -p -- "$dir" || { err "Konnte Verzeichnis nicht anlegen."; return 1; }
    fi
}

# ─── Datei-/Verzeichnis-Operationen ──────────────────────────────────────────

list_directory() {
    local dir
    dir="$(read_path "Verzeichnis anzeigen" "$CWD")"
    [[ -z "$dir" ]] && { err "Kein Pfad angegeben."; return; }
    if ! run test -d "$dir" 2>/dev/null; then err "Kein Verzeichnis: $dir"; return; fi
    echo
    echo -e "${ORANGE}${BOLD}Inhalt von: ${dir}${RESET}"
    echo -e "${DIM}$(printf '─%.0s' {1..52})${RESET}"
    ls -lhA --color=always --group-directories-first -- "$dir" 2>/dev/null \
        || run ls -lhA -- "$dir"
    echo
    echo -e "${DIM}Speicher: $(df -h "$dir" | awk 'NR==2{printf "%s von %s belegt (%s)", $3, $2, $5}')${RESET}"
}

view_file() {
    local path
    path="$(read_path "Datei anzeigen")"
    [[ -z "$path" ]] && { err "Kein Pfad angegeben."; return; }
    if ! run test -f "$path" 2>/dev/null; then err "Datei nicht gefunden: $path"; return; fi
    echo
    echo -e "${ORANGE}${BOLD}── ${path} ──${RESET}"
    if command -v less &>/dev/null; then
        less -- "$path"
    else
        run cat -- "$path"
    fi
}

change_cwd() {
    local dir
    dir="$(read_path "Neues Arbeitsverzeichnis" "$CWD")"
    if [[ -d "$dir" ]]; then
        CWD="$dir"
        info "Arbeitsverzeichnis: $CWD"
    else
        err "Verzeichnis nicht gefunden: $dir"
    fi
}

create_directory() {
    local path
    path="$(read_path "Neues Verzeichnis (z. B. /tmp/meinordner)")"
    [[ -z "$path" ]] && { err "Kein Pfad angegeben."; return; }
    if run test -e "$path" 2>/dev/null; then err "Existiert bereits: $path"; return; fi
    if run mkdir -p -- "$path"; then
        info "Verzeichnis erstellt: $path"
    else
        err "Konnte Verzeichnis nicht erstellen."
    fi
}

create_file() {
    local path
    path="$(read_path "Pfad der neuen Datei")"
    [[ -z "$path" ]] && { err "Kein Pfad angegeben."; return; }
    ensure_parent_dir "$path" || return
    if run touch -- "$path"; then
        info "Datei erstellt: $path"
    else
        err "Konnte Datei nicht erstellen."
    fi
}

edit_file() {
    local path
    path="$(read_path "Datei bearbeiten")"
    [[ -z "$path" ]] && { err "Kein Pfad angegeben."; return; }

    if ! run test -e "$path" 2>/dev/null; then
        confirm "Datei existiert nicht. Erstellen und bearbeiten?" || { info "Abgebrochen."; return; }
        ensure_parent_dir "$path" || return
        run touch -- "$path" || { err "Konnte Datei nicht erstellen."; return; }
    fi

    local editor="${EDITOR:-nano}"
    command -v "$editor" &>/dev/null || editor="vi"
    run "$editor" -- "$path"
}

copy_item() {
    local src dst
    src="$(read_path "Quelle (Datei oder Ordner)")"
    [[ -z "$src" ]] && { err "Kein Pfad angegeben."; return; }
    if ! run test -e "$src" 2>/dev/null; then err "Quelle existiert nicht: $src"; return; fi
    dst="$(read_path "Ziel")"
    [[ -z "$dst" ]] && { err "Kein Ziel angegeben."; return; }
    if run cp -r -- "$src" "$dst"; then
        info "Kopiert: $src → $dst"
    else
        err "Kopieren fehlgeschlagen."
    fi
}

move_item() {
    local src dst
    src="$(read_path "Quelle (Datei oder Ordner)")"
    [[ -z "$src" ]] && { err "Kein Pfad angegeben."; return; }
    if ! run test -e "$src" 2>/dev/null; then err "Quelle existiert nicht: $src"; return; fi
    dst="$(read_path "Ziel / neuer Name")"
    [[ -z "$dst" ]] && { err "Kein Ziel angegeben."; return; }
    if run mv -- "$src" "$dst"; then
        info "Verschoben/Umbenannt: $src → $dst"
    else
        err "Verschieben fehlgeschlagen."
    fi
}

remove_empty_dir() {
    local path
    path="$(read_path "Leeres Verzeichnis löschen")"
    [[ -z "$path" ]] && { err "Kein Pfad angegeben."; return; }
    if ! run test -d "$path" 2>/dev/null; then err "Kein Verzeichnis gefunden: $path"; return; fi
    confirm "Verzeichnis '${path}' wirklich löschen?" || { info "Abgebrochen."; return; }
    if run rmdir -- "$path" 2>/dev/null; then
        info "Verzeichnis gelöscht: $path"
    else
        err "Nicht leer oder Fehler. Für rekursives Löschen Option 10 nutzen."
    fi
}

remove_recursive() {
    local path
    path="$(read_path "Datei/Ordner rekursiv löschen")"
    [[ -z "$path" ]] && { err "Kein Pfad angegeben."; return; }
    if ! run test -e "$path" 2>/dev/null; then err "Existiert nicht: $path"; return; fi
    warn "Rekursives Löschen kann NICHT rückgängig gemacht werden!"
    confirm "Wirklich unwiderruflich löschen: '${path}'?" || { info "Abgebrochen."; return; }
    if run rm -rf -- "$path"; then
        info "Gelöscht: $path"
    else
        err "Löschen fehlgeschlagen."
    fi
}

show_info() {
    local path
    path="$(read_path "Datei/Ordner info" "$CWD")"
    [[ -z "$path" ]] && { err "Kein Pfad angegeben."; return; }
    if ! run test -e "$path" 2>/dev/null; then err "Existiert nicht: $path"; return; fi
    echo
    echo -e "${ORANGE}${BOLD}── Datei-Info ──────────────────────────────${RESET}"
    run stat -- "$path"
    echo
    if run test -d "$path" 2>/dev/null; then
        echo -e "${DIM}Gesamtgröße: $(du -sh -- "$path" 2>/dev/null | cut -f1)${RESET}"
    fi
}

change_permissions() {
    local path perms
    path="$(read_path "Pfad für Rechtevergabe")"
    [[ -z "$path" ]] && { err "Kein Pfad angegeben."; return; }
    if ! run test -e "$path" 2>/dev/null; then err "Existiert nicht: $path"; return; fi
    echo -e "${DIM}Aktuelle Rechte: $(stat -c '%A  %U:%G' -- "$path" 2>/dev/null)${RESET}"
    read -rp "$(echo -e "${CYAN}Neue Rechte (z. B. 755 oder u+x): ${RESET}")" perms
    [[ -z "$perms" ]] && { err "Keine Angabe gemacht."; return; }
    if run chmod "$perms" -- "$path"; then
        info "Rechte gesetzt ($perms): $path"
        echo -e "${DIM}Neue Rechte: $(stat -c '%A  %U:%G' -- "$path" 2>/dev/null)${RESET}"
    else
        err "Rechte konnten nicht gesetzt werden."
    fi
}

search_files() {
    local dir pattern
    dir="$(read_path "Suche in Verzeichnis" "$CWD")"
    [[ -z "$dir" ]] && { err "Kein Pfad angegeben."; return; }
    if ! run test -d "$dir" 2>/dev/null; then err "Kein Verzeichnis: $dir"; return; fi
    read -rp "$(echo -e "${CYAN}Suchmuster (z. B. *.log, config*): ${RESET}")" pattern
    [[ -z "$pattern" ]] && { err "Kein Muster angegeben."; return; }
    echo
    echo -e "${ORANGE}${BOLD}Treffer für '${pattern}' in '${dir}':${RESET}"
    echo -e "${DIM}$(printf '─%.0s' {1..52})${RESET}"
    local results
    results="$(find "$dir" -name "$pattern" 2>/dev/null | head -50)"
    if [[ -n "$results" ]]; then
        echo "$results"
    else
        warn "Keine Treffer gefunden."
    fi
}

show_system_info() {
    echo
    echo -e "${ORANGE}${BOLD}── Speicher & Dateisysteme ─────────────────${RESET}"
    df -h --output=target,size,used,avail,pcent 2>/dev/null \
        | grep -v '^tmpfs\|^udev\|^Dateisystem' \
        | awk 'BEGIN{printf "\033[2m%-22s %6s %6s %6s %5s\033[0m\n","Einhängepunkt","Größe","Belegt","Frei","Voll"}
               {printf "%-22s %6s %6s %6s %5s\n",$1,$2,$3,$4,$5}'

    echo
    echo -e "${ORANGE}${BOLD}── Raspberry Pi 5 Systeminfo ───────────────${RESET}"
    echo -e "  ${DIM}Hostname:${RESET}   $(hostname -f 2>/dev/null || hostname)"
    echo -e "  ${DIM}Uptime:${RESET}     $(uptime -p 2>/dev/null || uptime)"
    echo -e "  ${DIM}RAM:${RESET}        $(free -h | awk '/^Mem/{printf "%s / %s genutzt", $3, $2}')"
    echo -e "  ${DIM}Swap:${RESET}       $(free -h | awk '/^Swap/{printf "%s / %s genutzt", $3, $2}')"

    # CPU-Temperatur (Raspberry Pi spezifisch)
    local temp_file="/sys/class/thermal/thermal_zone0/temp"
    if [[ -r "$temp_file" ]]; then
        local raw temp
        raw="$(< "$temp_file")"
        temp=$(( raw / 1000 ))
        local temp_color="${GREEN}"
        (( temp >= 70 )) && temp_color="${YELLOW}"
        (( temp >= 80 )) && temp_color="${RED}"
        echo -e "  ${DIM}CPU-Temp:${RESET}   ${temp_color}${temp}°C${RESET}"
    fi

    # Load Average
    echo -e "  ${DIM}Load Avg:${RESET}   $(awk '{printf "%s %s %s", $1,$2,$3}' /proc/loadavg) (1/5/15 min)"

    # Kernel
    echo -e "  ${DIM}Kernel:${RESET}     $(uname -r)"
}

# ─── Abhängigkeiten prüfen ────────────────────────────────────────────────────

check_deps() {
    local missing=()
    for cmd in stat df du find less; do
        command -v "$cmd" &>/dev/null || missing+=("$cmd")
    done
    if [[ ${#missing[@]} -gt 0 ]]; then
        warn "Fehlende Tools: ${missing[*]}"
        warn "Installation: sudo apt install ${missing[*]}"
        echo
    fi
}

# ─── Menü ─────────────────────────────────────────────────────────────────────

show_menu() {
    clear
    local sudo_label
    if [[ "$USE_SUDO" == true ]]; then
        sudo_label="${RED}${BOLD}[SUDO AN]${RESET}"
    else
        sudo_label="${DIM}[sudo aus]${RESET}"
    fi

    echo -e "${ORANGE}${BOLD}╔══════════════════════════════════════════════╗${RESET}"
    echo -e "${ORANGE}${BOLD}║      LINUX DATEIMANAGER  v2.0                ║${RESET}"
    echo -e "${ORANGE}${BOLD}║      Raspberry Pi 5 · Server Edition         ║${RESET}"
    echo -e "${ORANGE}${BOLD}╚══════════════════════════════════════════════╝${RESET}"
    echo -e "  ${DIM}Arbeitsverz.:${RESET} ${CYAN}${CWD}${RESET}"
    echo -e "  ${DIM}Sudo-Modus:${RESET}   ${sudo_label}"
    echo -e "${DIM}────────────────────────────────────────────────${RESET}"
    echo -e "  ${ORANGE} 1)${RESET}  Verzeichnis anzeigen"
    echo -e "  ${ORANGE} 2)${RESET}  Arbeitsverzeichnis wechseln"
    echo -e "${DIM}────────────────────────────────────────────────${RESET}"
    echo -e "  ${ORANGE} 3)${RESET}  Verzeichnis erstellen"
    echo -e "  ${ORANGE} 4)${RESET}  Datei erstellen"
    echo -e "  ${ORANGE} 5)${RESET}  Datei erstellen und sofort bearbeiten"
    echo -e "  ${ORANGE} 6)${RESET}  Datei anzeigen (less/cat)"
    echo -e "  ${ORANGE} 7)${RESET}  Datei bearbeiten (${EDITOR:-nano})"
    echo -e "  ${ORANGE} 8)${RESET}  Datei/Ordner kopieren"
    echo -e "  ${ORANGE} 9)${RESET}  Datei/Ordner verschieben / umbenennen"
    echo -e "${DIM}────────────────────────────────────────────────${RESET}"
    echo -e "  ${ORANGE}10)${RESET}  (Leeres) Verzeichnis löschen"
    echo -e "  ${ORANGE}11)${RESET}  Datei/Ordner rekursiv löschen"
    echo -e "${DIM}────────────────────────────────────────────────${RESET}"
    echo -e "  ${ORANGE}12)${RESET}  Datei-Info anzeigen (stat)"
    echo -e "  ${ORANGE}13)${RESET}  Rechte ändern (chmod)"
    echo -e "  ${ORANGE}14)${RESET}  Dateien suchen (find)"
    echo -e "  ${ORANGE}15)${RESET}  Speicher & Systeminfo"
    echo -e "${DIM}────────────────────────────────────────────────${RESET}"
    echo -e "  ${ORANGE}16)${RESET}  Sudo-Modus umschalten"
    echo -e "  ${ORANGE} 0)${RESET}  Beenden"
    echo -e "${DIM}────────────────────────────────────────────────${RESET}"
}

# ─── Hauptschleife ────────────────────────────────────────────────────────────

check_deps

while true; do
    show_menu
    read -rp "$(echo -e "${ORANGE}${BOLD}Auswahl [0-16]: ${RESET}")" choice
    echo
    case "$choice" in
        1)  list_directory;      pause ;;
        2)  change_cwd;          pause ;;
        3)  create_directory;    pause ;;
        4)  create_file;         pause ;;
        5)  edit_file;           pause ;;  # erstellt automatisch, falls nicht vorhanden
        6)  view_file;           pause ;;
        7)  edit_file;           pause ;;
        8)  copy_item;           pause ;;
        9)  move_item;           pause ;;
        10) remove_empty_dir;    pause ;;
        11) remove_recursive;    pause ;;
        12) show_info;           pause ;;
        13) change_permissions;  pause ;;
        14) search_files;        pause ;;
        15) show_system_info;    pause ;;
        16) toggle_sudo;         pause ;;
        0)  echo -e "${ORANGE}Auf Wiedersehen!${RESET}"; exit 0 ;;
        *)  err "Ungültige Auswahl: '$choice'"; pause ;;
    esac
done
