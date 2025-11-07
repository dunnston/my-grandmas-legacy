extends Node

# EconomyManager - Singleton for managing money, transactions, and economy
# Tracks cash, daily revenue/expenses, and provides transaction methods

# Signals
signal money_changed(new_amount: float)
signal transaction_completed(amount: float, description: String, is_income: bool)
signal daily_report_ready(revenue: float, expenses: float, profit: float)

# Economy state
var current_cash: float = 200.0  # Starting cash from GDD
var daily_revenue: float = 0.0
var daily_expenses: float = 0.0

# Transaction history (for current day)
var transaction_history: Array[Dictionary] = []

# Pricing data (can be expanded with recipe-specific pricing later)
var ingredient_prices: Dictionary = {
	"flour": 2.0,
	"sugar": 3.0,
	"eggs": 4.0,
	"butter": 5.0,
	"milk": 3.0,
	"yeast": 2.5,
	"chocolate_chips": 6.0,
	"blueberries": 7.0,
	"vanilla": 4.0,
	"salt": 1.0
}

func _ready() -> void:
	print("EconomyManager initialized")
	print("Starting cash: $", current_cash)

# Transaction methods
func add_money(amount: float, description: String = "Income") -> void:
	"""Add money (sales, rewards, etc.)"""
	if amount <= 0:
		push_warning("Attempted to add non-positive amount: ", amount)
		return

	current_cash += amount
	daily_revenue += amount

	# Record transaction
	var transaction: Dictionary = {
		"amount": amount,
		"description": description,
		"is_income": true,
		"timestamp": Time.get_ticks_msec()
	}
	transaction_history.append(transaction)

	print("+ $%.2f: %s (Balance: $%.2f)" % [amount, description, current_cash])
	money_changed.emit(current_cash)
	transaction_completed.emit(amount, description, true)

func remove_money(amount: float, description: String = "Expense") -> bool:
	"""Remove money (purchases, wages, etc.). Returns false if insufficient funds."""
	if amount <= 0:
		push_warning("Attempted to remove non-positive amount: ", amount)
		return false

	if current_cash < amount:
		print("INSUFFICIENT FUNDS: Need $%.2f, have $%.2f" % [amount, current_cash])
		return false

	current_cash -= amount
	daily_expenses += amount

	# Record transaction
	var transaction: Dictionary = {
		"amount": amount,
		"description": description,
		"is_income": false,
		"timestamp": Time.get_ticks_msec()
	}
	transaction_history.append(transaction)

	print("- $%.2f: %s (Balance: $%.2f)" % [amount, description, current_cash])
	money_changed.emit(current_cash)
	transaction_completed.emit(amount, description, false)
	return true

func can_afford(amount: float) -> bool:
	"""Check if player can afford a purchase"""
	return current_cash >= amount

# Sales methods
func complete_sale(item_name: String, price: float) -> void:
	"""Record a sale of a baked good"""
	add_money(price, "Sold: " + item_name)

# Purchase methods
func purchase_ingredient(ingredient_id: String, quantity: int = 1) -> bool:
	"""Purchase ingredients from storage. Returns true if successful."""
	if not ingredient_prices.has(ingredient_id):
		push_warning("Unknown ingredient: ", ingredient_id)
		return false

	var cost: float = ingredient_prices[ingredient_id] * quantity
	var ingredient_name: String = ingredient_id.capitalize()

	if remove_money(cost, "Purchased: %d x %s" % [quantity, ingredient_name]):
		return true
	return false

func get_ingredient_price(ingredient_id: String) -> float:
	"""Get the price of a single ingredient"""
	if ingredient_prices.has(ingredient_id):
		return ingredient_prices[ingredient_id]
	return 0.0

# Daily report methods
func generate_daily_report() -> Dictionary:
	"""Generate a summary of the day's financial activity"""
	var profit: float = daily_revenue - daily_expenses

	var report: Dictionary = {
		"revenue": daily_revenue,
		"expenses": daily_expenses,
		"profit": profit,
		"cash_on_hand": current_cash,
		"transactions": transaction_history.size()
	}

	print("\n=== DAILY FINANCIAL REPORT ===")
	print("Revenue:   $%.2f" % daily_revenue)
	print("Expenses:  $%.2f" % daily_expenses)
	print("Profit:    $%.2f" % profit)
	print("Cash:      $%.2f" % current_cash)
	print("Transactions: %d" % transaction_history.size())
	print("==============================\n")

	daily_report_ready.emit(daily_revenue, daily_expenses, profit)
	return report

func reset_daily_stats() -> void:
	"""Reset daily revenue/expenses for new day (called by GameManager)"""
	daily_revenue = 0.0
	daily_expenses = 0.0
	transaction_history.clear()
	print("Daily stats reset for new day")

# Getters
func get_current_cash() -> float:
	return current_cash

func get_daily_revenue() -> float:
	return daily_revenue

func get_daily_expenses() -> float:
	return daily_expenses

func get_daily_profit() -> float:
	return daily_revenue - daily_expenses

func get_transaction_history() -> Array[Dictionary]:
	return transaction_history

# Save/Load support (to be used by SaveManager)
func get_save_data() -> Dictionary:
	return {
		"current_cash": current_cash,
		"daily_revenue": daily_revenue,
		"daily_expenses": daily_expenses
	}

func load_save_data(data: Dictionary) -> void:
	if data.has("current_cash"):
		current_cash = data["current_cash"]
		money_changed.emit(current_cash)
	if data.has("daily_revenue"):
		daily_revenue = data["daily_revenue"]
	if data.has("daily_expenses"):
		daily_expenses = data["daily_expenses"]
	print("Economy data loaded: $%.2f cash" % current_cash)
