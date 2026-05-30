#!/bin/sh
# Pi-hole v6 Manager CLI Script
# POSIX-compliant with interactive menu and dynamic privilege escalation.

set -eu

# Default configurations
CONFIG_FILE="/etc/pihole-manager.conf"
LOG_FILE="/var/log/pihole-manager.log"
DRY_RUN=0
FORCE_YES=0

# Safe path extraction
SCRIPT_PATH=$(readlink -f "$0" 2>/dev/null || realpath "$0" 2>/dev/null || echo "$0")

# Load config if present
if [ -f "$CONFIG_FILE" ]; then
    # shellcheck disable=SC1090
    . "$CONFIG_FILE"
fi

# Color definitions
if [ -t 1 ]; then
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[0;33m'
    NC='\033[0m'
    BOLD='\033[1m'
else
    RED='' GREEN='' YELLOW='' NC='' BOLD=''
fi

# Logger helpers
log() {
    printf "%b[OK]%b %s\n" "$GREEN" "$NC" "$*"
    { printf "[%s] [INFO] %s\n" "$(date '+%Y-%m-%d %H:%M:%S')" "$*" >> "$LOG_FILE"; } 2>/dev/null || true
}

warn() {
    printf "%b[WARN]%b %s\n" "$YELLOW" "$NC" "$*"
    { printf "[%s] [WARN] %s\n" "$(date '+%Y-%m-%d %H:%M:%S')" "$*" >> "$LOG_FILE"; } 2>/dev/null || true
}

err() {
    printf "%b[ERROR]%b %s\n" "$RED" "$NC" "$*" >&2
    { printf "[%s] [ERROR] %s\n" "$(date '+%Y-%m-%d %H:%M:%S')" "$*" >> "$LOG_FILE"; } 2>/dev/null || true
}

# Safe command execution (no unsafe eval)
run_cmd() {
    if [ "$DRY_RUN" -eq 1 ]; then
        printf "%b[DRY-RUN]%b %s\n" "$YELLOW" "$NC" "$*"
        return 0
    fi
    "$@"
}

# Dynamic sudo runner for least privilege execution
run_root_cmd() {
    if [ "$DRY_RUN" -eq 1 ]; then
        printf "%b[DRY-RUN-ROOT]%b %s\n" "$YELLOW" "$NC" "$*"
        return 0
    fi
    if [ "$(id -u)" -eq 0 ]; then
        "$@"
    else
        if command -v sudo >/dev/null 2>&1; then
            warn "Dieses Kommando erfordert Root-Rechte. Fordere 'sudo' an..."
            sudo "$@"
        else
            err "Root-Rechte erforderlich, aber 'sudo' ist nicht installiert."
            return 1
        fi
    fi
}

# Confirmation dialog
confirm() {
    [ "$FORCE_YES" -eq 1 ] && return 0
    printf "%b[?]%b %s [j/N]: " "$YELLOW" "$NC" "$1"
    response=""
    read -r response || true
    case "$response" in
        [jJ][aA]|[jJ]|[yY][eE][sS]|[yY]) return 0 ;;
        *) return 1 ;;
    esac
}

# Verify Pi-hole v6
check_v6() {
    if ! command -v pihole >/dev/null 2>&1; then
        err "Pi-hole ist nicht auf diesem System installiert."
        return 1
    fi
    # POSIX compliant version check
    VERSION=$(pihole -v 2>/dev/null | grep -i "Core" | sed -n 's/.*\([vV]6\.[0-9]\{1,\}\).*/\1/p' || echo "")
    if [ -z "$VERSION" ]; then
        err "Pi-hole Version 6.x wird benötigt. Vorgängerversionen werden nicht unterstützt."
        return 1
    fi
    return 0
}

show_help() {
    printf "%bPi-hole v6 Manager%b\n" "$BOLD" "$NC"
    printf "Nutzung: %s [Optionen] <Kommando> [Argumente]\n\n" "$0"
    printf "Wird das Skript ohne Kommando aufgerufen, startet das interaktive Menü.\n\n"
    printf "Optionen:\n"
    printf "  --dry-run          Befehle nur anzeigen, nicht ausführen.\n"
    printf "  --yes              Automatische Bestätigung aller Abfragen.\n\n"
    printf "Kommandos:\n"
    printf "  install            Installiert Pi-hole v6 (erfordert Bestätigung)\n"
    printf "  update             Aktualisiert Pi-hole v6 Komponenten\n"
    printf "  backup <Pfad>      Erstellt ein Backup (Teleporter-Export)\n"
    printf "  restore <Pfad>     Stellt ein Backup wieder her (erfordert Bestätigung)\n"
    printf "  enable | disable   Aktiviert/Deaktiviert das Adblocking\n"
    printf "  restart            Startet den Pi-hole DNS-Server neu\n"
    printf "  status             Zeigt den aktuellen DNS-Status an\n"
    printf "  whitelist add|remove|list <Domain>\n"
    printf "  blacklist add|remove|list <Domain>\n"
    printf "  gravity update     Aktualisiert die Blocklisten\n"
    printf "  logs tail <N>      Zeigt die letzten N Zeilen des Pi-hole Logs\n"
    printf "  cron enable|disable Aktiviert/Deaktiviert tägliche Backups & Gravity-Runs\n"
    printf "  healthcheck        Führt DNS, DNSSEC und Port 53 Prüfungen durch\n"
    printf "  troubleshoot       Analysiert Dienste, RAM und Festplattenspeicher\n"
}

# --- Subcommand Actions ---

do_install() {
    if confirm "Möchten Sie Pi-hole v6 wirklich installieren?"; then
        log "Starte Pi-hole v6 Installation..."
        if ! run_root_cmd sh -c "curl -sSL https://install.pi-hole.net | bash"; then
            err "Installation fehlgeschlagen."
            return 1
        fi
        log "Installation erfolgreich abgeschlossen."
    else
        warn "Installation abgebrochen."
    fi
    return 0
}

do_update() {
    check_v6 || return 1
    log "Aktualisiere Pi-hole v6..."
    if ! run_root_cmd pihole -up; then
        err "Update fehlgeschlagen."
        return 1
    fi
    log "Update erfolgreich abgeschlossen."
    return 0
}

do_backup() {
    check_v6 || return 1
    DEST="${1:-/var/backups/pihole-teleporter.tar.gz}"
    
    # Ensure parent directory exists (requires root if protected path)
    DIR="${DEST%/*}"
    if [ -n "$DIR" ] && [ "$DIR" != "$DEST" ]; then
        if ! run_root_cmd mkdir -p "$DIR"; then
            err "Erstellung des Zielverzeichnisses fehlgeschlagen."
            return 1
        fi
    fi
    
    log "Erstelle Backup unter $DEST..."
    if ! run_root_cmd pihole teleporter -c "$DEST"; then
        err "Backup-Erstellung fehlgeschlagen."
        return 1
    fi
    log "Backup erfolgreich unter $DEST gesichert."
    return 0
}

do_restore() {
    check_v6 || return 1
    SRC="${1:-}"
    if [ -z "$SRC" ] || [ ! -f "$SRC" ]; then
        err "Gültiger Backup-Dateipfad benötigt."
        return 1
    fi
    if confirm "Möchten Sie das Backup aus $SRC wirklich wiederherstellen?"; then
        log "Stelle Backup wieder her..."
        if ! run_root_cmd pihole teleporter -r "$SRC"; then
            err "Wiederherstellung fehlgeschlagen."
            return 1
        fi
        log "Backup erfolgreich wiederhergestellt."
    else
        warn "Wiederherstellung abgebrochen."
    fi
    return 0
}

do_list_cmd() {
    check_v6 || return 1
    list_type="${1:-}"
    action="${2:-}"
    domain="${3:-}"

    case "$action" in
        add)
            [ -z "$domain" ] && { err "Domain fehlt."; return 1; }
            log "Füge $domain zu $list_type hinzu..."
            if [ "$list_type" = "blacklist" ]; then
                if ! run_root_cmd pihole deny "$domain"; then
                    err "Eintrag konnte nicht hinzugefügt werden."
                    return 1
                fi
            else
                if ! run_root_cmd pihole allow "$domain"; then
                    err "Eintrag konnte nicht hinzugefügt werden."
                    return 1
                fi
            fi
            log "Eintrag erfolgreich hinzugefügt."
            ;;
        remove)
            [ -z "$domain" ] && { err "Domain fehlt."; return 1; }
            log "Entferne $domain aus $list_type..."
            if [ "$list_type" = "blacklist" ]; then
                if ! run_root_cmd pihole deny "$domain" -d; then
                    err "Eintrag konnte nicht entfernt werden."
                    return 1
                fi
            else
                if ! run_root_cmd pihole allow "$domain" -d; then
                    err "Eintrag konnte nicht entfernt werden."
                    return 1
                fi
            fi
            log "Eintrag erfolgreich entfernt."
            ;;
        list)
            log "Liste Einträge in $list_type:"
            type_val=1
            [ "$list_type" = "whitelist" ] && type_val=0
            if ! run_root_cmd pihole-FTL sqlite3 "/etc/pihole/gravity.db" "SELECT domain FROM domainlist WHERE type = $type_val;"; then
                err "Auslesen der Datenbank fehlgeschlagen."
                return 1
            fi
            ;;
        *)
            err "Ungültige Listen-Aktion: $action (Erwartet: add, remove, list)"
            return 1
            ;;
    esac
    return 0
}

do_cron() {
    CRON_FILE="/etc/cron.d/pihole-manager"
    case "${1:-}" in
        enable)
            log "Aktiviere tägliche Cronjobs für Backup & Gravity..."
            cron_entry="30 3 * * * root \"$SCRIPT_PATH\" gravity update && \"$SCRIPT_PATH\" backup"
            if ! printf '%s\n' "$cron_entry" | run_root_cmd tee "$CRON_FILE" >/dev/null; then
                err "Schreiben der Cronjob-Datei fehlgeschlagen."
                return 1
            fi
            if ! run_root_cmd chmod 0644 "$CRON_FILE"; then
                err "Setzen der Berechtigungen fehlgeschlagen."
                return 1
            fi
            log "Cronjob erfolgreich eingerichtet."
            ;;
        disable)
            log "Deaktiviere Cronjobs..."
            if [ -f "$CRON_FILE" ]; then
                if ! run_root_cmd rm -f "$CRON_FILE"; then
                    err "Entfernen der Cronjob-Datei fehlgeschlagen."
                    return 1
                fi
                log "Cronjob erfolgreich deaktiviert."
            else
                warn "Keine Cronjobs aktiv."
            fi
            ;;
        *)
            err "Gebrauch: cron enable|disable"
            return 1
            ;;
    esac
    return 0
}

do_restart() {
    check_v6 || return 1
    log "Starte DNS-Dienst (pihole-ftl) neu..."
    if command -v systemctl >/dev/null 2>&1; then
        if ! run_root_cmd systemctl restart pihole-ftl; then
            err "Fehler beim DNS-Neustart via systemctl."
            return 1
        fi
    elif command -v service >/dev/null 2>&1; then
        if ! run_root_cmd service pihole-ftl restart; then
            err "Fehler beim DNS-Neustart via service."
            return 1
        fi
    else
        err "Kein unterstützter Init-Dienst (systemctl/service) gefunden."
        return 1
    fi
    log "DNS-Dienst erfolgreich neu gestartet."
    return 0
}

do_healthcheck() {
    check_v6 || return 1
    log "Starte System-Healthcheck..."
    
    # Check port 53 with fallback to root escalations if non-root access restricted
    port_53=""
    if command -v ss >/dev/null 2>&1; then
        port_53=$(ss -tuln 2>/dev/null | grep -E ":53 " || run_root_cmd ss -tuln 2>/dev/null | grep -E ":53 " || echo "")
    elif command -v netstat >/dev/null 2>&1; then
        port_53=$(netstat -tuln 2>/dev/null | grep -E ":53 " || run_root_cmd netstat -tuln 2>/dev/null | grep -E ":53 " || echo "")
    else
        port_53=$(cat /proc/net/tcp /proc/net/udp 2>/dev/null | grep -i " 0035 " || echo "")
    fi

    if [ -n "$port_53" ]; then
        log "Port 53 ist aktiv und lauscht."
    else
        err "Kein Dienst lauscht auf Port 53!"
    fi

    if command -v dig >/dev/null 2>&1; then
        resolved_ip=$(dig +short @127.0.0.1 google.com 2>/dev/null || echo "")
        if [ -n "$resolved_ip" ]; then
            log "Lokale DNS-Auflösung erfolgreich."
        else
            err "Lokale DNS-Auflösung failed."
        fi
        
        dnssec_res=$(dig +short +dnssec @127.0.0.1 sigok.test.dnssec.dns-oarc.net 2>/dev/null || echo "")
        if [ -n "$dnssec_res" ]; then
            log "DNSSEC Validierung funktioniert."
        else
            warn "DNSSEC Validierung unzuverlässig oder inaktiv."
        fi
    else
        ns_res=$(nslookup google.com 127.0.0.1 2>/dev/null || echo "")
        if echo "$ns_res" | grep -q "Address:"; then
            log "Lokale DNS-Auflösung erfolgreich (nslookup)."
        else
            err "Lokale DNS-Auflösung fehlgeschlagen."
        fi
    fi
    return 0
}

do_troubleshoot() {
    log "Starte Fehlerdiagnose..."
    
    if systemctl is-active --quiet pihole-ftl 2>/dev/null; then
        log "pihole-ftl Dienst läuft."
    else
        err "pihole-ftl Dienst ist inaktiv oder nicht installiert!"
    fi

    DISK_FREE=$(df -P / 2>/dev/null | awk 'NR==2 {print $4}' || echo "N/A")
    RAM_FREE=$(free -m 2>/dev/null | awk '/^Mem:/ {print $7}' || echo "")
    
    log "Freier Festplattenspeicher (/): $DISK_FREE"
    
    if [ -n "$RAM_FREE" ]; then
        log "Verfügbarer Arbeitsspeicher: ${RAM_FREE}MB"
    else
        if [ -r /proc/meminfo ]; then
            mem_avail=$(awk '/^MemAvailable:/ {print int($2/1024)}' /proc/meminfo 2>/dev/null || echo "")
            if [ -n "$mem_avail" ]; then
                log "Verfügbarer Arbeitsspeicher (meminfo): ${mem_avail}MB"
            else
                warn "Arbeitsspeicher-Check konnte nicht durchgeführt werden."
            fi
        else
            warn "Arbeitsspeicher-Check konnte nicht durchgeführt werden."
        fi
    fi
    return 0
}

# --- Interactive CLI Menu ---

wait_key() {
    printf "\n[Drücken Sie die Eingabetaste, um fortzufahren]"
    read -r _ || true
}

interactive_list_menu() {
    list_name="$1"
    while true; do
        clear
        printf "%b=== %s verwalten ===%b\n\n" "$BOLD" "$list_name" "$NC"
        printf "1) Eintrag hinzufügen\n"
        printf "2) Eintrag entfernen\n"
        printf "3) Einträge auflisten\n"
        printf "z) Zurück zum Hauptmenü\n\n"
        printf "Auswahl: "
        choice=""
        read -r choice || true
        case "$choice" in
            1)
                printf "Domain eingeben: "
                dom=""
                read -r dom || true
                if [ -n "$dom" ]; then
                    do_list_cmd "$list_name" "add" "$dom" || true
                fi
                wait_key
                ;;
            2)
                printf "Domain eingeben: "
                dom=""
                read -r dom || true
                if [ -n "$dom" ]; then
                    do_list_cmd "$list_name" "remove" "$dom" || true
                fi
                wait_key
                ;;
            3)
                do_list_cmd "$list_name" "list" "" || true
                wait_key
                ;;
            z|Z)
                break
                ;;
            *)
                warn "Ungültige Option."
                wait_key
                ;;
        esac
    done
}

interactive_menu() {
    while true; do
        clear
        printf "%b=== Pi-hole v6 Manager CLI-Menü ===%b\n\n" "$BOLD" "$NC"
        printf "1) Status & Healthcheck\n"
        printf "2) Troubleshooting (Fehlerdiagnose)\n"
        printf "3) Adblocking einschalten\n"
        printf "4) Adblocking ausschalten\n"
        printf "5) Whitelist verwalten\n"
        printf "6) Blacklist verwalten\n"
        printf "7) Gravity-Update ausführen\n"
        printf "8) Backup erstellen (Teleporter)\n"
        printf "9) Backup wiederherstellen\n"
        printf "10) DNS-Dienst neu starten\n"
        printf "11) Cronjob konfigurieren\n"
        printf "12) Pi-hole v6 aktualisieren\n"
        printf "13) Pi-hole Logs anzeigen\n"
        printf "q) Beenden\n\n"
        printf "Auswahl: "
        main_choice=""
        read -r main_choice || true
        case "$main_choice" in
            1) do_healthcheck || true; wait_key ;;
            2) do_troubleshoot || true; wait_key ;;
            3)
                if check_v6; then
                    log "Aktiviere Adblocking..."
                    run_root_cmd pihole enable || err "Fehler beim Aktivieren."
                fi
                wait_key
                ;;
            4)
                if check_v6; then
                    log "Deaktiviere Adblocking..."
                    run_root_cmd pihole disable || err "Fehler beim Deaktivieren."
                fi
                wait_key
                ;;
            5) interactive_list_menu "whitelist" ;;
            6) interactive_list_menu "blacklist" ;;
            7)
                if check_v6; then
                    log "Aktiviere Gravity Update..."
                    run_root_cmd pihole -g || err "Fehler beim Gravity-Update."
                fi
                wait_key
                ;;
            8)
                printf "Zielpfad für Backup (Leerlassen für Standard): "
                bpath=""
                read -r bpath || true
                do_backup "$bpath" || true
                wait_key
                ;;
            9)
                printf "Dateipfad zum Backup: "
                rpath=""
                read -r rpath || true
                do_restore "$rpath" || true
                wait_key
                ;;
            10)
                do_restart || true
                wait_key
                ;;
            11)
                printf "Option (enable/disable): "
                copt=""
                read -r copt || true
                if [ "$copt" = "enable" ] || [ "$copt" = "disable" ]; then
                    do_cron "$copt" || true
                else
                    warn "Ungültige Option. Nur 'enable' oder 'disable' erlaubt."
                fi
                wait_key
                ;;
            12) do_update || true; wait_key ;;
            13)
                printf "Anzahl der Zeilen (Standard: 50): "
                lines=""
                read -r lines || true
                lines="${lines:-50}"
                # Safely check if log file exists with/without sudo
                if [ -f /var/log/pihole/pihole.log ] || run_root_cmd [ -f /var/log/pihole/pihole.log ]; then
                    run_root_cmd tail -n "$lines" /var/log/pihole/pihole.log || err "Fehler beim Lesen des Logs."
                else
                    err "Log-Datei /var/log/pihole/pihole.log wurde nicht gefunden."
                fi
                wait_key
                ;;
            q|Q)
                log "Menü beendet."
                break
                ;;
            *)
                warn "Ungültige Auswahl."
                wait_key
                ;;
        esac
    done
}

# --- CLI Argument Parsing ---

while [ $# -gt 0 ]; do
    case "$1" in
        --dry-run) DRY_RUN=1; shift ;;
        --yes) FORCE_YES=1; shift ;;
        -h|--help) show_help; exit 0 ;;
        -*) err "Unbekannte Option: $1"; show_help; exit 1 ;;
        *) break ;;
    esac
done

if [ $# -eq 0 ]; then
    interactive_menu
    exit 0
fi

CMD="${1:-}"
shift

case "$CMD" in
    install) do_install || exit 1 ;;
    update) do_update || exit 1 ;;
    backup) do_backup "${1:-}" || exit 1 ;;
    restore) do_restore "${1:-}" || exit 1 ;;
    enable)
        check_v6 || exit 1
        log "Aktiviere Adblocking..."
        run_root_cmd pihole enable || { err "Fehler beim Aktivieren."; exit 1; }
        ;;
    disable)
        check_v6 || exit 1
        log "Deaktiviere Adblocking..."
        run_root_cmd pihole disable || { err "Fehler beim Deaktivieren."; exit 1; }
        ;;
    restart)
        do_restart || exit 1
        ;;
    status)
        check_v6 || exit 1
        run_cmd pihole status || { err "Fehler beim Abfragen des Status."; exit 1; }
        ;;
    gravity)
        if [ "${1:-}" = "update" ]; then
            check_v6 || exit 1
            log "Aktiviere Gravity Update..."
            run_root_cmd pihole -g || { err "Fehler beim Gravity-Update."; exit 1; }
        else
            err "Gebrauch: gravity update"
            exit 1
        fi
        ;;
    whitelist|blacklist)
        if [ $# -lt 1 ]; then
            err "Aktion fehlt (add, remove, list)."
            exit 1
        fi
        do_list_cmd "$CMD" "$1" "${2:-}" || exit 1
        ;;
    logs)
        if [ "${1:-}" = "tail" ]; then
            NUM="${2:-50}"
            log "Zeige letzte $NUM Logeinträge..."
            run_root_cmd tail -n "$NUM" /var/log/pihole/pihole.log || exit 1
        else
            err "Gebrauch: logs tail <N>"
            exit 1
        fi
        ;;
    cron)
        if [ $# -lt 1 ]; then
            err "Aktion fehlt (enable, disable)."
            exit 1
        fi
        do_cron "$1" || exit 1
        ;;
    healthcheck) do_healthcheck || exit 1 ;;
    troubleshoot) do_troubleshoot || exit 1 ;;
    *)
        err "Unbekanntes Kommando: $CMD"
        show_help
        exit 1
        ;;
esac

exit 0