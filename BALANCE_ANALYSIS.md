# My Grandma's Legacy - Balance Analysis & Tuning Guide

## Table of Contents
1. [Executive Summary](#executive-summary)
2. [Critical Balance Issues](#critical-balance-issues)
3. [What's Working Well](#whats-working-well)
4. [Balance Recommendations](#balance-recommendations)
5. [Quick Tuning Guide](#quick-tuning-guide)
6. [Testing Scenarios](#testing-scenarios)

---

## Executive Summary

### Overall Assessment: ⚠️ NEEDS REBALANCING

The game has solid systems in place, but several **critical economic issues** make the game unwinnable in its current state. The primary problems are:

1. **🔴 CRITICAL: Two starter recipes are unprofitable** - Players will lose money making cookies and muffins
2. **🔴 CRITICAL: Baking times exceed business day length** - Legendary recipes take 23 minutes but business day is only 8 minutes
3. **🟡 MODERATE: Upgrade costs conflict with milestone unlocks** - First oven upgrade costs $2,000, which is a milestone threshold
4. **🟡 MODERATE: Customer patience drains too quickly** - 20 seconds until rage quit
5. **🟢 MINOR: Quality timing windows are very strict** - 5% margin for perfect quality

---

## Critical Balance Issues

### 🔴 ISSUE #1: Unprofitable Starter Recipes

**Problem:** Players start with 3 recipes, but 2 of them LOSE MONEY at normal quality.

#### White Bread (PROFITABLE ✅)
```
Ingredients Cost: $7.50 (flour×2, yeast, salt, water)
Base Price: $15.00
Profit at Normal Quality (1.0x): $7.50 (50% margin)
Profit at Poor Quality (0.7x): $3.00 (20% margin)
Profit at Perfect Quality (2.0x): $22.50 (150% margin)
```
**Status:** ✅ Profitable at all quality levels

#### Chocolate Chip Cookies (UNPROFITABLE ❌)
```
Ingredients Cost: $26.00 (flour, sugar, butter, eggs, chocolate_chips×2)
Base Price: $12.00
Profit at Normal Quality (1.0x): -$14.00 (LOSING MONEY!)
Profit at Poor Quality (0.7x): -$17.60
Profit at Good Quality (1.2x): -$11.60
Profit at Excellent Quality (1.5x): -$8.00
Profit at Perfect Quality (2.0x): -$2.00
Profit at Perfect + Legendary (3.0x): +$10.00 (requires 5% chance proc)
```
**Status:** ❌ **ALWAYS LOSES MONEY** (even at perfect quality!)

#### Blueberry Muffins (UNPROFITABLE ❌)
```
Ingredients Cost: $33.00 (flour×2, sugar, eggs, milk, blueberries×2, butter)
Base Price: $18.00
Profit at Normal Quality (1.0x): -$15.00 (LOSING MONEY!)
Profit at Good Quality (1.2x): -$11.40
Profit at Excellent Quality (1.5x): -$6.00
Profit at Perfect Quality (2.0x): +$3.00 (needs PERFECT timing!)
```
**Status:** ❌ **Loses money unless perfect quality**

**Impact:**
- Starting with $200, players might make 1-2 batches before going broke
- No way to reach first milestone ($500) if making unprofitable items
- Players will be confused why they're losing money

**Fix Recommendations:**
1. **IMMEDIATE FIX:** Increase base prices
   - Cookies: $12 → $35 (profitable at normal quality)
   - Muffins: $18 → $40 (profitable at normal quality)
2. **ALTERNATIVE:** Reduce ingredient costs across the board by 40%
3. **ALTERNATIVE:** Reduce ingredient quantities in recipes

---

### 🔴 ISSUE #2: Baking Times vs Business Day Duration

**Problem:** Business day is 8 game hours = 480 real seconds (8 minutes at 1x speed). Several recipes take longer than the entire business day!

#### Business Day Length
```
Business Hours: 9 AM to 5 PM = 8 game hours
At 1x speed: 8 hours × 60 seconds/hour = 480 seconds = 8 minutes
At 2x speed: 240 seconds = 4 minutes
At 3x speed: 160 seconds = 2.67 minutes
```

#### Recipe Production Times (mixing + baking)

**Starter Recipes**
- White Bread: 60s + 300s = **360s (6 minutes)** - Can make ~1.3 per day at 1x
- Cookies: 45s + 180s = **225s (3.75 minutes)** - Can make ~2 per day at 1x
- Muffins: 50s + 240s = **290s (4.8 minutes)** - Can make ~1.6 per day at 1x

**Legendary Recipes (worst offenders)**
- Legendary Cake: 180s + 1200s = **1380s (23 minutes!)** - IMPOSSIBLE at 1x speed!
- Championship Recipe: 160s + 960s = **1120s (18.7 minutes)** - IMPOSSIBLE at 1x speed!
- Cheesecake: 85s + 900s = **985s (16.4 minutes)** - IMPOSSIBLE at 1x speed!

**Impact:**
- Players MUST use 3x speed to complete most recipes
- Legendary recipes are mathematically impossible to complete in one business day
- No time pressure or interesting time management decisions

**Fix Recommendations:**
1. **REDUCE BAKING TIMES** by 50-66% across the board
   - White Bread: 300s → 150s (2.5 minutes)
   - Legendary Cake: 1200s → 400s (6.67 minutes)
2. **EXTEND BUSINESS DAY** to 12 hours (9 AM to 9 PM)
   - 12 hours × 60s = 720 seconds = 12 minutes at 1x
3. **ADD BAKING PHASE** separate from business phase (like planning phase)
   - Baking Phase: 30 minutes (prepare goods)
   - Business Phase: 8 hours (sell goods)

---

### 🟡 ISSUE #3: Upgrade Costs vs Milestone Thresholds

**Problem:** Equipment upgrade costs overlap with milestone unlock thresholds, creating confusion and forcing difficult choices.

#### Milestone Thresholds
```
$500   - Basic Pastries unlock
$2,000 - Artisan Breads unlock (also Oven Tier 1 & Mixer Tier 1 unlock)
$5,000 - Special Occasion unlock
$10,000 - Secret Recipes unlock (also Oven Tier 2 & Mixer Tier 2 unlock)
$25,000 - International unlock (also Oven Tier 3 & Mixer Tier 3 unlock)
$50,000 - Legendary unlock
```

#### Equipment Upgrade Costs
```
Oven Tier 1: $2,000 (unlocks at $2,000 revenue)
Oven Tier 2: $5,000 (unlocks at $10,000 revenue)
Oven Tier 3: $10,000 (unlocks at $25,000 revenue)

Mixer Tier 1: $1,500 (unlocks at $2,000 revenue)
Mixer Tier 2: $4,000 (unlocks at $10,000 revenue)
Mixer Tier 3: $8,000 (unlocks at $25,000 revenue)
```

**Conflict Example:**
- You reach $2,000 total revenue → Artisan Breads unlock + Oven Tier 1 available
- Oven Tier 1 costs $2,000 (100% of milestone threshold!)
- If you buy it, you're broke and can't afford ingredients
- Oven only gives +2% quality bonus (not worth the cost)

**Impact:**
- Players feel forced to choose between progression content or upgrades
- Upgrades don't feel valuable (spending $2k for +2% quality is bad ROI)
- Milestone moments feel bad because you're immediately broke again

**Fix Recommendations:**
1. **REDUCE UPGRADE COSTS** to 10-20% of unlock threshold
   - Oven Tier 1: $2,000 → $300 (15% of $2,000)
   - Oven Tier 2: $5,000 → $1,200 (12% of $10,000)
2. **INCREASE QUALITY BONUSES** to make upgrades feel impactful
   - Tier 1: +2% → +10% quality
   - Tier 2: +4% → +20% quality
   - Tier 3: +6% → +30% quality
3. **OFFSET UNLOCK THRESHOLDS** from upgrade costs
   - Unlock oven upgrades at 50% of milestone (unlock at $1k, $5k, $12.5k)

---

### 🟡 ISSUE #4: Customer Patience Drains Too Fast

**Problem:** Customers start with 100 patience and lose 5 points per second, giving only 20 seconds before they rage quit.

#### Current System
```
Starting Patience: 100
Drain Rate: 5.0 per second
Time to 0 patience: 100 / 5 = 20 seconds
Time to unhappy (<30): 14 seconds
Time to neutral (<60): 8 seconds

Satisfaction Penalties:
- Patience < 30: -20 satisfaction
- No items purchased: -30 satisfaction
```

**Implications:**
- Browse time (5s) + queue time (5-10s) = 10-15 seconds used before purchase
- Leaves only 5-10 seconds buffer before customer becomes unhappy
- If display case is empty, customers WILL rage quit
- Very punishing during early game when player is learning systems

**Impact:**
- Too stressful during learning phase
- Doesn't give player time to react to empty display
- Small hiccups (ran out of bread) cascade into reputation loss

**Fix Recommendations:**
1. **REDUCE DRAIN RATE** to 2.5 per second (40 seconds total)
2. **INCREASE STARTING PATIENCE** to 150 (30 seconds at current rate)
3. **ADD GRACE PERIOD** - no patience drain during browsing (first 5 seconds)
4. **REDUCE PENALTIES** for low patience:
   - Patience < 30: -20 → -10 satisfaction
   - No items: -30 → -20 satisfaction

---

### 🟢 ISSUE #5: Quality Timing Windows Are Very Strict

**Problem:** Perfect quality requires baking within 5% of target time. On a 300-second bake, that's only ±15 seconds.

#### Current Timing Quality
```
Within 5% of target: 100% quality (Perfect)
Within 10% of target: 95% quality (Excellent)
Within 20% of target: 85% quality (Acceptable)
Within 30% of target: 75% quality (Poor)
Over 30% off: 60% quality (Failed)
```

**Example: White Bread (300s bake time)**
```
Perfect: 285-315 seconds (±15s window)
Excellent: 270-330 seconds (±30s window)
Acceptable: 240-360 seconds (±60s window)
```

**Impact:**
- Difficult to achieve perfect quality consistently
- Requires watching oven timer closely
- Less room for experimentation or learning
- Mobile/casual players may struggle

**Note:** This is a **MINOR** issue - strict timing creates skill ceiling and rewarding gameplay. Could be good if intentional!

**Optional Fix:**
1. **RELAX TIMING WINDOWS** for easier difficulty:
   - Perfect: 5% → 10% (±30s on 300s bake)
   - Excellent: 10% → 15%
2. **ADD AUDIO/VISUAL CUES** when approaching perfect timing
   - Bell sound at 95% bake time
   - Oven glow effect at optimal time
3. **KEEP AS-IS** if you want skill-based gameplay (recommended!)

---

## What's Working Well

### ✅ Progression Curve
The milestone structure is solid:
```
$500 → $2,000 → $5,000 → $10,000 → $25,000 → $50,000
Each milestone roughly 2x-2.5x previous milestone
```
This creates a satisfying exponential growth curve (IF economy issues are fixed).

### ✅ Reputation System
The reputation ↔ traffic feedback loop is elegant:
```
Good service → High satisfaction → +Rep → More customers → More revenue → Better equipment → Higher quality → Better service
```
The decay toward 50 prevents runaway reputation and keeps players engaged.

### ✅ Cleanliness System
Daily decay of 15 points means:
- Day 1: 100 → 85 (still "Spotless")
- Day 3: 85 → 70 (drops to "Clean")
- Day 6: 70 → 40 (drops to "Dirty")

Forces cleaning every 5-6 days without being oppressive. Good balance!

### ✅ Marketing Campaigns
Wide variety of costs ($25 to $1,000) with different durations and effects. Grand Opening (2.5x traffic for 1 day) is an exciting burst, while Loyalty Program provides permanent passive benefit.

### ✅ Day-of-Week Traffic Variation
Weekends being busier (1.5x Saturday, 1.2x Sunday) creates natural rhythm and planning opportunities.

### ✅ Quality System
The 5-tier quality system (Poor/Normal/Good/Excellent/Perfect) with price multipliers (0.7x to 2.0x) creates meaningful differentiation and rewards skillful play. The 5% legendary chance on perfect items is a great "jackpot" moment.

---

## Balance Recommendations

### Priority 1: Fix Economy (Critical - Do First!)

#### Option A: Increase Recipe Prices (Recommended)
```gd
# In balance_config.gd, modify RECIPES.recipes:

"chocolate_chip_cookies": {
    "base_price": 35.0,  # Was 12.0 - now profitable!
},
"blueberry_muffins": {
    "base_price": 40.0,  # Was 18.0 - now profitable!
},
```

**Why this option:**
- Easiest to implement
- Maintains ingredient value (ingredients feel precious)
- Makes quality matter more (bigger price swings)

#### Option B: Reduce Ingredient Costs
```gd
# In balance_config.gd, modify ECONOMY.ingredient_prices:
# Multiply all prices by 0.6 (40% reduction)

"ingredient_prices": {
    "flour": 1.2,         # Was 2.0
    "sugar": 1.8,         # Was 3.0
    "eggs": 2.4,          # Was 4.0
    "butter": 3.0,        # Was 5.0
    # etc...
}
```

**Why this option:**
- Makes stocking up feel less punishing
- Easier for new players
- Could make game too easy long-term

#### Option C: Reduce Recipe Ingredient Quantities
Modify recipe definitions in `recipe_manager.gd` to use fewer ingredients.

**Why this option:**
- Most work (need to edit each recipe)
- Changes recipe balance individually
- Could make some recipes feel "empty"

**RECOMMENDATION:** Do Option A first (increase prices), test, then adjust.

---

### Priority 2: Fix Timing Issues

#### Recommended: Reduce Baking Times by 50%
```gd
# In balance_config.gd, modify this multiplier:

RECIPES = {
    "baking_time_multiplier": 0.5,  # All baking times × 0.5
    # ...
}
```

**Results:**
- White Bread: 300s → 150s (2.5 minutes)
- Cookies: 180s → 90s (1.5 minutes)
- Legendary Cake: 1200s → 600s (10 minutes)

**Impact:**
- Can produce ~3 white breads per business day (instead of 1.3)
- Legendary cake fits in business day
- Still requires time management

**Alternative:** Reduce by 66% (×0.33) for even faster gameplay

---

### Priority 3: Rebalance Equipment Costs

```gd
# In balance_config.gd, modify EQUIPMENT costs:

EQUIPMENT = {
    "oven_tier_1_cost": 300.0,      # Was 2000.0
    "oven_tier_2_cost": 1200.0,     # Was 5000.0
    "oven_tier_3_cost": 3000.0,     # Was 10000.0

    "mixer_tier_1_cost": 250.0,     # Was 1500.0
    "mixer_tier_2_cost": 1000.0,    # Was 4000.0
    "mixer_tier_3_cost": 2500.0,    # Was 8000.0

    # And increase quality bonuses:
}

# In balance_config.gd, modify QUALITY:
QUALITY = {
    "equipment_bonus_per_tier": 10.0,  # Was 2.0 - now +10% per tier!
}
```

**Impact:**
- Upgrades feel affordable (15% of milestone)
- Quality bonus is meaningful (+10%/+20%/+30% vs +2%/+4%/+6%)
- Clear value proposition for spending money

---

### Priority 4: Adjust Customer Patience

```gd
# In balance_config.gd, modify CUSTOMERS:

CUSTOMERS = {
    "patience_drain_rate": 2.5,     # Was 5.0 - now 40 seconds total
    # OR
    "patience_start": 150.0,        # Was 100.0 - now 30 seconds at old rate
    # OR BOTH for 60 seconds total patience
}
```

**Recommendation:** Start with drain rate 2.5 (40 seconds), test, adjust if needed.

---

### Optional: Relax Quality Timing (Only if Too Difficult)

```gd
# In balance_config.gd, modify QUALITY:

QUALITY = {
    "timing_perfect_threshold": 0.10,    # Was 0.05 - now ±10%
    "timing_good_threshold": 0.15,       # Was 0.10
    "timing_acceptable_threshold": 0.25, # Was 0.20
}
```

**When to use:** After playtesting, if players consistently get Poor/Failed quality

---

## Quick Tuning Guide

### How to Use `balance_config.gd`

All balance parameters are now centralized in `scripts/autoload/balance_config.gd`.

**Step 1:** Make sure it's registered as an autoload (see installation instructions below)

**Step 2:** Modify values in `balance_config.gd`

**Step 3:** Reload the game (F5)

**Step 4:** Test and iterate

### Quick Balance Adjustments

#### Make Game Easier
```gd
ECONOMY.starting_cash = 500.0          # More starting money
RECIPES.price_multiplier_global = 1.5   # 50% higher prices
RECIPES.baking_time_multiplier = 0.5    # 50% faster baking
CUSTOMERS.patience_drain_rate = 2.0     # Slower patience drain
QUALITY.timing_perfect_threshold = 0.15 # Easier perfect quality
```

#### Make Game Harder
```gd
ECONOMY.starting_cash = 100.0          # Less starting money
RECIPES.price_multiplier_global = 0.8   # 20% lower prices
CUSTOMERS.base_customers_per_hour = 4.0 # Fewer customers
QUALITY.timing_perfect_threshold = 0.03 # Stricter quality
CLEANLINESS.daily_decay = 25.0          # Faster dirt accumulation
```

#### Adjust Game Pace
```gd
# Faster progression
PROGRESSION.milestone_basic_pastries = 300.0      # Was 500
PROGRESSION.milestone_artisan_breads = 1000.0     # Was 2000
PROGRESSION.milestone_special_occasion = 2500.0   # Was 5000

# Slower progression
PROGRESSION.milestone_basic_pastries = 1000.0     # Was 500
PROGRESSION.milestone_artisan_breads = 5000.0     # Was 2000
```

#### Adjust Business Day Length
```gd
TIME.seconds_per_game_hour = 30.0      # Faster (half speed)
TIME.business_end_hour = 21            # Longer day (9 AM - 9 PM)
```

---

## Comprehensive Balance Variable List

Here's every tweakable parameter, organized by category:

### 📅 Time & Pacing
| Variable | Location | Default | What It Does |
|----------|----------|---------|--------------|
| `TIME.seconds_per_game_hour` | balance_config.gd | 60.0 | Real seconds per game hour |
| `TIME.business_start_hour` | balance_config.gd | 9 | Business phase starts (9 AM) |
| `TIME.business_end_hour` | balance_config.gd | 17 | Business phase ends (5 PM) |
| `TIME.max_time_scale` | balance_config.gd | 3.0 | Max speed multiplier |
| `TIME.cleanup_auto_delay` | balance_config.gd | 2.0 | Auto-complete cleanup delay |
| `RECIPES.mixing_time_multiplier` | balance_config.gd | 1.0 | Global mixing time multiplier |
| `RECIPES.baking_time_multiplier` | balance_config.gd | 1.0 | Global baking time multiplier |

**Quick Adjustment:** Change `baking_time_multiplier` to 0.5 for 2x faster baking.

---

### 💰 Economy & Pricing
| Variable | Location | Default | What It Does |
|----------|----------|---------|--------------|
| `ECONOMY.starting_cash` | balance_config.gd | 200.0 | Starting money |
| `ECONOMY.ingredient_prices.*` | balance_config.gd | Various | Price per ingredient unit |
| `RECIPES.price_multiplier_global` | balance_config.gd | 1.0 | Global price multiplier |
| `RECIPES.price_multiplier_starter` | balance_config.gd | 1.0 | Starter recipe price boost |
| `RECIPES.price_multiplier_basic` | balance_config.gd | 1.0 | Basic pastries price boost |
| `RECIPES.price_multiplier_artisan` | balance_config.gd | 1.0 | Artisan breads price boost |
| `RECIPES.price_multiplier_special` | balance_config.gd | 1.0 | Special occasion price boost |
| `RECIPES.price_multiplier_secret` | balance_config.gd | 1.0 | Secret recipes price boost |
| `RECIPES.price_multiplier_international` | balance_config.gd | 1.0 | International price boost |
| `RECIPES.price_multiplier_legendary` | balance_config.gd | 1.0 | Legendary price boost |
| `RECIPES.recipes.*.base_price` | balance_config.gd | Various | Individual recipe base prices |

**Quick Fix for Economy:** Set `price_multiplier_starter` to 2.0 to make starter recipes more profitable.

---

### 📈 Progression & Milestones
| Variable | Location | Default | What It Does |
|----------|----------|---------|--------------|
| `PROGRESSION.milestone_basic_pastries` | balance_config.gd | 500.0 | First milestone revenue |
| `PROGRESSION.milestone_artisan_breads` | balance_config.gd | 2000.0 | Second milestone |
| `PROGRESSION.milestone_special_occasion` | balance_config.gd | 5000.0 | Third milestone |
| `PROGRESSION.milestone_secret_recipes` | balance_config.gd | 10000.0 | Fourth milestone |
| `PROGRESSION.milestone_international` | balance_config.gd | 25000.0 | Fifth milestone |
| `PROGRESSION.milestone_legendary` | balance_config.gd | 50000.0 | Final milestone |
| `PROGRESSION.reputation_start` | balance_config.gd | 50 | Starting reputation |
| `PROGRESSION.reputation_decay_rate` | balance_config.gd | 0.5 | Daily drift toward 50 |
| `PROGRESSION.rep_excellent` | balance_config.gd | 3 | Rep gain for 90%+ satisfaction |
| `PROGRESSION.rep_terrible` | balance_config.gd | -3 | Rep loss for <25% satisfaction |

**Quick Adjustment:** Halve all milestone values for faster progression testing.

---

### 👥 Customer Behavior
| Variable | Location | Default | What It Does |
|----------|----------|---------|--------------|
| `CUSTOMERS.base_customers_per_hour` | balance_config.gd | 6.0 | Customers at 50 rep |
| `CUSTOMERS.spawn_interval_base` | balance_config.gd | 10.0 | Base spawn interval |
| `CUSTOMERS.spawn_interval_min` | balance_config.gd | 3.0 | Min spawn interval (busy) |
| `CUSTOMERS.spawn_interval_max` | balance_config.gd | 120.0 | Max spawn interval (slow) |
| `CUSTOMERS.traffic_at_rep_0` | balance_config.gd | 0.1 | Traffic at 0 reputation |
| `CUSTOMERS.traffic_at_rep_100` | balance_config.gd | 2.5 | Traffic at 100 reputation |
| `CUSTOMERS.traffic_saturday` | balance_config.gd | 1.5 | Saturday traffic boost |
| `CUSTOMERS.patience_start` | balance_config.gd | 100.0 | Starting patience |
| `CUSTOMERS.patience_drain_rate` | balance_config.gd | 5.0 | Patience loss per second |
| `CUSTOMERS.max_browse_time` | balance_config.gd | 5.0 | Browse display time |
| `CUSTOMERS.satisfaction_patience_good` | balance_config.gd | 20 | Bonus if patience > 50 |
| `CUSTOMERS.satisfaction_no_items` | balance_config.gd | -30 | Penalty if can't buy |

**Quick Fix for Patience:** Set `patience_drain_rate` to 2.5 for double the wait time.

---

### ⭐ Quality & Crafting
| Variable | Location | Default | What It Does |
|----------|----------|---------|--------------|
| `QUALITY.quality_poor_multiplier` | balance_config.gd | 0.7 | Poor quality price (50-69%) |
| `QUALITY.quality_normal_multiplier` | balance_config.gd | 1.0 | Normal quality price (70-89%) |
| `QUALITY.quality_good_multiplier` | balance_config.gd | 1.2 | Good quality price (90-94%) |
| `QUALITY.quality_excellent_multiplier` | balance_config.gd | 1.5 | Excellent price (95-99%) |
| `QUALITY.quality_perfect_multiplier` | balance_config.gd | 2.0 | Perfect quality price (100%) |
| `QUALITY.quality_legendary_multiplier` | balance_config.gd | 1.5 | Extra legendary multiplier |
| `QUALITY.equipment_bonus_per_tier` | balance_config.gd | 2.0 | Quality bonus per equipment tier |
| `QUALITY.random_variance` | balance_config.gd | 5.0 | Random quality variance (±%) |
| `QUALITY.legendary_chance` | balance_config.gd | 0.05 | Legendary proc chance (5%) |
| `QUALITY.timing_perfect_threshold` | balance_config.gd | 0.05 | Perfect timing window (±5%) |
| `QUALITY.timing_good_threshold` | balance_config.gd | 0.10 | Good timing window (±10%) |

**Quick Adjustment:** Increase `equipment_bonus_per_tier` to 10.0 to make upgrades more impactful.

---

### 🔧 Equipment & Upgrades
| Variable | Location | Default | What It Does |
|----------|----------|---------|--------------|
| `EQUIPMENT.oven_tier_1_cost` | balance_config.gd | 2000.0 | Tier 1 oven upgrade cost |
| `EQUIPMENT.oven_tier_2_cost` | balance_config.gd | 5000.0 | Tier 2 oven upgrade cost |
| `EQUIPMENT.oven_tier_3_cost` | balance_config.gd | 10000.0 | Tier 3 oven upgrade cost |
| `EQUIPMENT.mixer_tier_1_cost` | balance_config.gd | 1500.0 | Tier 1 mixer upgrade cost |
| `EQUIPMENT.mixer_tier_2_cost` | balance_config.gd | 4000.0 | Tier 2 mixer upgrade cost |
| `EQUIPMENT.mixer_tier_3_cost` | balance_config.gd | 8000.0 | Tier 3 mixer upgrade cost |
| `EQUIPMENT.display_tier_1_cost` | balance_config.gd | 1000.0 | Display case upgrade 1 |
| `EQUIPMENT.display_tier_1_capacity` | balance_config.gd | 5 | Extra display slots |
| `EQUIPMENT.display_tier_2_cost` | balance_config.gd | 2500.0 | Display case upgrade 2 |
| `EQUIPMENT.display_tier_2_capacity` | balance_config.gd | 10 | Extra display slots |

**Quick Fix:** Divide all upgrade costs by 5 to make them affordable.

---

### 🧹 Cleanliness System
| Variable | Location | Default | What It Does |
|----------|----------|---------|--------------|
| `CLEANLINESS.start_cleanliness` | balance_config.gd | 100.0 | Starting cleanliness |
| `CLEANLINESS.daily_decay` | balance_config.gd | 15.0 | Decay per day |
| `CLEANLINESS.incomplete_chore_penalty` | balance_config.gd | 5.0 | Penalty per skipped chore |
| `CLEANLINESS.chore_dishes` | balance_config.gd | 15.0 | Cleanliness gain from dishes |
| `CLEANLINESS.chore_floor` | balance_config.gd | 20.0 | Cleanliness gain from floor |
| `CLEANLINESS.chore_counters` | balance_config.gd | 15.0 | Cleanliness gain from counters |
| `CLEANLINESS.spotless_satisfaction` | balance_config.gd | 1.2 | Satisfaction bonus (90-100%) |
| `CLEANLINESS.very_dirty_traffic` | balance_config.gd | 0.5 | Traffic penalty (<30%) |

**Quick Adjustment:** Reduce `daily_decay` to 10.0 for less frequent cleaning.

---

### 📢 Marketing Campaigns
| Variable | Location | Default | What It Does |
|----------|----------|---------|--------------|
| `MARKETING.newspaper_ad_cost` | balance_config.gd | 50.0 | Newspaper ad cost |
| `MARKETING.newspaper_ad_duration` | balance_config.gd | 3 | Days active |
| `MARKETING.newspaper_ad_traffic` | balance_config.gd | 1.2 | Traffic multiplier |
| `MARKETING.social_media_cost` | balance_config.gd | 100.0 | Social media cost |
| `MARKETING.social_media_traffic` | balance_config.gd | 1.35 | Traffic multiplier |
| `MARKETING.grand_opening_cost` | balance_config.gd | 200.0 | Grand opening event cost |
| `MARKETING.grand_opening_traffic` | balance_config.gd | 2.5 | Huge 1-day boost! |
| `MARKETING.loyalty_program_cost` | balance_config.gd | 300.0 | One-time cost |
| `MARKETING.loyalty_program_traffic` | balance_config.gd | 1.15 | Permanent boost |

**Note:** Marketing is well-balanced currently.

---

### 📦 Starting Resources
| Variable | Location | Default | What It Does |
|----------|----------|---------|--------------|
| `STARTING_RESOURCES.flour` | balance_config.gd | 10 | Starting flour units |
| `STARTING_RESOURCES.sugar` | balance_config.gd | 10 | Starting sugar units |
| `STARTING_RESOURCES.eggs` | balance_config.gd | 10 | Starting egg units |
| (all other ingredients) | balance_config.gd | 10 | Starting amounts |
| `STARTING_RESOURCES.*_batch` | balance_config.gd | 2-5 | Units per storage pickup |

**Quick Adjustment:** Set all starting resources to 20 for easier start.

---

### 🏃 Player Movement
| Variable | Location | Default | What It Does |
|----------|----------|---------|--------------|
| `PLAYER.move_speed` | balance_config.gd | 5.0 | Walking speed |
| `PLAYER.sprint_speed` | balance_config.gd | 8.0 | Sprinting speed |
| `PLAYER.interaction_distance` | balance_config.gd | 3.0 | Interaction range |

---

## Testing Scenarios

### Scenario 1: "Can I Make Money?" (Economy Test)
**Goal:** Ensure starter recipes are profitable

1. Set up test:
   ```gd
   ECONOMY.starting_cash = 1000.0  # Generous for testing
   ```
2. Make 10 batches of each starter recipe at NORMAL quality
3. Calculate profit per recipe
4. **Success Criteria:** All recipes show positive profit

**Expected Results (after fixes):**
- White Bread: ~$7.50 profit per loaf
- Cookies: ~$9.00 profit per batch
- Muffins: ~$7.00 profit per batch

---

### Scenario 2: "Can I Reach Milestone 1?" (Progression Test)
**Goal:** Verify first milestone is achievable in reasonable time

1. Start new game with default settings
2. Play optimally for 10 days
3. Track total revenue
4. **Success Criteria:** Reach $500 within 7-10 days

**Calculation:**
- Average 30 customers/day (50 rep, weekday)
- Average purchase value: $15 (1 white bread)
- Daily revenue: 30 × $15 = $450 gross
- Daily profit: ~$225 (after ingredient costs)
- Days to $500: ~2-3 days

**If taking longer:** Increase customer traffic or recipe prices

---

### Scenario 3: "Can I Complete Recipes?" (Timing Test)
**Goal:** Ensure all recipes can be completed within business day

1. Use 1x time scale
2. Attempt to complete each recipe tier
3. Track completion time vs business day (480s)
4. **Success Criteria:** Can complete at least 2 batches of any recipe per day

**Current Issues:**
- Legendary Cake: 1380s (3x business day length) ❌
- Cheesecake: 985s (2x business day) ❌

**After Fix (0.5x multiplier):**
- Legendary Cake: 690s (1.4x business day) ✅ (at 3x speed = 230s)
- Cheesecake: 492s (barely fits!) ✅

---

### Scenario 4: "Upgrade Value Test"
**Goal:** Ensure upgrades feel worth the cost

1. Calculate revenue from quality improvement
2. Compare to upgrade cost
3. **Success Criteria:** Upgrade pays for itself within 50 bakes

**Current Math (Oven Tier 1: $2,000 cost, +2% quality):**
- White bread at 88% quality → 90% quality (+2%)
- Moves from NORMAL (1.0x) to GOOD (1.2x)
- Price increase: $15 → $18 (+$3)
- Ingredient cost: $7.50
- Extra profit: $3 per loaf
- Loaves to break even: $2,000 / $3 = 667 loaves ❌ Too many!

**After Fix (cost $300, +10% quality):**
- Cost: $300
- Quality boost moves more items to higher tiers
- Conservative estimate: +$5 per item
- Items to break even: $300 / $5 = 60 items ✅ Reasonable!

---

### Scenario 5: "Customer Patience Test"
**Goal:** Verify customers don't rage quit during normal gameplay

1. Stock display case with items
2. Observe customer flow during business phase
3. Track patience levels when customers leave
4. **Success Criteria:** <10% of customers leave unhappy due to patience

**Current Issue:**
- 20 seconds total patience
- Browse (5s) + walk (3s) + queue (5s) = 13s used
- Only 7 seconds buffer
- If queue has 2 customers, third will be unhappy ❌

**After Fix (2.5 drain rate = 40s total):**
- Browse + walk + queue = 13s
- 27 seconds buffer
- Can handle 5-customer queue ✅

---

## Installation Instructions

### Add Balance Config as Autoload

1. Open Godot project
2. Go to **Project → Project Settings → Autoload**
3. Click the folder icon next to "Path"
4. Navigate to `scripts/autoload/balance_config.gd`
5. Set Node Name to: `BalanceConfig`
6. Click "Add"
7. Click "Close"

### Verify Installation

Add this to any script to test:
```gd
func _ready():
    print("Starting cash: $", BalanceConfig.ECONOMY.starting_cash)
    print("White bread price: $", BalanceConfig.get_recipe_price("white_bread"))
```

If you see the values printed, it's working!

---

## Next Steps

### Immediate Actions (Do This First!)

1. **Add BalanceConfig as autoload** (see above)
2. **Apply Priority 1 fixes:**
   - Increase cookie price to $35
   - Increase muffin price to $40
   - Test that starter recipes are profitable
3. **Apply Priority 2 fixes:**
   - Set `baking_time_multiplier` to 0.5
   - Test that recipes complete within business day
4. **Apply Priority 3 fixes:**
   - Reduce equipment costs to 15% of current values
   - Increase equipment quality bonus to 10% per tier
5. **Test Scenario 1** ("Can I Make Money?")
6. **Test Scenario 2** ("Can I Reach Milestone 1?")

### After Initial Fixes

1. Playtest for 30-60 minutes
2. Note any frustrations or pacing issues
3. Adjust using Quick Tuning Guide above
4. Repeat until game feels good

### Future Balance Iterations

1. **Add difficulty settings** using multipliers:
   ```gd
   # Easy mode
   BalanceConfig.ECONOMY.starting_cash *= 2.0
   BalanceConfig.CUSTOMERS.patience_drain_rate *= 0.5

   # Hard mode
   BalanceConfig.ECONOMY.starting_cash *= 0.5
   BalanceConfig.PROGRESSION.milestone_* *= 1.5
   ```

2. **Add balance logging** to track player performance:
   ```gd
   print("Day ", day_number, " Revenue: $", daily_revenue)
   print("Average quality: ", average_quality, "%")
   print("Customer satisfaction: ", avg_satisfaction, "%")
   ```

3. **Create balance presets:**
   ```gd
   # presets/easy.gd
   func apply_easy_mode():
       BalanceConfig.ECONOMY.starting_cash = 500.0
       BalanceConfig.RECIPES.price_multiplier_global = 1.5
       # etc.
   ```

---

## Summary

### Critical Issues to Fix
1. 🔴 Make cookies and muffins profitable (increase prices or reduce costs)
2. 🔴 Reduce baking times by 50% (or extend business day)
3. 🟡 Make equipment upgrades affordable and impactful
4. 🟡 Increase customer patience window

### What's Working
- ✅ Progression milestone curve
- ✅ Reputation feedback loop
- ✅ Cleanliness system
- ✅ Marketing campaign variety
- ✅ Quality tier system

### Recommended First Changes
```gd
# In balance_config.gd:
RECIPES.recipes.chocolate_chip_cookies.base_price = 35.0
RECIPES.recipes.blueberry_muffins.base_price = 40.0
RECIPES.baking_time_multiplier = 0.5
EQUIPMENT.oven_tier_1_cost = 300.0
EQUIPMENT.mixer_tier_1_cost = 250.0
QUALITY.equipment_bonus_per_tier = 10.0
CUSTOMERS.patience_drain_rate = 2.5
```

### Testing Priority
1. Test economy (can make profit?)
2. Test progression (can reach milestones?)
3. Test timing (can complete recipes?)
4. Test upgrades (worth buying?)
5. Test patience (customers happy?)

---

**Remember:** Balance is iterative! Make small changes, test, observe, adjust. Use the centralized `balance_config.gd` to quickly experiment with different values.

Good luck, and happy balancing! 🥖🍪🎂
