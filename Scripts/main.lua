-- Tested on version 0.1.3.0
vuxGameVersion = "0.1.3.0"

-- Time in minutes, 0 =  none, 1 = 1 minute etc
vuxReviveTimer = 5
NotifyOnNewObject("/Script/Pal.UPalGameSetting", function(var)
	var.PalBoxReviveTime = vuxReviveTimer
	print("Remove Pal revive timer loaded for game version " .. vuxGameVersion)
	print("Pal revive timer set to " .. vuxReviveTimer)
end)


--RegisterHook("/Game/Pal/Blueprint/Controller/AIAction/BaseCamp/RecoverHungry/BP_AIAction_BaseCampRecoverHungry.BP_AIAction_BaseCampRecoverHungry_C:ChangeActionEat", function(self)
--	print("Changing action to eat1");
-- end)

function dump(o)
   if type(o) == 'table' then
      local s = '{ '
      for k,v in pairs(o) do
         if type(k) ~= 'number' then k = '"'..k..'"' end
         s = s .. '['..k..'] = ' .. dump(v) .. ','
      end
      return s .. '} '
   else
      return tostring(o)
   end
end

 
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
	-- print(string.format("Changing action to eat2: %d", entrypoint:get()));
	
	if cachedMutexLock == true then
		return
	end
	
	-- print(string.format("Object name: %s", self:get():GetFullName()));
	
	-- print(string.format("Fullname: %s", self:get():GetOuter():GetOuter():GetFullName()));
	
	--print(string.format("Fullname: %s", self:get():GetOuter():GetOuter().Character:GetFullName()));
	
	local locationGetter = self:get():GetOuter():GetOuter().Character.K2_GetActorLocation
	
	-- print(string.format("Location function: %s", locationGetter:GetFullName()));

	vecLoc = locationGetter(self:get():GetOuter():GetOuter().Character)
	
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
	
	-- print(string.format("table: %s", dump(cachedArray[index])))
	-- vecLoc = locationGetter(self:get():GetOuter():GetOuter().Character)
	
	-- print(string.format("table: %s", dump(vecLoc)))
	-- print(string.format("X: %f, Y: %f, Z: %f", vecLoc[0], vecLoc[1], vecLoc[2]))
	
	
	-- result: Object name: BP_AIAction_BaseCampRecoverHungry_C /Game/Pal/Maps/MainWorld_5/PL_MainWorld5.PL_MainWorld5:PersistentLevel.BP_MonsterAIController_BaseCamp_C_2146959432.ActionsComp.BP_AIAction_BaseCampRecoverHungry_C_2146754408
	
	-- print(string.format("Object name: %s", self:get():GetOuter():GetFullName()));
	
	-- self:get():GetOuter():CallFunction("SetAction_DefaultPos");
	
	-- self:get():SetAction_DefaultPos();
	
	-- local ActorInstances = FindObject(nil, "/Game/Pal/Blueprint/Controller/Monster/BP_MonsterAIController_BaseCamp.BP_MonsterAIController_BaseCamp_C:SetAction_DefaultPos")
	-- if not ActorInstances or ActorInstances == nil then
	-- 	print("No instances of 'ExecuteUbergraph_BP_AIAction_BaseCampRecoverHungry' were found\n")
	-- else
	-- 	print(ActorInstances:GetFullName())
	-- end
end)


RegisterHook(
"/Game/Pal/Blueprint/Action/Common/BP_Action_BeThrown.BP_Action_BeThrown_C:ExecuteUbergraph_BP_Action_BeThrown", function(self, entrypoint)
	print(string.format("Getting thrown: %d", entrypoint:get()));
	print(string.format("Fullname: %s", self:get():GetOuter():GetOuter():GetFullName()));
	print(string.format("NetTag: %s", self:get():GetOuter():GetOuter().NetTag));
	
	local index = findFuncID(self:get():GetOuter():GetOuter():GetAddress())
	
	local locationGetter = self:get():GetOuter():GetOuter().K2_GetActorLocation
	
	local vecLocTable = locationGetter(self:get():GetOuter():GetOuter())
	
	cachedArray[index] = {self:get():GetOuter():GetOuter():GetAddress(), os.clock(), vecLocTable["X"], vecLocTable["Y"], vecLocTable["Z"]}
	
	print(string.format("table: %s", dump(cachedArray[index])))
	
end)


local catObj = FindFirstOf("BP_PinkCat_C");

if not catObj:IsValid() then
	print("failed to find cat")
else
	print(string.format("Cat obj: %s", catObj:GetFullName()));
	
	print(string.format("Values: %f", catObj.ReplicatedMovement.Location.X));
	
	print(string.format("New Values: %f", catObj.ReplicatedMovement.Location.X));
	
	-- local uFuncAnimation = catObj.Jump -- this works!!
	local uFuncAnimation = catObj.K2_TeleportTo
	
	-- print(string.format("Cat function: %s", uFuncAnimation:GetFullName()));
	
	local fVector2 = {}
	fVector2["X"] = -313772.738411
	fVector2["Y"] = 135060.324896
	fVector2["Z"] = -1128.302377
	
	 local fVector1 = {-313772.738411, 135060.324896,-1128.302377}
	 local fRotate1 = {0, 0, 0}
	
	 --uFuncAnimation(catObj, fVector2, fRotate1);
end

print(string.format("Time: %f", os.clock()));

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


print("Loaded vuxRemovePalReviveTimer jep")

