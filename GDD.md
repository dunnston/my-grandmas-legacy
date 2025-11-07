Perfect! I have everything I need. Let me create a comprehensive GDD for you.

---

# **GAME DESIGN DOCUMENT**
## **My Grandma's Legacy**
*A Cozy Bakery Management Game*

---

## **TABLE OF CONTENTS**
1. High Concept
2. Core Pillars
3. Game Loop
4. Systems Documentation
5. Progression & Economy
6. Content Overview
7. UI/UX Flow
8. Technical Requirements
9. Development Roadmap

---

## **1. HIGH CONCEPT**

**Genre:** 3D Cozy Management Simulation

**Platform:** PC (Godot 4.5)

**Target Audience:** Ages 15-90, fans of cozy games, management sims, and crafting games

**Elevator Pitch:**
Inherit your grandmother's rundown bakery and transform it from a dusty, broken-down shop into the town's premier bakery. Bake delicious goods through hands-on crafting, serve customers, manage your business, and unlock your grandmother's legacy one recipe at a time.

**Core Experience:**
Players experience the satisfying loop of creation (baking), reward (sales), maintenance (cleanup), and growth (planning). The game balances light time-management pressure with forgiving, cozy progression that rewards both efficiency and creativity.

---

## **2. CORE PILLARS**

### **Pillar 1: Hands-On Baking**
Players physically interact with ingredients and equipment, creating a tangible connection to their craft. The multi-step baking process mirrors real cooking while remaining accessible and fun.

### **Pillar 2: Meaningful Progression**
Every upgrade is visual and impactful. Players see their bakery transform from broken-down to beautiful, with each improvement offering both aesthetic appeal and gameplay benefits.

### **Pillar 3: Cozy Tension**
The game provides light challenge through time management and multi-tasking without punishing failure. Bad days slow progress; they don't end the game. Catch-up mechanics ensure everyone can succeed at their own pace.

### **Pillar 4: Legacy & Discovery**
Unlocking grandmother's recipes and story through milestone achievements creates emotional investment and narrative reward alongside mechanical progression.

---

## **3. GAME LOOP**

### **Daily Cycle Structure (30 minutes real-time)**

#### **PHASE 1: BAKING (Variable, player-controlled)**
**Objective:** Prepare goods for the day's sales

**Mechanics:**
- Walk to ingredient storage and retrieve items
- Interact with crafting stations (mixing bowls, ovens, cooling racks)
- Open station UI to transfer ingredients from player inventory to station inventory
- Initiate crafting timer
- Manage multiple items simultaneously (Overcooked-style multitasking)
- Monitor cooking timers to prevent burning (visual/audio cues)
- Transfer finished goods to display cases

**Time Control:** Pause, 1x, 2x, 3x speed available

**Challenge Scaling:** As bakery grows, players can produce more variety but must manage more stations simultaneously

**Quality Outcomes:**
- Perfect: Optimal time/temp, fresh ingredients, quality equipment
- Good: Slight timing variance, decent ingredients
- Acceptable: Overcooked/undercooked slightly, aging ingredients
- Poor: Burned, expired ingredients, broken equipment
- RARE: "Legendary" quality (random chance on perfect execution)

---

#### **PHASE 2: BUSINESS (9 AM - 5 PM game time)**
**Objective:** Serve customers and maximize revenue

**Mechanics:**
- Customers enter shop, browse displays
- Customer satisfaction factors:
  - **Product Availability:** Did shop have what they wanted?
  - **Price Point:** Player-set prices vs. customer expectations
  - **Wait Time:** Queue length at checkout
  - **Product Quality:** Quality of purchased items
  - **Shop Ambiance:** Cleanliness, decorations, atmosphere

**Customer Mood System:**
- 😊 Happy: All factors positive, may become regular, spreads positive word-of-mouth
- 😐 Neutral: Mixed experience, no impact on reputation
- 😞 Unhappy: Negative factors, decreases future traffic

**Checkout Interaction:**
- Ring up items
- Accept payment (cash/credit card mini-interaction)
- Make change
- Can hire staff to handle checkout

**Traffic System:**
- Base traffic determined by reputation
- Special events boost traffic for specific days
- Advertising in planning phase increases traffic
- Consistent quality builds regulars

**Time Control:** Pause, 1x, 2x speed available

---

#### **PHASE 3: CLEANUP (Variable, player-controlled)**
**Objective:** Prepare shop for next day

**Mechanics:**
- Dispose of unsold goods (ingredients spoil, baked goods don't carry over)
- Wash dishes at sink
- Sweep floor
- Wipe counters
- Empty trash
- Check equipment maintenance

**Cleanliness Impact:**
- Affects next day's customer satisfaction
- Very dirty shop = decreased traffic
- Can hire cleaning staff

**Time Control:** Pause, 1x, 2x, 3x speed available

---

#### **PHASE 4: PLANNING (Menu-based, no time pressure)**
**Objective:** Strategize for growth and next day

**Planning Menu Sections:**

**A. Daily Report**
- Revenue earned
- Expenses (ingredients used, staff wages)
- Net profit/loss
- Customer satisfaction breakdown
- Traffic analysis

**B. Ingredient Ordering**
- Purchase shipments from suppliers
- Delivery arrives in 1-3 game days (requires planning ahead)
- Storage capacity limits
- Expiration date tracking
- Bulk discounts available

**C. Marketing**
- Newspaper ad (small boost, next day)
- Social media campaign (medium boost, 2-3 days)
- Radio/TV spot (large boost, 3-5 days)
- Billboard (permanent small boost)
- Each has cost/benefit tradeoff

**D. Upgrades & Purchases**
- **Equipment:** Better ovens, mixers, display cases, refrigeration
- **Furniture:** Tables, chairs, shelving, lighting
- **Decoration:** Paint, artwork, plants, flooring
- **Expansion:** Knock out walls, add rooms, increase space
- **Storage:** Pantries, freezers, dry storage
- Preview upgrade placement in 3D space

**E. Staff Management**
- Hire employees (Baker, Cashier, Cleaner)
- Each has skill ratings (1-5 stars)
- Assign daily tasks
- Pay wages
- Staff skills improve with experience

**F. Recipe Book**
- View unlocked recipes
- See locked recipes (unlocks at milestones)
- Read grandmother's notes on each recipe

**G. Traffic Projections**
- Forecast for next day based on:
  - Day of week
  - Weather
  - Special events
  - Current reputation
  - Active marketing

---

## **4. SYSTEMS DOCUMENTATION**

### **4.1 CRAFTING SYSTEM**

**Ingredient Categories:**
- **Dry Goods:** Flour (white, wheat, rye), Sugar (white, brown), Salt, Baking Powder, Baking Soda, Cocoa Powder, Spices
- **Wet Goods:** Milk, Eggs, Butter, Oil, Vanilla Extract, Honey
- **Add-ins:** Chocolate Chips, Nuts, Dried Fruit, Fresh Fruit
- **Specialty:** Yeast, Food Coloring, Cream Cheese

**Crafting Stations:**

1. **Prep Counter**
   - Initial ingredient gathering
   - Player inventory staging area

2. **Mixing Bowl (Small/Medium/Large)**
   - Combine dry ingredients (30 seconds)
   - Combine wet ingredients (30 seconds)
   - Mix together for dough/batter (60 seconds)
   - Quality affected by mixing time

3. **Oven (Basic/Standard/Professional)**
   - Baking time: 3-8 minutes depending on item
   - Temperature setting affects outcome
   - Visual/audio cues for doneness
   - Can burn if left too long

4. **Cooling Rack**
   - Items must cool before display (30-60 seconds)
   - Rushing reduces quality

5. **Decorating Station (unlockable)**
   - Add frosting, toppings, decorations
   - Increases value and appeal
   - Adds 1-2 minutes to process

**Multi-Tasking Flow:**
- Start mixing bowl → while mixing, prep next batch
- Put item in oven → start new mixing
- Monitor oven timer while assembling ingredients
- Pull from oven → immediately load next item
- Cool items while baking continues

**Quality Calculation:**
```
Base Quality = Recipe Following (0-100%)
+ Equipment Bonus (+0-20%)
+ Ingredient Freshness (+0-15%)
+ Timing Accuracy (+0-15%)
- Timing Penalty (-0-30% if rushed/burned)

Legendary Chance: 5% on Perfect (100%+) quality
```

---

### **4.2 CUSTOMER & TRAFFIC SYSTEM**

**Customer Types:**
- **Regulars (unlock after 5 happy visits):** Consistent orders, forgiving on price/wait
- **Tourists:** Less price-sensitive, want variety
- **Locals:** Price-conscious, want staples
- **Critics (special event):** High standards, major reputation impact
- **Bulk Orders (special event):** Pre-orders for parties, high revenue

**Traffic Formula:**
```
Base Traffic = Reputation Score (0-100)
+ Day of Week Modifier (+0-20)
+ Weather Modifier (+0-10)
+ Active Marketing (+0-50)
+ Special Events (+0-100)

Traffic = Number of customers that day
```

**Reputation System:**
- Starts at 50
- Each happy customer: +0.5
- Each unhappy customer: -1.0
- Reputation decays slowly toward 50 if no change
- Reputation affects base traffic and prices customers will accept

**Price Tolerance:**
```
Customer Acceptance = Base Price * (0.8 to 1.5)
Affected by:
- Customer type
- Product quality
- Reputation
- Shop ambiance
```

---

### **4.3 PROGRESSION SYSTEM**

**Milestone-Based Unlocks:**

**Trust Fund Milestones** (Grandmother's Will):
1. **$500 Total Revenue:** "Basic Pastries" recipe page
2. **$2,000 Total Revenue:** "Artisan Breads" recipe page
3. **$5,000 Total Revenue:** Letter from grandmother + "Special Occasion Cakes" recipes
4. **$10,000 Total Revenue:** "Grandma's Secret Recipes" + decorating station unlock
5. **$25,000 Total Revenue:** "International Treats" + expansion option
6. **$50,000 Total Revenue:** Final letter + "Legendary Bakes"

**Upgrade Tiers:**

**Equipment:**
- Tier 1 (Broken): Functional but slow, poor quality modifier
- Tier 2 (Basic): Starting functional equipment
- Tier 3 (Standard): Faster, better quality
- Tier 4 (Professional): Fast, excellent quality, unlocks advanced recipes
- Tier 5 (Industrial): Multiple batches, automatic timers

**Shop Aesthetics:**
- Tier 1: Broken, dirty, cracks in walls
- Tier 2: Clean, functional, basic paint
- Tier 3: Nice paint, some decorations, improved lighting
- Tier 4: Beautiful, themed decorations, ambient features
- Tier 5: Showcase bakery, perfect ambiance, tourist attraction

**Storage Capacity:**
- Tier 1: 20 ingredient slots
- Tier 2: 40 slots + small refrigerator
- Tier 3: 60 slots + large refrigerator
- Tier 4: 100 slots + walk-in cooler
- Tier 5: 150 slots + deep freezer

---

### **4.4 ECONOMY SYSTEM**

**Starting Conditions:**
- Cash on hand: $200
- Broken oven (works but slow/unreliable)
- One small mixing bowl
- One small display case
- Basic cleaning supplies
- 3 starter recipes (white bread, cookies, muffins)
- Small ingredient starter kit

**Early Game Balancing:**
- Day 1-3: Learning, minimal profit ($20-50/day)
- Day 4-7: First upgrades, growing ($50-100/day)
- Week 2: Established rhythm ($100-200/day)
- Month 1: Profitable bakery ($200-500/day)

**Cost Structures:**

**Ingredients (per unit):**
- Flour: $2-5 depending on type
- Sugar: $3
- Eggs (dozen): $4
- Butter (lb): $5
- Milk (gallon): $4
- Specialty items: $5-15

**Recipe Costs (example):**
- Basic White Bread: $8 ingredients → Sell $15-25 (depending on quality/pricing)
- Chocolate Chip Cookies (dozen): $6 → Sell $12-20
- Croissants: $10 → Sell $20-35
- Decorated Cake: $25 → Sell $50-100

**Equipment Costs:**
- Standard Oven: $500
- Professional Oven: $2,000
- Industrial Oven: $8,000
- Mixing Bowl (Medium): $100
- Display Case (Large): $300
- Refrigerator: $800
- Decorating Station: $1,500

**Renovation Costs:**
- Wall Repair: $200
- Paint Job: $300
- Flooring: $500
- Lighting Upgrade: $400
- Expansion (knock out wall): $5,000

**Staff Wages (per day):**
- 1-star Baker: $50
- 3-star Baker: $100
- 5-star Baker: $200
- (Similar for Cashier/Cleaner roles)

**Marketing Costs:**
- Newspaper: $50 (next day boost)
- Social Media: $150 (2-3 day boost)
- Radio: $300 (3-5 day boost)
- Billboard: $1,000 (permanent minor boost)

**Catch-Up Mechanic:**
- If player has 3 consecutive days below $50 profit, trigger "Community Support" event
- Local business owner offers discount on next ingredient order (50% off)
- OR special high-traffic event announced for 2 days out
- This prevents complete stalls while maintaining tension

---

### **4.5 STAFF SYSTEM**

**Staff Attributes:**
- **Skill Level:** 1-5 stars in their specialty
- **Speed:** How fast they complete tasks
- **Reliability:** Chance of mistakes
- **Wage Expectation:** Based on skill level
- **Experience:** Improves with work (1-2% per week)

**Staff Actions:**

**Baker (Baking Phase):**
- Follows recipes player has unlocked
- Skill affects quality and speed
- 1-star: 70% average quality, slow
- 5-star: 95% average quality, fast

**Cashier (Business Phase):**
- Handles customer checkout
- Skill affects speed (reduces wait time)
- 1-star: 60 seconds per customer
- 5-star: 20 seconds per customer

**Cleaner (Cleanup Phase):**
- Handles all cleaning tasks
- Skill affects thoroughness and speed
- 1-star: 80% clean, slow
- 5-star: 100% clean, fast

**Hiring:**
- Available applicants refresh weekly
- Random skill distribution
- Player can hire up to 3 staff initially
- Unlockable expansions allow more staff

---

## **5. PROGRESSION & ECONOMY**

### **5.1 PROGRESSION CURVE**

**Week 1: Survival & Learning**
- Goal: Learn mechanics, make first $500
- Unlock: Basic Pastries recipes
- Upgrades: Repair oven, clean shop

**Week 2-3: Stabilization**
- Goal: Consistent profitability, reach $2,000 total
- Unlock: Artisan Breads recipes
- Upgrades: Better display case, first marketing

**Month 2: Growth**
- Goal: Hit $5,000 total, hire first staff
- Unlock: Special Occasion Cakes + grandmother's letter
- Upgrades: Professional oven, expanded storage

**Month 3: Expansion**
- Goal: $10,000 total, full staff
- Unlock: Grandma's Secret Recipes + decorating station
- Upgrades: Major renovations, beautiful shop

**Month 4+: Mastery**
- Goal: $25,000+ total, max upgrades
- Unlock: International Treats, Legendary Bakes
- Upgrades: Expansion, industrial equipment, tourist destination

### **5.2 DIFFICULTY CURVE**

**Complexity Increase:**
- Early: 2-3 recipes, simple ingredients
- Mid: 5-8 recipes, manage staff, marketing decisions
- Late: 12+ recipes, multiple staff, expansion planning, special events

**Time Management:**
- Early: Generous timers, few items to manage
- Mid: Multiple ovens, coordinating staff, busier shop
- Late: Production line efficiency, bulk orders, peak traffic management

**Economic Pressure:**
- Early: Small margins, careful spending
- Mid: Comfortable buffer, strategic investments
- Late: Large cash flow, portfolio management

---

## **6. CONTENT OVERVIEW**

### **6.1 RECIPE LIST (Examples)**

**Starter Recipes:**
1. White Bread
2. Chocolate Chip Cookies
3. Blueberry Muffins

**Basic Pastries ($500 unlock):**
4. Croissants
5. Danish Pastries
6. Scones
7. Cinnamon Rolls

**Artisan Breads ($2,000 unlock):**
8. Sourdough
9. Baguettes
10. Focaccia
11. Rye Bread
12. Multigrain Loaf

**Special Occasion Cakes ($5,000 unlock):**
13. Birthday Cake (customizable)
14. Wedding Cupcakes
15. Cheesecake
16. Layer Cake

**Grandma's Secret Recipes ($10,000 unlock):**
17. Grandmother's Apple Pie
18. Secret Recipe Cookies
19. Family Chocolate Cake
20. Holiday Specialty Bread

**International Treats ($25,000 unlock):**
21. French Macarons
22. German Stollen
23. Italian Biscotti
24. Japanese Melon Pan

**Legendary Bakes ($50,000 unlock):**
25. Grandmother's Legendary [Signature Item]
26. Championship Recipe
27. Town Festival Winner

*(Total: ~27 recipes for full game)*

---

### **6.2 UPGRADE CATALOG**

**Equipment Upgrades:**
- Mixing Bowls (3 sizes, 3 tiers each)
- Ovens (4 tiers)
- Display Cases (3 sizes, 3 tiers)
- Refrigeration (4 tiers)
- Decorating Station (2 tiers)
- Prep Counters (expandable)
- Sinks (2 tiers)

**Furniture:**
- Customer Tables (4 styles)
- Chairs (6 styles)
- Shelving Units (5 styles)
- Counters (3 styles)
- Checkout Counter (3 styles)

**Decorations:**
- Paint Colors (12 options)
- Wallpaper (6 patterns)
- Flooring (8 types)
- Lighting Fixtures (10 types)
- Wall Art (15 pieces)
- Plants (8 varieties)
- Window Treatments (5 styles)
- Signage (outdoor/indoor)

**Structural:**
- Wall Repairs
- Expansion (2 additional rooms possible)
- Exterior Facade Upgrade
- Outdoor Seating Area
- Upstairs Apartment Upgrades (decorative)

---

### **6.3 SPECIAL EVENTS**

**Random Events:**
- **Food Critic Visit:** High-stakes day, major reputation impact
- **Weather:** Rain (lower traffic), Sunshine (higher traffic), Snow (specialty demand)
- **Town Festival:** Huge traffic, opportunity for bulk orders
- **Competitor Opens:** Temporary traffic decrease, must win back customers
- **Local Celebrity Visit:** Reputation boost if they're satisfied
- **School Field Trip:** Many customers, lower price tolerance
- **Equipment Breakdown:** Emergency repair needed

**Scheduled Events:**
- **Holidays:** Christmas, Thanksgiving, Valentine's Day (specialty demands)
- **Weekly Farmer's Market:** Discount ingredient opportunity
- **Monthly Inspection:** Cleanliness matters
- **Seasonal Changeovers:** New trending items

---

### **6.4 STORY BEATS**

**Opening:**
- Letter from grandmother's lawyer: "You've inherited the bakery"
- Arrive to see rundown shop
- Find grandmother's recipe book with first 3 recipes
- Read her note: "Make this place special again"

**$500 Milestone:**
- New recipes unlock
- Discover grandmother's photo on wall
- Memory: Her teaching you to bake as a child

**$2,000 Milestone:**
- More recipes
- Find old newspaper article about bakery's glory days
- Grandmother's note about "staying true to quality"

**$5,000 Milestone:**
- Letter from grandmother (written before passing)
- Reveals she knew the bakery struggled but believed in you
- Unlocks special occasion recipes she used for celebrations

**$10,000 Milestone:**
- Discover grandmother's secret recipe box
- Letter explains each recipe's story and significance
- Decorating station unlocked (grandmother's specialty)

**$25,000 Milestone:**
- Town recognizes your success
- Newspaper article: "Bakery Reborn"
- Grandmother's final note about legacy and passing torch

**$50,000 Milestone (Ending):**
- Final letter from grandmother
- Reveals her proudest moment was sharing joy through baking
- You've fulfilled her legacy
- Unlock grandmother's legendary recipe (keep playing in endgame)

**Post-Game:**
- Continue playing to fully upgrade everything
- Pursue perfect reputation
- Master all recipes
- Build ultimate bakery

---

## **7. UI/UX FLOW**

### **7.1 HUD (In-Game)**

**Persistent Elements:**
- Current Phase indicator (top center)
- Clock/Timer (top right)
- Cash on Hand (top left)
- Pause/Speed Controls (bottom right)
- Quick Inventory (bottom center)
- Current Day Number (top left under cash)

**Phase-Specific:**
- **Baking:** Active timers for ovens/mixing
- **Business:** Customer queue count, checkout progress
- **Cleanup:** Task checklist
- **Planning:** None (menu-based)

---

### **7.2 INTERACTION PROMPTS**

When near interactive object:
- **[E] Interact** appears above object
- Pressing E opens context menu:
  - Mixing Bowl: "Combine Ingredients"
  - Oven: "Load Oven" / "Check Progress" / "Remove Items"
  - Display Case: "Stock Items"
  - Register: "Checkout Customer"
  - Cleaning Items: "Clean [Item]"

---

### **7.3 CRAFTING UI**

When interacting with station:
- **Left Panel:** Player inventory (drag-drop)
- **Center Panel:** Station inventory slots with recipe template
- **Right Panel:** Recipe book reference
- **Bottom:** "Start Crafting" button (when requirements met)
- Visual feedback: Ingredients glow green when correct, red when wrong

---

### **7.4 PLANNING PHASE MENU**

**Main Menu Tabs:**
1. Daily Report (default opens here)
2. Orders
3. Marketing
4. Upgrades
5. Staff
6. Recipes
7. Projections

Each tab is clean, readable, with clear call-to-action buttons
Preview changes before confirming purchases

---

### **7.5 ACCESSIBILITY FEATURES**

- Colorblind modes
- Adjustable text size
- Remappable controls
- Timer audio cues (for vision assistance)
- Pause anytime
- No twitch reflexes required

---

## **8. TECHNICAL REQUIREMENTS**

### **8.1 GODOT 4.5 IMPLEMENTATION**

**Scene Structure:**
```
Main.tscn (entry point, manages scene switching)
├── Bakery.tscn (main gameplay scene)
│   ├── Player (CharacterBody3D)
│   ├── Equipment (Nodes for each station)
│   ├── Customers (spawn points and pathing)
│   ├── Environment (lighting, decorations)
│   └── UI Layer
└── Apartment.tscn (upstairs decorative scene)
    ├── Player (CharacterBody3D)
    ├── Furniture (decorative)
    └── Interaction Points (sleep, news, etc.)
```

**Key Systems (Autoloaded Singletons):**
- **GameManager:** State machine for phases, day progression
- **InventoryManager:** Player and station inventories
- **CustomerManager:** Spawning, AI, satisfaction
- **ProgressionManager:** Unlocks, milestones, save data
- **EconomyManager:** Money, prices, costs
- **RecipeManager:** Recipe data, crafting logic
- **StaffManager:** Employee data, task assignment
- **EventManager:** Special events, random events

---

### **8.2 DATA STRUCTURES**

**Recipe Structure:**
```gdscript
class Recipe:
    var recipe_name: String
    var ingredients: Dictionary # {ingredient_id: quantity}
    var crafting_time: float
    var oven_temp: int
    var oven_time: float
    var base_quality: float
    var sell_price_base: int
    var unlock_milestone: int
```

**Customer Structure:**
```gdscript
class Customer:
    var customer_type: String
    var desired_items: Array
    var price_tolerance: float
    var patience: float
    var mood: int # 0=unhappy, 1=neutral, 2=happy
    var is_regular: bool
```

**Staff Structure:**
```gdscript
class Staff:
    var name: String
    var role: String # baker, cashier, cleaner
    var skill_level: int # 1-5
    var speed_multiplier: float
    var wage: int
    var experience: float
```

---

### **8.3 SAVE SYSTEM**

**Save Data Includes:**
- Current cash
- Day number
- Recipe unlocks
- Purchased upgrades (equipment, decorations, expansions)
- Staff roster
- Reputation score
- Active marketing campaigns
- Ingredient inventory (with expiration dates)
- Milestone progress
- Story flags

**Save Format:** JSON file in user:// directory
**Auto-save:** End of each day
**Manual save:** Available in planning phase

---

### **8.4 PERFORMANCE CONSIDERATIONS**

**Target:**
- 60 FPS on mid-range hardware
- Low-poly aesthetic keeps draw calls manageable

**Optimization:**
- Batch similar decorations
- LOD for distant objects
- Customer spawning: Max 15 simultaneous in shop
- Particle effects minimal (flour dust, steam)

---

### **8.5 ASSET PIPELINE**

**3D Models:**
- Low-poly style (target: 500-2000 tris per object)
- PBR materials (simple)
- Modular equipment for easy tier variants

**Placeholder Strategy:**
- Start with CSG/primitive shapes
- Replace with proper models later
- Maintain same collision shapes for consistency

**Audio:**
- Whimsical, upbeat music tracks (3-5 tracks minimum)
- SFX: Mixing, oven dings, cash register, customer chatter, footsteps
- Ambient: Bakery sounds (ovens humming, slight bustle)

---

## **9. DEVELOPMENT ROADMAP**

### **PHASE 1: CORE PROTOTYPE (Milestone 1)**

**Goal:** Prove core loop is fun

**Features:**
- Basic bakery scene (CSG shapes)
- Player movement (WASD)
- 1 recipe (bread)
- Ingredient system (5 ingredients)
- 1 crafting station (mixing bowl)
- 1 oven with timer
- 1 display case
- Time control (pause/speed)
- Phase transitions (manual)

**Success Criteria:** Can complete one full day loop, baking feels engaging

**Time Estimate:** 2-3 weeks

---

### **PHASE 2: BUSINESS & ECONOMY (Milestone 2)**

**Goal:** Complete gameplay loop with economy

**Features:**
- Customer spawning and pathing
- Checkout system
- Money system
- Pricing system
- Customer satisfaction (basic)
- End-of-day report
- Planning phase menu (basic)
- Save/load system
- 3 starter recipes

**Success Criteria:** Can play multiple days, earn money, see progression

**Time Estimate:** 3-4 weeks

---

### **PHASE 3: PROGRESSION SYSTEMS (Milestone 3)**

**Goal:** Add depth and long-term goals

**Features:**
- Upgrade system (equipment tiers)
- Recipe unlocks (milestone-based)
- Reputation system
- Traffic system
- Staff hiring (basic)
- Ingredient expiration
- Catch-up mechanic
- 10 total recipes

**Success Criteria:** 2-week playthrough feels rewarding, progression curve works

**Time Estimate:** 4-5 weeks

---

### **PHASE 4: POLISH & CONTENT (Milestone 4)**

**Goal:** Full content and juice

**Features:**
- All 27 recipes
- Full upgrade catalog
- Special events
- Story beats and letters
- Apartment scene (basic)
- Marketing system
- Advanced staff system
- Quality/legendary items
- Improved 3D models (replace placeholders)

**Success Criteria:** Game feels complete, story resonates

**Time Estimate:** 6-8 weeks

---

### **PHASE 5: JUICE & AUDIO (Milestone 5)**

**Goal:** Make it feel amazing

**Features:**
- Particle effects (steam, flour puffs)
- Sound effects (full set)
- Music tracks (3-5 songs)
- Visual feedback polish (hover effects, button animations)
- Camera polish (slight tilt, smooth follow)
- Customer animations
- Tutorial system
- Accessibility features

**Success Criteria:** Game feels cozy and polished

**Time Estimate:** 3-4 weeks

---

### **PHASE 6: BALANCE & TESTING (Milestone 6)**

**Goal:** Ensure fun across all skill levels

**Features:**
- Playtesting with target audience
- Balance economy numbers
- Adjust difficulty curve
- Fix progression pacing
- Bug fixes
- Performance optimization

**Success Criteria:** Multiple playtesters complete game and enjoy it

**Time Estimate:** 2-3 weeks

---

### **TOTAL ESTIMATED TIMELINE: 5-6 months of part-time development**

---

## **10. APPENDICES**

### **A. CONTROL SCHEME**

**Movement:**
- WASD: Move
- Mouse: Look
- Shift: Sprint (optional)
- Space: Jump (if needed for platforming to reach items)

**Interaction:**
- E: Interact with object
- Mouse Click: UI interactions, drag-drop

**UI:**
- ESC: Pause menu
- Tab: Quick inventory
- 1-9: Speed controls / hotkeys

---

### **B. CAMERA**

**Style:** Third-person over-the-shoulder
**Distance:** 3-5 units behind player
**Height:** Slightly above player head
**Collision:** Yes (prevents clipping through walls)
**Special:** Slight dynamic tilt when moving for juice

---

### **C. MONETIZATION (Future)**

*For initial release: Free or one-time purchase*

**Potential Future DLC:**
- Seasonal recipe packs
- Cosmetic decoration bundles
- New story chapters
- Additional locations (café expansion, farmers market booth)

---

## **CONCLUSION**

**My Grandma's Legacy** combines the satisfying crafting of cooking games with the strategic depth of management sims, all wrapped in a cozy, forgiving package perfect for players of all ages. The core loop of create → sell → maintain → grow provides endless satisfaction, while the emotional thread of grandmother's legacy gives meaningful context to every upgrade.

The game respects the player's time with generous catch-up mechanics while still providing enough challenge to keep experienced players engaged. Visual progression ensures every dollar spent feels impactful, and the milestone-based story creates natural stopping points and goals.

Starting with placeholder graphics and focusing on gameplay first allows for rapid iteration and ensures the core experience is fun before investing in art. The modular design supports long-term expansion while maintaining a manageable scope for initial release.

This GDD provides a complete roadmap from prototype to polish, with clear milestones and success criteria. The game is achievable for part-time development while remaining ambitious enough to provide dozens of hours of engaging gameplay.

---

**Let the baking begin! 🥖🍰**

---

Would you like me to drill deeper into any specific system, or shall we start building the Phase 1 prototype?