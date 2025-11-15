# STAR RATING & TASK SYSTEM

---

## **OVERVIEW**

Implement a 5-star progression system where the bakery earns stars (0.5 increments, 0 to 5 stars total = 10 half-stars) by completing specific tasks/quests. Stars unlock recipes, equipment, decorations, and story beats. This creates a clear progression path separate from money, guiding players on what to do next while gating content behind meaningful achievements rather than just grinding for cash.

---

## **1. STAR SYSTEM STRUCTURE**

### **Star Progression**

**Total Stars: 0 to 5 stars (10 half-star milestones)**

```
☆☆☆☆☆  (0 stars - Starting bakery)
★☆☆☆☆  (0.5 stars)
★★☆☆☆  (1 star)
★★★☆☆  (1.5 stars)
★★★☆☆  (2 stars)
★★★★☆  (2.5 stars)
★★★★☆  (3 stars)
★★★★★  (3.5 stars)
★★★★★  (4 stars)
★★★★★  (4.5 stars)
★★★★★★ (5 stars - Master bakery)
```

**Visual Representation:**
- Half-filled stars for .5 increments
- Gold/yellow for earned stars
- Gray/empty for unearned stars
- Prominent display on HUD and in menus

### **Dual Progression Systems**

**REPUTATION (0-100):**
- Short-term, fluctuating metric
- Based on daily customer satisfaction
- Affects traffic and customer tolerance
- Can go up and down

**STARS (0-5):**
- Long-term, permanent progression
- Based on completing specific tasks
- Unlocks content (recipes, equipment, story)
- Never decreases, only increases
- Guides player on what to do next

---

## **2. TASK/QUEST SYSTEM**

### **Task Structure**

Each task should have:

```gdscript
class_name BakeryTask
extends Resource

@export var task_id: String
@export var task_name: String
@export var task_description: String
@export var star_reward: float  # 0.5 per task
@export var required_star_level: float  # Unlocks at this star level
@export var task_category: String  # "baking", "customers", "business", "upgrades", "story"
@export var is_completed: bool = false
@export var progress_current: int = 0
@export var progress_required: int = 1

# Completion criteria
@export var completion_type: String  # "counter", "boolean", "collection"
@export var tracked_stat: String  # What to track (e.g., "happy_customers", "croissants_baked")

# Rewards beyond stars
@export var money_reward: int = 0
@export var unlocks: Array[String] = []  # Recipe IDs, equipment IDs, etc.
```

### **Task Categories**

**1. Customer Service Tasks**
- Serve X happy customers
- Achieve X% customer satisfaction for Y days
- Serve X customers in a single day
- Handle a rush (X customers within Y minutes)

**2. Baking Mastery Tasks**
- Bake X perfect quality items
- Bake X total items
- Bake X different recipes
- Achieve no burned items for X days
- Bake X legendary quality items

**3. Business Growth Tasks**
- Earn $X in a single day
- Earn $X total revenue
- Reach X reputation score
- Maintain X reputation for Y consecutive days
- Purchase X advertising campaigns

**4. Upgrade & Expansion Tasks**
- Purchase specific equipment (oven, display case, etc.)
- Fully clean the shop X times
- Place X decorations
- Unlock expansion (knock out wall)
- Upgrade equipment to tier X

**5. Recipe Mastery Tasks**
- Unlock X recipes total
- Bake all recipes in a category
- Master a specific recipe (bake it X times at perfect quality)

**6. Story Tasks**
- Read grandmother's letter
- Reach revenue milestone (triggers story)
- Special event completion (food critic, festival)
- Find hidden items in bakery (grandmother's mementos)

**7. Efficiency Tasks**
- Complete a full day in under X minutes
- Serve X customers with no errors
- Hire first employee
- Have staff at 100% morale
- Achieve 100% cleanliness for X days

**8. Special Challenges**
- Complete food critic visit successfully
- Win town festival competition
- Handle special bulk order
- Serve a VIP customer perfectly

---

## **3. STAR PROGRESSION ROADMAP**

### **☆☆☆☆☆ → ★☆☆☆☆ (0 to 0.5 Stars - Tutorial Phase)**

**Task 1: "First Steps"**
- Clean up the initial shop (complete all cleanup tasks once and repair all the broken things) 
- Star Reward: 0.5
- Unlocks: Tutorial completion, access to planning phase

**Goal:** Teach basic mechanics, make shop presentable

---

### **★☆☆☆☆ → ★★☆☆☆ (0.5 to 1 Star - Getting Started)**

**Task 2: "First Customers"**
- Serve 10 happy customers (any time frame)
- Star Reward: 0.5
- Unlocks: "Basic Pastries" recipe page (4 recipes)

**Goal:** Practice baking and serving, establish basic operation

---

### **★★☆☆☆ → ★★★☆☆ (1 to 1.5 Stars - Building Reputation)**

**Task 3: "Rising Reputation"**
- Reach 60 reputation score
- Star Reward: 0.5
- Unlocks: Standard Oven equipment, Grandmother's first letter (story)

**Goal:** Consistent quality over multiple days

---

### **★★★☆☆ → ★★★★☆ (1.5 to 2 Stars - Expansion Begins)**

**Task 4: "Baking Variety"**
- Bake at least 5 different recipes (any quality)
- Star Reward: 0.5
- Unlocks: "Artisan Breads" recipe page (5 recipes), Medium Mixing Bowl

**Goal:** Encourage experimentation with recipes

---

### **★★★★☆ → ★★★★★ (2 to 2.5 Stars - Business Growth)**

**Task 5: "Profitable Day"**
- Earn $200 profit in a single day (revenue minus expenses)
- Star Reward: 0.5
- Unlocks: Medium Display Case, ability to hire staff

**Goal:** Teach efficient operation and cost management

---

### **★★★★★ → ★★★★★★ (2.5 to 3 Stars - Professional Operation)**

**Task 6: "Team Player"**
- Hire your first employee
- Star Reward: 0.5
- Unlocks: "Special Occasion Cakes" recipe page (4 recipes), Grandmother's second letter

**Goal:** Introduce staff management

---

### **★★★★★★ → ★★★★★★★ (3 to 3.5 Stars - Quality Focus)**

**Task 7: "Perfectionist"**
- Bake 25 perfect quality items (any recipes)
- Star Reward: 0.5
- Unlocks: Professional Oven, Large Display Case, Decorating Station

**Goal:** Master the baking mechanics

---

### **★★★★★★★ → ★★★★★★★★ (3.5 to 4 Stars - Master Baker)**

**Task 8: "Grandmother's Legacy"**
- Reach 80 reputation AND earn $5,000 total revenue
- Star Reward: 0.5
- Unlocks: "Grandma's Secret Recipes" (5 special recipes), Grandmother's third letter, expansion option (knock out wall)

**Goal:** Major milestone, significant content unlock

---

### **★★★★★★★★ → ★★★★★★★★★ (4 to 4.5 Stars - Community Pillar)**

**Task 9: "Town Favorite"**
- Successfully complete food critic visit with positive review AND serve 500 total customers
- Star Reward: 0.5
- Unlocks: "International Treats" recipe page (6 recipes), Billboard advertising, Premium decorations

**Goal:** Handle high-pressure events, sustained excellence

---

### **★★★★★★★★★ → ★★★★★★★★★★ (4.5 to 5 Stars - Ultimate Achievement)**

**Task 10: "Master Baker"**
- Reach 95 reputation, own all equipment upgrades (tier 3+), and bake at least one legendary quality item from each recipe category
- Star Reward: 0.5
- Unlocks: "Legendary Bakes" recipe page (Grandmother's ultimate recipe), Grandmother's final letter, Industrial equipment tier, "Master Baker" title/achievement

**Goal:** Complete mastery of all systems

---

## **4. TASK TRACKING & DISPLAY**

### **HUD Display**

**Top Right Corner:**
```
┌─────────────────────────┐
│ ★★★☆☆ (3.0 Stars)      │
│                         │
│ CURRENT TASK:           │
│ "Perfectionist"         │
│ Perfect Items: 18/25    │
│ ████████░░              │
└─────────────────────────┘
```

**Elements:**
- Current star rating (visual stars + number)
- Active task name
- Progress bar and counter
- Compact, non-intrusive

### **Task Menu (Dedicated Tab in Shop Management)**

```
┌─────────────────────────────────────────────────┐
│  BAKERY TASKS & PROGRESSION                     │
├─────────────────────────────────────────────────┤
│                                                 │
│  CURRENT STAR RATING: ★★★☆☆ (3.0 Stars)        │
│  Next Star At: 3.5 Stars                        │
│                                                 │
│  ACTIVE TASKS (1)                               │
│  ┌──────────────────────────────────────────┐  │
│  │ ✓ IN PROGRESS                            │  │
│  │ "Perfectionist"                          │  │
│  │ Bake 25 perfect quality items            │  │
│  │                                           │  │
│  │ Progress: 18/25 ████████░░ 72%          │  │
│  │ Reward: ★ +0.5 Stars                     │  │
│  │ Unlocks: Professional Oven, Large        │  │
│  │ Display Case, Decorating Station         │  │
│  └──────────────────────────────────────────┘  │
│                                                 │
│  UPCOMING TASKS (2)                             │
│  ┌──────────────────────────────────────────┐  │
│  │ 🔒 LOCKED (Requires 3.5 Stars)           │  │
│  │ "Grandmother's Legacy"                   │  │
│  │ Reach 80 reputation AND earn $5,000      │  │
│  │ total revenue                            │  │
│  │                                           │  │
│  │ Reward: ★ +0.5 Stars                     │  │
│  │ Unlocks: Grandma's Secret Recipes (5),   │  │
│  │ Grandmother's letter, expansion option   │  │
│  └──────────────────────────────────────────┘  │
│                                                 │
│  ┌──────────────────────────────────────────┐  │
│  │ 🔒 LOCKED (Requires 4.0 Stars)           │  │
│  │ "Town Favorite"                          │  │
│  │ ???                                      │  │
│  │ (Details revealed at 3.5 stars)          │  │
│  └──────────────────────────────────────────┘  │
│                                                 │
│  COMPLETED TASKS (6)                            │
│  ✓ First Steps                                  │
│  ✓ First Customers                              │
│  ✓ Rising Reputation                            │
│  ✓ Baking Variety                               │
│  ✓ Profitable Day                               │
│  ✓ Team Player                                  │
│                                                 │
│  [View All Tasks] [Filter: All ▼]              │
└─────────────────────────────────────────────────┘
```

**Key Features:**
- Clear visual separation of active, upcoming, and completed
- Progress tracking for active tasks
- Preview of rewards (stars + unlocks)
- Locked tasks show requirements
- Completed tasks collapsible list for reference

---

## **5. TASK COMPLETION FLOW**

### **During Gameplay**

**When Task Progress Updates:**
1. Check if any active task's tracked stat changed
2. Update progress counter
3. Update HUD progress bar
4. If progress reaches requirement, trigger completion

**When Task Completes:**
1. **Immediate Feedback:**
   - Screen flash/particle effect
   - Sound effect (triumphant chime)
   - Large popup notification appears

2. **Completion Popup:**
```
┌─────────────────────────────────────────┐
│            TASK COMPLETED!              │
│                                         │
│         "Perfectionist"                 │
│    Bake 25 perfect quality items        │
│                                         │
│              ★ +0.5 STARS!              │
│         ★★★☆☆ → ★★★★☆                  │
│                                         │
│            UNLOCKED:                    │
│      • Professional Oven               │
│      • Large Display Case              │
│      • Decorating Station              │
│                                         │
│  [Awesome!] [View Upgrades Menu]       │
└─────────────────────────────────────────┘
```

3. **Backend Updates:**
   - Add 0.5 to player's star rating
   - Mark task as completed
   - Unlock recipes/equipment (make purchasable)
   - Add money reward if applicable
   - Activate next task in sequence
   - Save progress

4. **Post-Completion:**
   - Task moves to "Completed" section
   - Next task becomes active (if stars requirement met)
   - HUD updates to show new star count
   - New unlocks appear in shop/upgrade menus

---

## **6. UNLOCKING SYSTEM INTEGRATION**

### **Equipment Gating**

**Before Star System:**
- Equipment available for purchase if player has money

**With Star System:**
- Equipment requires BOTH stars AND money
- Example: Professional Oven
  - Requires: 3.5 stars
  - Cost: $2,000
  - Player must earn stars through tasks before they can buy

**Shop UI Update:**
```
┌──────────────────────────────────────────┐
│ PROFESSIONAL OVEN                        │
│ Cost: $2,000                             │
│ Required: ★★★★☆ (3.5 Stars)             │
│                                          │
│ ✓ Stars Requirement Met                  │
│ ✓ Sufficient Funds                       │
│                                          │
│ Benefits:                                │
│ • +20% baking speed                      │
│ • +10% quality bonus                     │
│ • Can bake 2 items simultaneously        │
│                                          │
│            [Purchase]                    │
└──────────────────────────────────────────┘
```

If player doesn't have required stars:
```
┌──────────────────────────────────────────┐
│ PROFESSIONAL OVEN                        │
│ Cost: $2,000                             │
│ Required: ★★★★☆ (3.5 Stars)             │
│                                          │
│ 🔒 Requires 3.5 Stars                    │
│ Current: ★★★☆☆ (3.0 Stars)              │
│                                          │
│ Complete "Perfectionist" task to unlock  │
│                                          │
│         [View Tasks]                     │
└──────────────────────────────────────────┘
```

### **Recipe Gating**

**Recipe Book UI:**
```
┌──────────────────────────────────────────┐
│ RECIPE BOOK                              │
│                                          │
│ UNLOCKED RECIPES (8)                     │
│ • White Bread                            │
│ • Chocolate Chip Cookies                 │
│ • Blueberry Muffins                      │
│ • Croissants                             │
│ • Danish Pastries                        │
│ • Scones                                 │
│ • Cinnamon Rolls                         │
│ • Sourdough                              │
│                                          │
│ LOCKED RECIPES (19)                      │
│ 🔒 Special Occasion Cakes (4 recipes)    │
│    Unlock at: ★★★☆☆ (2.5 Stars)         │
│    Task: "Team Player"                   │
│                                          │
│ 🔒 Grandma's Secret Recipes (5 recipes)  │
│    Unlock at: ★★★★☆ (3.5 Stars)         │
│    Task: "Grandmother's Legacy"          │
│                                          │
│ [Filter: All ▼] [Sort: Unlock Order]    │
└──────────────────────────────────────────┘
```

### **Story Content Gating**

**Grandmother's Letters:**
- Letter 1: 1.5 stars ("Rising Reputation" task)
- Letter 2: 2.5 stars ("Team Player" task)
- Letter 3: 3.5 stars ("Grandmother's Legacy" task)
- Letter 4: 4.5 stars ("Town Favorite" task)
- Final Letter: 5.0 stars ("Master Baker" task)

**Automatic Trigger:**
When task completes and unlocks story content:
1. Task completion popup appears
2. After dismissing, story popup appears
3. Show grandmother's letter with text
4. Can replay from story/memories menu

---

## **7. SIDE TASKS & OPTIONAL CHALLENGES**

### **Optional Tasks**

In addition to main progression tasks, add optional challenges:

**Purpose:**
- Provide variety and player choice
- Offer alternate paths to same star level
- Add replayability
- Give advanced players extra goals

**Structure:**
- Main task: Required to progress (1 per half-star)
- Optional tasks: 2-3 per star level, player chooses which to complete
- Completing optional tasks gives bonuses but not stars

**Example at 2.5 Stars:**

**Main Task (Required for 3.0 stars):**
- "Team Player" - Hire your first employee

**Optional Tasks (Choose any, for bonus rewards):**
- "Speed Demon" - Complete 3 full days in under 20 minutes each
  - Reward: $500 bonus, "Fast Worker" achievement
- "Variety Expert" - Bake every unlocked recipe at least once
  - Reward: +5 reputation, "Well-Rounded" achievement
- "Customer Champion" - Serve 50 happy customers
  - Reward: +10% customer traffic boost for 7 days

**Benefits:**
- Players feel less railroaded
- Multiple play styles rewarded
- Extra content for completionists
- Meaningful choices without blocking progression

---

## **8. TASK DESIGN PRINCIPLES**

### **Progression Difficulty Curve**

**Early Tasks (0-2 Stars):**
- Simple, achievable quickly (1-3 days)
- Teach core mechanics
- Low requirements (serve 10 customers, earn $200)
- Frequent rewards to maintain engagement

**Mid Tasks (2-3.5 Stars):**
- Moderate challenge (3-7 days)
- Require mastery of mechanics
- Combination requirements (reputation AND revenue)
- Introduce new systems (staff, decorations)

**Late Tasks (3.5-5 Stars):**
- Long-term goals (7-14 days)
- High skill requirements
- Complex multi-part objectives
- Test all systems together
- Feel like significant achievements

### **Task Variety**

**Mix Task Types Each Star Level:**
- Don't have 3 "serve customers" tasks in a row
- Alternate between baking, business, upgrades
- Balance quick wins with long-term goals
- Include at least one creative/exploration task

**Example Good Sequence:**
1. Serve customers (customer service)
2. Bake variety (baking mastery)
3. Buy equipment (business/upgrades)
4. Reach reputation (long-term quality)
5. Hire staff (management)

### **Clear, Measurable Goals**

**Good Task Design:**
- "Serve 25 happy customers" ✓ (specific number, clear criteria)
- "Bake 10 perfect quality croissants" ✓ (specific item, quality defined)
- "Reach 75 reputation" ✓ (exact number, visible stat)

**Poor Task Design:**
- "Make customers happier" ✗ (vague)
- "Bake lots of bread" ✗ (no specific number)
- "Do well" ✗ (subjective)

### **Player Guidance**

**Every Task Should:**
- Have clear completion criteria
- Show current progress
- Provide tips on how to complete
- Indicate why it matters (what it unlocks)

**Task Description Template:**
```
Task Name: Short, evocative title
Description: What player must do (specific)
Tips: How to accomplish it efficiently
Progress: X/Y with visual bar
Reward: Stars + unlocks listed
Why It Matters: Brief context (story or gameplay reason)
```

---

## **9. ADVANCED TASK FEATURES**

### **Task Chains**

Some tasks unlock follow-up tasks:

**Example Chain - "Baker's Journey":**
1. "Apprentice Baker" (1.0 stars) - Bake 50 items
   - Unlocks: "Journeyman Baker"
2. "Journeyman Baker" (2.0 stars) - Bake 200 items
   - Unlocks: "Master Baker" (main quest)
3. "Master Baker" (5.0 stars) - Complete ultimate challenge

**Benefits:**
- Creates narrative arc
- Long-term goals with checkpoints
- Sense of progression and mastery

### **Hidden/Secret Tasks**

Tasks that don't appear in task list until discovered:

**Examples:**
- "Grandmother's Treasure" - Find hidden item in apartment
  - Reward: Special decoration item, lore entry
- "Legendary Luck" - Bake 3 legendary items in one day
  - Reward: Increased legendary chance permanently
- "Community Hero" - Donate baked goods to charity (special event)
  - Reward: Major reputation boost

**Discovery Triggers:**
- Exploring apartment thoroughly
- Experimenting with mechanics
- Special events
- NPC conversations (future expansion)

### **Timed/Limited Tasks**

Tasks available only during specific conditions:

**Examples:**
- "Festival Champion" - Available only during town festival
  - Win baking competition
  - Reward: 0.5 stars (bonus, not required for progression)
- "Holiday Spirit" - Available during Christmas event
  - Bake 50 holiday cookies
  - Reward: Special holiday recipe unlock

**Purpose:**
- Create urgency and excitement
- Reward active players
- Seasonal content
- FOMO-free if not required for main progression

---

## **10. BALANCING STARS VS. MONEY**

### **Dual Currency System**

**MONEY ($$):**
- Earned through sales
- Spent on: ingredients, wages, marketing, upgrades
- Renewable resource (earn more each day)
- Can be lost (expenses, bad days)
- Used for operational costs

**STARS (★):**
- Earned through task completion
- "Spent" on: unlocking equipment/recipes (gating mechanism)
- Non-renewable, permanent progression
- Can never decrease
- Used for content gating

### **Purchase Requirements**

**All major purchases require BOTH:**

**Example: Professional Oven**
- Money Cost: $2,000
- Star Requirement: 3.5 stars
- Player must have BOTH to purchase

**Prevents:**
- Rushing progression with money grinding
- Skipping content/learning
- Overwhelming new players with options
- Trivialized difficulty

**Encourages:**
- Completing tasks (exploring all mechanics)
- Balanced progression
- Sense of achievement
- Learning systems gradually

### **Money as Soft Gate, Stars as Hard Gate**

**Money:**
- Can grind/earn more through smart play
- Catch-up mechanics help if struggling
- Flexible, player-controlled

**Stars:**
- Must complete specific tasks (no shortcuts)
- Ensures player has experienced content
- Hard gate, structured progression

**Result:**
- Players never feel stuck on money alone
- Stars give clear direction
- Both systems feel meaningful
- Progression feels earned, not bought

---

## **11. UI/UX POLISH**

### **Notifications & Feedback**

**Task Progress Updates:**
- Small popup when progress increments
  - "Perfectionist: 19/25 (+1)"
- Audio cue (gentle chime)
- Progress bar updates smoothly

**Near Completion:**
- When task is 80%+ complete, highlight in UI
- "Almost there! 23/25 perfect items"
- Gentle glow effect on task card

**Task Completion:**
- Full-screen celebration
- Confetti/particle effects
- Triumphant music sting
- Clear display of rewards
- Option to immediately view unlocked content

### **Star Display Prominence**

**Main Menu:**
- Show star rating on main game screen
- Always visible, part of player identity

**HUD:**
- Constant star display (top corner)
- Current task progress (expandable)

**Menus:**
- Star requirements shown on locked items
- Clear visual difference between locked/unlocked

**Social Proof:**
- "You earned 3 stars! Only 15% of bakers reach this level!"
- Achievement feeling

### **Tutorial & Onboarding**

**First Task Special Treatment:**
- Full tutorial popup explaining star system
- "Complete tasks to earn stars and unlock new content!"
- Show task menu
- Highlight HUD elements
- Guide through first task completion

**Gradual Introduction:**
- Star system explained at task 1
- Optional tasks introduced at task 3
- Task chains introduced at task 5
- Hidden tasks hinted at midgame

---

## **12. SAVE SYSTEM INTEGRATION**

### **Data to Save**

```gdscript
var save_data = {
    "star_rating": 3.0,
    "tasks_completed": ["first_steps", "first_customers", ...],
    "tasks_active": {
        "perfectionist": {
            "progress": 18,
            "required": 25
        }
    },
    "tasks_unlocked": ["team_player", "baking_variety", ...],
    "recipes_unlocked": ["white_bread", "croissants", ...],
    "equipment_unlocked": ["standard_oven", "medium_display", ...],
    "story_flags": {
        "letter_1_read": true,
        "letter_2_read": false
    }
}
```

### **Backward Compatibility**

**If adding star system to existing save:**
- Calculate appropriate star level based on current progress
- Award stars retroactively for implied completed tasks
- Mark early tasks as completed
- Example: If player has $5,000 revenue, give them 2.5 stars automatically

---

## **13. ENDGAME & REPLAYABILITY**

### **Post-5 Stars Content**

**After achieving 5 stars:**
- Prestige mode: "New Game+" with bonuses
- Endless optional challenges
- Perfecting all recipes to legendary
- Decorating/customization focus
- Leaderboards (if multiplayer future)

**Continued Progression:**
- "Master Tasks" - Ultra-hard optional challenges
  - "Perfect Week" - 7 consecutive days, all customers happy
  - "Speed Run" - Complete full game day in under 10 minutes
  - "Variety Master" - Bake every recipe at legendary quality
- Rewards: Cosmetic items, achievements, bragging rights

### **Achievement System**

**Separate from tasks but complementary:**
- Tasks: Required progression (stars)
- Achievements: Optional accomplishments (trophies/badges)

**Example Achievements:**
- "First Star" - Earn your first star
- "Rising Star" - Reach 3 stars
- "Five Star Baker" - Reach maximum stars
- "Overachiever" - Complete all optional tasks
- "Legendary" - Bake 100 legendary quality items
- "Speedrunner" - Complete game in under 20 hours
- "Grandmother's Favorite" - Read all story letters

---

## **14. FULL TASK LIST (Example)**

### **Complete 0-5 Star Task Progression**

**0 → 0.5 Stars:**
1. "First Steps" - Clean the entire shop once

**0.5 → 1.0 Stars:**
2. "First Customers" - Serve 10 happy customers

**1.0 → 1.5 Stars:**
3. "Rising Reputation" - Reach 60 reputation

**1.5 → 2.0 Stars:**
4. "Baking Variety" - Bake 5 different recipes

**2.0 → 2.5 Stars:**
5. "Profitable Day" - Earn $200 profit in one day

**2.5 → 3.0 Stars:**
6. "Team Player" - Hire your first employee

**3.0 → 3.5 Stars:**
7. "Perfectionist" - Bake 25 perfect quality items

**3.5 → 4.0 Stars:**
8. "Grandmother's Legacy" - Reach 80 reputation AND $5,000 total revenue

**4.0 → 4.5 Stars:**
9. "Town Favorite" - Complete food critic visit with positive review AND serve 500 total customers

**4.5 → 5.0 Stars:**
10. "Master Baker" - Reach 95 reputation, own all tier 3+ equipment, bake one legendary item per recipe category

### **Optional Tasks (Selection)**

**1-2 Star Range:**
- "Speed Demon" - Complete a full day in under 20 minutes
- "No Waste" - Complete 3 days with zero burned items
- "Penny Pincher" - Earn $500 profit without buying advertising

**2-3 Star Range:**
- "Variety Expert" - Bake every unlocked recipe
- "Customer Champion" - Serve 50 happy customers
- "Cleanliness is Key" - Maintain 100% cleanliness for 5 days

**3-4 Star Range:**
- "Marketing Guru" - Run 10 successful ad campaigns
- "Staff Satisfaction" - Have 3 employees at 100% morale simultaneously
- "Recipe Master" - Unlock all available recipes

**4-5 Star Range:**
- "Legendary Baker" - Bake 25 legendary quality items
- "Business Mogul" - Earn $10,000 total revenue
- "Community Leader" - Complete 5 special events successfully

---

## **15. IMPLEMENTATION CHECKLIST**

### **Phase 1: Core System**
- [ ] Create Task resource/class with all properties
- [ ] Implement star rating variable (0-5 in 0.5 increments)
- [ ] Create task tracking system (progress counters)
- [ ] Build task completion detection logic
- [ ] Implement save/load for tasks and stars

### **Phase 2: UI**
- [ ] Add star display to HUD (top corner)
- [ ] Create task menu tab in shop management
- [ ] Build task card UI (active, upcoming, completed)
- [ ] Create task completion popup
- [ ] Add progress bars and visual feedback

### **Phase 3: Task Content**
- [ ] Define all 10 main progression tasks
- [ ] Create 15-20 optional tasks
- [ ] Write task descriptions and tips
- [ ] Set up unlock chains (tasks unlock equipment/recipes)

### **Phase 4: Integration**
- [ ] Gate equipment purchases by stars
- [ ] Gate recipe unlocks by task completion
- [ ] Tie story letters to star milestones
- [ ] Update shop UI to show star requirements
- [ ] Add "View Tasks" buttons where relevant

### **Phase 5: Polish**
- [ ] Add particle effects for task completion
- [ ] Create sound effects (progress, completion)
- [ ] Implement smooth animations
- [ ] Add tutorial for star system
- [ ] Create achievement system (optional)

### **Phase 6: Balancing**
- [ ] Playtest task difficulty progression
- [ ] Adjust task requirements based on feedback
- [ ] Ensure tasks are achievable but challenging
- [ ] Verify unlock pacing feels good
- [ ] Test edge cases (save/load, retroactive completion)

---

## **END OF DOCUMENT**

The star system provides clear, structured progression that guides players through the game while gating content behind meaningful achievements. Combined with the reputation system, it creates a dual-track progression where short-term performance (reputation) and long-term mastery (stars) both matter. Tasks give players clear goals, prevent aimless grinding, and ensure they experience all game systems before unlocking advanced content.