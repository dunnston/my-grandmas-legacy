# Staff Movement System - Implementation Status

## Overview
Implemented realistic staff movement and animations where staff walk between workstations and perform visible tasks.

---

## ✅ COMPLETED: Cashier Movement System

### Features Implemented:
1. **State Machine** with 5 states:
   - `IDLE` - Standing at register, checking for customers
   - `WALKING_TO_DISPLAY` - Walking to display case to get items
   - `GATHERING_ITEMS` - Standing at display, gathering items (2 seconds)
   - `WALKING_TO_REGISTER` - Walking back to register with items
   - `CHECKING_OUT` - Processing payment at register

2. **Navigation & Pathfinding**:
   - Uses NavigationAgent3D for collision avoidance
   - Smooth movement with speed based on staff skill multiplier
   - Rotates to face movement direction
   - Proper arrival detection

3. **Animations**:
   - Walks when moving between stations
   - Stands idle when gathering items or processing payments
   - Automatically switches animations based on state

### How It Works:
- Cashier starts at register in IDLE state
- When customer arrives, cashier walks to display case
- Cashier stands at display gathering items (animated idle)
- Cashier walks back to register
- Cashier processes payment (animated idle)
- Returns to IDLE, waiting for next customer

---

## ⏳ TODO: Baker Movement System

### Planned States:
1. `IDLE` - Standing, checking for recipes to make
2. `WALKING_TO_CABINET` - Walking to ingredient storage
3. `GATHERING_INGREDIENTS` - Standing at cabinet, getting ingredients
4. `WALKING_TO_MIXER` - Walking to mixing bowl
5. `MIXING` - Standing at mixer, mixing ingredients
6. `WALKING_TO_OVEN` - Walking to oven with mixed dough
7. `LOADING_OVEN` - Placing items in oven
8. `WAITING_FOR_BAKE` - Idle waiting for oven to finish
9. `WALKING_TO_OVEN_UNLOAD` - Walking to finished oven
10. `UNLOADING_OVEN` - Taking finished goods from oven
11. `WALKING_TO_COOLING_RACK` - Walking to cooling area
12. `PLACING_ON_RACK` - Placing finished goods on rack

### Implementation Notes:
- Baker AI already exists in `scripts/staff/baker_ai.gd`
- Currently performs tasks invisibly (no movement)
- Needs same treatment as cashier: states, navigation, animation
- Should find: ingredient cabinets, mixing bowls, ovens, cooling racks

---

## ⏳ TODO: Cleaner Movement System

### Planned States:
1. `IDLE` - Standing, checking for cleanup tasks
2. `WALKING_TO_SINK` - Walking to dirty dishes
3. `WASHING_DISHES` - Standing at sink, washing dishes
4. `WALKING_TO_TRASH` - Walking to trash that needs emptying
5. `EMPTYING_TRASH` - Standing at trash, emptying it
6. `WALKING_TO_FLOOR` - Walking to dirty floor area
7. `MOPPING` - Standing, cleaning floor
8. `WALKING_BACK` - Returning to idle position

### Implementation Notes:
- Cleaner AI already exists in `scripts/staff/cleaner_ai.gd`
- Currently performs tasks invisibly (no movement)
- Needs states, navigation, and animation
- Should find: sinks, trash cans, dirty floor markers

---

## Technical Implementation Details

### Core Systems:
1. **Character Control** - AI has reference to visual Node3D character
2. **Navigation** - Uses existing NavigationAgent3D from customer scene
3. **Animation** - Controls AnimationPlayer (walk/idle)
4. **Equipment Finding** - Searches scene for workstations by name

### Key Functions (all AI types need these):
```gdscript
func set_character(p_character: Node3D) -> void
func _navigate_towards(target_pos: Vector3, delta: float) -> void
func _is_at_position(target_pos: Vector3) -> bool
func _set_animation(anim_name: String, playing: bool) -> void
```

### Integration with StaffManager:
- `staff_manager.gd` creates visual character
- Passes character reference to AI via `set_character()`
- AI controls movement, StaffManager just spawns/despawns

---

## Testing Instructions

### Test Cashier:
1. Hire a cashier during Planning Phase
2. Start Business Phase
3. Wait for customer to arrive at register
4. **Expected behavior:**
   - Cashier walks to display case
   - Stands idle gathering items (2 seconds)
   - Walks back to register
   - Stands idle processing payment
   - Customer leaves, cashier returns to idle at register

### Test Baker (once implemented):
1. Hire a baker during Planning Phase
2. Queue a recipe in crafting system
3. Start Baking Phase
4. **Expected behavior:**
   - Baker walks to ingredient cabinet
   - Stands gathering ingredients
   - Walks to mixing bowl
   - Stands mixing
   - Walks to oven
   - Stands loading oven
   - (Repeat for each recipe)

### Test Cleaner (once implemented):
1. Hire a cleaner during Planning Phase
2. Create dirty dishes/trash during gameplay
3. Start Cleanup Phase
4. **Expected behavior:**
   - Cleaner walks to sink
   - Stands washing dishes
   - Walks to trash can
   - Stands emptying trash
   - Returns to idle position

---

## Known Limitations

1. **Baker/Cleaner Not Yet Implemented**
   - Currently still use old invisible AI system
   - No visual movement yet
   - Need full state machine like cashier

2. **Simple Navigation**
   - Uses direct pathfinding
   - No fancy behaviors (carrying items visually, etc.)
   - Good enough for placeholder phase

3. **Animation Assumptions**
   - Assumes customer scene has "walk" animation
   - Idle is just stopping the animation
   - Could be enhanced with proper idle animations later

---

## Next Steps

**Immediate (for full staff movement):**
1. Implement baker state machine with equipment navigation
2. Implement cleaner state machine with task navigation
3. Test all three roles end-to-end

**Polish (later):**
1. Add carrying animations (holding items while walking)
2. Add equipment interaction animations (pouring, stirring, etc.)
3. Add particle effects (steam from oven, water splashes at sink)
4. Add sound effects for each action

---

## File Changes Made

**Modified:**
- `scripts/staff/cashier_ai.gd` - Full rewrite with state machine
- `scripts/autoload/staff_manager.gd` - Passes character reference to AI

**To Be Modified:**
- `scripts/staff/baker_ai.gd` - Needs state machine implementation
- `scripts/staff/cleaner_ai.gd` - Needs state machine implementation

---

## Performance Notes

- Staff movement uses delta-based updates (efficient)
- NavigationAgent3D handles pathfinding (built-in Godot system)
- Only active staff consume CPU (deactivated when not in their phase)
- Should easily handle 3-5 staff members simultaneously

