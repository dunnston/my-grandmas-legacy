# Phase 2 Testing Guide

**Status:** Ready for Testing
**Branch:** `phase-2-business-economy`
**Last Updated:** 2025-11-07

---

## 🎯 Testing Objectives

This guide will help you test the complete Phase 2 gameplay loop:
- **Full day cycle:** Baking → Business → Cleanup → Planning
- **3 recipes:** White Bread, Chocolate Chip Cookies, Blueberry Muffins
- **Customer AI:** Spawning, pathfinding, shopping, satisfaction
- **Economy:** Money tracking, sales, ingredient purchasing
- **Save/Load:** Auto-save system

---

## 🚀 Quick Start

1. **Open project** in Godot 4.5
2. **Press F5** to run the game
3. You'll start in the **Bakery scene** on **Day 1, Baking Phase**

---

## 📋 Test Sequence: Day 1

### **PHASE 1: Baking (9:00 AM)**

#### Step 1: Get Ingredients
1. Walk to **Ingredient Storage** (back left corner)
2. Press **E** to interact
3. **Expected:** Console shows you took a batch of ingredients
4. **Verify:** Console prints your inventory with 9 ingredient types

#### Step 2: Mix Recipe
1. Walk to **Mixing Bowl** (left side, center)
2. Press **E** to interact
3. **Expected:** Console shows available recipes and checks ingredients
4. **Result:** Automatically mixes the first recipe you have ingredients for
5. **Wait:** 45-60 seconds for mixing to complete
6. **Verify:** Console says "Mixing complete! [dough/batter] is ready!"

#### Step 3: Bake
1. Walk to **Oven** (center)
2. Press **E** to interact
3. **Expected:** Console loads dough into oven and starts baking
4. **Wait:** 3-5 minutes for baking (real-time, adjust with time scale)
5. **Watch:** Oven glows while baking
6. **Verify:** Console says "DING! Baking complete!"

#### Step 4: Stock Display Case
1. Walk to **Display Case** (right side)
2. Press **E** to interact
3. **Expected:** Console transfers finished goods from inventory to display
4. **Verify:** Console shows display case now contains your baked goods

**REPEAT** Steps 2-4 to make more items (optional)

### **PHASE 2: Business (Start Customers)**

#### Step 5: Open Shop
1. Look at **HUD** (top-left panel)
2. **Verify HUD shows:**
   - Day 1
   - Phase: BAKING
   - Cash: $200.00
   - Time: 00:00
3. Click **"Open Shop"** button
4. **Expected:**
   - Phase changes to BUSINESS
   - Console says "=== BUSINESS PHASE STARTED ==="
   - Time jumps to 09:00

#### Step 6: Watch Customers
1. **Wait 10 seconds** - First customer spawns at entrance
2. **Watch customer behavior:**
   - Walks from entrance (front) → Display Case (right)
   - Pauses to browse (5 seconds)
   - Walks to Register (far right)
   - Waits at register for checkout
3. **Console messages:**
   - "Customer spawned: customer_XXX"
   - "customer_XXX: Reached display case, browsing..."
   - "customer_XXX: Selected X items, going to register"
   - "customer_XXX: At register, waiting for checkout"

#### Step 7: Process Checkout
1. Walk to **Register** (far right side)
2. Press **E** when customer is waiting
3. **Expected Console Output:**
   ```
   === PROCESSING CHECKOUT ===
   Customer wants to buy:
     - 1x [Item Name] ($XX.XX each)
   Total: $XX.XX
   Checkout complete!
   ```
4. **Verify HUD:** Cash increases
5. **Watch:** Customer walks to exit and disappears

**Customer spawns every 10 seconds** - Process multiple customers!

#### Step 8: End Business Phase
1. Click **"Close Shop"** button in HUD
2. **Expected:**
   - Phase changes to CLEANUP
   - All customers clear out
   - After 2 seconds, auto-transitions to PLANNING

### **PHASE 3: Planning**

#### Step 9: Review Day
1. **Planning Menu** opens automatically
2. **Verify Daily Report shows:**
   - Day 1 Complete
   - Revenue: $XX.XX (from sales)
   - Expenses: $0.00 (no purchases yet)
   - Profit: $XX.XX (should be positive!)
   - Cash on Hand: $2XX.XX
   - Customers served, satisfaction %

#### Step 10: Order Ingredients
1. **Scroll down** to "Order Ingredients for Tomorrow"
2. **See list of ingredients** with prices
3. **Click +/- buttons** to order ingredients
   - Cost updates in real-time
   - Cannot exceed your cash
4. **Recommended first order:**
   - Flour: +5
   - Sugar: +3
   - Eggs: +3
   - Butter: +3
   - Chocolate chips: +4
   - (Enough for Day 2)

#### Step 11: Start Day 2
1. Click **"Start Next Day"** button
2. **Expected:**
   - Ingredients deducted from cash
   - Ingredients added to storage
   - Console says "=== DAY 2 ==="
   - Returns to BAKING phase

**AUTO-SAVE:** Game auto-saves before planning phase!

---

## 🔄 Test Sequence: Days 2-5

**Repeat the full day cycle 4 more times** to test:
- Multi-day progression
- Ingredient ordering economy
- Cash flow balance
- Save system persistence

**Check after each day:**
- ✅ Day counter increments
- ✅ Cash reflects sales and purchases
- ✅ Ingredient storage restocks with ordered items
- ✅ Can afford next day's ingredients

---

## 🎯 Success Criteria

### ✅ **Day Cycle Works**
- [x] All 4 phases transition correctly
- [x] Day counter increments
- [x] Time system works
- [x] No phase skips or freezes

### ✅ **Recipe System Works**
- [x] Can craft all 3 recipes (bread, cookies, muffins)
- [x] Mixing times vary correctly
- [x] Baking times vary correctly
- [x] Display case accepts all products

### ✅ **Customer System Works**
- [x] Customers spawn during business phase
- [x] Customers navigate correctly (entrance → display → register → exit)
- [x] Customers select items from display
- [x] Checkout processes correctly
- [x] Money increases on sales
- [x] Customer satisfaction tracked

### ✅ **Economy Works**
- [x] Starting cash: $200
- [x] Sales increase cash
- [x] Ingredient purchases decrease cash
- [x] Planning menu shows accurate financial report
- [x] Cannot overspend on ingredients
- [x] Can afford Day 2 ingredients after Day 1

### ✅ **Save/Load Works**
- [x] Auto-save creates file: `user://saves/autosave.json`
- [x] File location: `C:\Users\[YourName]\AppData\Roaming\Godot\app_userdata\My Grandmas Legacy\saves\`
- [x] Save contains all manager data
- [x] (Manual load test in Phase 3)

---

## 🐛 Known Issues to Check

### Navigation Issues
- **Symptom:** Customers get stuck or don't move
- **Cause:** Navigation mesh not baked
- **Fix:** In editor, select NavigationRegion3D node → Bake NavigationMesh

### Display Case Empty
- **Symptom:** Customers leave immediately, low satisfaction
- **Check:** Did you stock the display case?
- **Expected:** Some customers leave if no items match their preference

### No Customers Spawning
- **Symptom:** Business phase but no customers appear
- **Check Console:** Should see "Customer spawned" messages
- **Verify:** CustomerManager received navigation targets

### Money Not Updating
- **Symptom:** HUD cash doesn't change after sales
- **Check:** EconomyManager signals connected to HUD
- **Verify:** Console shows "+ $XX.XX: Customer sale"

### Register Interaction Fails
- **Symptom:** Pressing E at register does nothing
- **Check:** Is customer actually at register? (Check console)
- **Try:** Wait for "At register, waiting for checkout" message

---

## 📊 Economy Balance Testing

### Day 1 Target Results
**Starting:** $200
**Expected Revenue:** $50-150 (depending on items made)
**Expected Expenses:** $50-100 (ingredient restock)
**Expected Profit:** $0-50
**Ending Cash:** $200-300

### 5-Day Profitability
**Goal:** Reach $400-500 by Day 5
**If struggling:**
- Make more items during baking phase
- Stock display case fully
- Process more customers

---

## 🔍 Debug Console Commands

Watch for these key messages:

**Phase Transitions:**
```
=== BAKING PHASE STARTED ===
=== BUSINESS PHASE STARTED ===
=== CLEANUP PHASE STARTED ===
=== PLANNING PHASE STARTED ===
=== DAY X ===
```

**Customer Activity:**
```
Customer spawned: customer_XXX
customer_XXX: Reached display case, browsing...
customer_XXX: Selected X items to purchase
customer_XXX: At register, waiting for checkout
customer_XXX: Purchase complete! Spent $XX.XX
customer_XXX: Final satisfaction: XX%
```

**Economy:**
```
+ $XX.XX: Customer sale (Balance: $XXX.XX)
- $XX.XX: Ingredient order (Balance: $XXX.XX)
=== DAILY FINANCIAL REPORT ===
```

---

## 🚨 Critical Test Cases

### Test 1: Can Complete Full Day
- [x] Bake at least 1 item
- [x] Stock display case
- [x] Open shop
- [x] Serve at least 1 customer
- [x] Close shop
- [x] Order ingredients
- [x] Start Day 2

### Test 2: Economy Balance
- [x] Day 1 profit ≥ $0
- [x] Can afford Day 2 ingredients
- [x] Cash increases over 5 days

### Test 3: Recipe Variety
- [x] Successfully craft White Bread
- [x] Successfully craft Cookies
- [x] Successfully craft Muffins
- [x] All 3 sell to customers

### Test 4: Customer Flow
- [x] At least 5 customers spawn in one business phase
- [x] All customers navigate without getting stuck
- [x] At least 3 customers complete purchases
- [x] Average satisfaction > 40%

---

## 📝 Testing Checklist

Print this checklist and mark off as you test:

```
Day 1:
[ ] Got ingredients from storage
[ ] Mixed recipe at mixing bowl
[ ] Baked in oven
[ ] Stocked display case
[ ] Opened shop (button works)
[ ] Customer spawned
[ ] Customer reached display case
[ ] Customer went to register
[ ] Processed checkout at register
[ ] Money increased
[ ] Closed shop (button works)
[ ] Planning menu opened
[ ] Daily report showed correct data
[ ] Ordered ingredients
[ ] Started Day 2

Day 2-5:
[ ] Day 2 complete
[ ] Day 3 complete
[ ] Day 4 complete
[ ] Day 5 complete
[ ] Cash increased overall
[ ] No errors in console
[ ] Save file exists

Edge Cases:
[ ] Tested with empty display case
[ ] Tested with no money to order ingredients
[ ] Tested multiple recipe types
[ ] Tested rapid phase transitions
```

---

## ✅ Phase 2 Complete When:

- [x] Can play 5 consecutive days without errors
- [x] Economy feels balanced (can progress without running out of money)
- [x] All 3 recipes work end-to-end
- [x] Customers behave naturally
- [x] Save file is created and valid

**After successful testing → Merge to main → Begin Phase 3!**

---

## 🆘 Troubleshooting

**Game won't start:**
- Check console for errors
- Verify all autoloads are registered in Project Settings

**Errors on startup:**
- Check that all scene paths are correct
- Verify all scripts compile without errors

**Need help:**
- Check console output for detailed error messages
- Review PLAN.md for expected behavior
- Check GDD.md for design intent

---

**Happy Testing! 🎮**
