#!/bin/bash

# R36S Play Timer Controller
# Main Port Launcher Script
# Credits: Ümit Tunç (Software Engineer) - 2026

# Redirect stdout/stderr to tty1 so it draws on the handheld screen
exec >/dev/tty1 2>&1
exec </dev/tty1

export TERM=linux

PID_FILE="/tmp/play_timer.pid"
STATUS_FILE="/tmp/play_timer_status.txt"
DAEMON_PATH="/g/games/r36s/ports/custom/play_timer/play_timer_daemon.sh"
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
                  8 "Stop / Cancel Active Timer" 2>&1 >/dev/tty1)
                  
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
                           --inputbox "\nPlease enter play time in minutes (e.g. 25):" 10 50 2>&1 >/dev/tty1)
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
