HELL_POS = {x=2777, y=1367, z=13, stackpos=253}

dungeonStatus = 
{
	NONE = -1,
	IN_DUNGEON = 0,
	OUT_DUNGEON = 1
}

dungeonEntranceUids =
{
	7400, 7401
}

-- Construtor nao necessario?! Talvez nao...
--function Dungeons.New()
--end
	
Dungeons = { }	
	
function Dungeons.onPlayerEnter(cid, item, position)

	local dungeonId = item.actionid
	
	local canEnter = (getPlayerStorageValue(cid, dungeonId) == -1)
	
	-- Verificamos se o Player j� fez a Dungeon
	if not(canEnter) then
		doPlayerSendTextMessage(cid, MESSAGE_INFO_DESCR, "Voc� j� concluiu est� dungeon. N�o pode passar novamente por aqui.")
		
		Dungeons.doTeleportPlayerBack(cid, position)
		return FALSE
	end

	local dungeonInfo = dungeonList[dungeonId]
	
	-- Verificamos se h� espa�o na quest
	if(Dungeons.getPlayersIn(dungeonId) == dungeonInfo.maxPlayers) then
		doPlayerSendTextMessage(cid, MESSAGE_INFO_DESCR, "Est� dungeon j� est� com o numero maximo de jogadores a tentar realiza-la. Tente novamente mais tarde.")
		
		Dungeons.doTeleportPlayerBack(cid, position)
		return FALSE		
	end
	
	-- Incrementamos o numero de jogadores na quest
	Dungeons.increasePlayers(dungeonId, cid)
	
	setPlayerStorageValue(cid, sid.DUNGEON_STATUS, dungeonStatus.IN_DUNGEON)
	setPlayerStorageValue(cid, sid.ON_DUNGEON, dungeonId)
	
	Dungeons.doTeleportPlayer(cid, position)
	Dungeons.updateEntranceDescription(dungeonId)
	Dungeons.onTimeStart(cid)
	
	return TRUE	
end 

function Dungeons.increasePlayers(dungeonId, cid)

	--setGlobalStorageValue(dungeonId, Dungeons.getPlayersIn(dungeonId) + 1)
	local dungeonInfo = dungeonList[dungeonId]
	table.insert(dungeonInfo.players, cid)
end

function Dungeons.decreasePlayers(dungeonId, cid)

	--setGlobalStorageValue(dungeonId, Dungeons.getPlayersIn(dungeonId) - 1)
	local dungeonInfo = dungeonList[dungeonId]
	table.remove(dungeonInfo.players, cid)
end

function Dungeons.getPlayersIn(dungeonId)
	
	--local playersOnDungeon = getGlobalStorageValue(dungeonId) == -1 and 0 or getGlobalStorageValue(dungeonId)
	
	local dungeonInfo = dungeonList[dungeonId]
	return #dungeonInfo.players
end

function Dungeons.doTeleportPlayer(cid, position)
	
	local playerLookTo = getPlayerLookDir(cid)
	local destPos = {}
	
	if(playerLookTo == NORTH) then
		destPos = {x = position.x, y = position.y - 2, z = position.z, stackpos = 0}
	elseif(playerLookTo == SOUTH) then
		destPos = {x = position.x, y = position.y + 2, z = position.z, stackpos = 0}
	elseif(playerLookTo == EAST) then
		destPos = {x = position.x + 2, y = position.y, z = position.z, stackpos = 0}
	elseif(playerLookTo == WEST) then
		destPos = {x = position.x - 2, y = position.y, z = position.z, stackpos = 0}
	end
	
	doTeleportThing(cid, destPos)
	doSendMagicEffect(destPos, CONST_ME_MAGIC_BLUE)
end

function Dungeons.doTeleportPlayerBack(cid, position)

	local playerLookTo = getPlayerLookDir(cid)
	local destPos = {}
	
	if(playerLookTo == NORTH) then
		destPos = {x = position.x, y = position.y + 1, z = position.z, stackpos = 0}
		doSetCreatureDirection(cid, SOUTH)
	elseif(playerLookTo == SOUTH) then
		destPos = {x = position.x, y = position.y - 1, z = position.z, stackpos = 0}
		doSetCreatureDirection(cid, NORTH)
	elseif(playerLookTo == EAST) then
		destPos = {x = position.x - 1, y = position.y, z = position.z, stackpos = 0}
		doSetCreatureDirection(cid, WEST)
	elseif(playerLookTo == WEST) then
		destPos = {x = position.x + 1, y = position.y, z = position.z, stackpos = 0}
		doSetCreatureDirection(cid, EAST)
	end
	
	doTeleportThing(cid, destPos)
	doSendMagicEffect(destPos, CONST_ME_MAGIC_BLUE)
end

function Dungeons.onTimeStart(cid)
	
	local playerDungeonTime = getPlayerStorageValue(cid, sid.DUNGEON_TIME) == -1 and 0 or getPlayerStorageValue(cid, sid.DUNGEON_TIME)
	local playerDungeon = getPlayerStorageValue(cid, sid.ON_DUNGEON)
	
	local dungeonInfo = dungeonList[playerDungeon]
	
	if(playerDungeon ~= -1) then
		if(playerDungeonTime < dungeonInfo.maxTimeIn) then
		
			local leftTime = dungeonInfo.maxTimeIn - playerDungeonTime
			doPlayerSendTextMessage(cid, MESSAGE_INFO_DESCR, "Voc� possui " .. leftTime .. " minutos para concluir a dungeon...")
			
			setPlayerStorageValue(cid, sid.DUNGEON_TIME, playerDungeonTime + 5)
			addEvent(Dungeons.onTimeStart, 1000 * 60 * 5, cid)		
		elseif(playerDungeonTime == dungeonInfo.maxTimeIn) then
			Dungeons.onTimeEnd(cid)
		end
	end
end

function Dungeons.onTimeEnd(cid)

	local dungeonStatus = getPlayerStorageValue(cid, sid.DUNGEON_STATUS)
	
	if(dungeonStatus == dungeonStatus.IN_DUNGEON) then
		doPlayerSendTextMessage(cid, MESSAGE_INFO_DESCR, "O tempo para voc� cumprir esta dungeon acabou. Voc� agora ser� jugado no INFERNO!")
		doTeleportThing(cid, HELL_POS)
		
		setPlayerStorageValue(cid, sid.DUNGEON_TIME, -1)
	end

end

function Dungeons.onPlayerDeath(cid)

	local playerDungeon = getPlayerStorageValue(cid, sid.ON_DUNGEON)
	
	if(playerDungeon == -1) then
		return TRUE
	end
	
	Dungeons.decreasePlayers(playerDungeon, cid)
	
	setPlayerStorageValue(cid, sid.ON_DUNGEON, -1)
	setPlayerStorageValue(cid, sid.DUNGEON_STATUS, dungeonStatus.OUT_DUNGEON)
	setPlayerStorageValue(cid, sid.DUNGEON_TIME, -1)
	
	Dungeons.updateEntranceDescription(playerDungeon)
end

function Dungeons.onServerStart()
	
	--configuraremos as descri��es iniciais das portas das dungeons
	for key,dungeonValue in ipairs(dungeonEntranceUids) do
		
		if(getThing(dungeonValue) ~= nil) then
			Dungeons.updateEntranceDescription(dungeonValue)
		end
	end
end

function Dungeons.updateEntranceDescription(dungeonId)
	
	-- Atualizamos a descri��o da porta
	local dungeonInfo = dungeonList[dungeonId]
	print("jogadores na quest: " .. Dungeons.getPlayersIn(dungeonId) .. "/" .. dungeonInfo.maxPlayers .. ", uid: " .. dungeonId)
	doSetItemSpecialDescription(dungeonId, "[Esta dungeon possui " .. Dungeons.getPlayersIn(dungeonId) .. " jogadores de um maximo de " .. dungeonInfo.maxPlayers .. ".]")
end

function Dungeons.onPlayerLeave(cid)

	local playerDungeon = tonumber(getPlayerStorageValue(cid, sid.ON_DUNGEON))
	
	Dungeons.decreasePlayers(playerDungeon, cid)
	
	setPlayerStorageValue(cid, sid.ON_DUNGEON, -1)
	setPlayerStorageValue(cid, playerDungeon, 1)
	setPlayerStorageValue(cid, sid.DUNGEON_STATUS, dungeonStatus.OUT_DUNGEON)
	setPlayerStorageValue(cid, sid.DUNGEON_TIME, -1)
	
	Dungeons.updateEntranceDescription(playerDungeon)
end 