# Phase System to Time-Based System Refactor

## Status: IN PROGRESS

### Completed Changes

#### 1. GameManager (`scripts/autoload/game_manager.gd`) ✅
- Replaced `Phase` enum with `ShopState` enum (CLOSED, OPEN)
- Changed signal from `phase_changed(Phase)` to `shop_state_changed(bool)`
- Added new signal: `hour_changed(int)`
- Implemented continuous 24-hour time system (game_time: 0-86400 seconds)
- Added methods:
  - `open_shop()` - Opens shop, starts customer spawning
  - `close_shop()` - Closes shop, clears customers, regenerates employee energy
  - `toggle_shop()` - Toggles between open/closed
  - `sleep(hours: int)` - Advances time and regenerates player energy
  - `get_current_hour()`, `get_current_minute()`
  - `get_time_of_day_string()` - Returns "Morning", "Afternoon", etc.
  - `is_shop_open()` - Replaces phase checks
- Removed old phase methods: `start_baking_phase()`, `start_business_phase()`, etc.
- Added backwards compatibility: `get_current_phase()` returns 0/1 with deprecation warning

### Changes Needed

#### 2. BalanceConfig (`scripts/autoload/balance_config.gd`) ⏳
**Manual edit required** - Add to TIME section:

```gdscript
const TIME = {
    "seconds_per_game_hour": 60.0,
    "default_open_hour": 6,              # Shop opens at 6 AM by default
    "default_close_hour": 22,            # Shop closes at 10 PM by default
    "max_time_scale": 3.0,

    # Time-of-day traffic multipliers
    "traffic_multipliers": {
        "early_morning": {"hours": [5, 6, 7], "multiplier": 0.8},
        "morning_rush": {"hours": [8, 9, 10], "multiplier": 1.5},
        "late_morning": {"hours": [11], "multiplier": 1.2},
        "lunch": {"hours": [12, 13], "multiplier": 1.8},
        "afternoon": {"hours": [14, 15, 16], "multiplier": 1.3},
        "evening": {"hours": [17, 18, 19], "multiplier": 1.4},
        "late_evening": {"hours": [20, 21], "multiplier": 0.9},
        "night": {"hours": [22, 23], "multiplier": 0.3},
        "late_night": {"hours": [0, 1, 2, 3, 4], "multiplier": 0.2},
    },

    # Deprecated (backwards compatibility)
    "business_start_hour": 9,
    "business_end_hour": 17,
    "cleanup_auto_delay": 2.0,
}
```

#### 3. StaffManager (`scripts/autoload/staff_manager.gd`) ⏳
**Changes needed:**

Line 57: Change signal connection
```gdscript
# OLD:
GameManager.phase_changed.connect(_on_phase_changed)

# NEW:
GameManager.shop_state_changed.connect(_on_shop_state_changed)
```

Lines 653-670: Replace `_on_phase_changed()` with:
```gdscript
func _on_shop_state_changed(is_open: bool) -> void:
    """Handle shop opening/closing to activate/deactivate staff AI"""
    print("[StaffManager] Shop state changed - Open: ", is_open)
    print("[StaffManager] Currently hired staff: ", hired_staff.size())

    # Deactivate all current AI
    _deactivate_all_ai()

    # Activate ALL assigned staff when shop opens
    if is_open:
        print("[StaffManager] Shop opened - activating all staff...")
        _activate_all_staff()
    else:
        print("[StaffManager] Shop closed - staff inactive")

    print("[StaffManager] Active AI workers: ", active_ai_workers.size())
```

Add new methods:
```gdscript
func regenerate_all_employee_energy() -> void:
    """Fully regenerate energy for all employees (called when shop closes)"""
    for employee_id in hired_staff.keys():
        var employee_data: Dictionary = hired_staff[employee_id]
        employee_data["energy"] = BalanceConfig.STAFF.max_energy
    print("[StaffManager] Regenerated energy for all employees")

func process_daily_updates() -> void:
    """Process daily updates - called by GameManager at end of day"""
    pay_daily_wages()
    _process_daily_morale_and_energy()
    _check_employee_auto_quit()
```

#### 4. Bakery Scene (`scripts/bakery/bakery.gd`) ⏳
**Changes needed:**

Remove `_on_phase_changed()` method
Change signal connection:
```gdscript
# Connect to shop state changes instead of phase changes
GameManager.shop_state_changed.connect(_on_shop_state_changed)
```

Add:
```gdscript
func _on_shop_state_changed(is_open: bool) -> void:
    # Update UI or scene state based on shop being open/closed
    pass
```

#### 5. HUD (`scripts/ui/hud.gd`) ⏳
**Changes needed:**

- Replace phase display with time-of-day display
- Change "Start Business" button to "Open Shop"
- Change "End Business" button to "Close Shop"
- Connect buttons to `GameManager.open_shop()` and `GameManager.close_shop()`
- Show current time prominently (HH:MM format)
- Optionally show time of day string ("Morning", "Afternoon", etc.)

#### 6. CustomerManager (`scripts/autoload/customer_manager.gd`) ⏳
**Changes needed:**

- Change phase_changed connection to shop_state_changed
- Add time-of-day traffic multipliers
- Implement `get_traffic_multiplier_for_hour(hour: int)` method
- Apply multiplier to spawn interval calculations

#### 7. Planning Menu (`scripts/ui/planning_menu.gd`) ⏳
**Changes needed:**

- Remove automatic opening on PLANNING phase
- Make it a manually-accessible menu (ESC or button)
- Remove "Next Day" button (days advance automatically at midnight)
- Keep hiring, upgrades, and review functionality

### New Features to Add

#### 8. Player Tiredness System
**New file: `scripts/player/player_stats.gd`**

```gdscript
extends Node

signal energy_changed(new_energy: int)

var max_energy: int = 100
var current_energy: int = 100
var energy_drain_rate: float = 1.0  # Energy lost per 10 minutes of shop being open

func _ready():
    GameManager.shop_state_changed.connect(_on_shop_state_changed)
    GameManager.hour_changed.connect(_on_hour_changed)

func _on_shop_state_changed(is_open: bool):
    # Start/stop energy drain when shop opens/closes
    pass

func _on_hour_changed(hour: int):
    # Drain energy if shop is open
    if GameManager.is_shop_open():
        drain_energy(energy_drain_rate)

func drain_energy(amount: float):
    current_energy = maxi(current_energy - int(amount), 0)
    energy_changed.emit(current_energy)
    _apply_tiredness_effects()

func regenerate_energy(amount: int):
    current_energy = mini(current_energy + amount, max_energy)
    energy_changed.emit(current_energy)
    _apply_tiredness_effects()

func _apply_tiredness_effects():
    var tiredness_factor = current_energy / 100.0
    # Apply to player movement speed, action speed, etc.
    pass
```

#### 9. Sleep Mechanic
**New file: `scripts/apartment/bed_interaction.gd`**

```gdscript
extends Interactable

func _interact():
    # Show sleep UI
    var sleep_menu = preload("res://scenes/ui/sleep_menu.tscn").instantiate()
    get_tree().current_scene.add_child(sleep_menu)

func sleep(hours: int):
    GameManager.sleep(hours)
    # Regenerate player energy
    if PlayerStats:
        PlayerStats.regenerate_energy(hours * 10)  # 10 energy per hour
```

### Testing Checklist

- [ ] Shop can open and close manually
- [ ] Time passes continuously (visible in HUD)
- [ ] Customers spawn only when shop is open
- [ ] Employee energy regenerates when shop closes
- [ ] Employees work when shop is open (based on assigned phase)
- [ ] Day advances automatically at midnight
- [ ] Traffic varies by time of day
- [ ] Player tiredness increases when shop is open
- [ ] Player can sleep to restore energy and advance time
- [ ] Employees get tired after long work periods
- [ ] Employees can be assigned to phases and work accordingly

