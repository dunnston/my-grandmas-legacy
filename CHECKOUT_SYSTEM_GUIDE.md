# Interactive Checkout System - Implementation Guide

## Overview

A complete interactive checkout system for serving customers with hands-on gameplay, payment mini-games, and customer satisfaction feedback.

## System Components

### 1. Customer Feedback System
**File:** `scripts/customer/customer_feedback.gd`

- **Speech Bubble**: Appears above customer's head when ready for checkout
- **Emoji Feedback**: Shows satisfaction after transaction
  - 😊 Happy: Fast + Accurate (< 30 sec, no errors)
  - 😐 Neutral: Medium speed OR 1 error (30-60 sec)
  - ☹️ Sad: Slow OR multiple errors (> 60 sec or 2+ errors)

**Features:**
- Procedurally generated textures (no external assets needed)
- Billboard sprites (always face camera)
- Smooth bobbing animation
- Auto-hide after 2 seconds

### 2. Updated Customer Behavior
**File:** `scripts/customer/customer.gd`

**Changes:**
- Customers now **browse only** - they don't auto-take items
- After browsing (3-5 seconds), customers walk to register
- Speech bubble appears when customer reaches register
- Satisfaction now factors in transaction speed and accuracy
- `complete_purchase()` now accepts `transaction_time` and `had_errors` parameters

**Customer Flow:**
1. ENTERING → Walks to display case
2. BROWSING → Looks at items for 3-5 seconds
3. WAITING_CHECKOUT → Walks to register
4. CHECKING_OUT → Shows speech bubble, waits for player
5. LEAVING → Completes purchase, shows emoji, exits

### 3. Interactive Checkout UI
**File:** `scripts/ui/checkout_ui.gd`

**Main Features:**
- Customer's desired items list (left panel)
- Shopping bag area (shows items as you add them)
- Real-time transaction total
- Payment mini-games (cash and card)
- Transaction timing and error tracking

**Checkout Flow:**
1. **Gathering Items Phase**
   - Player walks to display case
   - Presses [E] to access display case
   - Items go into "player_carry" temporary inventory
   - Returns to register area
   - Clicks "Add to Shopping Bag" button
   - Items transfer from carry → bag

2. **Payment Phase** (70% cash, 30% card)
   - **Cash Payment:**
     - Shows amount due and customer payment
     - Player selects bills/coins to make correct change
     - Buttons: $10, $5, $1, 25¢, 10¢, 5¢, 1¢
     - "Clear" to reset, "Confirm" to submit
     - Wrong change = error (can retry)

   - **Card Payment:**
     - Drag-and-drop card swipe interaction
     - Click and drag card over reader area
     - "Processing..." animation
     - "Approved!" message

3. **Completion**
   - Items removed from display case
   - Money added to economy
   - Customer updated with performance metrics
   - Emoji feedback shown
   - Customer exits

### 4. Updated Register
**File:** `scripts/equipment/register.gd`

**Changes:**
- Creates checkout UI on _ready()
- `interact()` now opens checkout UI instead of auto-processing
- Handles checkout completion callbacks
- Maintains backward compatibility with auto-checkout for staff AI

### 5. Updated Display Case
**File:** `scripts/equipment/display_case.gd`

**Changes:**
- Detects if checkout is active
- Routes items to "player_carry" inventory during checkout
- Routes items to "player" inventory normally
- Seamless integration with existing UI manager

## Player Carry Inventory

**Inventory ID:** `"player_carry"`

- Temporary inventory created when checkout starts
- Holds items collected from display case
- Transferred to shopping bag via "Add to Bag" button
- Cleared when checkout completes or is cancelled

## Satisfaction System

Satisfaction is calculated based on multiple factors:

### Positive Factors:
- Patience > 50: +20 points
- Multiple items (2+): +10 points
- Fast service (< 30s): +15 points

### Negative Factors:
- Patience < 30: -20 points
- Slow service (> 60s): -20 points
- Checkout errors: -15 points per error
- No items available: -30 points

### Satisfaction Thresholds:
- **70-100**: HAPPY 😊
- **40-69**: NEUTRAL 😐
- **0-39**: UNHAPPY ☹️

## Testing the System

### Test Case 1: Basic Checkout Flow
1. Start game (F5)
2. Bake some items and stock display case
3. Wait for customer to spawn
4. Customer walks to display case → browses → walks to register
5. Speech bubble appears above customer
6. Walk to register and press [E]
7. Checkout UI opens showing customer's desired items
8. Walk to display case, press [E]
9. Transfer items from display case to carry inventory
10. Return to register area
11. Click "Add to Shopping Bag"
12. Items appear in shopping bag, total updates
13. Click "Proceed to Payment"
14. Complete payment mini-game (cash or card)
15. Checkout completes, customer shows emoji and leaves

### Test Case 2: Fast Service (< 30 seconds)
- Complete all steps quickly
- Customer should show 😊 happy emoji
- Print: "Final satisfaction: XX% (HAPPY)"

### Test Case 3: Slow Service (> 60 seconds)
- Take your time during checkout
- Customer should show ☹️ sad emoji
- Print: "Final satisfaction: XX% (UNHAPPY)"

### Test Case 4: Payment Errors
- Intentionally give wrong change during cash payment
- Should see "Incorrect! Try again."
- Customer satisfaction decreases
- Can retry until correct

### Test Case 5: Card Payment
- Drag card over reader area
- Should see "Processing..." then "Approved!"
- Faster than cash payment

### Test Case 6: Cancel Checkout
- Start checkout
- Click "Cancel (ESC)" button
- UI closes, customer remains at register
- No items removed, no money added

## Configuration & Customization

### Timing Thresholds
Located in `checkout_ui.gd`:
```gdscript
# Fast: < 30 seconds
if transaction_time < 30.0 and not had_errors:
    emoji_type = IndicatorType.HAPPY_EMOJI

# Slow: > 60 seconds
elif transaction_time > 60.0 or had_errors:
    emoji_type = IndicatorType.SAD_EMOJI
```

### Payment Method Distribution
Located in `checkout_ui.gd` → `_on_proceed_to_payment_pressed()`:
```gdscript
var rand = randf()
payment_method = PaymentMethod.CASH if rand < 0.7 else PaymentMethod.CARD
# 70% cash, 30% card
```

### Cash Denominations
Located in `checkout_ui.gd` → `_show_cash_payment_ui()`:
```gdscript
var denominations = [
    {"value": 10.0, "label": "$10"},
    {"value": 5.0, "label": "$5"},
    {"value": 1.0, "label": "$1"},
    {"value": 0.25, "label": "25¢"},
    {"value": 0.10, "label": "10¢"},
    {"value": 0.05, "label": "5¢"},
    {"value": 0.01, "label": "1¢"}
]
```

### Visual Customization
**Speech Bubble Height:** `customer_feedback.gd` → `indicator_height = 2.5`
**Bob Animation Speed:** `customer_feedback.gd` → `bob_speed = 2.0`
**Bob Amount:** `customer_feedback.gd` → `bob_amount = 0.2`

**UI Colors:** `checkout_ui.gd` → `_create_ui()`:
```gdscript
panel_style.bg_color = Color(0.2, 0.2, 0.25, 0.95)
panel_style.border_color = Color(0.4, 0.4, 0.5)
```

## Troubleshooting

### Issue: Speech bubble doesn't appear
**Cause:** Feedback system not initialized
**Fix:** Check console for "Feedback system created" message. Ensure customer.gd calls `_create_feedback_system()`

### Issue: Checkout UI doesn't open
**Cause:** UI not added to HUD
**Fix:** Check console for "Checkout UI created and added to HUD". Ensure HUD node exists in scene tree with group "hud"

### Issue: Items don't go to carry inventory
**Cause:** Display case not detecting checkout mode
**Fix:** Verify checkout UI is visible when accessing display case. Check `_is_checkout_active()` logic

### Issue: Wrong change not detected
**Cause:** Floating point precision
**Fix:** Already handled with tolerance = 0.01. If still issues, increase tolerance

### Issue: Card drag doesn't work
**Cause:** Input events not reaching card button
**Fix:** Ensure card button is on top of other UI elements. Check z-index/order

## Performance Considerations

- **Procedural Textures**: Speech bubbles and emojis are generated procedurally, no asset loading
- **UI Updates**: Checkout UI only updates when visible and in gathering state
- **Inventory**: Carry inventory is created/destroyed with each checkout session
- **Memory**: Feedback visuals are Sprite3D nodes attached to each customer

## Future Enhancements

### Potential Additions:
1. **Multiple Customers**: Queue system with visual indicators
2. **Customer Patience Bar**: Visual progress bar above customer
3. **Combo Bonuses**: Serve multiple customers quickly for bonus reputation
4. **Difficulty Scaling**: Harder change calculations as game progresses
5. **Express Lane**: Special lane for customers with 1-2 items
6. **Loyalty Cards**: Regular customers get special treatment
7. **Receipt Printing**: Mini-game where player must confirm items
8. **Bag Packing**: Tetris-style mini-game for organizing items
9. **Scanner Beep**: Audio feedback when items are scanned
10. **End-of-Day Report**: Statistics on checkout speed, accuracy, satisfaction

## Integration with Existing Systems

### ✓ InventoryManager
- Uses existing `add_item()`, `remove_item()`, `transfer_item()`
- Creates temporary "player_carry" inventory
- Respects quality metadata

### ✓ EconomyManager
- Calls `add_money()` on successful sale
- Uses quality-adjusted prices from QualityManager

### ✓ RecipeManager
- Gets item names and base prices
- No modifications needed

### ✓ QualityManager
- Uses `get_price_for_quality()` for quality-adjusted pricing
- Preserves quality data during transfers

### ✓ CustomerManager
- Uses existing `get_next_customer_at_register()`
- No modifications needed

### ✓ GameManager
- Respects existing pause/time scale systems
- No modifications needed

## Console Output Examples

### Successful Fast Checkout:
```
Customer spawned: customer_12345_1
customer_12345_1: Initialized, heading to display case
customer_12345_1: Reached display case, browsing...
customer_12345_1: Selected 2 items to purchase
customer_12345_1: At register, waiting for checkout
Showing speech bubble indicator
Started interactive checkout for customer_12345_1
Checkout active - items will go to carry inventory
Added 2x white_bread to shopping bag
Added $10.00 (Total: $10.00)
✓ Correct change!
Payment complete! Time: 24.3s, Errors: 0
Checkout completed! Time: 24.3s, Errors: No
customer_12345_1: Final satisfaction: 85% (HAPPY) [Time: 24.3s, Errors: No]
Showing emoji: HAPPY_EMOJI
customer_12345_1: Purchase complete! Spent $10.00
customer_12345_1: Exited bakery
```

### Slow Checkout with Errors:
```
customer_12345_2: At register, waiting for checkout
Started interactive checkout for customer_12345_2
✗ Incorrect change! Needed $7.53, gave $7.50
✗ Incorrect change! Needed $7.53, gave $8.00
✓ Correct change!
Payment complete! Time: 78.2s, Errors: 2
customer_12345_2: Final satisfaction: 25% (UNHAPPY) [Time: 78.2s, Errors: Yes]
Showing emoji: SAD_EMOJI
```

## File Summary

### New Files Created:
1. `scripts/customer/customer_feedback.gd` - Visual feedback system
2. `scripts/ui/checkout_ui.gd` - Interactive checkout UI
3. `CHECKOUT_SYSTEM_GUIDE.md` - This documentation

### Modified Files:
1. `scripts/customer/customer.gd` - Updated satisfaction + feedback integration
2. `scripts/equipment/register.gd` - Interactive UI instead of auto-checkout
3. `scripts/equipment/display_case.gd` - Carry inventory routing

### Total Lines of Code Added: ~1000+

## Credits

This system implements the comprehensive checkout mechanics described in the original requirements, including:
- ✓ Customer browsing without auto-taking items
- ✓ Speech bubble visual indicators
- ✓ Interactive checkout UI with shopping bag
- ✓ Player carry inventory system
- ✓ Cash payment mini-game (change calculation)
- ✓ Card payment mini-game (swipe interaction)
- ✓ Transaction timing and accuracy tracking
- ✓ Customer satisfaction based on performance
- ✓ Emoji feedback system (😊😐☹️)
- ✓ Full integration with existing game systems

Enjoy serving customers in your bakery! 🥖🍰🥐
