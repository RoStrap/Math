-- Level and Experience class
-- @author Validark

local Resources = require(game:GetService("ReplicatedStorage"):WaitForChild("Resources"))
local Debug = Resources:LoadLibrary("Debug")
local Table = Resources:LoadLibrary("Table")

local DEFAULT_AWARD = 1

local floor = math.floor

-- Level equations taken from https://minecraft.gamepedia.com/Experience
local function ToNextLevel(Lvl)
	-- @param number Lvl the Current level a player is on
	-- @returns number Exp the Exp required to reach the next level

	return
		0 <= Lvl and Lvl < 16 	and 2*Lvl + 7 or
		Lvl < 31 				and 5*Lvl - 38 or
		30 < Lvl 				and 9*Lvl - 158
end

local function LevelFromExperience(Exp)
	-- @param number Exp The Amount of Experience
	-- @returns number Level, number experience within the current level

	if Exp <= 0 then
		return 0, 0
	elseif Exp <= 352 and Exp > 0 then --Lvl 16 or under
		local Lvl = floor((Exp + 9) ^ 0.5 - 3)
		return Lvl, Exp - (Lvl * Lvl + 6 * Lvl)
	elseif Exp > 352 and Exp <= 1507 then
		local Lvl = floor((81 + (40 * Exp - 7839) ^ 0.5) * 0.1)
		return Lvl, Exp - (2.5 * Lvl * Lvl - 40.5 * Lvl + 360)
	else
		local Lvl = floor((325 + (72 * Exp - 54215) ^ 0.5) / 18)
		return Lvl, Exp - (4.5 * Lvl * Lvl - 162.5 * Lvl + 2220)
	end
end

local Leveler = {}
Leveler.__index = {}

function Leveler.new(Points)
	return setmetatable({}, Leveler):Award(Points or 0)
end

function Leveler.__index:Award(Points)
	if Points and (type(Points) ~= "number" or Points < 0) then
		Debug.Error("Cannot award points %s", Points)
	end

	self.Total = (self.Total or 0) + (Points or DEFAULT_AWARD)
	self.Lvl, self.Exp = LevelFromExperience(self.Total)
	self.Next = ToNextLevel(self.Lvl)
	self.Percent = self.Exp / self.Next
	return self
end

return Table.Lock(Leveler)
