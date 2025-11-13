# Staff Target Setup Guide

## Overview
Staff now use **StaffTarget** markers instead of searching for equipment. These are simple 3D waypoints you can place and position anywhere in your bakery scene.

---

## How to Add Staff Targets

### 1. Open Your Bakery Scene
- Open `scenes/bakery/bakery.tscn` in Godot editor

### 2. Add StaffTarget Nodes
- Click the **+** button or press Ctrl+A
- Navigate to `scenes/staff/staff_target.tscn`
- Or use "Instantiate Child Scene" and select `staff_target.tscn`

### 3. Configure Each Target
In the Inspector panel, set two properties:
- **target_name**: What this target is for (e.g., "sink", "oven", "register")
- **target_type**: Which staff role uses it ("baker", "cashier", "cleaner", or "any")

### 4. Position the Target
- Move the target to where you want the staff member to stand
- The target shows as a small box with a label in the editor
- Targets are invisible during gameplay

---

## Required Targets for Each Staff Type

### **Cleaner** (needs 2 targets minimum)
1. **Sink Target**
   - target_name: `sink`
   - target_type: `cleaner`
   - Position: In front of your sink

2. **Trash Target**
   - target_name: `trash`
   - target_type: `cleaner`
   - Position: Near your trash can

Optional:
- `counter` - For wiping counters
- Any other name - For equipment inspection

### **Baker** (needs 3 targets minimum)
1. **Storage Target**
   - target_name: `storage` (or `cabinet` or `ingredient`)
   - target_type: `baker`
   - Position: In front of ingredient storage

2. **Mixing Bowl Target**
   - target_name: `mixing_bowl` (or just `mixing`)
   - target_type: `baker`
   - Position: Where baker mixes ingredients

3. **Oven Target**
   - target_name: `oven`
   - target_type: `baker`
   - Position: In front of your oven

### **Cashier** (needs 2 targets minimum)
1. **Register Target**
   - target_name: `register`
   - target_type: `cashier`
   - Position: Behind or beside the register

2. **Display Target**
   - target_name: `display`
   - target_type: `cashier`
   - Position: In front of display case

---

## Example Setup

Here's a complete example for setting up all targets:

```
Bakery Scene
├── StaffTarget (Cleaner - Sink)
│   └── target_name: "sink"
│   └── target_type: "cleaner"
│   └── position: (x, 0, z) - in front of sink
│
├── StaffTarget (Cleaner - Trash)
│   └── target_name: "trash"
│   └── target_type: "cleaner"
│   └── position: (x, 0, z) - near trash can
│
├── StaffTarget (Baker - Storage)
│   └── target_name: "storage"
│   └── target_type: "baker"
│   └── position: (x, 0, z) - at ingredient cabinet
│
├── StaffTarget (Baker - Mixing)
│   └── target_name: "mixing_bowl"
│   └── target_type: "baker"
│   └── position: (x, 0, z) - at mixing station
│
├── StaffTarget (Baker - Oven)
│   └── target_name: "oven"
│   └── target_type: "baker"
│   └── position: (x, 0, z) - at oven
│
├── StaffTarget (Cashier - Register)
│   └── target_name: "register"
│   └── target_type: "cashier"
│   └── position: (x, 0, z) - at register
│
└── StaffTarget (Cashier - Display)
    └── target_name: "display"
    └── target_type: "cashier"
    └── position: (x, 0, z) - at display case
```

---

## Testing

1. Add the targets to your scene
2. Run the game (F5)
3. Hire staff during planning phase
4. Click "Open Shop"
5. Check console for messages like:
   - `[CleanerAI] Found sink target: StaffTarget`
   - `[BakerAI] Found mixing bowl target: StaffTarget`
   - `[CashierAI] Found register target: StaffTarget`

If you see warnings like `WARNING: No sink target found!`, you need to add that target.

---

## Tips

- **Naming**: The `target_name` can include keywords like "sink", "mixing_bowl", "oven", etc. The AI searches for these keywords (case-insensitive)
- **Positioning**: Position targets where you want staff to stand, not on top of equipment
- **Multiple Targets**: You can have multiple targets of the same type (e.g., 2 ovens means 2 oven targets)
- **Visibility**: Targets are visible in editor (small box + label) but invisible during gameplay
- **target_type='any'**: Use this if multiple staff types should use the same target

---

## Troubleshooting

**Staff not moving:**
- Check console for "WARNING: No [target] found!" messages
- Make sure you added the required targets
- Verify target_name and target_type are set correctly

**Staff walking in place:**
- Target position might be Vector3.ZERO
- Check that targets are Node3D nodes with valid positions
- Try repositioning the target

**Can't find StaffTarget scene:**
- Make sure you committed the new files
- Check that `scenes/staff/staff_target.tscn` exists
- Restart Godot editor if needed
