# =============================================================================
# Smart Pill Dispenser
# Platform : ESP32 + MicroPython
# Hardware : OLED (I2C) · DS3231 RTC · Servo 360° · IR Sensor
#            10x LEDs · Buzzer · SD Card · 18650 Battery Shield
# =============================================================================

from machine import Pin, PWM, I2C, SPI, ADC, UART
import time
import ssd1306
import ds3231
import sdcard
import os
import json


# -----------------------------------------------------------------------------
# State machine
#
# The main loop branches on STATE instead of ad-hoc flags.
# Only one state is active at a time, making the flow easy to follow.
#
#   IDLE      → watching the clock, showing time + battery on OLED
#   DISPENSING → drawer is open, LED is ON, waiting for user to take the dose
#   MISSED    → timeout elapsed without detection, LED stays ON until reset
# -----------------------------------------------------------------------------

STATE_IDLE       = "IDLE"
STATE_DISPENSING = "DISPENSING"
STATE_MISSED     = "MISSED"

state = STATE_IDLE


# -----------------------------------------------------------------------------
# Display (SSD1306 128×64 via I2C)
# -----------------------------------------------------------------------------

i2c  = I2C(0, scl=Pin(22), sda=Pin(21))
oled = ssd1306.SSD1306_I2C(128, 64, i2c)


def show(line1, line2="", line3=""):
    """Clear the screen and render up to three 16-character lines."""
    oled.fill(0)
    oled.text(line1[:16], 0,  8)
    if line2: oled.text(line2[:16], 0, 28)
    if line3: oled.text(line3[:16], 0, 48)
    oled.show()


def show_idle(h, m, v, pct):
    """
    Persistent idle screen: clock on line 1, battery on line 3.
    This is always visible so the user never stares at a blank display.
    """
    oled.fill(0)
    oled.text("{:02d}:{:02d}".format(h, m),    0,  8)
    oled.text("Pill Dispenser",                 0, 28)
    oled.text("BAT {}V {}%".format(v, pct)[:16], 0, 48)
    oled.show()


# -----------------------------------------------------------------------------
# Real-Time Clock (DS3231 via I2C)
# -----------------------------------------------------------------------------

rtc = ds3231.DS3231(i2c)


def get_time():
    """Return (hour, minute, second) from the RTC."""
    t = rtc.datetime()
    return t[4], t[5], t[6]


# -----------------------------------------------------------------------------
# SD Card (SPI)
# SD_READY stays False if the card is missing — the system keeps running.
# -----------------------------------------------------------------------------

try:
    spi_sd = SPI(1, baudrate=1_000_000, polarity=0, phase=0,
                 sck=Pin(14), mosi=Pin(13), miso=Pin(12))
    sd  = sdcard.SDCard(spi_sd, Pin(5))
    vfs = os.VfsFat(sd)
    os.mount(vfs, "/sd")
    SD_READY = True
    print("[SD] Mounted OK")
except Exception as e:
    SD_READY = False
    print("[SD] Mount failed:", e)


def log(msg):
    """Write a timestamped entry to /sd/log.txt and echo it to serial."""
    h, m, s   = get_time()
    timestamp = "{:02d}:{:02d}:{:02d}".format(h, m, s)
    entry     = "[{}] {}\n".format(timestamp, msg)
    print(entry.strip())
    if not SD_READY:
        return
    try:
        with open("/sd/log.txt", "a") as f:
            f.write(entry)
    except Exception as e:
        print("[SD] Write error:", e)


# -----------------------------------------------------------------------------
# Non-blocking UART input
#
# uart.readline() returns immediately with None if no data is available,
# so the main loop never stalls waiting for a keypress.
# Baud rate matches the default MicroPython REPL (115200).
# -----------------------------------------------------------------------------

uart        = UART(0, baudrate=115200)
_cmd_buffer = ""          # accumulates characters until a newline arrives


def read_command():
    """
    Drain any available UART bytes into a line buffer.
    Returns a complete command string when a newline is received, else None.
    """
    global _cmd_buffer
    while uart.any():
        ch = uart.read(1).decode("utf-8", "ignore")
        if ch in ("\r", "\n"):
            cmd = _cmd_buffer.strip()
            _cmd_buffer = ""
            if cmd:
                return cmd
        else:
            _cmd_buffer += ch
    return None


# -----------------------------------------------------------------------------
# Servo — 360° continuous rotation
#
# Duty cycle reference (freq = 50 Hz):
#   STOP → 75   (~1.5 ms pulse, no rotation)
#   CW   → 80   (~1.6 ms pulse, clockwise)
#   CCW  → 70   (~1.4 ms pulse, counter-clockwise)
#
# Position is tracked by elapsed time, not by encoder.
# drawer_centers[i] = travel time from drawer 0 to the centre of drawer i.
# -----------------------------------------------------------------------------

servo = PWM(Pin(15))
servo.freq(50)

STOP = 75
CW   = 80
CCW  = 70

FULL_ROTATION_TIME = 1.2
DRAWERS            = 10
TIME_PER_DRAWER    = FULL_ROTATION_TIME / DRAWERS

drawer_centers = [
    (i * TIME_PER_DRAWER) + (TIME_PER_DRAWER / 2)
    for i in range(DRAWERS)
]


def save_position(n):
    """Persist the current drawer index to flash so restarts are seamless."""
    try:
        with open("pos.txt", "w") as f:
            f.write(str(n))
    except Exception as e:
        print("[POS] Save error:", e)


def load_position():
    """Return the last saved drawer index, or 0 if no file exists."""
    try:
        with open("pos.txt", "r") as f:
            return int(f.read())
    except:
        return 0


current_drawer = load_position()


def move_to_drawer(target):
    """Rotate the carousel to the target drawer using timed open-loop control."""
    global current_drawer

    if target == current_drawer:
        return

    diff = drawer_centers[target] - drawer_centers[current_drawer]

    if diff > 0:
        servo.duty(CW)
    else:
        servo.duty(CCW)
        diff = abs(diff)

    time.sleep(diff)
    servo.duty(STOP)

    current_drawer = target
    save_position(target)
    log("Moved to drawer {}".format(target))


# -----------------------------------------------------------------------------
# Buzzer (active, GPIO output)
# -----------------------------------------------------------------------------

buzzer = Pin(27, Pin.OUT)


def beep(times=2, long=False):
    """Sound the buzzer `times` times. long=True doubles the pulse width."""
    duration = 0.6 if long else 0.3
    for _ in range(times):
        buzzer.on()
        time.sleep(duration)
        buzzer.off()
        time.sleep(0.2)


# -----------------------------------------------------------------------------
# LEDs — one per drawer, mapped to GPIO pins in drawer order
# -----------------------------------------------------------------------------

LED_PINS = [2, 4, 5, 18, 19, 23, 25, 26, 32, 33]
leds     = [Pin(p, Pin.OUT) for p in LED_PINS]


def led_on(drawer):  leds[drawer].on()
def led_off(drawer): leds[drawer].off()


# -----------------------------------------------------------------------------
# IR Sensor (active-low: value() == 0 means object detected)
# -----------------------------------------------------------------------------

ir = Pin(34, Pin.IN)


# -----------------------------------------------------------------------------
# Battery Monitor (18650 via ADC + resistor voltage divider on Pin 35)
#
# The divider halves the battery voltage so the ESP32's 3.6 V ADC can safely
# read a fully-charged cell (4.2 V).  Formula:
#   V_bat = (adc_raw / 4095) × 3.6 × 2
#
# Thresholds:
#   >= 3.5 V  → OK
#   <  3.5 V  → low warning
#   <  3.0 V  → critical, charge immediately
# -----------------------------------------------------------------------------

battery_adc = ADC(Pin(35))
battery_adc.atten(ADC.ATTN_11DB)   # full-scale input ~3.6 V

BAT_FULL     = 4.2
BAT_WARN     = 3.5
BAT_CRITICAL = 3.0

_bat_v            = 0.0   # last measured voltage — kept in module scope so
_bat_pct          = 0     # show_idle() can read it without re-sampling every tick
_last_bat_check   = 0     # unix timestamp of the last ADC read


def get_battery_voltage():
    """Read the ADC and return the estimated battery voltage in volts."""
    raw = battery_adc.read()
    return round((raw / 4095) * 3.6 * 2, 2)


def battery_percent(v):
    """Map voltage to a 0–100 % charge estimate."""
    pct = (v - BAT_CRITICAL) / (BAT_FULL - BAT_CRITICAL) * 100
    return max(0, min(100, int(pct)))


def check_battery(force=False):
    """
    Sample the battery and alert if below a threshold.
    Throttled to once every 5 minutes unless force=True.
    Always updates the module-level _bat_v / _bat_pct so the idle screen
    reflects the latest reading without an extra ADC call.
    Returns (voltage, percent).
    """
    global _last_bat_check, _bat_v, _bat_pct
    now = time.time()

    if not force and (now - _last_bat_check) < 300:
        return _bat_v, _bat_pct     # return cached values — no ADC read needed

    _last_bat_check = now
    _bat_v   = get_battery_voltage()
    _bat_pct = battery_percent(_bat_v)

    log("BATTERY: {}V  {}%".format(_bat_v, _bat_pct))

    if _bat_v < BAT_CRITICAL:
        show("!! BATTERY !!", "CRITICAL {}V".format(_bat_v), "Charge NOW!")
        beep(5, long=True)
        log("BATTERY CRITICAL: {}V".format(_bat_v))
    elif _bat_v < BAT_WARN:
        show("Low Battery", "{}V  {}%".format(_bat_v, _bat_pct), "Please charge")
        beep(2)
        log("BATTERY LOW: {}V".format(_bat_v))

    return _bat_v, _bat_pct


# -----------------------------------------------------------------------------
# Schedule
# Stored as JSON on the SD card so entries survive power cycles.
# Each entry: { "drawer": int, "hour": int, "minute": int, "name": str }
# -----------------------------------------------------------------------------

SCHEDULE_FILE = "/sd/schedule.json" if SD_READY else "schedule.json"
schedule = []
executed = []   # unique keys for alarms already fired today


def load_schedule():
    global schedule
    try:
        with open(SCHEDULE_FILE, "r") as f:
            schedule = json.load(f)
        print("[SCH] Loaded {} item(s)".format(len(schedule)))
    except:
        schedule = []
        print("[SCH] No schedule found — starting empty")


def save_schedule():
    try:
        with open(SCHEDULE_FILE, "w") as f:
            json.dump(schedule, f)
        print("[SCH] Saved")
    except Exception as e:
        print("[SCH] Save error:", e)


def add_schedule(drawer, hour, minute, name):
    item = {"drawer": drawer, "hour": hour, "minute": minute, "name": name}
    schedule.append(item)
    save_schedule()
    log("Schedule added: {}".format(item))


def remove_schedule(index):
    if 0 <= index < len(schedule):
        removed = schedule.pop(index)
        save_schedule()
        log("Schedule removed: {}".format(removed))
    else:
        print("[SCH] Invalid index:", index)


def list_schedule():
    if not schedule:
        print("[SCH] No entries.")
        return
    print("\n{:<4} {:<8} {:<6} {}".format("#", "Drawer", "Time", "Medication"))
    print("-" * 35)
    for i, item in enumerate(schedule):
        print("{:<4} {:<8} {:02d}:{:02d}  {}".format(
            i, item["drawer"], item["hour"], item["minute"], item["name"]))
    print()


# -----------------------------------------------------------------------------
# Serial menu (temporary — replace with BLE / Wi-Fi app in production)
# Commands are processed by handle_input() which is fed by the non-blocking
# read_command() so the loop never stalls.
# -----------------------------------------------------------------------------

def print_menu():
    print("\n" + "=" * 42)
    print("  Smart Pill Dispenser")
    print("=" * 42)
    print("  add      Add a new scheduled dose")
    print("  list     Show current schedule")
    print("  del N    Remove entry number N")
    print("  0-9      Manually open a drawer")
    print("  time     Show current RTC time")
    print("  bat      Show battery status")
    print("=" * 42)


def handle_input(cmd):
    cmd = cmd.strip()

    if cmd == "add":
        # Collect the four fields over UART (still blocking per-field,
        # but only when the user explicitly types "add").
        try:
            uart.write("Drawer (0-9) : ")
            drawer = int(uart.readline().decode().strip())
            uart.write("Hour   (0-23): ")
            hour   = int(uart.readline().decode().strip())
            uart.write("Minute (0-59): ")
            minute = int(uart.readline().decode().strip())
            uart.write("Medication   : ")
            name   = uart.readline().decode().strip()
            if 0 <= drawer < DRAWERS and 0 <= hour < 24 and 0 <= minute < 60:
                add_schedule(drawer, hour, minute, name)
                print("[OK] Added")
                show("Added!", name)
            else:
                print("[ERR] Value out of range")
        except (ValueError, AttributeError):
            print("[ERR] Numbers only")

    elif cmd == "list":
        list_schedule()

    elif cmd.startswith("del "):
        try:
            remove_schedule(int(cmd.split()[1]))
        except:
            print("[ERR] Usage: del N")

    elif cmd == "time":
        h, m, s = get_time()
        t = "{:02d}:{:02d}:{:02d}".format(h, m, s)
        print("[TIME]", t)
        show(t)

    elif cmd == "bat":
        v, pct = check_battery(force=True)
        print("[BAT] {}V  {}%".format(v, pct))
        show("Battery", str(v) + "V", str(pct) + "%")

    else:
        try:
            d = int(cmd)
            if 0 <= d < DRAWERS:
                move_to_drawer(d)
                log("Manual open drawer={}".format(d))
            else:
                print("[ERR] Drawer must be 0-9")
        except ValueError:
            print("[ERR] Unknown command")


# -----------------------------------------------------------------------------
# Dispensing cycle — called when a scheduled alarm fires
#
# Fix #2: LED turns ON as soon as the drawer opens (not only on MISSED).
# The IR loop runs non-blocking in 0.2 s slices so UART is still checked
# during the wait window (handled by the caller via the state machine).
# -----------------------------------------------------------------------------

_dispense_start  = 0     # time.time() when the current dispense began
_dispense_drawer = -1    # drawer index being served
_dispense_name   = ""    # medication name for the active dispense
DISPENSE_TIMEOUT = 60    # seconds the user has to take the dose


def start_dispense(drawer, name):
    """Open the drawer, turn the LED on, and enter DISPENSING state."""
    global state, _dispense_start, _dispense_drawer, _dispense_name

    move_to_drawer(drawer)
    led_on(drawer)                          # LED ON immediately on open
    beep(2)

    _dispense_drawer = drawer
    _dispense_name   = name
    _dispense_start  = time.time()
    state            = STATE_DISPENSING

    show("Take your med", name, "You have 60s")
    log("DISPENSING drawer={} med={}".format(drawer, name))


def tick_dispensing():
    """
    Called every loop iteration while STATE == DISPENSING.
    Checks the IR sensor and the timeout without blocking.
    Transitions to IDLE (taken) or MISSED on completion.
    """
    global state

    if ir.value() == 0:
        # Dose detected — clear the LED and return to idle
        led_off(_dispense_drawer)
        show("Taken!", _dispense_name, ":)")
        log("TAKEN  drawer={} med={}".format(_dispense_drawer, _dispense_name))
        beep(1)
        state = STATE_IDLE
        return

    elapsed = time.time() - _dispense_start
    seconds_left = DISPENSE_TIMEOUT - int(elapsed)

    if elapsed >= DISPENSE_TIMEOUT:
        # Timeout — LED stays ON, transition to MISSED
        show("MISSED!", _dispense_name, "LED stays ON")
        log("MISSED drawer={} med={}".format(_dispense_drawer, _dispense_name))
        beep(3, long=True)
        state = STATE_MISSED
        return

    # Still waiting — update the countdown on the OLED
    show("Take your med", _dispense_name, "{}s left".format(seconds_left))


# -----------------------------------------------------------------------------
# Startup
# -----------------------------------------------------------------------------

show("Pill Dispenser", "Starting...", "Please wait")
time.sleep(1)

load_schedule()
log("=== System started ===")

check_battery(force=True)   # initial read — populates _bat_v / _bat_pct
time.sleep(2)

show("System Ready", "Drawers: {}".format(DRAWERS), "Pos: {}".format(current_drawer))
time.sleep(1)
print_menu()


# -----------------------------------------------------------------------------
# Main loop — non-blocking, state-driven
#
# Each iteration takes ~0.2 s.  No call blocks for more than that except
# move_to_drawer() (servo travel, < 1.2 s) and the "add" sub-prompt.
# -----------------------------------------------------------------------------

while True:

    # 1. Read one complete UART command if available (non-blocking)
    cmd = read_command()
    if cmd:
        handle_input(cmd)

    # 2. Read the RTC once per tick
    h, m, s = get_time()

    # 3. Branch on the active state
    if state == STATE_IDLE:

        # Refresh the persistent idle screen every tick
        show_idle(h, m, _bat_v, _bat_pct)

        # Check whether a scheduled dose is due
        for item in schedule:
            key = "{}_{}_{}_{}".format(
                item["drawer"], item["hour"], item["minute"], item["name"])

            if h == item["hour"] and m == item["minute"] and key not in executed:
                executed.append(key)        # mark before acting to prevent re-firing
                log("ALARM: {}".format(item["name"]))
                start_dispense(item["drawer"], item["name"])
                break                       # handle one alarm per tick

    elif state == STATE_DISPENSING:
        tick_dispensing()

    elif state == STATE_MISSED:
        # LED stays ON; flash the OLED reminder every tick.
        # The system returns to IDLE at midnight (daily reset below)
        # or if the user manually resets via serial (future feature).
        show("MISSED!", _dispense_name, "LED ON - check!")

    # 4. Battery health check (throttled internally to every 5 minutes)
    check_battery()

    # 5. Reset the daily fired-alarm list and MISSED state at midnight
    if h == 0 and m == 0 and s < 2:
        executed.clear()
        if state == STATE_MISSED:
            led_off(_dispense_drawer)
            state = STATE_IDLE
        log("Daily reset complete")

    time.sleep(0.2)
