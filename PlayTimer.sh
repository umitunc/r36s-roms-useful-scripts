#!/bin/bash

# R36S Play Timer Controller
# Main Port Launcher Script

# Redirect stdout/stderr to tty1 so it draws on the handheld screen
exec >/dev/tty1 2>&1
exec </dev/tty1

export TERM=linux

PID_FILE="/tmp/play_timer.pid"
STATUS_FILE="/tmp/play_timer_status.txt"
DAEMON_PATH="/g/games/r36s/ports/custom/play_timer/play_timer_daemon.sh"

# Clear the console screen
clear

get_timer_status() {
  if [ -f "$PID_FILE" ] && kill -0 $(cat "$PID_FILE") 2>/dev/null; then
    local remaining="Bilinmiyor"
    if [ -f "$STATUS_FILE" ]; then
      remaining=$(cat "$STATUS_FILE")
    fi
    echo "Aktif (Kalan Süre: $remaining dk)"
  else
    echo "Pasif (Çalışmıyor)"
  fi
}

stop_timer() {
  if [ -f "$PID_FILE" ]; then
    local pid=$(cat "$PID_FILE")
    kill -9 "$pid" 2>/dev/null
    rm -f "$PID_FILE" "$STATUS_FILE"
    dialog --clear --backtitle "R36S Play Timer" --title "Zamanlayıcı Durduruldu" --msgbox "\nZamanlayıcı başarıyla iptal edildi." 8 45
  else
    dialog --clear --backtitle "R36S Play Timer" --title "Zamanlayıcı Durduruldu" --msgbox "\nÇalışan bir zamanlayıcı bulunamadı." 8 45
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
  
  dialog --clear --backtitle "R36S Play Timer" --title "Zamanlayıcı Başlatıldı" --msgbox "\nZamanlayıcı $minutes dakika için başlatıldı.\n\nSüre dolduğunda oyun otomatik kapatılacaktır.\nİyi oyunlar!" 10 50
}

while true; do
  STATUS=$(get_timer_status)
  
  # Create interactive dialog menu
  CHOICE=$(dialog --clear \
                  --backtitle "R36S Çocuk Zamanlayıcı Portu" \
                  --title " Zamanlayıcı Ayarları " \
                  --cancel-label "Çıkış" \
                  --menu "Durum: $STATUS\n\nLütfen bir süre seçin veya zamanlayıcıyı kapatın:" 16 60 8 \
                  1 "15 Dakika Oyun Süresi" \
                  2 "30 Dakika Oyun Süresi" \
                  3 "45 Dakika Oyun Süresi" \
                  4 "60 Dakika (1 Saat) Oyun Süresi" \
                  5 "90 Dakika (1.5 Saat) Oyun Süresi" \
                  6 "120 Dakika (2 Saat) Oyun Süresi" \
                  7 "Özel Süre Gir..." \
                  8 "Zamanlayıcıyı İptal Et / Durdur" 2>&1 >/dev/tty1)
                  
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
                           --backtitle "R36S Play Timer" \
                           --title "Özel Oyun Süresi" \
                           --inputbox "\nLütfen dakika cinsinden oyun süresini yazın (örn. 25):" 10 50 2>&1 >/dev/tty1)
      if [ $? -eq 0 ] && [ ! -z "$CUSTOM_MINS" ]; then
        # Validate that it is a positive integer
        if [[ "$CUSTOM_MINS" =~ ^[0-9]+$ ]] && [ "$CUSTOM_MINS" -gt 0 ]; then
          start_timer "$CUSTOM_MINS"
        else
          dialog --clear --backtitle "R36S Play Timer" --title "Hata" --msgbox "\nGeçersiz süre girdiniz! Lütfen sadece sayı girin." 8 45
        fi
      fi
      ;;
    8) stop_timer ;;
  esac
done

clear
