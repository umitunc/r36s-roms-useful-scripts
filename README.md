# R36S Play Timer Port (Child Play-Time Manager)

This port is a background play-time manager designed to control and limit kids' gaming sessions on the R36S handheld console running ArkOS.

When the timer expires, it automatically terminates active emulators and locks the screen for a mandatory break.

---

## 🛠️ Installation

Copy the files into the **Ports** partition of your R36S SD card following this directory structure:

```text
/roms/ports/
├── PlayTimer.sh
└── play_timer/
    ├── play_timer_daemon.sh
    └── play_timer_lock.sh
```

### 🔑 Setting Permissions

You must set executable permissions for the scripts via SSH terminal or the ArkOS File Manager command-line interface:

```bash
chmod +x /roms/ports/PlayTimer.sh
chmod +x /roms/ports/play_timer/play_timer_daemon.sh
chmod +x /roms/ports/play_timer/play_timer_lock.sh
```

---

## 🚀 How to Use

1. **Start the Timer**:
   - Navigate to the **Ports** menu on your R36S device.
   - Start **PlayTimer**.
   - Choose a predefined time option (15m, 30m, 45m, etc.) or choose **Özel Süre Gir...** (Enter Custom Time) to specify a custom countdown in minutes.
   - Once successfully started, the script will automatically return you to EmulationStation so you can play any game.

2. **In-game Remaining Time Notifications**:
   - The daemon checks the remaining time in the background.
   - For games running under RetroArch, it will trigger an OSD alert displaying `"Kalan Sure: X dk"` at the top center of the screen every minute.
   - During the last minute, a critical warning alert `"UYARI: Son 1 dakika!"` will pop up.

3. **Time Up & Screen Lock**:
   - Once the time runs out, the script gracefully kills any running emulator.
   - A lock screen will overlay `/dev/tty1` with a **5-minute (300 seconds) countdown break clock** and sound an alarm.
   - This screen remains locked until the countdown finishes, ensuring children take a mandatory break before starting a new session.

4. **Cancel or Check Active Status**:
   - Launching **PlayTimer** again from EmulationStation will display the current status and remaining time at the top. You can choose to stop/cancel the active timer here.
