extends Node2D

# Game config
export(Array) var kColors
export(int) var kNumAreas = 10
export(int) var kAreasStartPos = 600

export(float) var kBackoffTime = 2.0
export(float) var kBackoffSpeed = -5.0

export(float) var kBaseSpeed = 2.0
export(int) var kBaseScore = 100
	# Amount of scored areas to increase multiplier (speed & score)
export(int) var kMultiplierInterval = 1
export(int) var kMaxMultiplier = 10
	# Increase in speed per multiplier (speed is kBaseSpeed + kSpeedIncrease * _multiplier
export(float) var kSpeedIncrease = 1.0
	# Increase in score per multiplier (score is kBaseScore + kScoreIncrease * _multiplier
export(int) var kScoreIncrease = 10

# Game state
var _multiplier = 1
var _scoreCount = 0
var _backoffTime = 2.0
var _backingOff = false

# Player state
var _lives = 0
var _score = 0

# Color areas (obstacles)
var _colorAreaScn
var _colorAreas = Array()

# Persistent data
var _persistentData

func _ready():
	_persistentData = get_node("/root/PersistentData")
	randomize()
	_colorAreaScn = load("res://components/ColorArea.tscn")
	for i in range(kNumAreas):
		var colorArea = _colorAreaScn.instance()
		add_child(colorArea)
		_colorAreas.push_back(colorArea)
	resetGame()

func colorScored():
	_score += kBaseScore + kScoreIncrease * _multiplier
	get_node("Sprite/ScoreLabel").text = String(_score)
	_scoreCount += 1
	if _scoreCount == kMultiplierInterval:
		_multiplier = min(_multiplier + 1, kMaxMultiplier)
		_scoreCount = 0
		for i in range(kNumAreas):
			_colorAreas[i].speed = kBaseSpeed + kSpeedIncrease * _multiplier

func colorFailed():
	_lives -= 1
	if _lives > 0:
		get_node("Sprite/LifeBarLight"+String(_lives)).lifeLost()
	_scoreCount = 0
	if _lives == 0:
		print("Dead with score: " + String(_score))
		resetGame()
	else:
		_backoffTime = kBackoffTime
		_backingOff = true
		for i in range(kNumAreas):
			_colorAreas[i].speed = kBackoffSpeed
	
func resetGame():
	_multiplier = 1
	_lives = _persistentData._additionalLives + 1
	for i in range(1, _lives):
		get_node("Sprite/LifeBarLight"+String(i)).lifeAvailable()
	for i in range(_lives, _persistentData.kMaxLives + 1):
		get_node("Sprite/LifeBarLight"+String(i)).lifeUnavailable()
		
	_score = 0
	get_node("Sprite/ScoreLabel").text = String(_score)
	for i in range(kNumAreas):
		_colorAreas[i].position = Vector2(kAreasStartPos + i * 300, 500)
		_colorAreas[i].speed = kBaseSpeed
	
func _process(delta):
	for i in range(kColors.size()):
		if Input.is_action_pressed("Action"+String(i)):
			var prevColorIdx = get_node("Player")._color
			var newColor = kColors[i]
			get_node("Player").setColor(newColor, i)
			get_node("Node2D/ColorButton" + String(i)).setSelected(true)
			if prevColorIdx > -1 and prevColorIdx != i:
				get_node("Node2D/ColorButton" + String(prevColorIdx)).setSelected(false)

			
	if _backingOff == false:
		return
		
	_backoffTime -= delta
	if _backoffTime < 0:
		_backoffTime = 0
		for i in range(kNumAreas):
			_colorAreas[i].speed = kBaseSpeed + kSpeedIncrease * _multiplier
