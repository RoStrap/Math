-- Generates option-picker functions from relative probabilities
-- @author Validark

local WeightedProbabilities = {}

return {
	new = function(ProbabilityData)
		-- @param dictionary in the form: {
		--		[variant option1] = number Weight1;
		--		[variant option2] = number Weight2;
		-- }
		-- @returns a function that, when called, selects an option from its probability and returns it

		local n = 0
		local TotalWeight = 0
		local Options = {}
		local RelativeWeights = {}

		for Option, RelativeWeight in pairs(ProbabilityData) do
			assert(type(RelativeWeight) == "number", "[WeightedProbability] ProbabilityData must be in the form {variant Option = number Weight}")
			assert(RelativeWeight >= 0, "[WeightedProbability] Weights must be non-negative numbers")

			n = n + 1
			TotalWeight = TotalWeight + RelativeWeight

			Options[n] = Option
			RelativeWeights[n] = RelativeWeight
		end

		ProbabilityData = nil

		assert(TotalWeight ~= 0, "[WeightedProbability] Please give an option with a weight greater than 0")

		for i = 1, n do
			RelativeWeights[i] = RelativeWeights[i] / TotalWeight
		end

		local function Pick()
			local Picked = math.random()

			for i = 1, n do
				Picked = Picked - RelativeWeights[i]
				if Picked < 0 then
					local Option = Options[i]
					return WeightedProbabilities[Option] and Option() or Option
				end
			end
		end

		WeightedProbabilities[Pick] = true

		return Pick
	end
}
