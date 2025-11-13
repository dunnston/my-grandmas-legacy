# Claude Context - My Grandma's Legacy

## Project Overview
**Game:** My Grandma's Legacy
**Genre:** Cozy 3D Bakery Management Simulation
**Engine:** Godot 4.5
**Language:** GDScript

This is a cozy bakery management game where players inherit their grandmother's rundown bakery and restore it to its former glory through baking, customer service, and strategic upgrades.

---

## Critical Development Guidelines

### Technology Stack
- **DO NOT use npm, node, or JavaScript-related tools** - This is Godot, not web development
- Use GDScript for all scripting
- Use Godot's built-in systems (signals, autoloads, resources)
- Test in Godot editor using **F5** (run project) or **F6** (run current scene)
- Use Godot's built-in debugger and print() statements for debugging

### Development Philosophy
1. **Gameplay First, Art Later**
   - Start with CSG shapes and primitives for all visual elements
   - Focus on making mechanics fun before adding polish
   - Replace placeholders with proper assets only after gameplay is proven

2. **Iterative Development**
   - Test frequently in editor (F5/F6)
   - Get each phase working before moving to next
   - Use print() debug statements liberally during development

3. **Version Control Workflow**
   - **NEVER commit directly to main branch**
   - Main branch is production-ready code only
   - Create feature branch for each development phase: `phase-X-feature-name`
   - Commit frequently to feature branches
   - Merge to main only when phase is complete and tested

---

## Project Documentation

### Key Documents (Read Only When Needed)
To minimize token usage, only read these documents when directly relevant to the current task:

- **[GDD.md](GDD.md)** - Complete Game Design Document
  - Read when: Implementing new features, checking design specs, clarifying mechanics
  - Contains: Full game design, all systems, recipes, progression, story beats

- **[PLAN.md](PLAN.md)** - Dynamic Development Plan
  - Read when: Starting new phase, checking current tasks, updating progress
  - Contains: Phase-based breakdown, task checklists, success criteria, timeline

**Important:** Don't read these files in every conversation. Ask the user if you need clarification, or read only the specific section you need.

---

## Project Structure

### Recommended Directory Organization
```
my-grandmas-legacy/
├── scenes/
│   ├── main.tscn                    # Entry point
│   ├── bakery/
│   │   ├── bakery.tscn              # Main gameplay scene
│   │   ├── apartment.tscn           # Upstairs apartment
│   │   └── equipment/               # Ovens, mixers, etc.
│   ├── player/
│   │   └── player.tscn              # Player character
│   ├── customers/
│   │   └── customer.tscn            # Customer AI
│   └── ui/
│       ├── hud.tscn                 # In-game HUD
│       ├── crafting_ui.tscn         # Crafting interface
│       └── planning_menu.tscn       # Planning phase UI
├── scripts/
│   ├── autoload/                    # Singleton scripts
│   │   ├── game_manager.gd          # Phase management, day cycle
│   │   ├── inventory_manager.gd     # Player/station inventories
│   │   ├── customer_manager.gd      # Spawning, traffic
│   │   ├── progression_manager.gd   # Unlocks, milestones
│   │   ├── economy_manager.gd       # Money, prices
│   │   ├── recipe_manager.gd        # Recipe data
│   │   ├── staff_manager.gd         # Employee management
│   │   └── event_manager.gd         # Special events
│   ├── player/
│   ├── equipment/
│   ├── customer/
│   └── ui/
├── resources/
│   ├── recipes/                     # Recipe resource files (.tres)
│   ├── ingredients/                 # Ingredient data
│   ├── equipment/                   # Equipment definitions
│   └── staff/                       # Staff definitions
├── assets/                          # (Add later, start with CSG)
│   ├── models/
│   ├── textures/
│   └── audio/
├── GDD.md                           # Game Design Document
├── PLAN.md                          # Development Plan
└── CLAUDE.md                        # This file
```

---

## Development Phases

### Current Phase: Phase 1 - Core Prototype
**Branch:** `phase-1-core-prototype`
**Goal:** Prove core baking loop is fun
**Focus:** Player movement, ingredient system, mixing bowl, oven, display case, time controls

### Upcoming Phases
1. ✅ Phase 1: Core Prototype (2-3 weeks)
2. ⏳ Phase 2: Business & Economy (3-4 weeks)
3. ⏳ Phase 3: Progression Systems (4-5 weeks)
4. ⏳ Phase 4: Polish & Content (6-8 weeks)
5. ⏳ Phase 5: Juice & Audio (3-4 weeks)
6. ⏳ Phase 6: Balance & Testing (2-3 weeks)

See [PLAN.md](PLAN.md) for detailed task breakdowns.

---

## Core Game Systems (Reference)

### Daily Cycle (4 Phases)
1. **Baking Phase** - Craft goods for the day
2. **Business Phase** - Serve customers, make sales
3. **Cleanup Phase** - Prepare for next day
4. **Planning Phase** - Order supplies, hire staff, upgrades

### Key Mechanics
- **Hands-on Crafting:** Multi-step baking process (gather → mix → bake → cool → display)
- **Time Management:** Pause, 1x, 2x, 3x speed controls
- **Customer Satisfaction:** Product quality, availability, price, wait time, ambiance
- **Progression:** Milestone-based unlocks tied to total revenue
- **Economy:** Ingredient costs, pricing strategy, upgrade investments
- **Staff:** Hire bakers, cashiers, cleaners to automate tasks

---

## Technical Notes

### Godot 4.5 Specific
- Use CharacterBody3D for player and customers
- Use NavigationAgent3D for customer pathfinding
- Use CSGShape3D nodes for placeholder geometry
- Autoload singletons for managers (Project Settings → Autoload)
- Use Resources (.tres) for data (recipes, ingredients, staff)
- Save system: JSON files in `user://` directory

### Scene Management
- Main.tscn: Entry point, loads Bakery scene
- Bakery.tscn: Primary gameplay, contains all equipment and interaction points
- Player.tscn: Instanced in Bakery scene
- Apartment.tscn: Optional, connects to Bakery via stairs

### Signal Architecture
- Equipment emits signals when crafting complete
- GameManager broadcasts phase changes
- UI listens to manager signals for updates
- Avoid tight coupling between systems

---

## Common Tasks Reference

### Adding a New Recipe
1. Add to `RecipeManager` using `register_recipe()` with base values
2. Define ingredients array, mixing_time, baking_time, base_price
3. **If using new ingredients:** Add prices to `balance_config.gd` ECONOMY.ingredient_prices
4. (Optional) Add recipe reference to `balance_config.gd` RECIPES.recipes
5. Associate with unlock milestone in ProgressionManager
6. Test crafting workflow and profitability in editor
7. **See "Balance System" section below for full details**

### Adding Equipment
1. Create scene in `scenes/bakery/equipment/`
2. Use CSG shapes for placeholder visual
3. Add interaction area (Area3D)
4. Create associated script with crafting logic
5. Connect to InventoryManager for item transfer

### Testing Workflow
1. Press F5 to run full project
2. Press F6 to run current scene (faster iteration)
3. Use print() to debug state
4. Check debugger for errors/warnings
5. Test edge cases (empty inventory, etc.)

---

## Balance System (IMPORTANT!)

### Overview
All game balance parameters are centralized in `scripts/autoload/balance_config.gd`. This file contains 200+ tweakable values that control timing, economy, progression, and gameplay feel.

**Key Documents:**
- `scripts/autoload/balance_config.gd` - Central balance configuration (edit this to tweak balance)
- `BALANCE_ANALYSIS.md` - Comprehensive analysis of current balance state
- `BALANCE_QUICKSTART.md` - Quick reference for common tweaks

### How the Balance System Works

The system uses **automatic multipliers** that apply when content is registered:

```gd
# In balance_config.gd
RECIPES = {
    "mixing_time_multiplier": 1.0,      # Affects ALL recipes automatically
    "baking_time_multiplier": 0.5,      # Makes all baking 2x faster
    "price_multiplier_global": 1.5,     # Makes all recipes 50% more expensive
}
```

When you add a recipe to `recipe_manager.gd`, these multipliers apply automatically. You don't need to update balance_config.gd unless you want to tweak individual values.

### When Adding New Recipes

#### Required Steps:
1. Add recipe to `recipe_manager.gd` using `register_recipe()` (as usual)
2. Set base values (mixing_time, baking_time, base_price)
3. **That's it!** Multipliers apply automatically

#### Optional Step:
Add recipe reference to `balance_config.gd` for documentation:
```gd
# In balance_config.gd RECIPES.recipes section (~line 130-250)
"your_new_recipe": {
    "mixing_time": 60.0,
    "baking_time": 300.0,
    "base_price": 25.0,
},
```

**Why optional?** The recipe works without this. Adding it:
- Documents all recipes in one place
- Allows the `get_recipe_price()` helper to calculate tier multipliers
- Makes balance testing easier

#### Example:
```gd
# In recipe_manager.gd
register_recipe({
    "id": "pain_au_chocolat",
    "name": "Pain au Chocolat",
    "ingredients": {"flour": 2, "butter": 2, "chocolate": 1},
    "mixing_time": 90.0,          # Will be × mixing_time_multiplier
    "baking_time": 360.0,         # Will be × baking_time_multiplier
    "base_price": 28.0,           # Will be × price multipliers
})
```

### When Adding New Ingredients

#### Required Steps:
1. Add price to `balance_config.gd` ECONOMY.ingredient_prices (~line 46-85):
```gd
"ingredient_prices": {
    "flour": 2.0,
    # ... existing ingredients ...
    "dark_chocolate": 8.0,     # ADD THIS for new ingredient
    "pistachios": 10.0,        # ADD THIS for new ingredient
}
```

2. (Optional) Add starting stock to STARTING_RESOURCES (~line 505-530):
```gd
"dark_chocolate": 5,           # Players start with 5 units
```

**Why required?** `EconomyManager` loads prices from BalanceConfig on startup. Missing ingredients will have $0 cost, breaking the economy!

### When Adding New Equipment/Upgrades

#### Required Steps:
Add costs and stats to `balance_config.gd` EQUIPMENT section (~line 389-450):
```gd
EQUIPMENT = {
    # ... existing equipment ...

    "decorating_station_cost": 1500.0,
    "decorating_station_unlock": 5000.0,
    "decorating_station_quality_bonus": 5,
}
```

Then in your equipment script:
```gd
func _ready():
    upgrade_cost = BalanceConfig.EQUIPMENT.decorating_station_cost
    quality_bonus = BalanceConfig.EQUIPMENT.decorating_station_quality_bonus
```

### When Adding New Game Systems

For new managers or major systems:

1. **Add config section** to `balance_config.gd`:
```gd
const YOUR_SYSTEM = {
    "base_value": 50.0,
    "decay_rate": 2.0,
    "max_threshold": 100,
}
```

2. **Load in your manager** script:
```gd
func _ready():
    base_value = BalanceConfig.YOUR_SYSTEM.base_value
    decay_rate = BalanceConfig.YOUR_SYSTEM.decay_rate
```

3. **Document** in BALANCE_ANALYSIS.md (add new section with parameter table)

### Balance System Maintenance Checklist

Use this checklist when adding content:

**Adding a Recipe:**
- [ ] Add to `recipe_manager.gd` with `register_recipe()`
- [ ] Test that multipliers apply (check in-game prices/times)
- [ ] (Optional) Add to `balance_config.gd` RECIPES.recipes for reference

**Adding an Ingredient:**
- [ ] Add price to `balance_config.gd` ECONOMY.ingredient_prices
- [ ] (Optional) Add starting stock to STARTING_RESOURCES
- [ ] Test that recipes using it calculate cost correctly

**Adding Equipment:**
- [ ] Add cost/stats to `balance_config.gd` EQUIPMENT
- [ ] Update equipment script to load from BalanceConfig
- [ ] Add unlock threshold if progression-gated

**Adding New System:**
- [ ] Create const section in `balance_config.gd`
- [ ] Load values in system's `_ready()` function
- [ ] Document in BALANCE_ANALYSIS.md

### Common Mistakes to Avoid

❌ **Forgetting ingredient prices**
```gd
# recipe_manager.gd - added new ingredient
"ingredients": {"saffron": 2}

# Forgot to add to balance_config.gd!
# Result: Saffron costs $0, recipe is too profitable
```

✅ **Always add ingredient price:**
```gd
# balance_config.gd
"saffron": 15.0,
```

❌ **Hardcoding values that should scale**
```gd
var upgrade_cost = 2000.0  # Bad: can't balance easily
```

✅ **Load from BalanceConfig:**
```gd
var upgrade_cost = BalanceConfig.EQUIPMENT.oven_tier_1_cost
```

❌ **Updating individual recipe times instead of multiplier**
```gd
# Changing 27 recipes individually = tedious
"white_bread": { "baking_time": 150.0 }
"cookies": { "baking_time": 90.0 }
# ...
```

✅ **Use global multiplier:**
```gd
"baking_time_multiplier": 0.5  # One line affects all recipes
```

### Quick Balance Testing

After adding content, test:

1. **Run game** (F5)
2. **Check profitability** - New recipe should make profit at normal quality
3. **Check timing** - Recipe should complete within business day at 1x speed
4. **Check prices** - Compare to similar-tier recipes

If values feel off:
1. Open `balance_config.gd`
2. Adjust individual recipe values or multipliers
3. Press F5 to test
4. Repeat until balanced

### Balance System Philosophy

**The Goal:** Make balancing easy by centralizing all numbers in one place.

**Best Practices:**
- Use **global multipliers** for mass changes (all recipes faster/cheaper)
- Use **tier multipliers** for category changes (just starter recipes cheaper)
- Use **individual values** for fine-tuning specific recipes
- **Document changes** with comments explaining why
- **Test frequently** - balance changes can have cascading effects

**Workflow:**
```
New Content → Hardcode initially → Test → Stabilize → Move to BalanceConfig
Balance Tweaks → Edit BalanceConfig → Test → Iterate → Commit when good
```

---

## Git Workflow Reminder

### Creating a Feature Branch
```bash
git checkout -b phase-X-feature-name
```

### Committing Changes
```bash
git add .
git commit -m "Descriptive commit message"
```

### When Phase Complete
```bash
# Test thoroughly first!
git checkout main
git merge phase-X-feature-name
git push origin main
```

### Never Do This
```bash
git checkout main
git commit -m "..."  # ❌ NO! Don't commit to main directly
```

---

## Quick Reference

### Key Bindings (Default)
- WASD: Move
- Mouse: Look
- E: Interact
- ESC: Pause menu
- Tab: Quick inventory
- F5: Run project
- F6: Run current scene

### Starting Values (from GDD)
- Starting cash: $200
- Starting reputation: 50
- Starter recipes: White Bread, Cookies, Muffins
- Day length: 30 minutes real-time (adjustable with time scale)

### Milestone Revenue Targets
- $500: Basic Pastries unlock
- $2,000: Artisan Breads unlock
- $5,000: Special Occasion Cakes + letter
- $10,000: Grandma's Secret Recipes + decorating station
- $25,000: International Treats + expansion
- $50,000: Legendary Bakes + ending

---

## Communication Guidelines

When working with Claude on this project:

1. **Be Specific About Phase** - Mention which phase/task you're working on
2. **Reference PLAN.md** - "I'm working on Phase 1, task X"
3. **Test Frequently** - Run in editor after each feature
4. **Commit Often** - Small, focused commits on feature branch
5. **Ask for Clarification** - If GDD is unclear, ask before implementing

---

## Important Reminders

- ✅ Use CSG shapes for everything initially
- ✅ Test in Godot editor (F5/F6), not command line
- ✅ Use feature branches, never commit to main
- ✅ Refer to GDD.md for design details (but don't read entire file every time)
- ✅ Update PLAN.md checkboxes as tasks complete
- ✅ **Add new ingredient prices to balance_config.gd** when adding recipes
- ✅ **Use BalanceConfig for all tweakable numbers** (don't hardcode)
- ❌ Don't use npm, node, or web dev tools
- ❌ Don't add art assets until gameplay is proven
- ❌ Don't skip testing phases
- ❌ Don't forget to update balance_config.gd when adding content

---

**Current Focus:** Get Phase 1 working - one complete baking loop that feels good to play!
