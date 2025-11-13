# Staff Visual Spawning - Testing Guide

## Overview
Staff members now appear visually in the bakery scene during their respective phases. They use the customer model but have blue name labels and don't have AI customer behaviors.

## How It Works

### Phase-Based Activation
Staff only appear during phases where their role is active:

- **Baking Phase (Phase 0)**: Bakers spawn near mixing bowls/ovens
- **Business Phase (Phase 1)**: Cashiers spawn near the register
- **Cleanup Phase (Phase 2)**: Cleaners spawn near sinks/trash
- **Planning Phase (Phase 3)**: No staff spawn (planning time)

### Visual Indicators
- Staff characters have **light blue name labels** above their heads
- Label format: `"Name (Role)"` (e.g., "Grace (Baker)")
- Characters are positioned near their workstations
- They don't move around like customers

## Testing Steps

### Test 1: Verify Baker Spawning
1. **Hire a Baker** (e.g., Grace) in the Staff tab during Planning Phase
2. **Start Baking Phase** (press Space or wait for phase to change)
3. **Look for**:
   - Console log: `[StaffManager] Found 1 bakers to activate`
   - Console log: `[StaffManager] Spawned visual character for Grace at [position]`
   - Visual: Blue-labeled character near mixing bowl/oven area
   - Position: Approximately at `(2, 0, -2)` or near mixing bowl

### Test 2: Verify Cashier Spawning
1. **Hire a Cashier** in the Staff tab during Planning Phase
2. **Start Business Phase** (after Baking Phase completes)
3. **Look for**:
   - Console log: `[StaffManager] Found 1 cashiers to activate`
   - Console log: `[StaffManager] Spawned visual character for [Name] at [position]`
   - Visual: Blue-labeled character near register
   - Position: Approximately at `(7, 0, 3)` or near register
   - **Behavior**: Should process waiting customers automatically

### Test 3: Verify Cleaner Spawning
1. **Hire a Cleaner** (e.g., Jack) in the Staff tab during Planning Phase
2. **Start Cleanup Phase** (after Business Phase completes)
3. **Look for**:
   - Console log: `[StaffManager] Found 1 cleaners to activate`
   - Console log: `[StaffManager] Spawned visual character for Jack at [position]`
   - Visual: Blue-labeled character near sink/trash area
   - Position: Approximately at `(-2, 0, 2)` or near sink

### Test 4: Verify Phase Transitions
1. **Hire multiple staff** (1 baker, 1 cashier, 1 cleaner)
2. **Progress through all phases** and watch staff appear/disappear:
   - Baking Phase: Only baker appears
   - Business Phase: Only cashier appears
   - Cleanup Phase: Only cleaner appears
   - Planning Phase: No staff visible

## Why Staff Might Not Appear

### Issue: "I hired staff but don't see them"

**Check Phase Match:**
- Baker → Must be in Baking Phase
- Cashier → Must be in Business Phase
- Cleaner → Must be in Cleanup Phase

**Check Console Logs:**
```
[StaffManager] Phase changed to: [0/1/2/3]
[StaffManager] Currently hired staff: [count]
[StaffManager] Activating [role]...
[StaffManager] Found [count] [role] to activate
[StaffManager] Spawned visual character for [name] at [position]
[StaffManager] AI worker added to scene tree: [name]
```

If you see `Found 0 [role] to activate`, you haven't hired that role.

### Issue: "Staff appear but don't do anything"

**For Bakers:**
- Need recipes queued in CraftingManager
- Need ingredients in mixing bowls
- Check console for `[BakerAI]` logs

**For Cashiers:**
- Need customers at register
- Check console for `[CashierAI]` logs showing "serving customer"

**For Cleaners:**
- Need cleanup tasks available
- Check console for `[CleanerAI]` logs

## Your Previous Test Issue

You hired:
- **Jack (Cleaner)**
- **Grace (Baker)**

But tested during **Business Phase** - neither role is active in this phase!

To see them:
- **Grace**: Press Space during Baking Phase
- **Jack**: Press Space during Cleanup Phase
- Or hire a **Cashier** to see someone during Business Phase

## Debug Console Commands

The system logs everything. Watch console for:

```
[StaffManager] Phase changed to: 1
[StaffManager] Currently hired staff: 2
[StaffManager] Activating cashiers...
[StaffManager] Found 0 cashiers to activate   <-- No cashiers hired!
[StaffManager] Active AI workers: 0
```

vs.

```
[StaffManager] Phase changed to: 0
[StaffManager] Currently hired staff: 2
[StaffManager] Activating bakers...
[StaffManager] Found 1 bakers to activate
[StaffManager] Spawned visual character for Grace at (2.5, 0, -3.2)
[StaffManager] AI worker added to scene tree: Grace
[StaffManager] Active AI workers: 1
[BakerAI] Grace is now working!
```

## Expected Behavior Summary

✅ **Correct:**
- Staff spawn only in their active phase
- Staff have blue name labels
- Staff positioned near workstations
- Staff despawn when phase ends
- Multiple staff of same role all spawn

❌ **Bug Indicators:**
- Staff spawn in wrong phase
- Staff have no labels
- Staff spawn at (0,0,0)
- Staff don't despawn between phases
- Error messages in console

## Implementation Details

### Visual Character System
- **Scene**: Reuses `res://scenes/customer/customer.tscn`
- **Positioning**: Finds workstations by name (mixing_bowl, register, sink)
- **Fallback**: Default positions if equipment not found
- **Label**: Light blue `Label3D` with outline

### AI System
- **Separate Logic Nodes**: AI workers are invisible Node instances
- **Scene Tree**: AI nodes added as children of StaffManager
- **Process Loop**: Each AI has `process(delta)` called by StaffManager
- **Activation**: Role-specific AI only runs in matching phase

### Cleanup
- Visual characters removed with `queue_free()`
- AI nodes removed from scene tree and freed
- Both systems clear on phase change

## Next Steps

1. **Test each role separately** in its correct phase
2. **Watch console logs** to verify activation
3. **Check visual spawn positions** - adjust in code if needed
4. **Report any bugs** with console logs attached

The system is fully implemented. It should work correctly when testing in the appropriate phases!
