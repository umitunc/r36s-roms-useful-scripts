#!/bin/bash

# R36S Play Timer Lock Screen
# Displays a blocking warning screen, plays a warning sound, and enforces a break.
# Credits: Ümit Tunç (Software Engineer) - 2026

BACKTITLE="R36S Play Timer by Ümit Tunç (Software Engineer 2026)"

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

export TERM=linux
export SCREEN_RESOURCES=1

# Kill all emulators gracefully first, then forcefully
echo "Killing emulators..."
killall -15 retroarch PPSSPPSDL drastic flycast mupen64plus openbor scummvm dosbox pcsx retroarch32 2>/dev/null
sleep 2
killall -9 retroarch PPSSPPSDL drastic flycast mupen64plus openbor scummvm dosbox pcsx retroarch32 2>/dev/null

# Play alarm sound in background if speaker-test is available
(
  for i in {1..5}; do
    speaker-test -t sine -f 800 -l 1 >/dev/null 2>&1
    sleep 0.5
  done
) &

# Force a screen refresh / clear tty1
clear

# Lock screen duration: 5 minutes (300 seconds)
LOCK_TIME=300
ELAPSED=0

while [ $ELAPSED -lt $LOCK_TIME ]; do
  REMAINING=$((LOCK_TIME - ELAPSED))
  MINS=$((REMAINING / 60))
  SECS=$((REMAINING % 60))
  
  # Format remaining time nicely
  TIME_STR=$(printf "%02d:%02d" $MINS $SECS)
  
  # Display dialog message box (blocking for 5 seconds using a timeout)
  dialog --clear \
         --backtitle "$BACKTITLE" \
         --title " !!! TIME EXPIRED !!! " \
         --timeout 5 \
         --msgbox "\n  Your play time has expired.\n\n  The device has been locked automatically to let your eyes rest.\n\n  Remaining Break Time: $TIME_STR\n\n  Please power off the device or take a short break." 14 60
         
  RESPONSE=$?
  ELAPSED=$((ELAPSED + 5))
done

clear
dialog --clear \
       --backtitle "$BACKTITLE" \
       --title " Break Finished " \
       --msgbox "\n  Break time has completed. You can start the timer again to play." 10 50
clear
