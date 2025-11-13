extends Node

# StoryManager - Singleton for managing story beats, letters, and narrative
# Handles grandmother's letters revealed at each milestone

# Signals
signal letter_received(milestone_id: String, letter_text: String)
signal story_beat_triggered(beat_id: String)
signal ending_sequence_started()

# Story state
var letters_read: Array[String] = []
var current_story_beat: String = "beginning"

# Grandmother's letters for each milestone
var grandmother_letters: Dictionary = {
	"beginning": {
		"title": "A Letter from Grandma",
		"letter": """My Dearest,

If you're reading this, then I've passed on, and you've inherited my little bakery. I know it doesn't look like much right now - the paint is peeling, the oven's temperamental, and half the town probably thinks you're crazy for taking it on.

But let me tell you a secret: this bakery has magic in it. Not the kind from fairy tales, but the real kind - the magic of a warm loaf on a cold morning, a birthday cake that makes someone cry happy tears, cookies that taste like coming home.

I started with nothing but my grandmother's recipe book and a dream. Some days were hard. Some days I wanted to quit. But every customer who walked through that door reminded me why I loved this work.

The recipes I'm leaving you aren't just flour and sugar. They're pieces of my life, moments I captured in pastry and bread. Each one has a story. Each one is a gift.

Start small. The white bread, the cookies, the muffins - they're simple, but they're honest. Master those, and everything else will follow.

I believe in you. The bakery believes in you. Now you just need to believe in yourself.

With all my love,
Grandma

P.S. - The oven runs a little hot. Give it about 15 degrees less than the recipe says!"""
	},

	"basic_pastries": {
		"title": "Letter Two - Basic Pastries",
		"letter": """My Dear,

Look at you! You've made your first $500. I knew you could do it!

I remember when I reached this same milestone, back in 1958. I splurged on new mixing bowls and felt like a queen. Your grandfather said I was glowing brighter than the oven.

You've proven you can do the basics. Now it's time to stretch your wings a little. I'm unlocking some special recipes for you - the pastries that really put us on the map.

The croissants - oh, those croissants! They take patience. The butter must be cold, the layers must be precise. I failed seventeen times before I got them right. Don't be discouraged if yours aren't perfect at first. Even a "failed" croissant tastes pretty good!

The cinnamon rolls were your mother's favorite. Every Sunday morning, she'd wake up to the smell of them baking. She'd sneak downstairs in her pajamas and steal the middle one - always the gooiest.

The Danish pastries came from Mrs. Andersen down the street. She taught me in exchange for babysitting her daughter. That daughter is probably running her own bakery now!

These recipes require a little more time, a little more care. But the customers will notice. They'll start coming back not just for bread, but for the experience.

Keep going, sweetheart. You're doing better than you know.

With pride,
Grandma

P.S. - Save the burnt pastries. The birds love them, and kindness always comes back around."""
	},

	"artisan_breads": {
		"title": "Letter Three - Artisan Breads",
		"letter": """Dearest One,

Two thousand dollars! You're really doing it! The bakery is coming alive again, isn't it? I bet you can feel it in the morning warmth, hear it in the satisfied murmurs of customers.

It's time I shared something special with you: the bread recipes that made us famous.

That sourdough starter in the fridge? I've been feeding it since 1973. It's older than your parents! It came from my mother, who got it from her mother. Every loaf you make with it connects you to five generations of bakers.

Sourdough is alive. It breathes, it grows, it has moods. Some days it's perfect, some days it's stubborn. Treat it with respect - feed it regularly, keep it warm, talk to it if you like. I always did.

The baguettes require a confident hand. Score them quick and sure - hesitation shows in the crust. I learned that from Pierre, a French baker who stopped in town one summer. He ate at our place every day for three weeks and paid in lessons instead of money. Best trade I ever made.

The focaccia is forgiving - a good recipe for when you're tired but still need to create something beautiful. Press your fingers deep into the dough. Those dimples hold the olive oil, but they also hold intention. I always pressed mine with gratitude.

You're not just a baker anymore. You're an artisan. There's a difference.

So proud of you,
Grandma

P.S. - Never rush the rise. Good bread, like a good life, takes time."""
	},

	"special_occasion": {
		"title": "Letter Four - Special Occasions",
		"letter": """My Precious Child,

Five thousand dollars. I'm crying happy tears, wherever I am.

You've built something real. This isn't just a bakery anymore - it's a pillar of the community, a place where memories are made. And now, I want you to be part of the biggest memories of all.

Birthdays. Weddings. Celebrations.

The recipes I'm sharing now aren't just food. They're centerpieces. They're the cake that makes a six-year-old squeal with joy. They're the dessert at someone's wedding reception. They're the reason a grandmother calls on Tuesday to order something special for Sunday dinner.

I made your parents' wedding cake with these recipes. Three tiers, vanilla with raspberry filling, covered in buttercream roses. Your mother cried when she saw it. Your father kissed my cheek and called me the best baker in three states.

The birthday cake recipe is flexible - you can customize it for anyone. Use your creativity. Listen to what the customer needs, then pour your heart into making it perfect for them.

The cheesecake took me years to perfect. The secret is the water bath - it keeps the edges from cracking. Smooth, creamy, perfect every time.

These special orders will challenge you. They'll stress you out. You'll probably make mistakes. But they'll also fill you with pride like nothing else can.

You're making people's most important moments more beautiful. That's not just baking - that's art. That's love.

Forever proud,
Grandma

P.S. - I've also unlocked a decorating station for you. Time to make things pretty!"""
	},

	"secret_recipes": {
		"title": "Letter Five - Secret Recipes",
		"letter": """My Darling,

Ten thousand dollars. You did it. You actually did it.

I'm giving you something now that I've never shared with anyone - not your parents, not my friends, not even your grandfather (though he guessed the apple pie recipe after tasting it a hundred times).

These are my secret recipes. The ones I only made for special occasions. The ones that won awards. The ones that made people close their eyes and sigh.

The apple pie... oh, sweetheart. This pie won first place at the county fair three years in a row. The fourth year, they retired me from competition because they said I was "intimidating the other contestants." The secret? It's not just the cardamom (though that helps). It's the intention. Every apple slice gets cut with love. Every bit of crust gets folded with care.

The secret cookies - cardamom again! It's my signature. People would try to guess it for years. "Is it nutmeg? Cinnamon? Magic?" Just smile mysteriously when they ask. A baker's got to have some mystique.

That chocolate cake? I made it for every family gathering. Your uncle proposed to his wife over a slice of that cake. Your cousin asked for it instead of a birthday cake when she turned thirty. It's more than dessert - it's family history.

These recipes are my legacy. My gift to you. They're pieces of my soul, wrapped in flour and sugar.

Use them wisely. Share them generously. Make new memories with them.

I love you so much,
Grandma

P.S. - The recipe book is complete now. Everything I know is yours."""
	},

	"international": {
		"title": "Letter Six - International Treats",
		"letter": """My Adventurous One,

Twenty-five thousand dollars! You've surpassed every dream I ever had for this place!

I bet the bakery looks beautiful now. I bet the morning rush is chaotic and wonderful. I bet you're exhausted and exhilarated in equal measure.

It's time to see the world - or at least, taste it!

These international recipes are from my travels and friendships. I collected them like treasures, one conversation at a time.

The French macarons - I learned these in Paris on my honeymoon in 1962. A tiny bakery near the Seine, run by a woman named Colette. I went back every day for a week, watching, learning. On the last day, she wrote out the recipe on the back of a napkin and kissed both my cheeks. I still have that napkin.

It took me fifty tries to get them right back home. The humidity was different, the altitude was different, everything was different. But I persisted, and eventually - magic.

The German stollen came from your great-grandmother. She brought the recipe from the old country, written in a language I couldn't read. We translated it together, her guiding my hands, teaching me the feel of proper dough.

Mrs. Tanaka taught me the melon pan recipe when she moved to town. She was lonely, missing home. I asked her to teach me, thinking she'd feel less alone if she could share her culture. We became best friends.

Food connects us across oceans and generations. With every international recipe you make, you're honoring someone's heritage, sharing their story.

The world is wide and beautiful - now your bakery is too.

With wonder,
Grandma

P.S. - I've arranged for the bakery expansion. You've earned it."""
	},

	"legendary": {
		"title": "Letter Seven - The End and The Beginning",
		"letter": """My Dearest Heart,

Fifty thousand dollars. You beautiful, brilliant, incredible soul - you did it.

You didn't just save the bakery. You transformed it. You made it legendary.

These final recipes... they're my masterpiece. The cake that I made only twice in my life - once for your grandfather's 50th birthday, once for our golden anniversary. He said it tasted like fifty years of love, and he was right.

The championship recipe won the state baking competition in 1975. I beat 147 other bakers. They interviewed me for the newspaper. I was so nervous I forgot my own name, but I remembered every ingredient.

The town festival winner - they still talk about that one at the annual fair. It was 1982. I'd been baking all night, exhausted, running on pure determination. When I finished, the sun was rising, and somehow that pastry captured the hope of a new day.

But here's what I really want to tell you:

You don't need my recipes anymore. You're a master in your own right. Everything you create from here is YOUR legacy, YOUR story, YOUR magic.

This bakery isn't my gift to you anymore. It's your gift to the world.

I started this place with love, and you've filled it with even more. Every customer you've served, every bread you've baked, every early morning and late night - you've poured your heart into this work.

I'm so proud I could burst.

The bakery is yours. The future is yours. Make it wonderful.

All my love, forever and always,
Grandma

P.S. - There's one more recipe I never wrote down. The most important one. It's simple: Start with love, add patience, fold in kindness, and bake until golden. Works for bread. Works for life.

P.P.S. - I'm always with you. In every warm oven, every perfect rise, every satisfied smile. Always."""
	}
}

func _ready() -> void:
	print("StoryManager initialized")

	# Connect to ProgressionManager milestone signals
	if ProgressionManager:
		ProgressionManager.milestone_reached.connect(_on_milestone_reached)

func _on_milestone_reached(milestone_id: String, revenue_threshold: float) -> void:
	"""Triggered when a milestone is reached - show corresponding letter"""
	print("\n=== STORY BEAT ===")
	print("Milestone: %s ($%.2f)" % [milestone_id, revenue_threshold])

	trigger_letter(milestone_id)

func trigger_letter(milestone_id: String) -> void:
	"""Display a grandmother's letter"""
	if not grandmother_letters.has(milestone_id):
		print("No letter for milestone: %s" % milestone_id)
		return

	if milestone_id in letters_read:
		print("Letter already read: %s" % milestone_id)
		return

	var letter_data: Dictionary = grandmother_letters[milestone_id]
	letters_read.append(milestone_id)

	print("\n--- %s ---" % letter_data["title"])
	print(letter_data["letter"])
	print("\n=================\n")

	letter_received.emit(milestone_id, letter_data["letter"])
	story_beat_triggered.emit(milestone_id)

	# Trigger ending sequence for legendary milestone
	if milestone_id == "legendary":
		trigger_ending_sequence()

func trigger_ending_sequence() -> void:
	"""Trigger the game ending sequence"""
	print("\n=== GAME ENDING SEQUENCE ===")
	ending_sequence_started.emit()

func show_beginning_letter() -> void:
	"""Show the initial letter when starting a new game"""
	trigger_letter("beginning")

func get_letter(milestone_id: String) -> Dictionary:
	"""Get letter data for a milestone"""
	return grandmother_letters[milestone_id] if grandmother_letters.has(milestone_id) else {}

func has_read_letter(milestone_id: String) -> bool:
	"""Check if a letter has been read"""
	return milestone_id in letters_read

func get_all_read_letters() -> Array[String]:
	"""Get list of all letters that have been read"""
	return letters_read.duplicate()

# Save/Load support
func get_save_data() -> Dictionary:
	return {
		"letters_read": letters_read.duplicate(),
		"current_story_beat": current_story_beat
	}

func load_save_data(data: Dictionary) -> void:
	if data.has("letters_read"):
		letters_read = data["letters_read"].duplicate()
	if data.has("current_story_beat"):
		current_story_beat = data["current_story_beat"]

	print("Story data loaded: %d letters read" % letters_read.size())
