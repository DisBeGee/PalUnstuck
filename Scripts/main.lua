-- Tested on version 0.1.3.0

local cachedArray = {}
local cachedMutexLock = false

function findFuncID(funcAddr)
	if #cachedArray == 0 then
		return 1
	end

	local count = 1
	for i = 1, #cachedArray do
		if cachedArray[i][1] == funcAddr then
			print("Found a copy!")
			return i
		end
		count = count + 1
	end
	
	print(string.format("Could not find a copy! %d", count))
	return count
end

function teleportToSpawn(character)
	spawnVecLoc = character.SpawnLocation_ForServer
	
	local uFuncTeleport = character.K2_TeleportTo
	
	local fVector = {}
	fVector["X"] = spawnVecLoc["X"]
	fVector["Y"] = spawnVecLoc["Y"]
	fVector["Z"] = spawnVecLoc["Z"]
	
	local fRotate1 = {0, 0, 0}
	
	print(string.format("Unstucking character: %s", character:GetFullName()));
	
	uFuncTeleport(character, fVector2, fRotate1);
	
end

RegisterHook("/Game/Pal/Blueprint/Controller/AIAction/BaseCamp/RecoverHungry/BP_AIAction_BaseCampRecoverHungry.BP_AIAction_BaseCampRecoverHungry_C:ExecuteUbergraph_BP_AIAction_BaseCampRecoverHungry", function(self, entrypoint)
	
	if cachedMutexLock == true then
		return
	end
	
	local locationGetter = self:get():GetOuter():GetOuter().Character.K2_GetActorLocation

	local vecLoc = locationGetter(self:get():GetOuter():GetOuter().Character)
	
	local index = findFuncID(self:get():GetOuter():GetOuter().Character:GetAddress())
	
	if index > #cachedArray then
		cachedArray[index] = {self:get():GetOuter():GetOuter().Character:GetAddress(), os.clock(), vecLoc["X"], vecLoc["Y"], vecLoc["Z"], 1}
	else
		-- Okay this is the meat of the code
		vecLocX = vecLoc["X"]
		vecLocY = vecLoc["Y"]
		vecLocZ = vecLoc["Z"]
		
		cachedEntry = cachedArray[index]
		
		if (vecLocX == cachedEntry[3] and vecLocY == cachedEntry[4] and vecLocZ == cachedEntry[5]) then
			print("POTENTIALLY STUCK!!")
			cachedEntry[6] = cachedEntry[6] + 1
			if (cachedEntry[6] >= 3) then
				teleportToSpawn(self:get():GetOuter():GetOuter().Character)
				cachedEntry[6] = 1
			end
		else
			print("Updating location...")
			cachedEntry[3] = vecLocX
			cachedEntry[4] = vecLocY
			cachedEntry[5] = vecLocZ
			cachedEntry[2] = os.clock()
			
			cachedEntry[6] = 1
		end
	end
	
end)

LoopAsync(300000, function()
    print("Garbage collection!")
	
	cachedMutexLock = true
	
	ExecuteWithDelay(2000, function()
		if #cachedArray == 0 then
			return false
		end
		
		local currTime = os.time()
		
		local arrayLen = #cachedArray

		for i = 1, arrayLen do
			if i > arrayLen then
				break
			end
			
			local cachedTime = cachedArray[i][2]
			
			if (currTime - cachedTime > 300) then
				table.remove(cachedArray, i)
				i = i-1
				arrayLen = arrayLen-1
			end
		end
	end)
	
	cachedMutexLock = false
	
    return false -- Loops forever
end)


print("Loaded PalUnstuck successfully")

