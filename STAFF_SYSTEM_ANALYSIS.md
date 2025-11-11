# Staff System Analysis - My Grandma's Legacy

## Summary
A fully-featured staff hiring and automation system has been implemented on the `feature/staff-hiring-system` branch. The system includes staff management, AI workers, UI for hiring, and integration with the planning menu.

---

## What Already Exists

### 1. StaffManager (Autoload Singleton)
**Location:** `/Users/ryandunn/Desktop/my-grandmas-legacy/scripts/autoload/staff_manager.gd`
**Lines:** 401 lines of complete implementation

**Features Implemented:**
- Staff hiring and firing system
- Three staff roles: BAKER, CASHIER, CLEANER
- Applicant pool generation (5-8 new applicants weekly)
- Skill-based wage system (1-5 stars, $20-$120/day)
- Experience and skill progression
- Daily wage payment system
- AI worker activation by phase
- Save/load functionality

**Key Data Structures:**
```gdscript
hired_staff: Dictionary      # staff_id -> staff_data
applicant_pool: Array        # Available applicants
max_staff_slots: int         # Default 3, upgradeable
```

**Signals Emitted:**
- `staff_hired(staff_data: Dictionary)`
- `staff_fired(staff_id: String)`
- `staff_skill_improved(staff_id: String, new_skill: int)`
- `applicants_refreshed(applicants: Array)`
- `wages_paid(total_amount: float)`

**Key Methods:**
- `hire_staff(applicant_data: Dictionary) -> bool`
- `fire_staff(staff_id: String) -> void`
- `pay_daily_wages() -> float`
- `refresh_applicants() -> void`
- `get_hired_staff_count() -> int`
- `get_total_daily_wages() -> float`
- `increase_staff_capacity(additional_slots: int) -> void`

**Balance Values (Hardcoded in StaffManager):**
- Wage rates (skill 1-5): $20, $35, $55, $80, $120/day
- Speed multipliers (skill 1-5): 0.6x, 0.8x, 1.0x, 1.3x, 1.6x
- Quality multipliers (skill 1-5): 0.8x, 0.9x, 1.0x, 1.1x, 1.2x
- Experience thresholds: 30, 60, 90, 120 days for each skill level
- Staff names: 24 predefined names

### 2. StaffHiringPanel (UI Component)
**Location:** `/Users/ryandunn/Desktop/my-grandmas-legacy/scripts/ui/staff_hiring_panel.gd`
**Lines:** 265 lines of complete implementation

**Features:**
- Displays current hired staff with cards
- Displays available applicants
- Shows staff capacity (hired / max slots)
- Shows total daily wages cost
- Hire/Fire buttons with affordability checks
- Staff cards showing:
  - Name, Role, Skill (star rating)
  - Wage per day
  - Speed and Quality multipliers
  - Experience progress (for hired staff)

**Key Methods:**
- `_build_ui() -> void` - Creates entire UI dynamically
- `refresh_display() -> void` - Updates all displays
- `_display_current_staff() -> void`
- `_display_applicants() -> void`
- `_add_staff_card(data: Dictionary, is_hired: bool) -> void`

**Connected Signals:**
- Listens to StaffManager: `staff_hired`, `staff_fired`, `applicants_refreshed`

### 3. AI Workers (Three Classes)
All three AI implementations handle automation during their respective phases:

#### BakerAI
**Location:** `/Users/ryandunn/Desktop/my-grandmas-legacy/scripts/staff/baker_ai.gd`
**Responsibilities:**
- Collects baked goods from ovens
- Loads dough/batter into ovens
- Starts mixing new recipes
- Uses equipment discovery at activation
- Task-based work system with duration timers

#### CashierAI
**Location:** `/Users/ryandunn/Desktop/my-grandmas-legacy/scripts/staff/cashier_ai.gd`
**Responsibilities:**
- Processes customer checkouts
- Finds register equipment
- Tracks customers served
- Base checkout time: 8.0 seconds

#### CleanerAI
**Location:** `/Users/ryandunn/Desktop/my-grandmas-legacy/scripts/staff/cleaner_ai.gd`
**Responsibilities:**
- Automates cleanup tasks
- Handles: trash, equipment checks, sinks, counter wiping
- Task priority system
- Equipment discovery at activation

### 4. PlanningMenu Integration
**Location:** `/Users/ryandunn/Desktop/my-grandmas-legacy/scripts/ui/planning_menu.gd`
**Integration Points:**

**Staff Tab Creation (lines 373-396):**
```gdscript
func _create_staff_tab() -> void
    # Creates Staff tab dynamically in TabContainer
    # Loads StaffHiringPanel script
    # Adds as new tab to existing TabContainer

func _setup_staff_hiring() -> void
    # Refreshes staff panel when planning menu opens
```

**Scene Integration:**
- Planning menu has a TabContainer with Ingredients and Marketing tabs
- Staff tab is created dynamically at runtime
- Located after existing tabs in the UI

### 5. Planning Menu Scene
**Location:** `/Users/ryandunn/Desktop/my-grandmas-legacy/scenes/ui/planning_menu.tscn`

**Current Tab Structure:**
- Ingredients (existing)
- Marketing (existing)
- Staff tab added dynamically by planning_menu.gd
- Build Shop tab added dynamically by planning_menu.gd

---

## What Is NOT in Balance Config

**Important Note:** All staff balance values are currently HARDCODED in `staff_manager.gd` and NOT in `balance_config.gd`:
- Wage rates (lines 37-43)
- Speed multipliers (lines 46-52)
- Quality multipliers (lines 54-60)
- Experience thresholds
- Max staff slots default (3)

**This violates the project's balance system guidelines** and should be migrated to `balance_config.gd` following the pattern established in CLAUDE.md.

---

## Git Branch Status

**Current Feature Branch:** `feature/staff-hiring-system`
- Remote tracking exists: `origin/feature/staff-hiring-system`
- NOT merged to main yet

**How to Access:**
```bash
git checkout feature/staff-hiring-system
```

---

## Integration with Core Systems

### GameManager
- `day_changed` signal → triggers wage payment
- `phase_changed` signal → activates/deactivates AI workers
- Connected in StaffManager._ready()

### EconomyManager
- `get_current_cash()` - Check affordability for hiring
- `remove_cash(amount, reason)` - Pay daily wages

### InventoryManager
- AI workers access ingredient storage
- `get_inventory()`, `remove_item()`, `has_item()` for ingredient checks

### RecipeManager
- BakerAI queries `get_all_unlocked_recipes()`
- Uses recipe data for crafting decisions

### ProgressionManager
- Referenced in planning_menu for campaign unlocks (not staff-specific)

---

## Files and Line Counts

| File | Lines | Type | Status |
|------|-------|------|--------|
| staff_manager.gd | 401 | Autoload | Complete |
| staff_hiring_panel.gd | 265 | UI Component | Complete |
| baker_ai.gd | 268 | AI Logic | Complete |
| cashier_ai.gd | ~150+ | AI Logic | Complete |
| cleaner_ai.gd | ~150+ | AI Logic | Complete |
| planning_menu.gd | 422 | Menu Control | Integrated |
| planning_menu.tscn | 114 | Scene | Pre-integrated |

**Total Implementation:** ~1,600+ lines of staff system code

---

## What Still Needs To Be Done

Based on the balance system guidelines:

1. **Migrate Staff Balance Values to balance_config.gd**
   - Wage rates
   - Speed/quality multipliers
   - Experience thresholds
   - Max staff slots
   - Staff names pool

2. **Optional: Verify Balance**
   - Test wage costs impact on profitability
   - Confirm AI automation provides meaningful gameplay value
   - Check skill progression feels achievable

3. **Testing**
   - Run on main branch after merge
   - Verify hiring/firing workflow
   - Test AI automation during all three phases
   - Check UI updates correctly

4. **Integration Tasks**
   - Merge `feature/staff-hiring-system` to main
   - Update PLAN.md if staff system was part of scheduled work
   - Verify no conflicts with other features

---

## How the System Works (Flow)

### Hiring Phase (Planning Menu)
1. Player opens planning menu
2. Staff tab shows current staff and applicants
3. Player clicks "Hire" on an applicant
4. StaffManager checks: slots available + cash available
5. If valid, staff hired, added to hired_staff dictionary
6. UI refreshes to show new staff member
7. Applicants refresh weekly (day % 7 == 0)

### Daily Wage Payment
1. End of day, GameManager emits `day_changed`
2. StaffManager._on_day_changed() called
3. pay_daily_wages() iterates through hired_staff
4. Each staff member gets wage_rates[skill]
5. Money deducted from economy
6. Experience incremented
7. Skill improvement checked every 30, 60, 90, 120 days

### AI Automation
1. GameManager emits `phase_changed`
2. StaffManager._on_phase_changed() called
3. Deactivates previous phase's AI workers
4. Based on new phase:
   - BAKING (phase 0) → activate BakerAI
   - BUSINESS (phase 1) → activate CashierAI
   - CLEANUP (phase 2) → activate CleanerAI
5. AI instances created on demand
6. AI processes tasks during phase using skill multipliers
7. At phase end, AI deactivated and cleaned up

---

## Key Technical Details

### Skill Multipliers Applied During AI Work
- **BakerAI**: Uses `get_staff_speed_multiplier()` when working on tasks
- **CashierAI**: Speed multiplier affects checkout time
- **CleanerAI**: Speed multiplier affects task duration

### Quality Multiplier
- **BakerAI** applies `get_staff_quality_multiplier()` to recipes started
- Higher skill = higher quality products = higher sales

### Staff Data Structure
```gdscript
staff_data = {
    "id": "staff_1",
    "name": "Alice",
    "role": StaffRole.BAKER,  # 0=BAKER, 1=CASHIER, 2=CLEANER
    "skill": 3,                # 1-5 stars
    "days_worked": 15,
    "experience": 5,           # Progress toward next level
    "hire_date": 10            # Day hired
}
```

---

## Recommendations

1. **Immediate:** Migrate balance values to balance_config.gd before merging
2. **Testing:** Verify wage costs don't break early-game profitability
3. **Merge Strategy:** Merge `feature/staff-hiring-system` to main once balance is confirmed
4. **Documentation:** Update CLAUDE.md Common Tasks section with "Hiring Staff" workflow

