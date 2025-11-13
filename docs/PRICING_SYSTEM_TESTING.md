# Pricing System - Testing Guide

## ✅ Implementation Complete

The shop management menu with dynamic pricing is now fully integrated into the game!

---

## 🎮 How to Test

### 1. Open the Game
- Press **F5** in Godot Editor to run the game
- Or open `scenes/bakery/bakery.tscn` and press F6

### 2. Open Shop Management Menu
- Press **M** key during gameplay
- Menu should appear with 6 tabs

### 3. Test the Pricing Tab

#### View Current Prices:
- Click on **Pricing** tab
- You should see all unlocked recipes grouped by category
- Each recipe shows:
  - Cost (ingredient cost)
  - Market Range (80-150% of base price)
  - Suggested price (base price from balance config)
  - Current price (player-set or default)
  - Profit calculation
  - Price zone indicator (🟢 🟡 🔴)

#### Adjust Prices:
- Click **+** button to increase price by $0.50
- Click **-** button to decrease price by $0.50
- Or type directly into the spinbox
- Click **Reset to Suggested** to restore base price

#### Watch the Feedback:
- **Profit** updates in real-time
- **Price Zone** shows:
  - 🟢 Good (80-120% of base) - Most customers buy
  - 🟡 High (120-150% of base) - Only tourists/regulars
  - 🔴 Too High (>150% of base) - Few buyers
  - 🔴 Too Low (<cost) - Losing money!

### 4. Test Customer Reactions

#### Set up a test scenario:
1. **Bake some items** (any recipe)
2. **Put items in display case**
3. **Open Shop Menu (M)** and go to Pricing tab
4. **Set prices**:
   - White Bread → $30 (way too high)
   - Cookies → $15 (reasonable)
   - Muffins → $22 (good price)
5. **Close menu** and wait for customers

#### Watch the console output:
- **If price is acceptable**: Customer adds item to basket
- **If price is too high**:
  ```
  customer_001 (LOCAL): Rejected white_bread - $30.00 not in range $12.00-$18.00
  ```
- **If ALL items are too expensive**:
  ```
  customer_001: All items too expensive! (rejected 3 items)
  customer_001: Nothing to buy, leaving
  ```

### 5. Test Different Customer Types

Customer types react differently to prices:

| Type | Spawn Rate | Price Tolerance | Test By |
|------|------------|-----------------|---------|
| **LOCAL** | 45% | 80-120% | Set high prices, they'll reject |
| **TOURIST** | 25% | 90-150% | Set higher prices, they'll buy |
| **REGULAR** | 30% | 70-140% | Most forgiving |

#### To see customer types in action:
- Watch console for messages like:
  ```
  customer_002: Customer type set to TOURIST
  ```
- Tourists are more likely to accept premium prices
- Locals are price-conscious and reject expensive items

---

## 🔍 Expected Behavior

### Price Acceptance Logic

Each customer calculates acceptable price range:

```
min_acceptable = base_price × tolerance_min
max_acceptable = base_price × tolerance_max

if current_price < min_acceptable OR current_price > max_acceptable:
    REJECT ITEM
```

### Example: White Bread
- **Base price**: $15.00
- **Cost**: $8.50
- **LOCAL tolerance**: 80-120% → $12.00-$18.00 acceptable
- **TOURIST tolerance**: 90-150% → $13.50-$22.50 acceptable
- **REGULAR tolerance**: 70-140% → $10.50-$21.00 acceptable

### Set Price to $25:
- ❌ LOCAL rejects (above $18 max)
- ❌ TOURIST rejects (above $22.50 max)
- ❌ REGULAR rejects (above $21 max)
- Result: Nobody buys, customer leaves unhappy

### Set Price to $18:
- ✅ LOCAL accepts (within $12-$18)
- ✅ TOURIST accepts (within $13.50-$22.50)
- ✅ REGULAR accepts (within $10.50-$21)
- Result: Everyone buys!

---

## 🎯 Test Scenarios

### Scenario 1: Balanced Pricing (Recommended)
**Goal**: Maximize sales while maintaining profit

1. Open Pricing tab (M key)
2. Set all items to **100-110%** of suggested price
3. Close menu and observe business phase
4. **Expected**: High sales, good profit, happy customers

### Scenario 2: Premium Pricing
**Goal**: Target high-paying customers

1. Set all prices to **140-150%** of suggested
2. **Expected**:
   - Locals walk away (console: "Rejected ... too expensive")
   - Tourists and regulars buy
   - Lower volume, higher margin

### Scenario 3: Discount Pricing
**Goal**: Volume sales strategy

1. Set all prices to **80-90%** of suggested
2. **Expected**:
   - All customer types buy
   - High volume, lower margin
   - Reputation boost (good value)

### Scenario 4: Dynamic Pricing
**Goal**: Price by item quality

1. Bake items with different quality levels
2. Set premium prices on perfect quality items
3. Discount poor quality items
4. **Expected**: Customers pay more for quality

---

## 🐛 Debugging Tips

### If menu doesn't open:
- Check console for "ShopManagementMenu initialized"
- Verify M key isn't bound to another action
- Try ESC to close if it's stuck open

### If prices don't affect customers:
- Check console for rejection messages
- Ensure items are in display case
- Verify customer has browsed (reached display case)

### If profit calculations are wrong:
- Verify ingredient prices in `balance_config.gd`
- Check recipe costs in RecipeManager
- Ensure quality multipliers are applied

---

## 📊 Monitoring Sales

### Watch Console for:
```
CustomerManager: Customer joined queue (Position: 1/1)
customer_003: Selected 2 items to purchase
customer_003: Purchase complete! Spent $35.00
Customer left (Satisfaction: 85%)
```

### Check Daily Report:
- At end of day, view Planning Menu
- See total revenue, customer satisfaction
- Reputation changes based on satisfaction

---

## 🎨 UI Features Implemented

### Dashboard Tab:
- ✅ Daily summary (revenue, expenses, profit, customers)
- ✅ Reputation bar with status text
- ✅ Quick stats (satisfaction, cash on hand)

### Pricing Tab:
- ✅ Category-based recipe list
- ✅ +/- buttons for price adjustment
- ✅ Direct price input via spinbox
- ✅ Reset button to restore suggested price
- ✅ Real-time profit calculation
- ✅ Price zone indicators
- ✅ Cost and market range display

### Other Tabs:
- Staff (placeholder)
- Marketing (placeholder)
- Statistics (placeholder)
- Events (placeholder)

---

## 🚀 Next Steps (Future)

1. **Statistics Tab**: Add reputation/revenue graphs
2. **Marketing Tab**: Campaigns that boost traffic
3. **Staff Tab**: Hire employees, assign tasks
4. **Events Tab**: Special event planning
5. **Price History**: Track pricing performance over time
6. **Competitor Prices**: Show market comparison
7. **Customer Feedback**: Direct price complaints

---

## 📝 Notes

- Prices are saved with RecipeManager save data
- Quality affects final price charged to customers
- Reputation will eventually affect price tolerance (Phase 3)
- Perfect quality items can command +10% premium
- Poor quality items should be discounted to sell

**Ready to test!** Press F5 and press M to start pricing your bakery items!
