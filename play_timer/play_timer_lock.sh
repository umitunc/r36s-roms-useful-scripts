#!/bin/bash

# R36S Play Timer Lock Screen
# Displays a blocking warning screen, plays a warning sound, and enforces a break.

# Ensure we redirect output and input to /dev/tty1 (main console screen)
exec >/dev/tty1 2>&1
exec </dev/tty1

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
         --backtitle "R36S PLAY TIMER (Locked)" \
         --title " !!! TIME EXPIRED !!! " \
         --timeout 5 \
         --msgbox "\n  Oyun oynama süreniz sona ermiştir.\n\n  Gözlerinizin dinlenmesi için cihaz otomatik kilitlendi.\n\n  Kalan Mola Süresi: $TIME_STR\n\n  Lütfen cihazı kapatın ve biraz dinlenin." 14 60
         
  RESPONSE=$?
  ELAPSED=$((ELAPSED + 5))
done

clear
dialog --clear \
       --backtitle "R36S PLAY TIMER" \
       --title " Break Finished " \
       --msgbox "\n  Mola süresi tamamlandı. Tekrar oynamak için zamanlayıcıyı yeniden başlatabilirsiniz." 10 50
clear
