# Balance System - Quick Start Guide

## 🎯 Quick Overview

All game balance parameters are now centralized in **`scripts/autoload/balance_config.gd`**.

Change values there, reload game (F5), and test!

---

## 🚀 Getting Started (3 Steps)

### Step 1: Apply Critical Fixes

Open `scripts/autoload/balance_config.gd` and modify these values:

```gd
# Line ~140: Make cookies profitable
"chocolate_chip_cookies": {
    "base_price": 35.0,  # Change from 12.0
},

# Line ~146: Make muffins profitable
"blueberry_muffins": {
    "base_price": 40.0,  # Change from 18.0
},

# Line ~115: Speed up all baking by 50%
"baking_time_multiplier": 0.5,  # Change from 1.0
```

### Step 2: Test the Game

Press **F5** to run the game and verify:
- ✅ Cookies and muffins are now profitable
- ✅ Recipes complete faster (can bake 2-3 items per business day)

### Step 3: Tweak to Your Preference

Adjust other values in `balance_config.gd` to taste!

---

## 📋 Common Tweaks

### Make Game Easier

```gd
ECONOMY.starting_cash = 500.0           # More starting money (line ~43)
CUSTOMERS.patience_drain_rate = 2.5     # Slower patience drain (line ~348)
QUALITY.timing_perfect_threshold = 0.10 # Easier perfect quality (line ~436)
RECIPES.price_multiplier_global = 1.5   # 50% higher prices (line ~117)
```

### Make Game Harder

```gd
ECONOMY.starting_cash = 100.0           # Less starting money (line ~43)
CUSTOMERS.base_customers_per_hour = 4.0 # Fewer customers (line ~329)
QUALITY.timing_perfect_threshold = 0.03 # Stricter quality (line ~436)
```

### Adjust Game Speed

```gd
TIME.seconds_per_game_hour = 30.0       # Faster time (line ~30)
TIME.business_end_hour = 21             # Longer business day (9 AM to 9 PM) (line ~32)
RECIPES.baking_time_multiplier = 0.33   # Even faster baking (line ~115)
```

### Adjust Progression Speed

```gd
# Faster progression
PROGRESSION.milestone_basic_pastries = 300.0      # line ~268
PROGRESSION.milestone_artisan_breads = 1000.0     # line ~269
PROGRESSION.milestone_special_occasion = 2500.0   # line ~270

# Slower progression
PROGRESSION.milestone_basic_pastries = 1000.0     # line ~268
PROGRESSION.milestone_artisan_breads = 5000.0     # line ~269
```

---

## 🔧 Most Important Parameters

| What to Change | Variable | File Line |
|----------------|----------|-----------|
| Starting money | `ECONOMY.starting_cash` | 43 |
| Recipe prices | `RECIPES.price_multiplier_global` | 117 |
| Baking speed | `RECIPES.baking_time_multiplier` | 115 |
| Customer patience | `CUSTOMERS.patience_drain_rate` | 348 |
| Business day length | `TIME.business_end_hour` | 32 |
| Milestones | `PROGRESSION.milestone_*` | 268-273 |

---

## 📊 Critical Balance Issues Found

See **BALANCE_ANALYSIS.md** for full details. Summary:

### 🔴 CRITICAL (Fix Immediately!)

1. **Cookies & Muffins Unprofitable**
   - Problem: Lose money even at perfect quality
   - Fix: Increase `base_price` in balance_config.gd lines ~140-150
   - Recommended: Cookies $12 → $35, Muffins $18 → $40

2. **Baking Times Too Long**
   - Problem: Legendary cake takes 23 minutes, business day is 8 minutes
   - Fix: Set `baking_time_multiplier` to 0.5 (line ~115)

### 🟡 MODERATE (Fix Soon)

3. **Equipment Upgrades Too Expensive**
   - Problem: Oven Tier 1 costs $2,000 (same as milestone threshold)
   - Fix: Reduce costs by 85% (lines ~389-418)
   - Recommended: $2,000 → $300, etc.

4. **Customer Patience Too Low**
   - Problem: Customers rage quit after 20 seconds
   - Fix: Reduce `patience_drain_rate` from 5.0 → 2.5 (line ~348)

---

## 🎮 Testing Checklist

After making changes:

1. ✅ Can make profit on all starter recipes
2. ✅ Can complete at least 2 recipes per business day
3. ✅ Can reach first milestone ($500) within 5-7 days
4. ✅ Customers don't constantly rage quit
5. ✅ Game feels fun and balanced!

---

## 📁 File Locations

- **Balance Config:** `scripts/autoload/balance_config.gd` (edit this!)
- **Full Analysis:** `BALANCE_ANALYSIS.md` (read for detailed info)
- **Examples:** See `economy_manager.gd`, `game_manager.gd`, `recipe_manager.gd`

---

## ⚡ Quick Test Scenario

Want to test if economy works?

1. Open `balance_config.gd`
2. Set these test values:
   ```gd
   ECONOMY.starting_cash = 1000.0  # Generous for testing
   RECIPES.price_multiplier_starter = 2.0  # Double starter recipe prices
   RECIPES.baking_time_multiplier = 0.33  # 3x faster baking
   ```
3. Run game (F5)
4. Make 10 loaves of bread
5. Check if profit is positive
6. Adjust values until it feels right!

---

## 🆘 Need Help?

- **Full details:** Read `BALANCE_ANALYSIS.md`
- **All parameters:** See table of contents in `BALANCE_ANALYSIS.md`
- **Integration examples:** Check updated manager files with "BALANCE CONFIG INTEGRATION" comments

---

## 💡 Pro Tips

1. **Change one thing at a time** - Easier to see what's working
2. **Test frequently** - Press F5 after each change
3. **Use multipliers first** - Faster than changing individual values
4. **Document your changes** - Add comments in balance_config.gd
5. **Keep backups** - Git commit before major balance changes!

---

**Happy Balancing! 🥖🍪🎂**
