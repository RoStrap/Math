-- Random numbers along a Normal curve
-- @author Validark
-- @original https://github.com/Quenty/NevermoreEngine/blob/8f9cbd9b870b3f061457a5c713d84ed097a05ccd/src/probability/src/Shared/Probability.lua

--[[
MIT License

Copyright (c) 2014-2021 Quenty

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
--]]

local tau = 2 * math.pi
local cos = math.cos
local log = math.log
local random = math.random

local function Normal(Average, StdDeviation)
	--- Normal curve [-1, 1] * StdDeviation + Average
	return (Average or 0) + (-2 * log(random())) ^ 0.5 * cos(tau * random()) * 0.5 * (StdDeviation or 1)
end

return Normal
