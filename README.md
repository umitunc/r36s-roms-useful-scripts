# R36S Useful Scripts & Ports Collection

This repository is a collection of useful custom scripts, tools, and utility ports designed for the **R36S handheld console (running ArkOS / AmberELEC / EmulationStation)**. 

Feel free to contribute or add your own tools to this repository!

---

## 📂 Available Tools & Scripts

### 1. ⏱️ Play Timer (Child Play-Time Manager)
A background daemon and interactive port that monitors gameplay duration, sends remaining time alerts directly onto RetroArch games, and automatically exits emulators to lock the screen with a mandatory break screen when time is up.

* **Main Script**: `PlayTimer.sh`
* **Daemon & Lock Helpers**: `play_timer/`
* **Features**:
  - Predefined or custom time limits (minutes).
  - Live remaining-time OSD alerts using RetroArch UDP commands.
  - Mandatory 5-minute break screen lock upon expiration.
  - Option to view remaining time or stop the active timer from the Ports menu.

#### 🛠️ Installation & Activation
1. Copy `PlayTimer.sh` and the `play_timer` directory to `/roms/ports/` on your console.
2. Mark the scripts as executable:
   ```bash
   chmod +x /roms/ports/PlayTimer.sh
   chmod +x /roms/ports/play_timer/play_timer_daemon.sh
   chmod +x /roms/ports/play_timer/play_timer_lock.sh
   ```
3. Open EmulationStation, navigate to the **Ports** menu, and select **PlayTimer** to begin.

---

## ➕ How to Add More Scripts
If you want to add a new script to this collection:
1. Place your main user-facing script (with interactive elements) in the root or `ports/` directory (e.g. `MyUtility.sh`).
2. If your utility requires support files or background scripts, bundle them inside a dedicated subdirectory named after your utility (e.g. `my_utility/`).
3. Make sure to update this `README.md` with installation steps and descriptions for your new utility.

---

## ✒️ Credits
Developed and maintained by **Ümit Tunç (Software Engineer)** - 2026.

