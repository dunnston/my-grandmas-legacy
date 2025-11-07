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
1. Create recipe resource file in `resources/recipes/`
2. Define ingredients array, times, prices
3. Add to RecipeManager's recipe dictionary
4. Associate with unlock milestone in ProgressionManager
5. Test crafting workflow in editor

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
- ❌ Don't use npm, node, or web dev tools
- ❌ Don't add art assets until gameplay is proven
- ❌ Don't skip testing phases

---

**Current Focus:** Get Phase 1 working - one complete baking loop that feels good to play!
