-- Random numbers along a Normal curve

local tau = 2 * math.pi
local cos = math.cos
local log = math.log
local sqrt = math.sqrt
local random = math.random

local function Normal(Average, StdDeviation)
	--- Normal curve [-1, 1] * StdDeviation + Average
	return (Average or 0) + sqrt(-2 * log(random())) * cos(tau * random()) * 0.5 * (StdDeviation or 1)
end

return Normal
