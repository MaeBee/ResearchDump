-- RainmeterResearch
-- by gobbo (@gobbo1008)
RainmeterResearch = {}
RainmeterResearch.name = "RainmeterResearch"
RainmeterResearch.version = 1.0

RainmeterResearch.types = { CRAFTING_TYPE_BLACKSMITHING, CRAFTING_TYPE_CLOTHIER, CRAFTING_TYPE_WOODWORKING }

function RainmeterResearch.OnAddOnLoaded(eventCode, addonName)
	if addonName == RainmeterResearch.name then
		RainmeterResearch.savedVariables = ZO_SavedVars:New("RainmeterResearchSavedVariables", 1, nil, {})
		RainmeterResearch.ForceUpdate()
	end -- if
end -- function

function RainmeterResearch.ResearchStarted(eventCode, craftingSkillType, researchLineIndex, traitIndex)
	local duration, remaining = GetSmithingResearchLineTraitTimes(craftingSkillType, researchLineIndex, traitIndex)
	local now = GetTimeStamp()
	local finishTime = now + remaining
	
	RainmeterResearch.savedVariables[craftingSkillType][researchLineIndex][traitIndex]["duration"] = duration
	RainmeterResearch.savedVariables[craftingSkillType][researchLineIndex][traitIndex]["finishTime"] = finishTime
	
	d("[RainmeterResearch] Research found, ends in " .. RainmeterResearch.ToDDHHMMSS(remaining) .. " at " .. GetDateStringFromTimestamp(finishTime) .. ". Total time: " .. RainmeterResearch.ToDDHHMMSS(duration))
end -- function

function RainmeterResearch.ResearchCompleted(eventCode, craftingSkillType, researchLineIndex, traitIndex)
	if (RainmeterResearch.savedVariables[craftingSkillType][researchLineIndex][traitIndex]["duration"] ~= 0) then
		RainmeterResearch.savedVariables[craftingSkillType][researchLineIndex][traitIndex]["duration"] = 0
		RainmeterResearch.savedVariables[craftingSkillType][researchLineIndex][traitIndex]["finishTime"] = 0
	end -- if
end -- function

-- Events
EVENT_MANAGER:RegisterForEvent(RainmeterResearch.name, EVENT_ADD_ON_LOADED, RainmeterResearch.OnAddOnLoaded)
EVENT_MANAGER:RegisterForEvent(RainmeterResearch.name, EVENT_SMITHING_TRAIT_RESEARCH_STARTED, RainmeterResearch.ResearchStarted)
EVENT_MANAGER:RegisterForEvent(RainmeterResearch.name, EVENT_SMITHING_TRAIT_RESEARCH_COMPLETED, RainmeterResearch.ResearchCompleted)

function RainmeterResearch.ForceUpdate()
	for i = 1, 3 do
		local skill = RainmeterResearch.types[i]
		RainmeterResearch.savedVariables[skill] = {}
		for line = 1, GetNumSmithingResearchLines(skill) do
			RainmeterResearch.savedVariables[skill][line] = {}
			local name, icon, traitCount, timeForNext = GetSmithingResearchLineInfo(skill,line)
			for trait = 1, traitCount do
				RainmeterResearch.savedVariables[skill][line][trait] = {}
				local duration, remaining = GetSmithingResearchLineTraitTimes(skill, line, trait)
				if ((remaining == 0) or (remaining == nil)) then
					-- No research, clean table
					RainmeterResearch.savedVariables[skill][line][trait]["duration"] = 0
					RainmeterResearch.savedVariables[skill][line][trait]["finishTime"] = 0
				else
					-- Research is happening, get data and fill into table
					RainmeterResearch.ResearchStarted("force", skill, line, trait)
				end -- if, else
			end -- for trait
		end -- for line
	end -- for skill
end -- function

function RainmeterResearch.ToDDHHMMSS(timestamp)
	timestamp = math.floor(timestamp)
	
	local days = math.floor(timestamp/86400)
	
	local hours = math.floor((timestamp%86400)/3600)
	if hours < 10 then
		hours = "0" .. hours
	end -- if
	
	local minutes = math.floor(((timestamp%86400)%3600)/60)
	if minutes < 10 then
		minutes = "0" .. minutes
	end -- if
	
	local seconds = timestamp % 60
	if seconds < 10 then
		seconds = "0" .. seconds
	end -- if
	
	return days .. "d " .. hours .. "h " .. minutes .. "m " .. seconds .. "s"
end -- function

-- Slash Commands
SLASH_COMMANDS["/rr"] = function(arg)
	RainmeterResearch.ForceUpdate()
end -- function
