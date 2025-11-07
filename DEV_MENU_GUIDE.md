# Developer Menu Guide

## Overview
The Developer Menu is a comprehensive testing tool that allows you to manipulate all game systems without playing through the normal game loop. This is essential for rapid testing and iteration.

## Opening the Menu
Press **\`** (backtick key) at any time to toggle the developer menu.

---

## Features by Tab

### 📊 Economy Tab
**Purpose:** Manipulate money and cash flow

**Features:**
- **Current Cash Display** - Shows real-time cash balance
- **Add Money Buttons**
  - Add $100
  - Add $500
  - Add $1000
- **Set Exact Cash** - Enter any amount and set cash to that exact value (can go negative)

**Use Cases:**
- Test purchasing with different budgets
- Simulate bankruptcy scenarios
- Unlock milestone-gated content

---

### 🎒 Inventory Tab
**Purpose:** Spawn items directly into player inventory

**Features:**
- **Ingredients Section**
  - 10 ingredient buttons (Flour, Sugar, Eggs, Butter, Milk, Yeast, Chocolate Chips, Blueberries, Vanilla, Salt)
  - Each button adds 10 of that ingredient
- **Finished Products Section**
  - White Bread x5
  - Chocolate Chip Cookies x5
  - Blueberry Muffins x5
- **Utilities**
  - **Fill All Ingredients** - Add 50 of each ingredient
  - **Clear Player Inventory** - Empty entire inventory

**Use Cases:**
- Test crafting recipes without gathering ingredients
- Test display case with pre-made goods
- Test inventory limits
- Quickly stock up for business phase testing

---

### 👥 Customers Tab
**Purpose:** Control customer spawning and behavior

**Features:**
- **Active Customer Counter** - Shows current number of customers
- **Spawn Controls**
  - Spawn 1 Customer (manual single spawn)
  - Spawn Multiple (specify count, 1-50)
- **Auto-Spawn Toggle**
  - Start Auto-Spawn (enable automatic customer spawning)
  - Stop Auto-Spawn (disable automatic customer spawning)
- **Clear All Customers** - Remove all active customers instantly

**Use Cases:**
- Test customer AI pathfinding
- Stress test with many simultaneous customers
- Test register checkout flow
- Clear stuck customers during testing

**Notes:**
- Spawning works even outside BUSINESS phase (for testing)
- Customer spawn requires navigation targets to be set (should be automatic in bakery scene)

---

### ⏰ Time Tab
**Purpose:** Control time scale, phases, and day progression

**Features:**
- **Current State Display**
  - Current Day
  - Current Phase
  - Current Time Scale
- **Time Scale Controls**
  - Pause (0x speed)
  - 1x (normal speed)
  - 2x (double speed)
  - 3x (triple speed)
- **Phase Controls**
  - **Skip to Next Phase** - Advance through the cycle
  - **Set Specific Phase**
    - Set: BAKING
    - Set: BUSINESS
    - Set: CLEANUP
    - Set: PLANNING
- **Day Controls**
  - **Advance to Next Day** - Skip to Day 2, Day 3, etc.
  - **Set Specific Day** - Jump to any day number (1-999)

**Use Cases:**
- Test phase transitions
- Test day cycle completion
- Speed through slow game sections
- Test milestone unlocks tied to days
- Test save/load at different days

---

### 🛠️ Utilities Tab
**Purpose:** Save/load and debug tools

**Features:**
- **Save/Load**
  - Quick Save
  - Quick Load
- **Debug**
  - Print Debug Info to Console (prints full game state)
- **Info Panel** - Instructions for using the dev menu

**Use Cases:**
- Create save states for specific test scenarios
- Load save to reset to known state
- Debug game state issues
- Print inventory/economy/customer data

---

## Tips & Best Practices

### Efficient Testing Workflow
1. **Open dev menu** (backtick)
2. **Set up test scenario:**
   - Add money (Economy tab)
   - Fill ingredients (Inventory tab)
   - Set phase to BUSINESS (Time tab)
3. **Execute test** (close menu, interact with game)
4. **Quick Save** before risky operations
5. **Quick Load** to retry scenarios

### Common Test Scenarios

**Testing Recipe Crafting:**
1. Inventory tab → Fill All Ingredients
2. Time tab → Set BAKING phase
3. Test mixing bowl and oven

**Testing Customer Flow:**
1. Inventory tab → Add finished products x5 each
2. Equipment → Stock display case manually
3. Time tab → Set BUSINESS phase
4. Customers tab → Spawn 5 customers
5. Test register checkout

**Testing Economy Balance:**
1. Economy tab → Set Cash to $50
2. Test ingredient ordering in Planning phase
3. Track profit margins

**Testing Phase Transitions:**
1. Time tab → Speed 3x
2. Watch phase auto-transitions
3. Use Skip Phase to bypass delays

**Stress Testing:**
1. Customers tab → Spawn 20+ customers
2. Economy tab → Set very low cash
3. Test edge cases and errors

---

## Keyboard Shortcuts
- **\`** (Backtick) - Toggle dev menu
- **ESC** - Close dev menu (same as Close button)

---

## Notes for Expansion

As you add new systems to the game, expand the dev menu with:
- **Staff tab** - Hire/fire staff instantly
- **Reputation tab** - Set reputation values
- **Unlocks tab** - Toggle recipe/equipment unlocks
- **Events tab** - Trigger special events
- **Stats tab** - View detailed analytics

The dev menu is designed to grow with your game's systems. Add new tabs and controls as needed!

---

## Implementation Details
- **Location:** [scenes/ui/dev_menu.tscn](scenes/ui/dev_menu.tscn)
- **Script:** [scripts/ui/dev_menu.gd](scripts/ui/dev_menu.gd)
- **Integration:** Automatically added to [bakery.tscn](scenes/bakery/bakery.tscn)
- **Pause Behavior:** Game pauses when menu is open
- **Input Handling:** Uses `_input()` to catch backtick key globally

---

## Testing the Dev Menu

### First Test (F6 - Run Current Scene)
1. Open [bakery.tscn](scenes/bakery/bakery.tscn) in Godot
2. Press **F6** to run the scene
3. Press **\`** to open dev menu
4. Test each tab's buttons
5. Check console for debug output

### Full Test (F5 - Run Project)
1. Press **F5** to run full project
2. Navigate to bakery
3. Press **\`** to open dev menu
4. Test all features in live gameplay

### What to Verify
- ✅ Menu opens/closes with backtick
- ✅ Game pauses when menu opens
- ✅ Money adds correctly (check HUD)
- ✅ Inventory items appear (check inventory system)
- ✅ Customers spawn (visual confirmation)
- ✅ Time scale changes (watch game speed)
- ✅ Phase changes work (check HUD phase display)
- ✅ Save/load functions work
- ✅ All buttons trigger console output

---

**Ready to test!** Press **F5** in Godot to run the game and press **\`** to open your new developer menu!
