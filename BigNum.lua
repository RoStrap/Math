-- BigNum Library
-- @author Validark

-- This library implements two's complement signed integers in base 16777216 (2^24)

-- In binary, numbers have place values like so:
-- | -2^4 | 2^3 | 2^2 | 2^1 | 2^0 |
-- | -16's| 8's | 4's | 2's | 1's |

-- In base 16777216, the place values look like this (the leftmost radix is a bit more complicated)
-- | 16777216^4        | 16777216^3      | 16777216^2   | 16777216^1 | 16777216^0 |

-- Hence, each base 16777216 value holds what would be 24 base 2 values, or 3 bytes
-- This means we could hypothetically implement a 64 bit signed integer using 2 2/3 radix

-- These BigNums are initialized with a pre-allocated amount of radix
-- This is because signed integers work in a particular way
-- In order to achieve efficient, signed integers, we basically flip the number line below the negative so
-- we can intentionally overflow one way or the other when adding and subtracting across the 0 boundary

-- Caveats:
-- The most negative number possible can not be used in a division expression
-- 		This is an extreme edge case but it could be encountered if someone turns the DEFAULT_RADIX to 1

local DEFAULT_RADIX = 32 -- Number of places/digits/radix
local PLATFORM = "Roblox"

-- We use 2^24 for two reasons:
--	1) It can be represented by 4 radix in base 2^6
--	2) It is large enough to take advantage of the underlying double construct but small
-- 		enough that the internal operands will not be larger than the largest (consecutive) integer a double can represent: 2^53
-- 		This is the largest internal operand value (before modulo): (DEFAULT_BASE - 1)^2 + DEFAULT_BASE - 1
local DEFAULT_BASE = 2^24 -- Don't change this

local BigNum = {}
BigNum.__index = {}

local WRITE_FILE_FOR_PLATFORM = {
	Roblox = function(Source)
		Instance.new("Script", game:GetService("Lighting")).Source = Source
	end;

	Vanilla = function(Source)
		local f = io.open("BigNum_Const.txt", "w")
		f:write(Source)
		f:close()
	end;
}

local CONSTANTS_VALUE = {
	__index = function(self, i)
		local t = {}
		local j = self.n

		for a = 1, j - 1 do
			t[a] = 0
		end

		t[j] = i

		while t[j] >= self.Base do
			local t_j = t[j]
			local x = t_j % self.Base
			t[j] = x
			j = j - 1
			t[j] = (t_j - x) / self.Base
		end

		self[i] = t
		return setmetatable(t, BigNum)
	end
}

local CONSTANTS_LENGTH = {
	__index = function(self, i)
		local t = setmetatable({n = i; Base = self.Base}, CONSTANTS_VALUE)
		self[i] = t
		return t
	end;
}

local CONSTANTS = setmetatable({}, { -- Usage: CONSTANTS[BASE][LENGTH][VALUE]
	__index = function(self, i)
		local t = setmetatable({Base = i}, CONSTANTS_LENGTH)
		self[i] = t
		return t
	end;
})

local function __unm(self, Base)
	-- Find the 2's complement

	local Characters = {}

	local j = #self

	for i = 1, j - 1 do
		Characters[i] = Base - self[i] - 1
	end

	local LastValue = Base - self[j]

	while LastValue == Base do
		Characters[j] = 0
		j = j - 1
		if j == 0 then break end
		LastValue = Characters[j] + 1
	end

	if j > 0 then
		Characters[j] = LastValue
	end

	return setmetatable(Characters, BigNum)
end

local function IsNegative(self, Base)
	return self[1] >= Base / 2
end

local function abs(self, Base)
	local b = IsNegative(self, Base)
	return b and __unm(self, Base) or self, b
end

local function __add(a, b, Base)
	local Carry = 0

	local Characters = {}

	for i = #a, 1, -1 do
		local v = a[i] + b[i] + Carry

		if v >= Base then
			local k = v % Base
			Carry = (v - k) / Base
			v = k
		else
			Carry = 0
		end

		Characters[i] = v
	end

	return setmetatable(Characters, BigNum)
end

local function __sub(a, b, Base)
	return __add(a, __unm(b, Base), Base)
end

local function __eq(a, b)
	for i = 1, #a do
		if a[i] ~= b[i] then
			return false
		end
	end

	return true
end

local function __lt(a, b, Base)
	local a_1 = a[1]
	local b_1 = b[1]

	if a_1 ~= b_1 then
		if a_1 >= Base / 2 then
			if b_1 >= Base / 2 then
				return a_1 < b_1
			else
				return true
			end
		elseif b_1 >= Base / 2 then
			return false
		end

		return a_1 < b_1
	end

	for i = 2, #a do
		local a_i = a[i]
		local b_i = b[i]

		if a_i ~= b_i then
			return a_i < b_i
		end
	end

	return false -- equal
end

local function __mul(a, b, Base)
	local n = #a
	local Characters = {}

	for i = n, 1, -1 do
		local b_i = b[i]

		if b_i == 0 then
			if not Characters[i] then
				Characters[i] = 0
			end
		else
			for j = n, 1, -1 do
				local a_j = a[j]

				local k = i + j - n

				if k > 0 then -- TODO: Change for loops to accomodate automatically
					local x = b_i * a_j + (Characters[k] or 0)
					local y = x % Base
					local z = (x - y) / Base

					Characters[k] = y

					while z > 0 and k > 1 do
						k = k - 1
						x = (Characters[k] or 0) + z
						y = x % Base
						z = (x - y) / Base

						Characters[k] = y
					end
				end
			end
		end
	end

	return setmetatable(Characters, BigNum)
end

local function __div(N, D, Base)
	-- https://youtu.be/6bpLYxk9TUQ
	local n = #N -- n-digit numbers

	local N_IsNegative, D_IsNegative

	N, N_IsNegative = abs(N, Base)
	D, D_IsNegative = abs(D, Base)

	local Q_IsNegative

	if N_IsNegative then
		Q_IsNegative = not D_IsNegative
	elseif D_IsNegative then
		Q_IsNegative = true
	else
		Q_IsNegative = false
	end

	if __lt(N, D, Base) then
		return CONSTANTS[Base][n][0], N
	end

	local NumDigits
	local SingleDigit

	for i = 1, n do
		if D[i] ~= 0 then
			NumDigits = i
			SingleDigit = D[i]
			break
		end
	end

	if not NumDigits then
		error("Cannot divide by 0")
	end

	local Q
	local R = N

	repeat
		local R_Is_Negative = IsNegative(R, Base)

		if R_Is_Negative then
			R = __unm(R, Base)
		end

		local Sub_Q = setmetatable({}, BigNum)
		local Remainder = 0

		for i = 1, NumDigits do
			local x = Base * Remainder + R[i]
			Remainder = x % SingleDigit
			Sub_Q[n - NumDigits + i] = (x - Remainder) / SingleDigit
		end

		for i = 1, n - NumDigits do
			Sub_Q[i] = 0
		end

		if R_Is_Negative then Sub_Q = __unm(Sub_Q, Base) end

		Q = Q and __add(Q, Sub_Q, Base) or Sub_Q
		R = __sub(N, __mul(D, Q, Base), Base)
	until __lt((abs(R, Base)), D, Base)

	if IsNegative(R, Base) then
		Q = __sub(Q, CONSTANTS[Base][n][1], Base)
		R = __sub(N, __mul(D, Q, Base), Base)
	end

	if Q_IsNegative then
		Q = __unm(Q, Base)
	end

	return Q, R
end

local function __pow(a, b, Base)
	local n = #a

    if __eq(b, CONSTANTS[Base][n][0], Base) then
		return CONSTANTS[Base][n][1]
	end

    local x = __pow(a, __div(b, CONSTANTS[Base][n][2], Base), Base)

    if b[n] % 2 == 0 then
        return __mul(x, x, Base)
    else
        return __mul(a, __mul(x, x, Base), Base)
	end
end

local function __mod(a, b, Base)
	local _, x = __div(a, b, Base)
	return x
end

local log = math.log
local LOG_11 = log(11)

local function __tostring(self, Base)
	local n = #self
	local Negative = IsNegative(self, Base)

	-- Not all bases with a given number of places can represent the number 10
	-- Therefore, for small numbers we can simply convert to a Lua number
	-- However, for larger numbers we need to use the math functions in this library

	-- The following conditional is derived from: 10 < Base^(n - 1) - 1

	if LOG_11 / log(Base) + 1 < n then
		local Characters = {}
		local Ten = CONSTANTS[Base][n][10]
		local Zero = CONSTANTS[Base][n][0]

		local i = 0

		repeat
			local x
			self, x = __div(self, Ten, Base)
			i = i + 1
			Characters[i] = x[n]
		until __eq(self, Zero)

		if Negative and not __eq(Characters, CONSTANTS[Base][i][0]) then
			Characters[i + 1] = "-"
		end

		return table.concat(Characters):reverse()
	else
		local PlaceValue = 1
		local Sum = 0

		for i = n, 2, -1 do
			Sum = Sum + self[i]*PlaceValue
			PlaceValue = PlaceValue * Base
		end

		return tostring(Sum + (self[1] - (Negative and Base or 0))*PlaceValue)
	end
end

local function EnsureCompatibility(Func, Unary)
	local typeof = typeof or type

	if Unary then
		return function(a, ...)
			local type_a = type(a)

			if type_a == "number" then
				a = BigNum.new(tostring(a))
			elseif type_a == "string" then
				a = BigNum.new(a)
			elseif type_a ~= "table" or getmetatable(a) ~= BigNum then
				error("bad argument to #1: expected BigNum, got " .. typeof(a))
			end

			return Func(a, DEFAULT_BASE, ...)
		end
	else
		return function(a, b)
			local type_a = type(a)

			if type_a == "number" then
				a = BigNum.new(tostring(a))
			elseif type_a == "string" then
				a = BigNum.new(a)
			elseif type_a ~= "table" or getmetatable(a) ~= BigNum then
				error("bad argument to #1: expected BigNum, got " .. typeof(a))
			end

			local type_b = type(b)

			if type_b == "number" then
				b = BigNum.new(tostring(b))
			elseif type_b == "string" then
				b = BigNum.new(b)
			elseif type_b ~= "table" or getmetatable(b) ~= BigNum then
				error("bad argument to #2: expected BigNum, got " .. typeof(b))
			end

			if #a ~= #b then
				error("You cannot operate on BigNums with different radix: " .. #a .. " and " .. #b)
			end

			return Func(a, b, DEFAULT_BASE)
		end
	end
end

local function GCD(m, n, Base)
	local _0 = CONSTANTS[Base][#m][0]

	while not __eq(n, _0, Base) do
		m, n = n, __mod(m, n, Base)
	end

    return m
end

local function LCM(m, n, Base)
	local _0 = CONSTANTS[Base][#m][0]
    return m ~= _0 and n ~= _0 and __mul(m, n, Base) / GCD(m, n, Base) or _0
end

local Char_0 = ("0"):byte()

local function toScientificNotation(self, Base, DigitsAfterDecimal)
	DigitsAfterDecimal = DigitsAfterDecimal or 2

	local MaxString = __tostring(self, Base)

	if #MaxString - 2 < DigitsAfterDecimal then
		return MaxString
	else
		local Arguments = {}

		for i = 1, DigitsAfterDecimal do
			Arguments[i] = MaxString:byte(i) - Char_0
		end

		Arguments[DigitsAfterDecimal + 1] = MaxString:byte(DigitsAfterDecimal + 1) - Char_0 + ((MaxString:byte(DigitsAfterDecimal + 2) - Char_0) > 4 and 1 or 0)
		Arguments[DigitsAfterDecimal + 2] = #MaxString - 1

		return ("%d." .. ("%d"):rep(DigitsAfterDecimal) .. "e%d"):format(unpack(Arguments))
	end
end

-- Unary operators
BigNum.__tostring = EnsureCompatibility(__tostring, true)
BigNum.__unm = EnsureCompatibility(__unm, true)
BigNum.__index.toScientificNotation = EnsureCompatibility(toScientificNotation, true)

-- Binary operators
BigNum.__add = EnsureCompatibility(__add)
BigNum.__sub = EnsureCompatibility(__sub)
BigNum.__mul = EnsureCompatibility(__mul)
BigNum.__div = EnsureCompatibility(__div)
BigNum.__pow = EnsureCompatibility(__pow)
BigNum.__mod = EnsureCompatibility(__mod)

BigNum.__lt = EnsureCompatibility(__lt)
BigNum.__eq = EnsureCompatibility(__eq)

-- Other operations
BigNum.__index.GDC = EnsureCompatibility(GCD)
BigNum.__index.LCM = EnsureCompatibility(LCM)

local function ProcessAsDecimal(Bytes, Negative, Value, Power, FromBase, ToBase)
	-- @param boolean Negative Whether the number is negative
	-- @param string Value a number in the form "%d*%.?%d*"
	-- @param number Power The power of 10 by which Value should be multiplied

	if Power then -- Truncates anything that falls after a decimal point, moved by X in AeX
		Power = tonumber(Power)
		local PointLocation = Value:find(".", 1, true) - 1
		local K = PointLocation + Power

		Value = (Value:sub(1, PointLocation) .. Value:sub(PointLocation + 2)):sub(1, K > 0 and K or 0)

		if Value == "" then
			Value = "0"
		end

		return __mul(ProcessAsDecimal(Bytes, Negative, Value, nil, FromBase, ToBase), __pow(CONSTANTS[ToBase][Bytes][10], CONSTANTS[ToBase][Bytes][K - #Value], ToBase), ToBase)
	end

	local self = {(("0"):rep(Bytes - #Value) .. Value):byte(1, -1)}
	local n = #self

	local Zero = CONSTANTS[FromBase][n][0]
	local Divisor = CONSTANTS[FromBase][n][ToBase]

	for i = 1, n do
		self[i] = self[i] - Char_0
	end

	local Characters = {}
	local i = Bytes

	repeat
		local x
		self, x = __div(self, Divisor, FromBase)
		Characters[i] = tonumber(table.concat(x))
		i = i - 1
	until __eq(self, Zero)

	for j = 1, i do
		Characters[j] = 0
	end

	return setmetatable(Negative and __unm(Characters, ToBase) or Characters, BigNum)
end

function BigNum.new(Number, Bytes)
	-- Parses a number, and determines whether it is a valid number
	-- If valid, it will call ProcessAsHexidecimal or ProcessAsDecimal depending
	-- on the number's format

	-- @param string Number The number to convert into base_256
	-- @return what the called Process function returns (array representing base256)

	local Type = type(Number)

	if Type == "number" then
		Number = tostring(Number)
		Type = "string"
	end

	if Type == "string" then
		local n = #Number

		if n > 0 then
			local Negative, Hexidecimal = Number:match("^(%-?)0[Xx](%x*%.?%x*)$")

			if Hexidecimal and Hexidecimal ~= "" and Hexidecimal ~= "." then
				return error("Hexidecimal is currently unsupported") -- ProcessAsDecimal(Bytes or DEFAULT_RADIX, Negative == "-", Hexidecimal, false, 16, 256)
			else
				local _, DecimalEndPlace, Minus, Decimal, Point = Number:find("^(%-?)(%d*(%.?)%d*)")

				if Decimal ~= "" and Decimal ~= "." then
					local Power = Number:match("^[Ee]([%+%-]?%d+)$", DecimalEndPlace + 1)

					if Power or DecimalEndPlace == n then
						return ProcessAsDecimal(Bytes or DEFAULT_RADIX, Minus == "-", Power and Point == "" and Decimal .. "." or Decimal, Power, 10, DEFAULT_BASE)
					end
				end
			end
		end

		error(Number .. " is not a valid Decimal value")
	elseif Type == "table" then
		return setmetatable(Number, BigNum)
	else
		error(tostring(Number) .. " is not a valid input to BigNum.new, please supply a string or table")
	end
end

function BigNum:GetRange(Radix, Base)
	-- Returns the range for a given integer number of Radix
	-- @returns string

	if not Base then Base = DEFAULT_BASE end

	local Max = {}

	for i = 2, Radix or DEFAULT_RADIX do
		Max[i] = Base - 1
	end

	Max[1] = (Base - Base % 2) / 2 - 1
	return "+/- " .. toScientificNotation(Max, Base)
end

function BigNum:SetDefaultRadix(NumRadix)
	DEFAULT_RADIX = NumRadix
end

-- The range of usable characters should be [CHAR_OFFSET, CHAR_OFFSET + 64]
local CHAR_OFFSET = 58
local _64_2 = 64 * 64
local _64_3 = _64_2 * 64

function BigNum.fromString64(String)
	-- Creates a BigNum from characters which were outputted by toString64()
	local t = {}

	for i = 1, #String / 4 do
		local v = 4*i
		local a, b, c, d = String:byte(v - 3, v)
		t[i] = (a - CHAR_OFFSET) * _64_3 + (b - CHAR_OFFSET) * _64_2 + (c - CHAR_OFFSET) * 64 + (d - CHAR_OFFSET)
	end

	return setmetatable(t, BigNum)
end

function BigNum.__index:toString64()
	-- returns a string of characters which hold the values in the array for storage purposes

	local t = {}

	for i = 1, #self do
		local x = self[i]
		local d = x % 64
		x = (x - d) / 64
		local c = x % 64
		x = ((x - c) / 64)
		local b = x % 64
		x = ((x - b) / 64)
		local a = x % 64

		t[i] = string.char(a + CHAR_OFFSET, b + CHAR_OFFSET, c + CHAR_OFFSET, d + CHAR_OFFSET)
	end

	return table.concat(t)
end

function BigNum.__index:toConstantForm(l)
	-- l is number of numbers per row

	l = l or 16
	local t = {"local CONSTANT_NUMBER = BigNum.new{\n\t"}
	local n = #self

	for i = 1, n do
		local v = tostring(self[i])
		table.insert(t, (" "):rep(0) .. v)
		table.insert(t, ",")
		if i % l == 0 then
			table.insert(t, "\n\t")
		else
			table.insert(t, " ")
		end
	end

	table.remove(t)
	t[#t] = "\n}"

	WRITE_FILE_FOR_PLATFORM[PLATFORM](table.concat(t))
end

function BigNum.__index:stringify(Base)
	return (IsNegative(self, Base or DEFAULT_BASE) and "-" or " ") .. "{" .. table.concat(self, ", ") .. "}"
end

local Fraction = {}
Fraction.__index = {}

local function newFraction(Numerator, Denominator, Base)
	if IsNegative(Denominator, Base) then
		Numerator = __unm(Numerator, Base);
		Denominator = __unm(Denominator, Base);
	end

	return setmetatable({
		Numerator = Numerator;
		Denominator = Denominator;
	}, Fraction)
end

local function Fraction__reduce(self, Base)
	local CommonFactor = GCD(self.Numerator, self.Denominator, Base)

	self.Numerator = __div(self.Numerator, CommonFactor, Base);
	self.Denominator = __div(self.Denominator, CommonFactor, Base);

	return self
end

local function Fraction__add(a, b, Base)
	return newFraction(__add(__mul(a.Numerator, b.Denominator, Base), __mul(b.Numerator, a.Denominator, Base), Base), __mul(a.Denominator, b.Denominator, Base), Base)
end

local function Fraction__sub(a, b, Base)
	return newFraction(__sub(__mul(a.Numerator, b.Denominator, Base), __mul(b.Numerator, a.Denominator, Base), Base), __mul(a.Denominator, b.Denominator, Base), Base)
end

local function Fraction__mul(a, b, Base)
	return newFraction(__mul(a.Numerator, b.Numerator, Base), __mul(a.Denominator, b.Denominator, Base), Base)
end

local function Fraction__div(a, b, Base)
	return newFraction(__mul(a.Numerator, b.Denominator, Base), __mul(a.Denominator, b.Numerator, Base), Base)
end

local function Fraction__mod()
	error("The modulo operation is undefined for Fractions")
end

local function Fraction__pow(self, Power, Base)
	Power = __div(Power.Numerator, Power.Denominator, Base)

	if type(Power) == "number" then
		return newFraction(__pow(self.Numerator, Power, Base), __pow(self.Denominator, Power, Base), Base)
	else
		error("Cannot raise " .. __tostring(self, Base) .. " to the Power of " .. __tostring(Power, Base))
	end
end

local function Fraction__tostring(self, Base)
	return __tostring(self.Numerator, Base) .. " / " .. __tostring(self.Denominator, Base)
end

local function Fraction__toScientificNotation(self, Base, DigitsAfterDecimal)
	return toScientificNotation(self.Numerator, Base, DigitsAfterDecimal) .. " / " .. toScientificNotation(self.Denominator, Base, DigitsAfterDecimal)
end

local function Fraction__lt(a, b, Base)
	return __lt(__mul(a.Numerator, b.Denominator, Base), __mul(b.Numerator, a.Denominator, Base), Base)
end

local function Fraction__unm(a, Base)
	return newFraction(__unm(a.Numerator, Base), a.Denominator, Base)
end

local function Fraction__eq(a, b, Base)
	return __eq(__mul(a.Numerator, b.Denominator, Base), __mul(b.Numerator, a.Denominator, Base), Base)
end

local function EnsureFractionalCompatibility(Func, Unary)
	local typeof = typeof or type

	if Unary then
		return function(a, ...)
			if getmetatable(a) ~= Fraction then
				error("bad argument to #1: expected Fraction, got " .. typeof(a))
			end

			return Func(a, DEFAULT_BASE, ...)
		end
	else
		return function(a, b)
			if getmetatable(a) ~= Fraction then
				error("bad argument to #1: expected Fraction, got " .. typeof(a))
			end

			if getmetatable(b) ~= Fraction then
				error("bad argument to #2: expected Fraction, got " .. typeof(b))
			end

			if #a ~= #b then
				error("You cannot operate on Fractions with BigNums of different sizes: " .. #a .. " and " .. #b)
			end

			return Func(a, b, DEFAULT_BASE)
		end
	end
end

-- Unary operators
Fraction.__tostring = EnsureFractionalCompatibility(Fraction__tostring, true)
Fraction.__unm = EnsureFractionalCompatibility(Fraction__unm, true)
Fraction.__index.Reduce = EnsureFractionalCompatibility(Fraction__reduce, true)
Fraction.__index.toScientificNotation = EnsureFractionalCompatibility(Fraction__toScientificNotation, true)

-- Binary operators
Fraction.__add = EnsureFractionalCompatibility(Fraction__add)
Fraction.__sub = EnsureFractionalCompatibility(Fraction__sub)
Fraction.__mul = EnsureFractionalCompatibility(Fraction__mul)
Fraction.__div = EnsureFractionalCompatibility(Fraction__div)
Fraction.__pow = EnsureFractionalCompatibility(Fraction__pow)
Fraction.__mod = EnsureFractionalCompatibility(Fraction__mod)

Fraction.__lt = EnsureFractionalCompatibility(Fraction__lt)
Fraction.__eq = EnsureFractionalCompatibility(Fraction__eq)

BigNum.newFraction = EnsureCompatibility(newFraction)

return BigNum
