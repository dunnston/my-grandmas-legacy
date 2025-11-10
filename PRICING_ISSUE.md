# Pricing Issue Analysis

## Problem
When clicking "Reset to Suggested", some items reset to prices HIGHER than what's shown as "Suggested":
- **Cookies**: Reset to $1 higher than suggested
- **White Bread**: Reset to $0.20 higher than suggested  
- **Muffins**: Work correctly

## Root Cause

Found in `balance_config.gd` lines 117-122:

```gd
"chocolate_chip_cookies": {
    "base_price": 12.0,  # NOTE: Unprofitable at current ingredient costs!
},
"blueberry_muffins": {
    "base_price": 18.0,  # NOTE: Unprofitable at current ingredient costs!
},
```

**The "suggested" prices are BELOW COST!** This means:
- Cookies cost more than $12 to make
- Muffins cost more than $18 to make
- White bread likely costs close to $15

## Ingredient Costs (from balance_config.gd)

Let me calculate the actual costs:

### Chocolate Chip Cookies
Ingredients: flour(1), sugar(1), butter(1), eggs(1), chocolate_chips(2)
- Flour: $2.00 × 1 = $2.00
- Sugar: $3.00 × 1 = $3.00
- Butter: $4.00 × 1 = $4.00
- Eggs: $3.00 × 1 = $3.00
- Chocolate chips: $5.00 × 2 = $10.00
**Total Cost: $22.00**
**Suggested Price: $12.00**
**LOSS: -$10.00 per batch!**

### White Bread
Ingredients: flour(2), water(1), yeast(1), salt(1)
- Flour: $2.00 × 2 = $4.00
- Water: $0.50 × 1 = $0.50
- Yeast: $3.00 × 1 = $3.00
- Salt: $1.00 × 1 = $1.00
**Total Cost: $8.50**
**Suggested Price: $15.00**
**Profit: +$6.50** ✅ (This one is profitable!)

### Blueberry Muffins  
Ingredients: flour(2), sugar(1), eggs(1), milk(1), blueberries(2), butter(1)
- Flour: $2.00 × 2 = $4.00
- Sugar: $3.00 × 1 = $3.00
- Eggs: $3.00 × 1 = $3.00
- Milk: $2.00 × 1 = $2.00
- Blueberries: $6.00 × 2 = $12.00
- Butter: $4.00 × 1 = $4.00
**Total Cost: $28.00**
**Suggested Price: $18.00**
**LOSS: -$10.00 per batch!**

## Solution Options

### Option 1: Increase Base Prices (Recommended)
Update `balance_config.gd` RECIPES.recipes section:

```gd
"chocolate_chip_cookies": {
    "base_price": 25.0,  # Increased from 12.0 (Cost: $22.00, Profit: $3.00)
},
"blueberry_muffins": {
    "base_price": 32.0,  # Increased from 18.0 (Cost: $28.00, Profit: $4.00)
},
```

### Option 2: Decrease Ingredient Costs
Update `balance_config.gd` ECONOMY.ingredient_prices:

```gd
"chocolate_chips": 3.0,     # Down from 5.0
"blueberries": 4.0,         # Down from 6.0
```

### Option 3: Reduce Recipe Requirements
Change recipes in `recipe_manager.gd` to use fewer expensive ingredients.

## Recommendation

**Go with Option 1** - Increase the base prices. This is more realistic:
- Cookies with chocolate chips SHOULD be expensive ($25 is reasonable)
- Blueberry muffins with fresh blueberries SHOULD be premium ($32 is fair)
- Customers will still buy them if priced correctly

The current "suggested" prices were set before ingredient costs were finalized, creating the unprofitable situation.
