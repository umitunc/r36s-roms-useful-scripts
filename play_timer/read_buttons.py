#!/usr/bin/env python3
"""
R36S Play Timer - Button Menu
Reads gamepad buttons directly from /dev/input/js0.
Prints UI to a console TTY, prints the selection result to stdout.
Usage: python3 read_buttons.py <console_tty> [remaining_mins]
"""
import sys
import struct
import os
import time

# ANSI Colors
C = "\033[1;36m"   # Cyan
G = "\033[1;32m"   # Green
Y = "\033[1;33m"   # Yellow
B = "\033[1;34m"   # Blue
M = "\033[1;35m"   # Magenta
R = "\033[1;31m"   # Red
W = "\033[1;37m"   # White/Bold
D = "\033[0m"      # Reset

def draw_ui(tty, status_line):
    """Draw the button menu to the given TTY file object."""
    tty.write("\033[2J\033[H")  # clear screen + cursor home
    lines = [
        f"{C}{'=' * 50}{D}",
        f"{W}           R36S PLAY TIME TIMER{D}",
        f"{C}{'=' * 50}{D}",
        "",
        f"  {status_line}",
        "",
        f"{C}{'─' * 50}{D}",
        f"  Press a button to set play time:",
        "",
        f"    {G}[A]{D}  -->  {W}15 Minutes{D}",
        f"    {Y}[B]{D}  -->  {W}30 Minutes{D}",
        f"    {B}[X]{D}  -->  {W}45 Minutes{D}",
        f"    {M}[Y]{D}  -->  {W}60 Minutes{D} (1 Hour)",
        "",
        f"{C}{'─' * 50}{D}",
        f"    {R}[SELECT]{D}  Cancel / Stop Timer",
        f"    {R}[START]{D}   Exit Without Changes",
        f"{C}{'=' * 50}{D}",
    ]
    tty.write("\n".join(lines) + "\n")
    tty.flush()

def show_message(tty, title, msg, color, seconds=3):
    """Show a full-screen confirmation message on the TTY."""
    tty.write("\033[2J\033[H")  # clear
    lines = [
        f"{C}{'=' * 50}{D}",
        f"{color}  {title}{D}",
        f"{C}{'=' * 50}{D}",
        "",
        f"  {msg}",
        "",
        f"{C}{'=' * 50}{D}",
    ]
    tty.write("\n".join(lines) + "\n")
    tty.flush()
    time.sleep(seconds)
    tty.write("\033[2J\033[H")  # clear after
    tty.flush()

def main():
    # Parse arguments
    console_path = sys.argv[1] if len(sys.argv) > 1 else "/dev/tty1"
    remaining = sys.argv[2] if len(sys.argv) > 2 else None

    # Build status line
    if remaining and remaining != "inactive":
        status_line = f"{G}TIMER ACTIVE{D} - {W}{remaining} min{D} remaining"
    else:
        status_line = f"{Y}NO TIMER ACTIVE{D}"

    # Open console TTY for drawing
    try:
        tty = open(console_path, "w")
    except Exception:
        tty = sys.stderr

    draw_ui(tty, status_line)

    # Open joystick
    js_dev = "/dev/input/js0"
    if not os.path.exists(js_dev):
        show_message(tty, "ERROR", f"Gamepad not found ({js_dev})", R, 3)
        print("exit")
        return

    try:
        fd = open(js_dev, "rb")
    except Exception as e:
        show_message(tty, "ERROR", f"Cannot open gamepad: {e}", R, 3)
        print("exit")
        return

    EVENT_FORMAT = "IhBB"
    EVENT_SIZE = struct.calcsize(EVENT_FORMAT)

    try:
        while True:
            event = fd.read(EVENT_SIZE)
            if not event:
                break

            _time, value, ev_type, number = struct.unpack(EVENT_FORMAT, event)

            # ev_type == 1 = Button, value == 1 = Pressed
            if ev_type == 1 and value == 1:
                if number == 0:    # A -> 15 min
                    show_message(tty,
                        "TIMER STARTED  (15 Minutes)",
                        "Games will auto-close when time is up. Have fun!",
                        G, 3)
                    print("15")
                    return
                elif number == 1:  # B -> 30 min
                    show_message(tty,
                        "TIMER STARTED  (30 Minutes)",
                        "Games will auto-close when time is up. Have fun!",
                        G, 3)
                    print("30")
                    return
                elif number == 2:  # X -> 45 min
                    show_message(tty,
                        "TIMER STARTED  (45 Minutes)",
                        "Games will auto-close when time is up. Have fun!",
                        G, 3)
                    print("45")
                    return
                elif number == 3:  # Y -> 60 min
                    show_message(tty,
                        "TIMER STARTED  (60 Minutes)",
                        "Games will auto-close when time is up. Have fun!",
                        G, 3)
                    print("60")
                    return
                elif number == 8:  # Select -> stop
                    show_message(tty,
                        "TIMER CANCELLED",
                        "The play timer has been stopped.",
                        R, 2)
                    print("stop")
                    return
                elif number == 9:  # Start -> exit
                    tty.write("\033[2J\033[H")
                    tty.flush()
                    print("exit")
                    return
    except KeyboardInterrupt:
        print("exit")
    finally:
        fd.close()
        if tty != sys.stderr:
            tty.close()

if __name__ == "__main__":
    main()
