#!/bin/bash

# R36S Play Timer Controller
# Main Port Launcher Script
# Credits: Ümit Tunç (Software Engineer) - 2026

export TERM=linux

# Detect writable console TTY for rendering UI
if [ -w /dev/tty1 ]; then
  CONSOLE_TTY="/dev/tty1"
elif [ -w /dev/tty3 ]; then
  CONSOLE_TTY="/dev/tty3"
elif [ -w /dev/tty0 ]; then
  CONSOLE_TTY="/dev/tty0"
else
  CONSOLE_TTY="/dev/tty"
fi

PID_FILE="/tmp/play_timer.pid"
STATUS_FILE="/tmp/play_timer_status.txt"
SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)
DAEMON_PATH="$SCRIPT_DIR/play_timer/play_timer_daemon.sh"

# Check if a timer is currently active
get_remaining() {
  if [ -f "$PID_FILE" ] && kill -0 $(cat "$PID_FILE") 2>/dev/null; then
    if [ -f "$STATUS_FILE" ]; then
      cat "$STATUS_FILE"
    else
      echo "active"
    fi
  else
    # Clean up stale files
    rm -f "$PID_FILE" "$STATUS_FILE" 2>/dev/null
    echo "inactive"
  fi
}

stop_timer() {
  if [ -f "$PID_FILE" ]; then
    local pid=$(cat "$PID_FILE")
    kill -9 "$pid" 2>/dev/null
    rm -f "$PID_FILE" "$STATUS_FILE"
  fi
}

start_timer() {
  local minutes=$1
  # Stop any running timer first
  stop_timer
  # Start daemon in background
  /bin/bash "$DAEMON_PATH" "$minutes" &
}

# Get current status to pass to the python menu
REMAINING=$(get_remaining)

# Run the python menu: UI goes to CONSOLE_TTY, result comes back via stdout
CHOICE=$(python3 "$SCRIPT_DIR/play_timer/read_buttons.py" "$CONSOLE_TTY" "$REMAINING")

case "$CHOICE" in
  15|30|45|60)
    start_timer "$CHOICE"
    ;;
  "stop")
    stop_timer
    ;;
  *)
    # exit - clear screen
    printf "\033[2J\033[H" > "$CONSOLE_TTY" 2>/dev/null
    ;;
esac
