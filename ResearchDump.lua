-- ResearchDump
-- by gobbo (@gobbo1008)
ResearchDump = {}
ResearchDump.name = "ResearchDump"
ResearchDump.version = 1.0

ResearchDump.types = { CRAFTING_TYPE_BLACKSMITHING, CRAFTING_TYPE_CLOTHIER, CRAFTING_TYPE_WOODWORKING }

function ResearchDump.OnAddOnLoaded(eventCode, addonName)
	if addonName == ResearchDump.name then
		ResearchDump.savedVariables = ZO_SavedVars:New("RainmeterResearchSavedVariables", 1, nil, {})
		ResearchDump.ForceUpdate()
	end -- if
end -- function

function ResearchDump.ResearchStarted(eventCode, craftingSkillType, researchLineIndex, traitIndex)
	local duration, remaining = GetSmithingResearchLineTraitTimes(craftingSkillType, researchLineIndex, traitIndex)
	local now = GetTimeStamp()
	local finishTime = now + remaining
	
	ResearchDump.savedVariables[craftingSkillType][researchLineIndex][traitIndex]["duration"] = duration
	ResearchDump.savedVariables[craftingSkillType][researchLineIndex][traitIndex]["finishTime"] = finishTime
end -- function

function ResearchDump.ResearchCompleted(eventCode, craftingSkillType, researchLineIndex, traitIndex)
	if (ResearchDump.savedVariables[craftingSkillType][researchLineIndex][traitIndex]["duration"] ~= 0) then
		ResearchDump.savedVariables[craftingSkillType][researchLineIndex][traitIndex]["duration"] = 0
		ResearchDump.savedVariables[craftingSkillType][researchLineIndex][traitIndex]["finishTime"] = 0
	end -- if
end -- function

function ResearchDump.StableInteractEnd(eventCode)
	ResearchDump.UpdateRiding()
end -- function

-- Events
EVENT_MANAGER:RegisterForEvent(ResearchDump.name, EVENT_ADD_ON_LOADED, ResearchDump.OnAddOnLoaded)
EVENT_MANAGER:RegisterForEvent(ResearchDump.name, EVENT_SMITHING_TRAIT_RESEARCH_STARTED, ResearchDump.ResearchStarted)
EVENT_MANAGER:RegisterForEvent(ResearchDump.name, EVENT_SMITHING_TRAIT_RESEARCH_COMPLETED, ResearchDump.ResearchCompleted)
EVENT_MANAGER:RegisterForEvent(ResearchDump.name, EVENT_STABLE_INTERACT_END, ResearchDump.StableInteractEnd)

function ResearchDump.UpdateRiding()
	local now = GetTimeStamp()
	local remaining, duration = GetTimeUntilCanBeTrained()
	local finishTime = now + remaining
	ResearchDump.savedVariables[0] = finishTime
end -- function

function ResearchDump.ForceUpdate()
	for i = 1, 3 do
		local skill = ResearchDump.types[i]
		ResearchDump.savedVariables[skill] = {}
		for line = 1, GetNumSmithingResearchLines(skill) do
			ResearchDump.savedVariables[skill][line] = {}
			local name, icon, traitCount, timeForNext = GetSmithingResearchLineInfo(skill,line)
			for trait = 1, traitCount do
				ResearchDump.savedVariables[skill][line][trait] = {}
				local duration, remaining = GetSmithingResearchLineTraitTimes(skill, line, trait)
				if ((remaining == 0) or (remaining == nil)) then
					-- No research, clean table
					ResearchDump.savedVariables[skill][line][trait]["duration"] = 0
					ResearchDump.savedVariables[skill][line][trait]["finishTime"] = 0
				else
					-- Research is happening, get data and fill into table
					ResearchDump.ResearchStarted("force", skill, line, trait)
				end -- if, else
			end -- for trait
		end -- for line
	end -- for skill
	ResearchDump.UpdateRiding()
end -- function

function ResearchDump.ToDDHHMMSS(timestamp)
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
	ResearchDump.ForceUpdate()
end -- function
