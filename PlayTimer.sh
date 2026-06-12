#!/bin/bash

# R36S Play Timer Controller
# Main Port Launcher Script
# Credits: Ümit Tunç (Software Engineer) - 2026

# Rename process for gptokeyb tracking
if [ "$1" != "--run" ]; then
  exec -a playtimer_menu /bin/bash "$0" --run "$@"
fi
shift

# Load PortMaster controls
XDG_DATA_HOME=${XDG_DATA_HOME:-$HOME/.local/share}
if [ -d "/opt/system/Tools/PortMaster/" ]; then
  controlfolder="/opt/system/Tools/PortMaster"
elif [ -d "/opt/tools/PortMaster/" ]; then
  controlfolder="/opt/tools/PortMaster"
elif [ -d "$XDG_DATA_HOME/PortMaster/" ]; then
  controlfolder="$XDG_DATA_HOME/PortMaster"
else
  controlfolder="/roms/ports/PortMaster"
fi

if [ -f "$controlfolder/control.txt" ]; then
  source "$controlfolder/control.txt"
  get_controls
fi

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)

# Redirect stdout/stderr to tty1/tty3 so it draws on the handheld screen if available
if [ -w /dev/tty1 ]; then
  CONSOLE_TTY="/dev/tty1"
elif [ -w /dev/tty3 ]; then
  CONSOLE_TTY="/dev/tty3"
else
  CONSOLE_TTY="/dev/stdout"
fi

if [ "$CONSOLE_TTY" != "/dev/stdout" ]; then
  exec >"$CONSOLE_TTY" 2>&1
  exec <"$CONSOLE_TTY"
fi

# Start control mapper (gptokeyb) for gamepad input
if [ ! -z "$GPTOKEYB" ]; then
  export SDL_GAMECONTROLLERCONFIG="$sdl_controllerconfig"
  $GPTOKEYB "playtimer_menu" -c "$SCRIPT_DIR/play_timer/play_timer.gptokeyb" &
elif [ -f "/usr/local/bin/gptokeyb" ]; then
  /usr/local/bin/gptokeyb "playtimer_menu" -c "$SCRIPT_DIR/play_timer/play_timer.gptokeyb" &
fi

cleanup() {
  killall -9 gptokeyb 2>/dev/null
  if [ ! -z "$ESUDO" ]; then
    $ESUDO systemctl restart oga_events &
  elif [ -f "/usr/bin/systemctl" ]; then
    sudo systemctl restart oga_events &
  fi
}
trap cleanup EXIT

export TERM=linux

PID_FILE="/tmp/play_timer.pid"
STATUS_FILE="/tmp/play_timer_status.txt"
DAEMON_PATH="$SCRIPT_DIR/play_timer/play_timer_daemon.sh"
BACKTITLE="R36S Play Timer by Ümit Tunç (Software Engineer 2026)"

# Clear the console screen
clear

get_timer_status() {
  if [ -f "$PID_FILE" ] && kill -0 $(cat "$PID_FILE") 2>/dev/null; then
    local remaining="Unknown"
    if [ -f "$STATUS_FILE" ]; then
      remaining=$(cat "$STATUS_FILE")
    fi
    echo "Active (Time Remaining: $remaining min)"
  else
    echo "Inactive (Not Running)"
  fi
}

stop_timer() {
  if [ -f "$PID_FILE" ]; then
    local pid=$(cat "$PID_FILE")
    kill -9 "$pid" 2>/dev/null
    rm -f "$PID_FILE" "$STATUS_FILE"
    dialog --clear --backtitle "$BACKTITLE" --title "Timer Stopped" --msgbox "\nThe timer has been cancelled successfully." 8 45
  else
    dialog --clear --backtitle "$BACKTITLE" --title "Timer Stopped" --msgbox "\nNo active timer was found." 8 45
  fi
}

start_timer() {
  local minutes=$1
  # Stop any running timer first
  if [ -f "$PID_FILE" ]; then
    local pid=$(cat "$PID_FILE")
    kill -9 "$pid" 2>/dev/null
    rm -f "$PID_FILE" "$STATUS_FILE"
  fi
  
  # Start daemon in background
  /bin/bash "$DAEMON_PATH" "$minutes" &
  
  dialog --clear --backtitle "$BACKTITLE" --title "Timer Started" --msgbox "\nTimer started for $minutes minutes.\n\nGames will automatically close when time is up.\nHave fun!" 10 50
}

while true; do
  STATUS=$(get_timer_status)
  
  # Create interactive dialog menu
  CHOICE=$(dialog --clear \
                  --backtitle "$BACKTITLE" \
                  --title " Timer Settings " \
                  --cancel-label "Exit" \
                  --menu "Status: $STATUS\n\nPlease select a duration or stop the timer:" 16 60 8 \
                  1 "15 Minutes Play Time" \
                  2 "30 Minutes Play Time" \
                  3 "45 Minutes Play Time" \
                  4 "60 Minutes (1 Hour) Play Time" \
                  5 "90 Minutes (1.5 Hours) Play Time" \
                  6 "120 Minutes (2 Hours) Play Time" \
                  7 "Enter Custom Duration..." \
                  8 "Stop / Cancel Active Timer" 2>&1 >"$CONSOLE_TTY")
                  
  # Exit if user hits Cancel or ESC
  if [ $? -ne 0 ] || [ -z "$CHOICE" ]; then
    clear
    exit 0
  fi
  
  case "$CHOICE" in
    1) start_timer 15 ;;
    2) start_timer 30 ;;
    3) start_timer 45 ;;
    4) start_timer 60 ;;
    5) start_timer 90 ;;
    6) start_timer 120 ;;
    7)
      # Ask for custom minutes
      CUSTOM_MINS=$(dialog --clear \
                           --backtitle "$BACKTITLE" \
                           --title "Custom Play Time" \
                           --inputbox "\nPlease enter play time in minutes (e.g. 25):" 10 50 2>&1 >"$CONSOLE_TTY")
      if [ $? -eq 0 ] && [ ! -z "$CUSTOM_MINS" ]; then
        # Validate that it is a positive integer
        if [[ "$CUSTOM_MINS" =~ ^[0-9]+$ ]] && [ "$CUSTOM_MINS" -gt 0 ]; then
          start_timer "$CUSTOM_MINS"
        else
          dialog --clear --backtitle "$BACKTITLE" --title "Error" --msgbox "\nInvalid duration entered! Please enter numbers only." 8 45
        fi
      fi
      ;;
    8) stop_timer ;;
  esac
done

clear
