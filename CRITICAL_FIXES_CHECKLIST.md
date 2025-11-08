# Critical Fixes Checklist - Phase 3 Completion

This is a prioritized action list for fixing the most important issues before merging to main.

---

## CRITICAL ISSUES (Must Fix Before Merge)

### 1. [CRITICAL] Recipe Unlock Desynchronization
- **Files:** ProgressionManager.gd, RecipeManager.gd
- **Issue:** Duplicate unlocked_recipes tracking causes save/load desync
- **Action:** Make RecipeManager the single source of truth
- **Time Estimate:** 2 hours
- **Priority:** P0 - Can break core progression

```gdscript
# Current Problem: Two separate arrays track unlocked recipes
ProgressionManager.unlocked_recipes
RecipeManager.unlocked_recipes  # Can diverge

# Solution: Remove from one manager, emit signals between them
```

**Status:** [ ] Not Started

---

### 2. [CRITICAL] Hard-Coded Inventory ID
- **File:** planning_menu.gd line 221
- **Issue:** `"ingredient_storage_IngredientStorage"` breaks on node rename
- **Action:** Get inventory ID from IngredientStorage object at runtime
- **Time Estimate:** 30 minutes
- **Priority:** P0 - Game breaks silently if node renamed

```gdscript
# Current: Hard-coded string
InventoryManager.add_item("ingredient_storage_IngredientStorage", ingredient_id, quantity)

# Fix: Get ID from storage
var storage_id = ingredient_storage.get_inventory_id()
InventoryManager.add_item(storage_id, ingredient_id, quantity)
```

**Status:** [ ] Not Started

---

### 3. [CRITICAL] Material Access Crashes
- **Files:** oven.gd lines 143-146, 171-174; mixing_bowl.gd lines 154-156
- **Issue:** Material could be null, crashes when setting properties
- **Action:** Add defensive checks for material validity
- **Time Estimate:** 45 minutes
- **Priority:** P0 - Game crashes during crafting

```gdscript
# Current: Unsafe
if mesh:
    var mat = mesh.material
    if mat:
        mat.emission_enabled = true  # Could crash

# Fix: Create material if missing
if mesh:
    if not mesh.material:
        var mat = StandardMaterial3D.new()
        mesh.set_surface_override_material(0, mat)
    # Now safe to use
```

**Status:** [ ] Not Started

---

### 4. [CRITICAL] Active Customers Not Saved
- **File:** customer_manager.gd get_save_data()
- **Issue:** Customers disappear on load
- **Action:** Clear active customers when saving OR save customer state
- **Time Estimate:** 1 hour
- **Priority:** P0 - Loses game progress on load during business phase

```gdscript
# Current: Active customers lost
func get_save_data() -> Dictionary:
    return {
        "customers_served_today": customers_served_today,
        # customers not saved!
    }

# Fix Option A (Recommended): Clear on save
clear_all_customers()  # Safe, customers respawn each day

# Fix Option B: Serialize full customer state (complex)
```

**Status:** [ ] Not Started

---

## HIGH PRIORITY ISSUES (Should Fix Before Phase 4)

### 5. [HIGH] Register Modifies Customer State Directly
- **File:** register.gd line 102
- **Issue:** Violates encapsulation, direct property manipulation
- **Action:** Add `purchase_failed()` method to Customer
- **Time Estimate:** 1 hour
- **Priority:** P1 - Potential consistency issues

**Status:** [ ] Not Started

---

### 6. [HIGH] Customer Satisfaction Calculation Collision
- **File:** customer.gd lines 255, 284
- **Issue:** `_update_mood()` overwrites calculated satisfaction
- **Action:** Only update mood before purchase, not after
- **Time Estimate:** 1 hour
- **Priority:** P1 - Inconsistent satisfaction tracking

**Status:** [ ] Not Started

---

### 7. [HIGH] Float Timer Precision Issues
- **Files:** mixing_bowl.gd line 74, oven.gd line 61, customer.gd line 120
- **Issue:** Direct float comparisons can miss exact moment
- **Action:** Use epsilon tolerance or threshold crossing detection
- **Time Estimate:** 1.5 hours (3 locations)
- **Priority:** P1 - Rare but causes missed timer completions

**Status:** [ ] Not Started

---

### 8. [HIGH] Incomplete Inventory Transfer Rollback
- **File:** mixing_bowl.gd lines 131-139
- **Issue:** No rollback if mid-transfer fails
- **Action:** Validate all items first, then transfer all or none
- **Time Estimate:** 1.5 hours
- **Priority:** P1 - Can lose ingredients without starting recipe

**Status:** [ ] Not Started

---

### 9. [HIGH] Missing Node Reference Validation
- **File:** hud.gd _ready()
- **Issue:** Some nodes checked, others not - inconsistent
- **Action:** Assert all required nodes at startup
- **Time Estimate:** 30 minutes
- **Priority:** P1 - Silent failures if scene changes

**Status:** [ ] Not Started

---

### 10. [HIGH] Missing Type Hints
- **Files:** Multiple autoload managers
- **Issue:** Dictionary types not specified (should be `Dictionary[String, int]`)
- **Action:** Add explicit type hints to all complex return types
- **Time Estimate:** 2 hours
- **Priority:** P2 - Improves code clarity but not critical

**Status:** [ ] Not Started

---

## TESTING CHECKLIST

After fixing critical issues, test these scenarios:

- [ ] Save game mid-business phase, load, verify customers still exist (or gracefully cleared)
- [ ] Rename IngredientStorage node in scene, try to order ingredients (should not break)
- [ ] Place oven/mixing bowl at world position (0,0,0), verify crafting works
- [ ] Start crafting at different frame rates (30fps, 60fps, 120fps) - all should complete
- [ ] Transfer ingredients from storage to mixing bowl, delete some mid-transfer - should rollback
- [ ] Open planning menu, verify all UI labels exist and update
- [ ] Unlock recipes by reaching milestones, save/load, verify unlocks persist

---

## TIME ESTIMATE

**Total estimated time to fix all CRITICAL + HIGH issues:**
- Critical: 4.5 hours
- High: 8 hours
- **Total: ~12.5 hours**

Recommended: Fix in 2-3 hour sessions with testing between each fix.

---

## TRACKING

| Issue | Owner | Status | Completed | Notes |
|-------|-------|--------|-----------|-------|
| Recipe Desync | | [ ] | | |
| Hard-Coded ID | | [ ] | | |
| Material Crashes | | [ ] | | |
| Customers Not Saved | | [ ] | | |
| Register Encapsulation | | [ ] | | |
| Satisfaction Collision | | [ ] | | |
| Float Precision | | [ ] | | |
| Transfer Rollback | | [ ] | | |
| Node Validation | | [ ] | | |
| Type Hints | | [ ] | | |

---

**Generated:** 2025-11-08  
**For Project:** My Grandma's Legacy (Phase 3)  
**Document Location:** `/home/user/my-grandmas-legacy/CRITICAL_FIXES_CHECKLIST.md`
