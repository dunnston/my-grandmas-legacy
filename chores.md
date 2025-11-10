CLEANING CHORES
1. Wash Dishes (Sink)

Dirty dishes pile visible in/near sink
Hold [E] with progress bar
Switch to clean, empty sink model
Particle effect: water splashing, soap bubbles

2. Sweep Floor

Floor has dirt/crumbs decal/texture overlay
Hold [E] near broom (or broom appears in player hand)
Progress bar fills as player "sweeps" area
Dirt decal fades/disappears when complete
Could have multiple floor zones to sweep

3. Wipe Counters

Counter has dirty texture/decal (flour dust, spills)
Hold [E] at counter
Progress bar completes
Counter switches to clean texture

4. Mop Floor

Similar to sweep but for "wet spills" or sticky areas
Different decal type (puddles, sticky spots)
Hold [E] with mop
Decal fades away

5. Clean Display Case Glass

Display case has "smudged" glass material/texture
Hold [E] on display case
Progress bar
Glass becomes crystal clear (material swap or alpha adjustment)

6. Wipe Tables (if you add customer seating)

Tables have crumb/spill decals
Hold [E] at each table
Decal disappears


MAINTENANCE CHORES
7. Restock Display Case

Empty or low display case slots
Player holds baked goods in inventory
Hold [E] at display case to restock
Items appear on shelves as progress bar fills

8. Empty Grease Trap (for ovens)

Oven has "needs cleaning" indicator (red light, smoke, dirty texture)
Hold [E] at oven
Progress bar
Oven returns to clean state, efficiency restored

9. Replace Trash Bag

After emptying trash (your original idea)
Second interaction: Hold [E] to put new bag in
Visual: trash can liner appears

10. Refill Ingredient Bins

Ingredient containers show "low" or "empty" state
Player must have ingredients in storage
Hold [E] to transfer from storage to active bins
Container fills visually

11. Organize Storage/Pantry

Storage area becomes "messy" over time (boxes askew, items scattered)
Hold [E] in storage zone
Progress bar
Items snap to organized grid positions

12. Check/Reset Mouse Traps (adds character!)

Occasionally a mouse trap needs checking
Hold [E] on trap
Either: "Empty - reset" or "Caught mouse - dispose and reset"
Adds cozy/rustic bakery charm


PREP WORK CHORES
13. Grind Coffee Beans (if you sell coffee)

Coffee grinder with beans visible
Hold [E] to grind
Progress bar
Ground coffee appears in container

14. Chop Ingredients for Tomorrow

Cutting board with whole ingredients (fruits, nuts)
Hold [E] to prep
Ingredients change to "chopped" state

15. Mix Butter to Room Temperature

Butter in "cold/hard" state (needs softening for tomorrow)
Hold [E] at prep counter
Butter becomes "softened" state for next day

16. Proof Dough Overnight (if making sourdough/specialty breads)

Place dough in proofing area
Hold [E] to cover and set aside
Dough ready for tomorrow's baking phase


AESTHETIC/OPTIONAL CHORES
17. Water Plants

Decorative plants become "wilted" after several days
Hold [E] with watering can
Plants perk up (model swap or animation)

18. Wind Grandfather Clock (if you have one for atmosphere)

Clock stops after several days
Hold [E] to wind
Clock pendulum swings again, chimes

19. Replace Light Bulbs

Occasionally a light flickers or goes out
Hold [E] near light fixture
Light returns to full brightness

20. Refill Hand Soap/Paper Towels (bathroom maintenance if you add one)

Dispenser shows "empty"
Hold [E] to refill
Dispenser looks full again


IMPLEMENTATION SUGGESTIONS
Chore Priority System:

Critical (Red): Affects customer satisfaction (dirty floor, full trash, no clean dishes)
Important (Yellow): Affects efficiency (dirty oven, messy storage)
Optional (Green): Aesthetic only (plants, decorations)

Visual Indicators:

Exclamation point icon above dirty/broken items
Color-coded outlines when player looks at choreable items
Checklist in corner of screen during cleanup phase

Progression/Upgrades:

Dishwasher: Reduces dish-washing time
Roomba/Auto-Sweeper: Automatically sweeps overnight
Self-Cleaning Oven: Reduces maintenance frequency
Hire Cleaning Staff: Automates chores (but costs money)

Satisfaction Impact:
Clean Shop Bonus: +10% customer satisfaction
Dirty Shop Penalty: -20% customer satisfaction

Individual effects:
- Dirty floor: -5%
- Smudged display case: -3%
- Full trash: -2%
- Dirty tables: -5%
- Grimy counters: -3%
Time Management:

Each chore takes 3-10 seconds (progress bar)
Players must balance: thorough cleaning vs. prepping for next day
Can speed through some and hire staff for others later


MY TOP 5 RECOMMENDATIONS TO START:

Take Out Trash (your original idea) - Simple, universal
Wash Dishes - Directly tied to baking phase usage
Sweep Floor - Most visible to customers
Wipe Counters - Quick, satisfying
Clean Display Case Glass - Directly tied to sales area

These five give you variety without overwhelming, and all use the same hold-[E]-with-progress-bar interaction you designed. You can add more as you expand!

Want me to create a prompt for Claude Code to implement the chore system with these interactions?RetryRWhat is the best way to show the dirty dishes? Should I make a model that is full of dirty dishes or should I create dirty dish models and put them in the sink individualy?Great question! Here's my recommendation:

BEST APPROACH: Hybrid System
Use individual dish models, but spawn them in predefined positions
Here's why this is superior:
ADVANTAGES:

Scalable Visual Feedback

2 recipes baked = 2-3 dishes appear
10 recipes baked = sink overflowing with dishes
Player sees direct consequence of their baking activity


Reusable Assets

Same dish models used throughout bakery (on counters, in use, clean stack)
No need for multiple "full sink" variations
Can reuse: bowl, spoon, baking pan, measuring cup, plate models


Granular Progression

Progress bar could remove dishes one-by-one during cleaning
More satisfying visual feedback as sink empties
Player sees "almost done" vs "just started"


Performance Friendly

Only spawn what's needed (3-15 dishes typically)
Not rendering complex "full sink" mega-model
Easy LOD management




IMPLEMENTATION STRUCTURE
gdscript# Sink with predefined spawn points
@export var dish_spawn_points: Array[Marker3D] = []
var dirty_dishes: Array[Node3D] = []

func add_dirty_dish(dish_type: String):
    if dirty_dishes.size() >= dish_spawn_points.size():
        return # Sink full!
    
    var dish = DISH_SCENES[dish_type].instantiate()
    var spawn_point = dish_spawn_points[dirty_dishes.size()]
    
    dish.position = spawn_point.position
    dish.rotation = spawn_point.rotation + random_slight_rotation()
    add_child(dish)
    dirty_dishes.append(dish)

func clean_dishes_progress(progress: float):
    # Remove dishes as cleaning progresses
    var dishes_to_show = ceil(dirty_dishes.size() * (1.0 - progress))
    
    for i in range(dirty_dishes.size()):
        dirty_dishes[i].visible = (i < dishes_to_show)
```

---

## **VISUAL SETUP**

**In your sink scene:**
```
Sink (Node3D)
├── SinkModel (MeshInstance3D)
├── DirtyDishSpawnPoints (Node3D)
│   ├── SpawnPoint1 (Marker3D) - bottom of sink, left
│   ├── SpawnPoint2 (Marker3D) - bottom, center  
│   ├── SpawnPoint3 (Marker3D) - bottom, right
│   ├── SpawnPoint4 (Marker3D) - stacked on point 1
│   ├── SpawnPoint5 (Marker3D) - stacked on point 2
│   └── ... (10-15 total spawn points in realistic stacking pattern)
└── InteractionArea (Area3D)
```

---

## **DISH MODELS YOU'LL NEED**

**Essential (5 models):**
1. Mixing Bowl (large)
2. Baking Pan/Sheet
3. Measuring Cup
4. Wooden Spoon
5. Plate

**Optional (adds variety):**
6. Small Bowl
7. Whisk
8. Spatula
9. Muffin Tin
10. Rolling Pin

**Modeling Tips:**
- Low poly (200-500 tris each)
- Add slight "grime" texture variant for dirty state
- Random rotation when spawned makes it look natural
- Slight scale variation (0.95-1.05) adds realism

---

## **ALTERNATIVE APPROACHES** (and why they're less ideal)

### ❌ **Single "Full Sink" Model**
**Cons:**
- Need multiple models: empty, 1/4 full, 1/2 full, 3/4 full, overflowing
- Doesn't scale with actual baking activity
- Can't reuse assets elsewhere
- Less satisfying progression feedback

**When to use:** If performance is a huge concern and you need absolute minimum draw calls

---

### ❌ **Particle System of Dishes**
**Cons:**
- Dishes would look floaty/fake
- Hard to make look realistic
- Doesn't give tactile "these are real objects" feel

**When to use:** Never for this use case

---

### ✅ **Individual Models in Predefined Positions** (RECOMMENDED)
**Pros:**
- Realistic stacking/placement
- Scales with gameplay
- Reusable assets
- Satisfying visual progression
- Easy to implement

**Cons:**
- Need to set up spawn points (one-time work)
- Slightly more draw calls than single model (but negligible with low-poly)

---

## **BONUS: ENHANCED FEEDBACK**

**Make it even better:**

1. **Particle Effects During Cleaning**
   - Soap bubbles float up
   - Steam/water splashes
   - Dishes "sparkle" when clean

2. **Audio Feedback**
   - Clink/clatter when dishes spawn
   - Running water sound during cleaning
   - Satisfying "clean" chime when finished

3. **Progressive States**
```
   0-25% progress: All dishes visible + dirty
   25-50%: Some dishes fade out
   50-75%: Most dishes gone
   75-100%: Last few dishes vanish
   100%: Sparkling clean sink!

Overflow Mechanic

If more dishes than spawn points, start placing on counter nearby
Visual indicator: "Sink Full! Clean dishes to continue baking"




FINAL RECOMMENDATION
Start with 8-10 individual dish models spawned at predefined Marker3D positions in the sink.
This gives you:

✅ Realistic, scalable visuals
✅ Direct gameplay feedback
✅ Reusable assets
✅ Easy to implement
✅ Satisfying progression
✅ Good performance

You can always optimize later if needed, but this approach balances quality, flexibility, and development speed perfectly.