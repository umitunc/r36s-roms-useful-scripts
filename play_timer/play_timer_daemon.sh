#!/bin/bash

# R36S Play Timer Daemon
# Runs in the background and tracks the remaining play time.
# Credits: Ümit Tunç (Software Engineer) - 2026

DURATION_MINS=$1
if [ -z "$DURATION_MINS" ]; then
  echo "Usage: $0 <minutes>"
  exit 1
fi

PID_FILE="/tmp/play_timer.pid"
STATUS_FILE="/tmp/play_timer_status.txt"
echo $$ > "$PID_FILE"

# Function to configure RetroArch network commands
configure_retroarch() {
  local cfg_files=(
    "/opt/retroarch/configs/retroarch.cfg"
    "/home/ark/.config/retroarch/retroarch.cfg"
    "/opt/retroarch/retroarch.cfg"
  )
  
  for cfg in "${cfg_files[@]}"; do
    if [ -f "$cfg" ]; then
      # If setting is not present, append it. If present as false, change to true.
      if grep -q "network_cmd_enable" "$cfg"; then
        sed -i 's/network_cmd_enable = "false"/network_cmd_enable = "true"/g' "$cfg"
      else
        echo 'network_cmd_enable = "true"' >> "$cfg"
      fi
      # Also set the port just in case
      if ! grep -q "network_cmd_port" "$cfg"; then
        echo 'network_cmd_port = "55355"' >> "$cfg"
      fi
    fi
  done
}

# Apply RetroArch configurations so OSD messages will work
configure_retroarch

START_TIME=$(date +%s)
TARGET_TIME=$((START_TIME + DURATION_MINS * 60))
LAST_NOTIFIED_MIN=0

while true; do
  NOW=$(date +%s)
  REMAINING_SECS=$((TARGET_TIME - NOW))
  
  if [ $REMAINING_SECS -le 0 ]; then
    echo "0" > "$STATUS_FILE"
    # Launch lock screen
    SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)
    /bin/bash "$SCRIPT_DIR/play_timer_lock.sh"
    rm -f "$PID_FILE" "$STATUS_FILE"
    exit 0
  fi
  
  REMAINING_MINS=$(( (REMAINING_SECS + 59) / 60 ))
  echo "$REMAINING_MINS" > "$STATUS_FILE"
  
  # Send OSD notification to RetroArch every 5 mins, or every min if <= 5 mins
  if [ "$REMAINING_MINS" != "$LAST_NOTIFIED_MIN" ]; then
    SHOULD_NOTIFY=0
    if [ $((REMAINING_MINS % 5)) -eq 0 ]; then
      SHOULD_NOTIFY=1
    fi
    if [ $REMAINING_MINS -le 5 ]; then
      SHOULD_NOTIFY=1
    fi
    
    if [ $SHOULD_NOTIFY -eq 1 ]; then
      MSG="Play Timer: $REMAINING_MINS min remaining"
      if [ $REMAINING_MINS -le 2 ]; then
        MSG="WARNING: Only $REMAINING_MINS min left!"
      fi
      
      # Try to send UDP message to RetroArch port 55355
      python3 -c "
import socket
s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
try:
    s.sendto(b'SHOW_MSG $MSG', ('127.0.0.1', 55355))
except:
    pass
s.close()
" >/dev/null 2>&1
      LAST_NOTIFIED_MIN=$REMAINING_MINS
    fi
  fi
  
  # Sleep 30s for reliable boundary detection
  sleep 30
done
