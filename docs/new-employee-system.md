SKILL-BASED EMPLOYEE SYSTEM DESIGN

OVERVIEW
Transform the employee system from job-specific hiring to a flexible skill-based system where employees have multiple skills and can be assigned to any task. Their performance depends on their skill level in the relevant area.

1. EMPLOYEE STRUCTURE
Employee Data
Each employee should have:
Identity:

employee_name: String (randomly generated)
employee_id: Unique identifier
portrait: Optional texture for UI (can be placeholder color/icon initially)
hire_date: Day number when hired

Skills (0-100 scale each):

culinary_skill: Affects baking speed, quality, and recipe success rate
customer_service_skill: Affects checkout speed and customer satisfaction
cleaning_skill: Affects cleanup speed and thoroughness
organization_skill: Affects restocking and inventory management
barista_skill: (Future expansion) For coffee/beverage station

Attributes:

energy: 0-100, depletes during work shifts, recovers between phases
morale: 0-100, affects all skill performance (multiplier)
experience_points: Grows over time, can unlock skill improvements
days_employed: Counter for tenure

Employment:

base_wage: Daily wage based on total skill points
assigned_phase: Which phase they work ("baking", "checkout", "cleanup", "none")
current_task: Specific task within phase (optional granularity)

Personality Traits (1-3 per employee):

Affects morale changes, skill growth rates, and special behaviors
Examples: "Perfectionist", "Quick Learner", "People Person", "Night Owl", "Clumsy"


2. SKILL DISPLAY
Visual Representation
Star Rating System (0-5 stars):
 0-20: ⭐ (1 star) - Novice
21-40: ⭐⭐ (2 stars) - Beginner  
41-60: ⭐⭐⭐ (3 stars) - Competent
61-80: ⭐⭐⭐⭐ (4 stars) - Skilled
81-100: ⭐⭐⭐⭐⭐ (5 stars) - Expert

3. EMPLOYEE GENERATION
Applicant Pool Generation
Name Generation:

Random first name from pool (10-15 names)
Random last name from pool (10-15 names)
Combine for full name

Skill Distribution Archetypes:
Create realistic skill distributions, not purely random:
Archetype: "Baker"

Culinary: 60-90
Customer Service: 20-40
Cleaning: 30-50
Organization: 40-60

Archetype: "Server"

Culinary: 20-40
Customer Service: 60-90
Cleaning: 30-50
Organization: 40-60

Archetype: "All-Rounder"

All skills: 40-60 (balanced but not exceptional)

Archetype: "Specialist"

One skill: 80-100
Other skills: 10-30

Archetype: "Raw Talent"

One skill: 70-85
Other skills: 50-65
Lower wage, high growth potential

Generation Rules:

Higher total skill points = higher wage demands
Formula: base_wage = 30 + (total_skill_points / 10)
Ensure variety: Don't generate too many of same archetype at once
Applicant pool refreshes weekly or on demand (costs small fee)

Personality Trait Assignment:

Each employee gets 1-3 random traits
Some traits are rare (5% chance)
Traits should be visible during hiring decision


4. SKILL EFFECTS ON PERFORMANCE
Baking Phase (Uses Culinary Skill)
Quality Impact:
Base Quality = Recipe Base Quality
Modified Quality = Base Quality * (culinary_skill / 100) * (morale / 100) * (energy / 100)

Examples:
- 90 culinary, 80 morale, 100 energy = 72% of base quality
- 50 culinary, 60 morale, 50 energy = 15% of base quality (poor performance)
Speed Impact:
Base Time = Recipe Crafting Time
Modified Time = Base Time * (2.0 - (culinary_skill / 100))

Examples:
- 100 culinary: Takes 100% of base time (1.0x)
- 50 culinary: Takes 150% of base time (1.5x)
- 20 culinary: Takes 180% of base time (1.8x)
Failure Chance:
Failure Chance = max(0, (30 - culinary_skill) / 100)

Examples:
- 80 culinary: 0% failure chance
- 50 culinary: 0% failure (above threshold)
- 20 culinary: 10% chance to burn/ruin item
Checkout Phase (Uses Customer Service Skill)
Speed Impact:
Base Checkout Time = 45 seconds per customer
Modified Time = Base Time * (1.5 - (customer_service_skill / 200))

Examples:
- 100 customer service: 30 seconds (0.67x speed)
- 50 customer service: 37.5 seconds (0.83x speed)
- 20 customer service: 40.5 seconds (0.90x speed)
Customer Satisfaction Bonus:
Satisfaction Bonus = (customer_service_skill / 100) * 10

Examples:
- 90 customer service: +9% satisfaction
- 50 customer service: +5% satisfaction
- 20 customer service: +2% satisfaction
Change-Making Accuracy:

Low skill (< 40): 20% chance of error requiring correction (delays transaction)
Medium skill (40-70): 5% chance of error
High skill (70+): 0% errors

Cleanup Phase (Uses Cleaning Skill)
Speed Impact:
Base Cleanup Time = 10 seconds per chore
Modified Time = Base Time * (1.8 - (cleaning_skill / 125))

Examples:
- 100 cleaning: 6 seconds per chore
- 50 cleaning: 8 seconds per chore
- 20 cleaning: 10.4 seconds per chore
Thoroughness:
Cleanliness Achieved = (cleaning_skill / 100) * 100%

Examples:
- 90 cleaning: 90% clean (excellent)
- 50 cleaning: 50% clean (acceptable)
- 20 cleaning: 20% clean (poor, may need player intervention)
If cleanliness < 70%, customer satisfaction is negatively affected the next day.

5. ENERGY & MORALE SYSTEMS
Energy Depletion
Per Task Energy Cost:

Baking: -5 energy per recipe crafted
Checkout: -3 energy per customer served
Cleanup: -4 energy per chore completed

Low Energy Effects:
When energy < 30:

All skill effectiveness reduced by 50%
Speed reduced by 30%
Morale decreases by -2 per task

Energy Recovery:

Employees regain 50 energy between phases (if not working continuously)
Full recovery overnight (reset to 100 at start of new day)

Morale System
Morale Effects on Performance:
All skill calculations multiply by (morale / 100)

Examples:
- 90 culinary skill, 50 morale = effectively 45 culinary
- 90 culinary skill, 100 morale = effectively 90 culinary
Morale Changes:
Positive Factors:

Successful shift (no major issues): +2 morale
Player gives praise/bonus: +5 morale
Wage increase: +10 morale
Holiday/special event: +5 morale
Working with high-morale coworkers: +1 morale

Negative Factors:

Overworked (energy depleted to 0): -5 morale
Customer complaint: -3 morale
Fired coworker: -2 morale
No wage increase after 30 days: -5 morale
Assigned to task they're bad at repeatedly: -2 morale per day

Morale Thresholds:

80-100: Happy (works efficiently, small bonus to skill growth)
50-79: Neutral (standard performance)
20-49: Unhappy (reduced performance, may quit warning)
0-19: Miserable (threatens to quit, very poor performance)

Automatic Quitting:

If morale stays below 20 for 3 consecutive days, employee quits automatically

Add a bonus system. Can give the employee a one time bonus to boost moral temporarily. 


6. SKILL PROGRESSION
Experience Gain
Experience Points (XP) Earned:

Per task completed: +1-5 XP (based on task difficulty and performance)
Successful day with no errors: +10 bonus XP
Exceptional performance (player recognition): +20 XP

Skill Improvement:
Every 100 XP, employee can improve ONE skill:

Auto-improve skill most used in assigned phase
Improvement amount: +5 to chosen skill (capped at 100)

Personality Trait Modifiers:

"Quick Learner": XP gain +50%
"Perfectionist": Skill improvements +2 (gains +7 instead of +5)
"Lazy": XP gain -30%


7. WAGE SYSTEM
Base Wage Calculation
Total Skill Points = culinary + customer_service + cleaning + organization
Base Daily Wage = 30 + (Total Skill Points / 10)

Examples:
- Total 200 skill points: $50/day
- Total 300 skill points: $60/day
- Total 400 skill points: $70/day (excellent all-rounder or specialist)
Wage Negotiation
Employees request raises:

Every 30 days employed
After gaining 50+ skill points
If morale drops below 40

Raise Amounts:

Standard raise: +10% of current wage
Large raise (exceptional performance): +20%
Player can negotiate lower raise (risks morale loss)

Consequences of Denying Raise:

Morale: -15
Increased chance of quitting
Reduced performance temporarily


8. PERSONALITY TRAITS
Trait List & Effects
Positive Traits:
"Quick Learner" (15% spawn chance)

XP gain: +50%
Effect: Skills improve faster

"People Person" (15% spawn chance)

Customer service tasks: +10 bonus to skill
Morale gain from positive interactions: +50%

"Perfectionist" (10% spawn chance)

Quality bonus: +5% to all output quality
Morale loss from mistakes: -5 (more sensitive)
Skill improvements: +2 bonus

"Morning Person" (12% spawn chance)

Baking phase: +20 energy bonus
Other phases: standard energy

"Night Owl" (12% spawn chance)

Cleanup phase: +20 energy bonus
Other phases: standard energy

"Efficient" (10% spawn chance)

All tasks: -20% time required
Energy cost: -1 per task

"Mentor" (5% spawn chance, rare)

Nearby employees (working same phase) gain XP +25% faster
Unlocks after 50 days employed

Neutral/Quirky Traits:
"Chatty" (10% spawn chance)

Customer satisfaction: +5%
Checkout time: +10% (talks too much)

"Methodical" (10% spawn chance)

Quality: +3%
Speed: -15%

Negative Traits:
"Clumsy" (8% spawn chance)

5% chance to break/drop items during baking
Quality: -5%

"Impatient" (8% spawn chance)

Speed: +10%
Quality: -8%

"Lazy" (5% spawn chance)

XP gain: -30%
Energy depletion: +2 per task (tires faster)

"Anxious" (6% spawn chance)

High-pressure situations (lots of customers): -15 to all skills
Normal situations: standard performance


9. STAFF MANAGEMENT UI
Employee Card Layout
Each employee should display:
┌─────────────────────────────────────────┐
│ 👤 Sarah Martinez                       │
│                                         │
│ SKILLS                                  │
│ Culinary:         ⭐⭐⭐⭐☆ (78)        │
│ Customer Service: ⭐⭐⭐☆☆ (52)        │
│ Cleaning:         ⭐⭐☆☆☆ (38)        │
│ Organization:     ⭐⭐⭐☆☆ (61)        │
│                                         │
│ ATTRIBUTES                              │
│ Energy:  ████████░░ 82/100             │
│ Morale:  ██████░░░░ 65/100 (Neutral)   │
│ XP:      ███░░░░░░░ 34/100             │
│                                         │
│ EMPLOYMENT                              │
│ Wage: $63/day                           │
│ Days Employed: 24                       │
│ Assigned: Baking Phase                  │
│                                         │
│ TRAITS                                  │
│ • Quick Learner                         │
│ • Morning Person                        │
│                                         │
│ [Change Assignment ▼] [Give Raise]     │
│ [Give Bonus] [Fire]                    │
└─────────────────────────────────────────┘
Assignment Dropdown Options
When clicking "Change Assignment":

Baking Phase (Uses: Culinary skill)
Checkout Phase (Uses: Customer Service skill)
Cleanup Phase (Uses: Cleaning skill)
Restocking (Uses: Organization skill)
Off Duty (Recovers energy, no pay deduction)

Show recommended phase based on highest skill with indicator:

✓ "Best fit based on skills"


10. HIRING INTERFACE
Applicant Pool Display
Show 3-5 applicants at a time:
┌─────────────────────────────────────────┐
│ AVAILABLE APPLICANTS (3)                │
│                                         │
│ ┌─────────────────────────────────────┐ │
│ │ 👤 Jamie Rodriguez                  │ │
│ │ Wage: $68/day                       │ │
│ │                                     │ │
│ │ Culinary:      ⭐⭐⭐⭐⭐ (92)      │ │
│ │ Customer Svc:  ⭐⭐☆☆☆ (34)      │ │
│ │ Cleaning:      ⭐⭐☆☆☆ (28)      │ │
│ │ Organization:  ⭐⭐⭐☆☆ (55)      │ │
│ │                                     │ │
│ │ Traits: Perfectionist, Morning      │ │
│ │ Person                              │ │
│ │                                     │ │
│ │ Summary: Expert baker, weak in      │ │
│ │ customer service. Best for baking.  │ │
│ │                                     │ │
│ │        [View Details] [Hire]        │ │
│ └─────────────────────────────────────┘ │
│                                         │
│ [Show similar entries for 2 more        │
│  applicants with different archetypes]  │
│                                         │
│ [Refresh Applicants ($50)]              │
└─────────────────────────────────────────┘
Hiring Logic:

Player clicks [Hire]
Confirmation dialog shows total weekly cost
Employee added to roster
Removed from applicant pool
Player must assign them to a phase

Applicant Refresh:

Automatic: Every 7 days (free)
Manual: Player can pay $50 to refresh immediately
Generates 3-5 new applicants with random archetypes


11. STAFF CAPACITY & LIMITS
Maximum Staff
Initial Capacity: 2 employees
Upgrade Path:

Small Bakery: 2 staff (starting)
Medium Bakery: 4 staff (unlock: $2,000 upgrade)
Large Bakery: 6 staff (unlock: $5,000 upgrade)
Industrial Bakery: 10 staff (unlock: $10,000 upgrade)

Task Assignment Rules
Multiple Employees Same Phase:

Allowed and encouraged for busy phases
Example: 2 bakers working baking phase simultaneously
Work is distributed between them
Can overlap on tasks or work independently

Optimal Assignments:

Early game: 1 baker, 1 cashier
Mid game: 2 bakers, 1 cashier, 1 cleaner
Late game: 3 bakers, 2 cashiers, 1 cleaner, specialized roles


12. AI BEHAVIOR & AUTOMATION
Employee Task Execution
When Assigned to Phase:
Baking Phase:

Employee automatically looks for recipes to bake
Prioritizes items that are low stock in display cases
Uses skills to determine quality and speed
Cannot bake recipes player hasn't unlocked

Checkout Phase:

Automatically serves customers in queue
Processes payments based on customer service skill
Adds money to register

Cleanup Phase:

Automatically detects dirty items (dishes, floors, counters)
Cleans based on priority (critical items first)
Achieves cleanliness based on skill level

Player Can Override:

"Pause" employee (stops working, recovers energy)
Assign specific tasks (advanced): "Only bake croissants"
Fire employee mid-shift (loses morale for remaining staff)

Visual Feedback
Employee Status Indicators:

Working: Moving between stations, progress bars visible
Idle: Standing still, looking around
Low Energy: Slower movement, slouched posture (if animated)
Low Morale: Frown icon above head
Level Up: Star burst effect, celebratory animation


13. BALANCE & TUNING
Recommended Starting Values
Early Game Applicants:

Total skill points: 120-180
Wages: $42-$54/day
Mix of archetypes with emphasis on balanced and beginner specialists

Mid Game Applicants:

Total skill points: 180-260
Wages: $54-$72/day
More specialists and raw talent types

Late Game Applicants:

Total skill points: 260-360
Wages: $72-$96/day
Expert specialists and high-performing all-rounders

Economic Balance
Employee ROI:
A good employee should generate 3-5x their daily wage in value:

$50/day wage → Should contribute to ~$150-250 in sales
Player can still profit without staff (solo operation viable)
Staff make scaling easier and less time-intensive

Skill Growth Pacing:

Employee should gain +1-2 skill levels per week of employment
Full transformation from beginner to expert: ~40-60 game days


14. INTEGRATION WITH EXISTING SYSTEMS
Economy Manager
Daily Wage Deduction:

At end of day, deduct total staff wages from cash
Show in expense breakdown: "Staff Wages: $150"
If player can't afford wages, staff morale: -20, threatens to quit

Staff Performance Tracking:

Track revenue generated by employee actions
Show in statistics: "Sarah (Baker) contributed $340 this week"

Customer Satisfaction
Staff Impact on Satisfaction:

High customer service skill: +5-10% satisfaction
Low customer service skill: -5% satisfaction
Staff mistakes (wrong change, slow service): -10% satisfaction
Multiple staff serving: Reduced wait times, higher satisfaction

Progression System
Unlocks:

"Hire Staff" tutorial triggers at $500 total revenue
Staff management tab appears in planning phase
Initial applicant pool generated


15. FUTURE EXPANSION IDEAS
Additional Skills:

Barista Skill: For coffee/beverage station (future content)
Marketing Skill: Employee can help with social media/promotions
Management Skill: Can oversee other employees, provide bonuses

Advanced Features:

Employee Relationships: Staff who work together build friendship, morale boosts
Staff Requests: Employees ask for specific equipment, schedule changes
Training Programs: Player pays to send employee to culinary school (+20 culinary over 10 days)
Employee Events: Birthday, family emergency, vacation requests

Special Employee Types:

Intern: Very low wage, low skills, rapid growth
Retired Expert: Very high skill, high wage, no growth, part-time only
Family Member: Special unique employee with story connection


16. IMPLEMENTATION CHECKLIST
Phase 1: Core System

 Create Employee resource/class with all attributes
 Implement employee generation with archetypes
 Build basic staff management UI
 Implement skill-based performance calculations
 Create assignment system (dropdown, phase selection)

Phase 2: Hiring & Management

 Build applicant pool UI
 Implement hiring flow
 Add wage system and daily deductions
 Create employee detail view
 Implement fire/raise/bonus actions

Phase 3: Progression & Morale

 Implement XP system and skill improvements
 Build morale system with triggers
 Create energy depletion and recovery
 Add personality traits and effects
 Implement auto-quit logic

Phase 4: AI Behavior

 Implement employee task automation for baking
 Implement employee task automation for checkout
 Implement employee task automation for cleanup
 Add visual status indicators
 Polish animations and feedback

Phase 5: Balance & Polish

 Tune skill effects on performance
 Balance wages vs. value generated
 Test progression pacing
 Add tooltips and tutorials
 Implement save/load for employee data


END OF DOCUMENT
This skill-based employee system provides depth, strategy, and meaningful player choice while maintaining the cozy, forgiving tone of the game. Employees feel like real people who grow and develop rather than static job-holders.