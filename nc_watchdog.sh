#!/usr/bin/env bash
# Nextcloud 443 watchdog con notificaciones Telegram y cooldown

set -Eeuo pipefail

load_environment() {
    ENV_FILE="${ENV_FILE:-.env}"
    [[ -f "$ENV_FILE" ]] && source "$ENV_FILE" || true
}

setup_variables() {
    DOMAIN="${DOMAIN}"
    WATCHDOG_DIR="${WATCHDOG_DIR:-/home/rafa/nextcloud/watchdog}"
    setup_file_paths
    setup_timing_variables
}

setup_file_paths() {
    BLOCK_FILE="${WATCHDOG_DIR}/${BLOCK_FILENAME:-block_restart.txt}"
    LOG="${WATCHDOG_DIR}/${LOG_FILENAME:-nc_watchdog.log}"
    COOLDOWN_FILE="${WATCHDOG_DIR}/${COOLDOWN_FILENAME:-nc_watchdog.cooldown}"
    STATUS_FILE="${WATCHDOG_DIR}/${STATUS_FILENAME:-nc_watchdog.status}"
}

setup_timing_variables() {
    RETRIES="${RETRIES:-3}"
    SLEEP_BETWEEN="${SLEEP_BETWEEN:-20}"
    setup_network_timeouts
    setup_telegram_config
}

setup_network_timeouts() {
    HTTPS_PORT="${HTTPS_PORT:-443}"
    EXTERNAL_CONNECT_TIMEOUT="${EXTERNAL_CONNECT_TIMEOUT:-5}"
    EXTERNAL_MAX_TIME="${EXTERNAL_MAX_TIME:-10}"
    LOCAL_CONNECT_TIMEOUT="${LOCAL_CONNECT_TIMEOUT:-3}"
}

setup_telegram_config() {
    LOCAL_MAX_TIME="${LOCAL_MAX_TIME:-6}"
    TELEGRAM_BOT_TOKEN="${TELEGRAM_BOT_TOKEN:-}"
    TELEGRAM_CHAT_ID="${TELEGRAM_CHAT_ID:-}"
    setup_system_config
}

setup_system_config() {
    REQUIRED_DEPS="${REQUIRED_DEPS:-curl ss}"
    STATUS_FAIL="${STATUS_FAIL:-FAIL}"
    STATUS_OK="${STATUS_OK:-OK}"
    STATUS_UNKNOWN="${STATUS_UNKNOWN:-UNKNOWN}"
}

setup_reboot_config() {
    REBOOT_COMMANDS="${REBOOT_COMMANDS:-systemctl reboot /sbin/reboot reboot}"
}

log() {
    echo "[$(date -Is)] $*" | tee -a "$LOG"
}

is_telegram_configured() {
    [[ -n "$TELEGRAM_BOT_TOKEN" && -n "$TELEGRAM_CHAT_ID" ]]
}

send_telegram_message() {
    local msg="$1"
    curl -sS -X POST "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage" \
        -d "chat_id=${TELEGRAM_CHAT_ID}" --data-urlencode "text=${msg}" >/dev/null
}

notify() {
    local msg="$1"
    if ! is_telegram_configured; then
        log "Telegram no configurado."
        return 0
    fi
    send_telegram_message "$msg" || log "Aviso Telegram falló."
}

have() {
    command -v "$1" >/dev/null 2>&1
}

is_port_listening() {
    ss -ltn "( sport = :${HTTPS_PORT} )" | awk 'NR>1{exit 0} END{exit 1}'
}

is_external_https_working() {
    curl -sSIk --connect-timeout "$EXTERNAL_CONNECT_TIMEOUT" \
        --max-time "$EXTERNAL_MAX_TIME" "https://${DOMAIN}" >/dev/null
}

is_local_https_working() {
    curl -sSIk --connect-timeout "$LOCAL_CONNECT_TIMEOUT" --max-time "$LOCAL_MAX_TIME" \
        --resolve "${DOMAIN}:${HTTPS_PORT}:127.0.0.1" "https://${DOMAIN}" >/dev/null
}

should_reboot_now() {
    ! is_external_https_working && ! is_local_https_working && ! is_port_listening
}

set_status() {
    echo "$1" > "$STATUS_FILE"
}

get_status() {
    [[ -f "$STATUS_FILE" ]] && cat "$STATUS_FILE" || echo "$STATUS_UNKNOWN"
}

validate_dependencies() {
    for dep in $REQUIRED_DEPS; do
        have "$dep" || { log "ERROR: falta '$dep'"; exit 1; }
    done
}

is_manually_blocked() {
    [[ -f "$BLOCK_FILE" ]]
}

handle_manual_block() {
    log "Bloqueo manual activo (${BLOCK_FILE}). No se reinicia."
    notify "⚠️ Watchdog: bloqueo manual activo. No se reinicia el host.\nHost: $(hostname)\nDominio: ${DOMAIN}"
    exit 0
}

get_cooldown_remaining() {
    local last=$(cat "$COOLDOWN_FILE" || echo 0)
    local now=$(date +%s)
    echo $((COOLDOWN_SECS - (now - last)))
}

is_in_cooldown() {
    [[ -f "$COOLDOWN_FILE" ]] && (( $(get_cooldown_remaining) > 0 ))
}

handle_cooldown() {
    local rest=$(get_cooldown_remaining)
    log "En cooldown: faltan ${rest}s para reinicio."
    notify "⏳ Watchdog en cooldown (${rest}s restantes). No se reinicia.\nHost: $(hostname)\nDominio: ${DOMAIN}"
    exit 0
}

record_cooldown() {
    date +%s > "$COOLDOWN_FILE"
}

execute_reboot() {
    for cmd in $REBOOT_COMMANDS; do
        $cmd && break
    done
}

handle_service_failure() {
    record_cooldown
    set_status "$STATUS_FAIL"
    local msg="❌ Watchdog: servicio en ${HTTPS_PORT} caído.\nAcción: REINICIO del host.\nHost: $(hostname)\nDominio: ${DOMAIN}"
    log "$msg"
    notify "$msg"
    sync || true
    execute_reboot
}

should_notify_recovery() {
    local prev="$(get_status)"
    [[ "$prev" == "$STATUS_FAIL" || "$prev" == "$STATUS_UNKNOWN" ]]
}

handle_service_recovery() {
    if should_notify_recovery; then
        notify "✅ Watchdog: servicio restaurado en ${HTTPS_PORT}.\nHost: $(hostname)\nDominio: ${DOMAIN}"
    fi
    set_status "$STATUS_OK"
}

run_monitoring_loop() {
    for i in $(seq 1 "$RETRIES"); do
        if should_reboot_now; then
            log "Intento ${i}/${RETRIES}: fallo persistente."
            (( i < RETRIES )) && { sleep "$SLEEP_BETWEEN"; continue; }
            handle_service_failure
            exit 0
        else
            log "Intento ${i}/${RETRIES}: OK."
            handle_service_recovery
            exit 0
        fi
    done
}

main() {
    load_environment
    setup_variables
    setup_reboot_config

    validate_dependencies
    is_manually_blocked && handle_manual_block
    is_in_cooldown && handle_cooldown

    run_monitoring_loop
}

main "$@"
