-- Random numbers along a Normal curve
-- @author Validark
-- @original https://github.com/Quenty/NevermoreEngine/tree/version2/Modules/Math

local tau = 2 * math.pi
local cos = math.cos
local log = math.log
local random = math.random

local function Normal(Average, StdDeviation)
	--- Normal curve [-1, 1] * StdDeviation + Average
	return (Average or 0) + (-2 * log(random())) ^ 0.5 * cos(tau * random()) * 0.5 * (StdDeviation or 1)
end

return Normal
