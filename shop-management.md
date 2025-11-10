SHOP MANAGEMENT MENU - FULL DESIGN

MENU STRUCTURE & TABS
Shop Management Menu (Opens with [Tab] or [M] key)
├── Dashboard (Default landing tab)
├── Pricing
├── Staff
├── Marketing
├── Statistics
├── Events & Projections
└── Settings (optional)

TAB 1: DASHBOARD
Purpose: Quick overview of current business health
Layout:
┌─────────────────────────────────────────────────┐
│  DASHBOARD - Day 47                             │
├─────────────────────────────────────────────────┤
│                                                 │
│  TODAY'S SUMMARY                                │
│  ┌─────────────────┬─────────────────┐         │
│  │ Revenue: $347   │ Expenses: $89   │         │
│  │ Profit: $258    │ Customers: 23   │         │
│  └─────────────────┴─────────────────┘         │
│                                                 │
│  REPUTATION                     🌟 78/100      │
│  ████████████████░░░░                          │
│  Status: "Popular Local Bakery"                │
│                                                 │
│  CURRENT ALERTS                                │
│  ⚠️ Low ingredient stock: Flour (2 days left)  │
│  ⚠️ Staff wages due tomorrow: $150             │
│  ✓ Food critic visit in 3 days                │
│                                                 │
│  QUICK STATS                                    │
│  • Average Customer Satisfaction: 😊 85%       │
│  • Best Selling Item: Croissants (14 sold)     │
│  • Daily Traffic Trend: ↑ +12%                 │
│                                                 │
└─────────────────────────────────────────────────┘
Key Elements:

Today's financials at a glance
Reputation bar with numerical value
Alert/notification system
Quick actionable insights


TAB 2: PRICING
Purpose: Set individual prices for all products
Layout:
┌─────────────────────────────────────────────────┐
│  PRICING MANAGER                                │
├─────────────────────────────────────────────────┤
│                                                 │
│  Search: [________] Filter: [All ▼]            │
│                                                 │
│  BREADS                                         │
│  ┌──────────────────────────────────────────┐  │
│  │ White Bread                              │  │
│  │ Cost: $8  Market: $15-25  Current: $18  │  │
│  │ [-] [$18] [+]  [Reset to Market Avg]    │  │
│  │ Sales (7 days): 47 units                 │  │
│  │ Customer Feedback: ✓ Fair Price          │  │
│  └──────────────────────────────────────────┘  │
│                                                 │
│  ┌──────────────────────────────────────────┐  │
│  │ Sourdough                                │  │
│  │ Cost: $12  Market: $20-35  Current: $28  │  │
│  │ [-] [$28] [+]  [Reset to Market Avg]    │  │
│  │ Sales (7 days): 32 units                 │  │
│  │ Customer Feedback: ⚠️ Slightly High      │  │
│  └──────────────────────────────────────────┘  │
│                                                 │
│  PASTRIES                                       │
│  [Similar layout for each pastry...]           │
│                                                 │
│  BULK ACTIONS:                                  │
│  [Apply 10% Discount to All]                   │
│  [Reset All to Market Average]                 │
│  [Match Competitor Prices]                     │
│                                                 │
└─────────────────────────────────────────────────┘
Key Features:

Individual price sliders/input for each item
Show cost vs. market range vs. current price
Real-time feedback on customer price tolerance
Sales history for each item
Bulk pricing actions
Visual indicators (green = good price, yellow = high, red = too high)

Pricing Logic:
gdscript# Customer tolerance calculation
func is_price_acceptable(item: String, price: float) -> bool:
    var base_tolerance = item_data[item].market_price_range
    var reputation_modifier = reputation / 100.0
    var quality_modifier = average_quality[item] / 100.0
    
    var max_acceptable = base_tolerance.max * (1.0 + reputation_modifier * 0.2)
    
    return price <= max_acceptable
```

---

## **TAB 3: STAFF**

**Purpose:** Hire, manage, and assign employees

**Layout:**
```
┌─────────────────────────────────────────────────┐
│  STAFF MANAGEMENT                               │
├─────────────────────────────────────────────────┤
│                                                 │
│  CURRENT EMPLOYEES (2/5)                        │
│                                                 │
│  ┌──────────────────────────────────────────┐  │
│  │ 👤 Sarah Martinez                        │  │
│  │ Role: Baker  Experience: ★★★★☆           │  │
│  │ Skills: Baking ★★★★☆ Speed ★★★☆☆        │  │
│  │ Wage: $100/day  Hired: Day 12            │  │
│  │                                           │  │
│  │ Assignment: [Baking Phase ▼]             │  │
│  │ Status: ✓ Happy (Morale: 85%)            │  │
│  │                                           │  │
│  │ [View Details] [Give Raise] [Fire]       │  │
│  └──────────────────────────────────────────┘  │
│                                                 │
│  ┌──────────────────────────────────────────┐  │
│  │ 👤 Marcus Chen                           │  │
│  │ Role: Cashier  Experience: ★★☆☆☆         │  │
│  │ Skills: Service ★★★☆☆ Speed ★★☆☆☆       │  │
│  │ Wage: $60/day  Hired: Day 35             │  │
│  │                                           │  │
│  │ Assignment: [Checkout Phase ▼]           │  │
│  │ Status: ⚠️ Neutral (Morale: 60%)          │  │
│  │                                           │  │
│  │ [View Details] [Give Raise] [Fire]       │  │
│  └──────────────────────────────────────────┘  │
│                                                 │
│  HIRE NEW STAFF                                 │
│  ┌──────────────────────────────────────────┐  │
│  │ AVAILABLE APPLICANTS (3)                 │  │
│  │                                           │  │
│  │ 👤 Jamie Rodriguez - Baker ★★★★★         │  │
│  │    Wage: $180/day  [View] [Hire]        │  │
│  │                                           │  │
│  │ 👤 Alex Kim - Cleaner ★★☆☆☆              │  │
│  │    Wage: $45/day  [View] [Hire]         │  │
│  │                                           │  │
│  │ 👤 Pat O'Brien - Cashier ★★★☆☆           │  │
│  │    Wage: $75/day  [View] [Hire]         │  │
│  └──────────────────────────────────────────┘  │
│                                                 │
│  [Refresh Applicants ($50)] - Updates weekly   │
│                                                 │
└─────────────────────────────────────────────────┘
Key Features:

Current staff roster with stats
Skill visualization (star ratings)
Assignment dropdown (which phase they work)
Morale system (affects performance)
Hiring interface with applicant pool
Staff progression (skills improve over time)

Staff Impact:
gdscript# Staff effectiveness calculation
func get_staff_performance(staff: Staff) -> float:
    var base_performance = staff.skill_level / 5.0
    var morale_modifier = staff.morale / 100.0
    var experience_bonus = min(staff.days_worked / 100.0, 0.3)
    
    return base_performance * morale_modifier + experience_bonus
```

---

## **TAB 4: MARKETING**

**Purpose:** Purchase advertising and view active campaigns

**Layout:**
```
┌─────────────────────────────────────────────────┐
│  MARKETING & ADVERTISING                        │
├─────────────────────────────────────────────────┤
│                                                 │
│  ACTIVE CAMPAIGNS                               │
│  ┌──────────────────────────────────────────┐  │
│  │ 📰 Newspaper Ad                          │  │
│  │ Days Remaining: 1  Traffic Boost: +15%   │  │
│  │ Total Customers Reached: ~230            │  │
│  └──────────────────────────────────────────┘  │
│                                                 │
│  ┌──────────────────────────────────────────┐  │
│  │ 📱 Social Media Campaign                 │  │
│  │ Days Remaining: 3  Traffic Boost: +25%   │  │
│  │ Engagement: 1,247 likes, 89 shares       │  │
│  └──────────────────────────────────────────┘  │
│                                                 │
│  PURCHASE NEW CAMPAIGNS                         │
│                                                 │
│  ┌──────────────────────────────────────────┐  │
│  │ 📰 NEWSPAPER AD            Cost: $50     │  │
│  │ Duration: Next day only                   │  │
│  │ Expected Boost: +10-20% traffic          │  │
│  │ Best For: Quick local awareness          │  │
│  │                              [Purchase]   │  │
│  └──────────────────────────────────────────┘  │
│                                                 │
│  ┌──────────────────────────────────────────┐  │
│  │ 📱 SOCIAL MEDIA             Cost: $150   │  │
│  │ Duration: 3 days                         │  │
│  │ Expected Boost: +20-30% traffic          │  │
│  │ Best For: Younger demographic            │  │
│  │                              [Purchase]   │  │
│  └──────────────────────────────────────────┘  │
│                                                 │
│  ┌──────────────────────────────────────────┐  │
│  │ 📻 RADIO SPOT               Cost: $300   │  │
│  │ Duration: 5 days                         │  │
│  │ Expected Boost: +30-50% traffic          │  │
│  │ Best For: Broad reach                    │  │
│  │                              [Purchase]   │  │
│  └──────────────────────────────────────────┘  │
│                                                 │
│  ┌──────────────────────────────────────────┐  │
│  │ 🏢 BILLBOARD            Cost: $1,000     │  │
│  │ Duration: Permanent                       │  │
│  │ Expected Boost: +5% traffic (ongoing)    │  │
│  │ Best For: Long-term visibility           │  │
│  │                              [Purchase]   │  │
│  └──────────────────────────────────────────┘  │
│                                                 │
│  MARKETING TIPS:                                │
│  • Stack campaigns for bigger events           │
│  • Plan ads 2-3 days before special events     │
│  • Monitor ROI in Statistics tab               │
│                                                 │
└─────────────────────────────────────────────────┘
```

**Key Features:**
- Active campaign tracking
- Clear cost/benefit display
- Purchase buttons with confirmation
- Campaign stacking allowed
- Marketing tips/advice

---

## **TAB 5: STATISTICS**

**Purpose:** Deep dive into business analytics

**Layout:**
```
┌─────────────────────────────────────────────────┐
│  STATISTICS & ANALYTICS                         │
├─────────────────────────────────────────────────┤
│                                                 │
│  TIME RANGE: [Last 7 Days ▼] [Custom Range]    │
│                                                 │
│  REPUTATION HISTORY                             │
│  ┌──────────────────────────────────────────┐  │
│  │ 100│                            ╱─╲      │  │
│  │  90│                       ╱───╯   ╲     │  │
│  │  80│                  ╱───╯         ╲    │  │
│  │  70│             ╱───╯               ╲─  │  │
│  │  60│        ╱───╯                        │  │
│  │  50│───────╯                             │  │
│  │    └────────────────────────────────────│  │
│  │     D1  D10  D20  D30  D40  D50         │  │
│  └──────────────────────────────────────────┘  │
│                                                 │
│  REVENUE & PROFIT                               │
│  ┌──────────────────────────────────────────┐  │
│  │ $500│        Revenue ─── Profit ─ ─ ─    │  │
│  │ $400│           ╱─╲          ╱─╲         │  │
│  │ $300│      ╱───╯   ╲    ╱───╯   ╲        │  │
│  │ $200│ ╱───╯         ╲──╯         ╲─      │  │
│  │ $100│╯                              ─     │  │
│  │   $0└────────────────────────────────────│  │
│  │     Day1  Day3  Day5  Day7               │  │
│  └──────────────────────────────────────────┘  │
│                                                 │
│  CUSTOMER METRICS                               │
│  ┌────────────────────┬─────────────────────┐  │
│  │ Total Served: 347  │ Avg/Day: 49.6      │  │
│  │ Returning: 89 (26%)│ New: 258 (74%)     │  │
│  │ Happy: 78%  😊     │ Neutral: 18% 😐    │  │
│  │ Unhappy: 4% ☹️     │ Lost: 12           │  │
│  └────────────────────┴─────────────────────┘  │
│                                                 │
│  TOP SELLING ITEMS (Last 7 Days)                │
│  1. Croissants........98 sold.....$1,960 rev   │
│  2. Sourdough Bread...67 sold.....$1,876 rev   │
│  3. Choc Chip Cookies.89 sold.....$1,513 rev   │
│  4. Cinnamon Rolls....45 sold.....$1,125 rev   │
│  5. Blueberry Muffins.56 sold.....$1,008 rev   │
│                                                 │
│  EXPENSE BREAKDOWN                              │
│  ┌──────────────────────────────────────────┐  │
│  │ Ingredients: 45% ████████████            │  │
│  │ Staff Wages: 30% ████████                │  │
│  │ Marketing:   15% ████                    │  │
│  │ Utilities:    7% ██                      │  │
│  │ Other:        3% █                       │  │
│  └──────────────────────────────────────────┘  │
│                                                 │
│  [Export Report as CSV]  [Print Summary]       │
│                                                 │
└─────────────────────────────────────────────────┘
Key Features:

Line graph for reputation over time (This is your main request!)
Revenue/profit dual-line graph
Customer satisfaction breakdown
Best/worst selling items
Expense pie chart or bar graph
Exportable data (nice touch for players who like data)

Graph Implementation:
gdscript# Simple line graph using Godot's draw functions
extends Control

var data_points: Array[Vector2] = []
var max_value: float = 100.0
var graph_size: Vector2 = Vector2(600, 200)

func _draw():
    if data_points.size() < 2:
        return
    
    # Draw axes
    draw_line(Vector2(0, graph_size.y), Vector2(graph_size.x, graph_size.y), Color.GRAY, 2.0)
    draw_line(Vector2(0, 0), Vector2(0, graph_size.y), Color.GRAY, 2.0)
    
    # Draw data line
    for i in range(data_points.size() - 1):
        var p1 = _convert_to_screen_space(data_points[i])
        var p2 = _convert_to_screen_space(data_points[i + 1])
        draw_line(p1, p2, Color.CYAN, 3.0)
        draw_circle(p1, 4.0, Color.CYAN)
    
    # Draw last point
    var last_point = _convert_to_screen_space(data_points[-1])
    draw_circle(last_point, 4.0, Color.CYAN)

func _convert_to_screen_space(data_point: Vector2) -> Vector2:
    var x = (data_point.x / data_points[-1].x) * graph_size.x
    var y = graph_size.y - (data_point.y / max_value) * graph_size.y
    return Vector2(x, y)
```

---

## **TAB 6: EVENTS & PROJECTIONS**

**Purpose:** Plan ahead for upcoming events and traffic

**Layout:**
```
┌─────────────────────────────────────────────────┐
│  EVENTS & TRAFFIC PROJECTIONS                   │
├─────────────────────────────────────────────────┤
│                                                 │
│  UPCOMING EVENTS                                │
│                                                 │
│  ┌──────────────────────────────────────────┐  │
│  │ 🎉 TOWN FESTIVAL                         │  │
│  │ In 3 days (Thursday)                     │  │
│  │                                           │  │
│  │ Expected Impact:                          │  │
│  │ • Traffic: +150% (Est. 120 customers)   │  │
│  │ • High demand for: Pastries, Cakes       │  │
│  │ • Suggested prep: Stock extra ingredients│  │
│  │                                           │  │
│  │ Tips: Consider bulk discounts, hire temp │  │
│  │ staff, extend hours if possible          │  │
│  └──────────────────────────────────────────┘  │
│                                                 │
│  ┌──────────────────────────────────────────┐  │
│  │ 📰 FOOD CRITIC VISIT                     │  │
│  │ In 5 days (Saturday)                     │  │
│  │                                           │  │
│  │ Expected Impact:                          │  │
│  │ • Reputation: +20 if positive review     │  │
│  │ • Reputation: -15 if negative review     │  │
│  │                                           │  │
│  │ Requirements for positive review:         │  │
│  │ ✓ Shop cleanliness: 95%+                │  │
│  │ ✓ Product quality: Excellent             │  │
│  │ ✓ Service speed: < 30 seconds            │  │
│  │ ✓ Price fairness: Within market range   │  │
│  └──────────────────────────────────────────┘  │
│                                                 │
│  DAILY TRAFFIC FORECAST (Next 7 Days)          │
│  ┌──────────────────────────────────────────┐  │
│  │ Mon (Tomorrow):  ████████░░  45 customers│  │
│  │ Tue:             ██████░░░░  35 customers│  │
│  │ Wed:             ████████░░  48 customers│  │
│  │ Thu (Festival):  ██████████ 120 customers│  │
│  │ Fri:             ████████░░  50 customers│  │
│  │ Sat (Critic):    █████████░  58 customers│  │
│  │ Sun:             ███████░░░  42 customers│  │
│  └──────────────────────────────────────────┘  │
│                                                 │
│  FACTORS AFFECTING TRAFFIC:                     │
│  ✓ Reputation (78): +28% customers             │
│  ✓ Active marketing: +25% customers            │
│  ⚠️ Competitor opened: -10% customers           │
│  ☀️ Weather (Sunny): +5% customers             │
│                                                 │
│  RECOMMENDATIONS:                               │
│  • Order extra flour (3 bags) for Thursday     │
│  • Consider hiring temp staff for festival     │  │
│  • Prepare signature items for critic visit    │
│                                                 │
└─────────────────────────────────────────────────┘
Key Features:

Upcoming events with countdowns
Impact estimates for planning
Daily traffic bars (visual forecast)
Actionable recommendations
Factor breakdown (why traffic is up/down)

Traffic Calculation:
gdscriptfunc calculate_projected_traffic(day_offset: int) -> int:
    var base_traffic = 30
    var reputation_bonus = (reputation - 50) * 0.5
    var marketing_bonus = get_active_marketing_boost(day_offset)
    var event_modifier = get_event_modifier(day_offset)
    var day_of_week_mod = get_day_of_week_modifier(day_offset)
    var weather_mod = get_weather_modifier(day_offset)
    
    var total = base_traffic + reputation_bonus + marketing_bonus
    total *= (1.0 + event_modifier + day_of_week_mod + weather_mod)
    
    return int(total)

MENU SYSTEM IMPLEMENTATION
Opening/Closing:
gdscriptextends Control

@onready var tab_container = $TabContainer
@onready var dashboard_tab = $TabContainer/Dashboard
# ... other tab references

var is_open = false

func _input(event):
    if event.is_action_pressed("open_menu"): # Tab or M key
        toggle_menu()

func toggle_menu():
    is_open = !is_open
    visible = is_open
    
    if is_open:
        get_tree().paused = true  # Pause gameplay
        refresh_all_tabs()
    else:
        get_tree().paused = false

func refresh_all_tabs():
    dashboard_tab.update_data()
    # Refresh other tabs as needed
Data Persistence:
gdscript# GameManager tracks all stats
var daily_stats = {
    "day": 1,
    "revenue": 0,
    "expenses": 0,
    "customers_served": 0,
    "customer_satisfaction": [],
    "items_sold": {},
    "reputation": 50
}

var historical_data = {
    "reputation_history": [],
    "revenue_history": [],
    "customer_history": []
}

func end_of_day():
    # Record today's data
    historical_data.reputation_history.append(daily_stats.reputation)
    historical_data.revenue_history.append(daily_stats.revenue)
    historical_data.customer_history.append(daily_stats.customers_served)
    
    # Reset daily stats
    daily_stats = create_new_day_stats()

