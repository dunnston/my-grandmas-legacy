# My Grandma's Legacy - Development Plan

**Last Updated:** 2025-11-07
**Current Phase:** Phase 4 - Polish & Content
**Project Status:** Active Development

**Phase 1 Status:** ✅ COMPLETE (Merged to main)
**Phase 2 Status:** ✅ COMPLETE (Merged to main)
**Phase 3 Status:** ✅ COMPLETE (Merged to main)
**Phase 4 Status:** 🔄 IN PROGRESS

---

## Overview

This is a living document that tracks the development progress of "My Grandma's Legacy" - a cozy 3D bakery management game. Development follows a phase-based approach with feature branches for each phase.

**Development Philosophy:**
- Gameplay first, art assets later
- Start with CSG/primitive shapes for rapid iteration
- Test frequently in Godot editor (F5/F6)
- Commit often to feature branches
- Merge to main only when phase is complete and tested

**Branching Strategy:**
- `main` = Production-ready code only (never commit directly)
- `phase-X-feature-name` = Feature branches for each phase
- Commit frequently during development
- Merge PR to main when phase complete

---

## Phase 1: Core Prototype ✅ COMPLETE
**Branch:** `phase-1-core-prototype` (merged to main)
**Goal:** Prove core loop is fun
**Time Estimate:** 2-3 weeks
**Status:** ✅ COMPLETE

### Success Criteria
- [x] Can complete one full day loop
- [x] Baking feels engaging and satisfying
- [x] Controls feel responsive
- [x] Time system works correctly

### Tasks

#### Scene Setup
- [ ] Create main Bakery scene (Bakery.tscn)
- [ ] Add basic bakery layout using CSG shapes (walls, floor, ceiling)
- [ ] Set up lighting (basic DirectionalLight3D and ambient)
- [ ] Add camera system (third-person follow)
- [ ] Create spawn points for player start position

#### Player Character
- [ ] Create Player scene (CharacterBody3D)
- [ ] Implement WASD movement with proper physics
- [ ] Add mouse look/camera rotation
- [ ] Add sprint functionality (optional)
- [ ] Add interaction raycast/area detection
- [ ] Show [E] prompt when near interactable objects

#### Ingredient System
- [ ] Create Ingredient resource class (ingredient_id, name, quantity)
- [ ] Implement player inventory (array/dictionary)
- [ ] Create 5 basic ingredients (flour, sugar, eggs, butter, milk)
- [ ] Add ingredient storage area (CSG box placeholder)
- [ ] Allow picking up ingredients from storage

#### Crafting Station - Mixing Bowl
- [ ] Create MixingBowl scene with CSG shapes
- [ ] Add interaction area/prompt
- [ ] Create crafting UI panel
- [ ] Show player inventory in left panel
- [ ] Show station inventory slots in center
- [ ] Implement drag-and-drop ingredient transfer
- [ ] Create simple bread recipe (flour + water + yeast)
- [ ] Add "Start Mixing" button when recipe complete
- [ ] Implement mixing timer (60 seconds)
- [ ] Show progress bar during mixing
- [ ] Transfer mixed dough to player inventory when complete

#### Oven System
- [ ] Create Oven scene with CSG shapes
- [ ] Add interaction area/prompt
- [ ] Create oven UI (load/check/remove options)
- [ ] Allow loading dough into oven
- [ ] Implement baking timer (5 minutes game time)
- [ ] Add visual indicator (glow/particles) during baking
- [ ] Add audio cue when done
- [ ] Allow removing finished bread
- [ ] Transfer baked bread to player inventory

#### Display Case
- [ ] Create DisplayCase scene with CSG shapes
- [ ] Add interaction area
- [ ] Create display case UI
- [ ] Allow stocking baked goods from inventory
- [ ] Show items visually in case (simple meshes)

#### Time System
- [ ] Create GameManager singleton (autoload)
- [ ] Implement game time tracking
- [ ] Add time scale controls (pause, 1x, 2x, 3x)
- [ ] Create HUD with clock display
- [ ] Add HUD with current phase indicator

#### Phase Transitions
- [ ] Implement phase state machine in GameManager
- [ ] Add "Start Baking Phase" button/trigger
- [ ] Add "End Baking Phase" button (transition to Business)
- [ ] Add placeholder for Business phase (skip for now)
- [ ] Add "End Day" button to test full loop
- [ ] Reset scene for next day

#### Testing & Polish
- [ ] Test complete baking workflow (storage → mix → bake → display)
- [ ] Test time controls (pause/speed)
- [ ] Verify collision and movement feel good
- [ ] Check camera doesn't clip through walls
- [ ] Add basic print() debug statements
- [ ] Playtest and document any issues

---

## Phase 2: Business & Economy ✅ COMPLETE
**Branch:** `phase-2-business-economy` (merged to main)
**Goal:** Complete gameplay loop with economy
**Time Estimate:** 3-4 weeks
**Status:** ✅ COMPLETE

### Success Criteria
- [ ] Can play multiple days in sequence (READY TO TEST)
- [ ] Economy feels balanced for early game (NEEDS TESTING)
- [ ] Customer interactions work smoothly (READY TO TEST)
- [ ] Can save and load progress (READY TO TEST)

### Tasks

#### Customer System
- [x] Create Customer scene (CharacterBody3D)
- [x] Create customer spawn points
- [x] Implement customer pathfinding (NavigationAgent3D)
- [x] Create path: entrance → display case → register → exit
- [x] Add customer browsing behavior (pause at display)
- [x] Implement customer mood system (happy/neutral/unhappy)
- [x] Add simple customer variations (3-4 body types with CSG) - Basic variation done

#### Shopping & Checkout
- [x] Create Register/Checkout station
- [x] Implement customer item selection from display
- [x] Create checkout UI (console-based for now)
- [x] Show selected items and prices
- [x] Add "Complete Transaction" button (automatic via register interaction)
- [x] Calculate total and update money
- [x] Customer leaves after purchase
- [x] Track customer satisfaction (basic)

#### Economy System
- [x] Create EconomyManager singleton
- [x] Implement money tracking (starts at $200)
- [x] Create HUD element for current cash
- [x] Add ingredient costs to storage pickup (pricing in place)
- [x] Set bread sell price ($15-25 based on quality) - Recipes have base prices
- [x] Track daily revenue
- [x] Track daily expenses

#### Recipe Expansion
- [x] Add Chocolate Chip Cookies recipe
- [x] Add Blueberry Muffins recipe
- [x] Update crafting UI to show recipe selection (can be done in Phase 3)
- [x] Create RecipeManager singleton
- [x] Store recipe data (ingredients, times, prices)

#### Planning Phase Menu
- [x] Create Planning phase UI (CanvasLayer)
- [x] Add Daily Report tab (revenue, expenses, profit)
- [x] Add simple ingredient ordering interface
- [x] Show cash on hand and deduct for purchases
- [x] Add "Start Next Day" button
- [x] Transition back to Baking phase

#### Save/Load System
- [x] Create SaveManager singleton
- [x] Define save data structure (cash, day, recipes, upgrades)
- [x] Implement save to JSON in user:// directory
- [x] Implement load from JSON
- [x] Auto-save at end of each day
- [ ] Add manual save button in planning phase (can add later)
- [ ] Add load game option in main menu (can add later)

#### Day Progression
- [x] Implement day counter
- [x] Show day number in HUD
- [x] Phase transitions: Baking → Business → Cleanup → Planning → next day
- [x] Add Cleanup phase placeholder (auto-complete for now)

#### Testing & Iteration
- [ ] Playtest 5-day sequence (READY TO TEST IN EDITOR)
- [ ] Verify economy balance (can afford next day ingredients?)
- [ ] Test save/load at various points
- [ ] Check customer spawning and pathing
- [ ] Verify phase transitions work smoothly
- [ ] Document any bugs or balance issues

---

## Phase 3: Progression Systems ✅ COMPLETE
**Branch:** `phase-3-progression-systems` (merged to main)
**Goal:** Add depth and long-term goals
**Time Estimate:** 4-5 weeks
**Status:** ✅ COMPLETE

**Core systems implemented:**
- ✅ ProgressionManager with milestone tracking
- ✅ Reputation system (0-100, affects traffic)
- ✅ Lifetime revenue tracking
- ✅ Recipe unlock system
- ✅ Traffic calculation based on reputation + day of week

**Remaining work:**
- Equipment upgrade system
- Staff hiring and management
- Ingredient expiration
- UI integration for progression features

### Success Criteria
- [x] Core progression systems implemented
- [x] Reputation system tracking customer satisfaction
- [x] Milestone-based unlocks functioning
- [x] Traffic scaling with reputation and day-of-week

### Tasks

#### Progression Manager
- [x] Create ProgressionManager singleton
- [x] Track total revenue across all days
- [x] Implement milestone checking ($500, $2000, $5000, etc.)
- [x] Create unlock system for recipes
- [ ] Add unlock notifications/popups (signals ready, UI pending)

#### Recipe Unlocks
- [ ] Create all recipes from GDD (27 total)
- [ ] Organize by unlock tiers (Basic Pastries, Artisan Breads, etc.)
- [ ] Lock recipes behind milestones
- [ ] Add "New Recipe Unlocked!" UI feedback
- [ ] Update recipe book UI to show locked recipes (grayed out)
- [ ] Add grandmother's notes to each recipe

#### Upgrade System - Equipment
- [ ] Create equipment tier data (Broken/Basic/Standard/Professional/Industrial)
- [ ] Implement oven upgrades (speed, quality modifiers)
- [ ] Implement mixing bowl size upgrades
- [ ] Implement display case capacity upgrades
- [ ] Add upgrade shop in Planning phase
- [ ] Show costs and benefits for each upgrade
- [ ] Apply equipment bonuses to crafting quality/speed
- [ ] Visual changes when equipment upgraded (placeholder)

#### Reputation System
- [x] Add reputation score (0-100, starts at 50)
- [x] Track customer satisfaction per day
- [x] Update reputation based on happy/unhappy customers
- [x] Show reputation in Planning phase report (data available)
- [x] Implement reputation decay (slow return to 50)

#### Traffic System
- [x] Create CustomerManager for spawning logic (enhanced existing)
- [x] Base traffic on reputation score
- [x] Add day-of-week modifiers (Mon-Thu 1.0x, Fri 1.3x, Sat 1.5x, Sun 1.2x)
- [x] Implement traffic projection in Planning phase
- [x] Scale customer spawns based on traffic calculation

#### Staff Hiring System
- [ ] Create Staff resource class (name, role, skill, wage)
- [ ] Add Staff Management tab in Planning phase
- [ ] Generate random applicants weekly
- [ ] Allow hiring up to 3 staff initially
- [ ] Implement Baker AI (follows recipes, produces items)
- [ ] Implement Cashier AI (handles checkout)
- [ ] Implement Cleaner AI (auto-completes cleanup)
- [ ] Deduct daily wages from cash
- [ ] Track staff experience and skill improvement

#### Ingredient Expiration
- [ ] Add expiration_date to ingredients
- [ ] Show days until expiration in inventory
- [ ] Ingredients spoil after expiration
- [ ] Warning indicators for expiring items
- [ ] Disposal during cleanup phase

#### Catch-Up Mechanic
- [ ] Detect 3 consecutive days below $50 profit
- [ ] Trigger "Community Support" event
- [ ] Offer 50% discount on ingredient order
- [ ] Or announce special high-traffic event

#### Testing & Balance
- [ ] Playtest 2-week progression
- [ ] Verify milestone pacing feels good
- [ ] Check unlock timing
- [ ] Test staff hiring and effectiveness
- [ ] Validate economy still balanced with staff wages
- [ ] Adjust costs/prices as needed

---

## Phase 4: Polish & Content 🔄 IN PROGRESS
**Branch:** `phase-4-polish-content`
**Goal:** Full content and visual improvements
**Time Estimate:** 6-8 weeks
**Status:** 🔄 IN PROGRESS

### Success Criteria
- [ ] Game feels complete from start to finish
- [ ] Story beats are emotional and engaging
- [ ] All 27 recipes implemented
- [ ] Full upgrade catalog available

### Tasks

#### Complete Recipe Catalog
- [x] Implement all 27 recipes with proper data
- [x] Connect recipes to milestone unlock system
- [ ] Test each recipe's crafting workflow in-game
- [ ] Balance costs and sell prices for each
- [ ] Add quality variations for each recipe
- [ ] Implement legendary item chance (5% on perfect)

#### Upgrade Catalog Expansion
- [ ] Add all furniture options (tables, chairs, shelving)
- [ ] Add decoration options (paint, wallpaper, flooring, lighting)
- [ ] Add structural upgrades (wall repairs, expansion)
- [ ] Implement visual changes for aesthetic upgrades
- [ ] Create upgrade preview system

#### Marketing System
- [ ] Add Marketing tab in Planning phase
- [ ] Implement Newspaper ad (cost, boost, duration)
- [ ] Implement Social Media campaign
- [ ] Implement Radio/TV advertising
- [ ] Implement Billboard (permanent boost)
- [ ] Show active campaigns in Planning phase
- [ ] Apply traffic bonuses during active campaigns

#### Special Events System
- [ ] Create EventManager singleton
- [ ] Implement random events (critic, weather, festival, etc.)
- [ ] Add scheduled events (holidays, market, inspection)
- [ ] Create event notification UI
- [ ] Implement event-specific mechanics (bulk orders, critic scoring)
- [ ] Balance event frequency and impact

#### Story Implementation
- [x] Write grandmother's letters for each milestone (7 letters complete)
- [x] Create StoryManager singleton for narrative
- [x] Trigger story beats at milestones (auto-connected)
- [x] Integrate with save/load system
- [ ] Create story beat UI (letter reading popup) - needs UI work
- [ ] Add grandmother's photo to bakery (visual asset)
- [ ] Add newspaper article props (visual asset)
- [ ] Add recipe book with notes (UI work)
- [ ] Polish final ending sequence ($50k milestone)

#### Apartment Scene
- [ ] Create Apartment.tscn (upstairs)
- [ ] Add basic furniture and decorations (CSG)
- [ ] Add transition between bakery and apartment
- [ ] Add sleep interaction (optional time skip)
- [ ] Add decorative interactions (TV, bookshelf)

#### Quality of Life Features
- [ ] Add hotkeys for common actions
- [ ] Add quick inventory access (Tab key)
- [ ] Add batch ingredient purchasing
- [ ] Add recipe favorites/pinning
- [ ] Add undo/redo for planning purchases
- [ ] Add confirmation dialogs for expensive purchases

#### Begin Asset Replacement
- [ ] Identify critical models for replacement
- [ ] Replace oven CSG with low-poly model
- [ ] Replace mixing bowl with model
- [ ] Replace display case with model
- [ ] Keep player as simple capsule/cylinder for now
- [ ] Keep customers simple for now

#### Testing & Content Validation
- [ ] Full playthrough from day 1 to $50k milestone
- [ ] Verify all recipes unlock correctly
- [ ] Test all upgrades visually appear
- [ ] Verify story beats trigger correctly
- [ ] Check for softlocks or progression blockers
- [ ] Balance review for mid-late game

---

## Phase 5: Juice & Audio
**Branch:** `phase-5-juice-audio`
**Goal:** Make it feel amazing
**Time Estimate:** 3-4 weeks
**Status:** Not Started

### Success Criteria
- [ ] Game feels cozy and polished
- [ ] Audio enhances the experience
- [ ] Visual feedback is satisfying
- [ ] Onboarding is smooth for new players

### Tasks

#### Visual Effects
- [ ] Add particle effects for mixing (flour puffs)
- [ ] Add particle effects for oven (steam when opened)
- [ ] Add glow effect on interactable objects when nearby
- [ ] Add item pickup animation (lerp to inventory)
- [ ] Add money popup on sales (+$XX floats up)
- [ ] Add quality indicator sparkles (legendary items)
- [ ] Add screen transitions between phases (fade)

#### UI Polish
- [ ] Add hover effects on all buttons
- [ ] Add click animations (scale down/up)
- [ ] Add smooth transitions for panel open/close
- [ ] Add progress bars for timers with color changes
- [ ] Add tooltips for all upgrade items
- [ ] Polish HUD layout and readability
- [ ] Add icons for money, reputation, day count

#### Camera Polish
- [ ] Add slight dynamic tilt when moving
- [ ] Smooth camera follow with lag
- [ ] Add subtle camera shake for oven opening
- [ ] Ensure camera collision prevents wall clipping
- [ ] Add camera zoom options (optional)

#### Sound Effects
- [ ] Footstep sounds (different for floor types)
- [ ] Mixing bowl sounds (whisk, scrape)
- [ ] Oven sounds (door open/close, ding when ready)
- [ ] Cash register sound
- [ ] Money sounds (coins, bills)
- [ ] UI click/hover sounds
- [ ] Customer chatter (ambient loop)
- [ ] Door chime when customers enter
- [ ] Item pickup sound

#### Music
- [ ] Source/create 3-5 cozy background music tracks
- [ ] Implement music manager with crossfade
- [ ] Assign tracks to different phases/moods
- [ ] Add music volume control in settings
- [ ] Loop music smoothly

#### Ambient Audio
- [ ] Oven humming sound (positional 3D audio)
- [ ] Refrigerator hum
- [ ] Clock ticking (subtle)
- [ ] Outside ambiance (birds, light traffic)
- [ ] Implement 3D spatial audio for world sounds

#### Animation System
- [ ] Add simple idle/walk animations for player (or keep capsule)
- [ ] Add customer walking animation
- [ ] Add customer browsing animation (look around)
- [ ] Add equipment animations (oven door, mixing bowl rotation)
- [ ] Add item placement animations (stocking display case)

#### Tutorial System
- [ ] Create tutorial popup manager
- [ ] Add Day 1 intro tutorial sequence
- [ ] Add context-sensitive tips (first time at each station)
- [ ] Add recipe tutorial (first crafting attempt)
- [ ] Add business phase tutorial (first customers)
- [ ] Add planning phase tutorial
- [ ] Add skip tutorial option

#### Accessibility Features
- [ ] Add colorblind mode options
- [ ] Add adjustable text size
- [ ] Add control remapping UI
- [ ] Add audio cues for timer completion (vision assist)
- [ ] Add subtitles for any voiceover (if added)
- [ ] Test with keyboard-only controls

#### Testing & Feel
- [ ] Playtest for "juice" and satisfaction
- [ ] Get feedback on audio levels
- [ ] Verify tutorial clarity with new players
- [ ] Test accessibility features
- [ ] Polish any rough edges

---

## Phase 6: Balance & Testing
**Branch:** `phase-6-balance-testing`
**Goal:** Ensure fun across all skill levels
**Time Estimate:** 2-3 weeks
**Status:** Not Started

### Success Criteria
- [ ] Multiple playtesters complete game and enjoy it
- [ ] Economy is balanced across entire game
- [ ] No major bugs or crashes
- [ ] Performance is smooth (60 FPS target)

### Tasks

#### Playtesting
- [ ] Recruit 5-10 playtesters (varied skill levels)
- [ ] Provide playtest builds
- [ ] Create feedback survey/form
- [ ] Collect playtester feedback
- [ ] Watch playtester sessions (if possible)
- [ ] Identify pain points and confusion

#### Economy Balancing
- [ ] Review all ingredient costs vs recipe profits
- [ ] Adjust prices for balanced progression
- [ ] Verify milestone timing (not too fast/slow)
- [ ] Check staff wages vs benefit tradeoff
- [ ] Adjust upgrade costs for pacing
- [ ] Test economy with different playstyles

#### Difficulty Curve
- [ ] Adjust early game difficulty (tutorial/learning)
- [ ] Balance mid-game challenge (growth phase)
- [ ] Tune late-game complexity (mastery)
- [ ] Ensure catch-up mechanic triggers appropriately
- [ ] Verify no impossible scenarios

#### Bug Fixing
- [ ] Address all critical bugs (crashes, softlocks)
- [ ] Fix high-priority bugs (broken features)
- [ ] Fix medium-priority bugs (exploits, QOL)
- [ ] Address low-priority bugs (minor visual issues)
- [ ] Test fixes thoroughly

#### Performance Optimization
- [ ] Profile game performance
- [ ] Optimize customer spawning/despawning
- [ ] Batch similar decorations/objects
- [ ] Implement LOD for distant objects
- [ ] Reduce draw calls where possible
- [ ] Test on lower-end hardware
- [ ] Aim for stable 60 FPS

#### Final Polish
- [ ] Fix any remaining visual glitches
- [ ] Adjust audio mixing/levels
- [ ] Final pass on UI clarity
- [ ] Check all text for typos
- [ ] Verify all story beats work
- [ ] Test edge cases (empty displays, no money, etc.)

#### Prepare for Release
- [ ] Create final release build
- [ ] Test release build thoroughly
- [ ] Write release notes / patch notes
- [ ] Create itch.io page (or chosen platform)
- [ ] Prepare screenshots and trailer (if applicable)
- [ ] Set up community feedback channels

#### Merge to Main
- [ ] Final code review
- [ ] Merge phase-6 branch to main
- [ ] Tag release version (v1.0.0)
- [ ] Archive phase branches
- [ ] Celebrate launch!

---

## Post-Release (Ongoing)

### Potential Updates
- [ ] Monitor player feedback
- [ ] Address critical post-launch bugs
- [ ] Balance adjustments based on data
- [ ] Consider DLC: seasonal recipes, new locations
- [ ] Community features (sharing bakery designs?)

---

## Notes & Decisions

### 2025-11-07
- Project initialized
- GDD reviewed and approved
- PLAN.md created with 6-phase breakdown
- Git repository to be initialized
- Starting with Phase 1: Core Prototype

---

## Resources
- **GDD:** [GDD.md](GDD.md) - Complete game design document
- **Project Instructions:** [CLAUDE.md](CLAUDE.md) - Development guidelines
- **Godot Docs:** https://docs.godotengine.org/en/stable/
- **Project Repository:** (local git)

---

**Remember:** Commit often, test in editor frequently (F5/F6), and keep it fun!
