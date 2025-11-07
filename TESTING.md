# Testing Guide - Phase 1: Core Prototype

## How to Run

1. Open the project in Godot 4.5
2. Press **F5** to run the project (or click the Play button)
3. The Bakery scene will load automatically

## Controls

- **WASD** - Move around
- **Mouse** - Look around (camera)
- **E** - Interact with equipment
- **Shift** - Sprint
- **ESC** - Release/capture mouse cursor

## Testing the Complete Baking Loop

Follow these steps to test the full workflow:

### 1. Get Ingredients (Ingredient Storage)
- Walk to the **brown cabinet** (back-left corner of bakery)
- Look for the "[E] to get Ingredients" prompt
- Press **E** to take ingredients
- The console will show you received: 2x flour, 1x water, 1x yeast
- Check the console output to see your inventory

### 2. Mix Dough (Mixing Bowl)
- Walk to the **white sphere on counter** (second station from left)
- Press **E** to interact
- The system will check if you have ingredients
- If you do, mixing starts automatically (60 second timer)
- Console shows mixing progress
- After 60 seconds, you'll receive "bread_dough"

### 3. Bake Bread (Oven)
- Walk to the **gray metal box** (third station)
- Press **E** to interact
- The system detects bread_dough and loads it automatically
- Baking takes 300 seconds (5 minutes game time)
- Oven glows orange while baking
- Press **E** again to check progress
- After 5 minutes, you receive "bread"

### 4. Stock Display Case (Display Case)
- Walk to the **glass display case** (rightmost station)
- Press **E** to interact
- Your finished bread is automatically stocked in the display
- Console shows display case contents

### 5. Repeat!
- Go back to Ingredient Storage (it auto-restocks for testing)
- Complete the loop multiple times to verify everything works

## Expected Console Output

When you complete a full loop, you should see:
```
GameManager initialized
InventoryManager initialized
Starting Day 1 - Phase: BAKING
Player ready
IngredientStorage ready: IngredientStorage
MixingBowl ready: MixingBowl
Oven ready: Oven
DisplayCase ready: DisplayCase

[At Storage]
=== INGREDIENT STORAGE ===
Available ingredients:
=== Inventory: ingredient_storage_IngredientStorage ===
  flour: 10
  water: 10
  yeast: 10
...
Took 2x flour
Took 1x water
Took 1x yeast

[At Mixing Bowl]
=== MIXING BOWL ===
Recipe: Bread Dough
You have all ingredients! Starting to mix...
Started mixing bread_dough! Wait 60 seconds...

[After 60 seconds]
Mixing complete! bread_dough is ready!
Added 1x bread_dough to player

[At Oven]
=== OVEN ===
You can bake: bread_dough -> bread
Loading bread_dough into oven...
Started baking bread_dough!
Baking time: 300 seconds

[After 300 seconds]
=== DING! ===
Baking complete! bread is ready!
Added 1x bread to player

[At Display Case]
=== DISPLAY CASE ===
Stocking 1x bread in display case...
Successfully stocked 1x bread
```

## What to Look For

### Movement & Camera
- ✅ Player moves smoothly with WASD
- ✅ Camera follows player and rotates with mouse
- ✅ Camera doesn't clip through walls
- ✅ Sprint (Shift) makes player move faster

### Interactions
- ✅ "[E] to..." prompts appear when near equipment
- ✅ Pressing E triggers the correct interaction
- ✅ Console output shows what's happening

### Crafting Flow
- ✅ Ingredients transfer from storage to player
- ✅ Mixing bowl checks for required ingredients
- ✅ Mixing timer counts down (60 seconds)
- ✅ Dough appears in player inventory after mixing
- ✅ Oven detects bread dough and starts baking
- ✅ Oven glows orange while baking
- ✅ Baking timer counts down (300 seconds)
- ✅ Bread appears in inventory after baking
- ✅ Display case stocks the finished bread

### Time System
- ✅ GameManager starts on Day 1
- ✅ Phase is set to BAKING
- ✅ Timers respect time scale (currently 1x)

## Known Phase 1 Limitations

These are **intentional** and will be addressed in later phases:

- ❌ No graphical UI (all console-based for now)
- ❌ No visual progress bars on equipment
- ❌ No customer system yet (Phase 2)
- ❌ No business phase yet (Phase 2)
- ❌ No time controls (pause/speed) implemented yet
- ❌ No HUD/UI overlay yet
- ❌ Only one recipe (bread)
- ❌ Unlimited ingredients (for testing)
- ❌ Equipment is very basic (CSG shapes)
- ❌ No audio/sound effects

## Debug Tips

### View All Inventories
The console automatically prints inventories when you interact with stations.

### Check for Errors
- Red errors in the Godot console indicate problems
- Yellow warnings are usually okay
- Look for "Error:" messages in console output

### Reset the Scene
- Press **F5** again to reload and start fresh
- Or close and reopen the game

## Success Criteria for Phase 1

✅ **Phase 1 is complete when:**
1. Player can move around the bakery smoothly
2. Player can interact with all 4 stations
3. Complete bread workflow works: Storage → Mix → Bake → Display
4. Timers work correctly (mixing = 60s, baking = 300s)
5. Inventory transfers work (ingredients → player → stations → results)
6. No critical errors or crashes

## Next Steps (Phase 2)

Once Phase 1 is validated, Phase 2 will add:
- Customer system (NPCs walking in, browsing, buying)
- Business phase (shop open hours, sales, money)
- End-of-day report
- Planning phase menu
- Save/load system
- 3 starter recipes (bread, cookies, muffins)

---

**Happy Baking! Report any issues you find.** 🍞
