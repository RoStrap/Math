# WeightedProbabilityFunction
Example:
```lua
local require = require(game:GetService("ReplicatedStorage"):WaitForChild("Resources")).LoadLibrary
local WeightedProbabilityFunction = require("WeightedProbabilityFunction")

local CoinToss = WeightedProbabilityFunction.new{
	Heads = 0.5;
	Tails = 0.5;
}

local DiceRoll = WeightedProbabilityFunction.new{
	-- These weights are relative to one another, so if they are all 1, they will each have a 1/6 chance
	[1] = 1;
	[2] = 1;
	[3] = 1;
	[4] = 1;
	[5] = 1;
	[6] = 1;
}

local DiceRollOrCoinToss = WeightedProbabilityFunction.new{
	-- 9/10 of the time, toss a coin
	-- 1/10 of the time, roll a dice

	[CoinToss] = 9;
	[DiceRoll] = 1;
}

local t = {}

for i = 1, 10000 do
	local pick = DiceRollOrCoinToss()
	t[pick] = (t[pick] or 0) + 1
end

table.foreach(t, print)
```

# Leveler
This is a super simple library. Run this little demo and you will learn everything you need to know.
```lua
local require = require(game:GetService("ReplicatedStorage"):WaitForChild("Resources")).LoadLibrary
local Leveler = require("Leveler")

local Kills = Leveler.new()
table.foreach(Kills, print)
print()

Kills:Award()
table.foreach(Kills, print)
print()

Kills:Award(6)
table.foreach(Kills, print)
```
