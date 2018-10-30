local Spring = { }
Spring.__index = Spring

local pi = 3.1415926535898
local e = 2.718281828459
local sin = math.sin
local cos = math.cos

local EPS = 1e-4

function Spring.new(dampingRatio, frequency, position)
	assert(type(dampingRatio) == "number")
	assert(type(frequency) == "number")
	assert(dampingRatio*frequency >= 0, "Spring does not converge")
	
	local self = { }
	self.d = dampingRatio
	self.f = frequency
	self.g = position
	self.p = position
	self.v = position * 0
	
	setmetatable(self, Spring)

	return self
end

function Spring:Reset(position)
	self.p = position
	self.v = position * 0
end

function Spring:SetGoal(newGoal)
	self.g = newGoal
end

function Spring:SetFrequency(newFreq)
	self.f = newFreq
end

function Spring:SetDampingRatio(newDamp)
	self.d = newDamp
end

function Spring:GetGoal()
	return self.g
end

function Spring:GetPosition()
	return self.p
end

function Spring:GetVelocity()
	return self.v
end

function Spring:Update(dt)
	local d = self.d
	local f = self.f * 6.2831853071796
	local g = self.g
	local p0 = self.p
	local v0 = self.v

	local offset = p0 - g
	local decay = e ^ (-d*f*dt)

	local p1, v1

	if d == 1 then -- Critically damped
		p1 = (offset*(1 + f*dt) + v0*dt)*decay + g
		v1 = (v0*(1 - f*dt) - offset*(f*f*dt))*decay

	elseif d < 1 then -- Underdamped
		local c = (1 - d*d) ^ 0.5

		local i = cos(f*c*dt)
		local j = sin(f*c*dt)

		local z
		if c > EPS then
			z = j/c
		else
			local a = dt*f
			z = a + ((a*a)*(c*c)*(c*c)/20 - c*c)*(a*a*a)/6
		end

		local y
		if f * c > EPS then
			y = j / (f * c)
		else
			local b = f * c
			y = dt + ((dt * dt) * (b * b) * (b * b) / 20 - b * b) * (dt * dt * dt) / 6
		end

		p1 = (offset * (i + d * z) + v0 * y) * decay + g
		v1 = (v0 * (i - z * d) - offset * (z * f)) * decay

	else
		local c = (d * d - 1) ^ 0.5

		local r1 = -f * (d - c)
		local r2 = -f * (d + c)

		local co2 = (v0 - offset * r1) / (2 * f * c)
		local co1 = offset - co2

		local e1 = co1 * e ^ (r1 * dt)
		local e2 = co2 * e ^ (r2 * dt)

		p1 = e1 + e2 + g
		v1 = e1 * r1 + e2 * r2
	end

	self.p = p1
	self.v = v1

	return p1
end

return Spring
