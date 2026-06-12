#!/bin/bash

# R36S Play Timer Daemon
# Runs in the background and tracks the remaining play time.

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

while true; do
  NOW=$(date +%s)
  REMAINING_SECS=$((TARGET_TIME - NOW))
  
  if [ $REMAINING_SECS -le 0 ]; then
    echo "0" > "$STATUS_FILE"
    # Launch lock screen
    /bin/bash /g/games/r36s/ports/custom/play_timer/play_timer_lock.sh
    rm -f "$PID_FILE" "$STATUS_FILE"
    exit 0
  fi
  
  REMAINING_MINS=$(( (REMAINING_SECS + 59) / 60 ))
  echo "$REMAINING_MINS" > "$STATUS_FILE"
  
  # Send OSD notification to RetroArch if it is running
  if pgrep -x retroarch >/dev/null 2>&1 || pgrep -x retroarch32 >/dev/null 2>&1; then
    # Construct message
    MSG="Kalan Sure: $REMAINING_MINS dk"
    if [ $REMAINING_MINS -eq 1 ]; then
      MSG="UYARI: Son 1 dakika!"
    fi
    
    # Send UDP message to RetroArch port 55355 using python3
    python3 -c "import socket; s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM); s.sendto(b'SHOW_MSG $MSG', ('127.0.0.1', 55355))" >/dev/null 2>&1
  fi
  
  # Check more frequently when less than 2 minutes are remaining
  if [ $REMAINING_SECS -le 120 ]; then
    sleep 15
  else
    sleep 60
  fi
done
