class('IngameSpectator')

function IngameSpectator:__init()
	self._allowSpectateAll = false
	self._spectatedPlayer = nil

	self._distance = -0.85
	self._height = 1.8
	self._data = nil
	self._entity = nil
	self._active = false
	self._lookAtPos = nil

	Events:Subscribe('Extension:Unloading', self, self.disable)
	Events:Subscribe('Player:Respawn', self, self._onPlayerRespawn)
	Events:Subscribe('Player:Killed', self, self._onPlayerKilled)
	Events:Subscribe('Player:Deleted', self, self._onPlayerDeleted)
	Events:Subscribe('Level:Destroy', self, self.disable)

	Events:Subscribe('Engine:Update', self, self._onUpdate)

	self.m_PlayersPitchAndYaw = { }

	NetEvents:Subscribe("kPM:PlayersPitchAndYaw", self, self._onPlayersPitchAndYaw)
end

function IngameSpectator:_onPlayersPitchAndYaw(p_PitchAndYaw)
	self.m_PlayersPitchAndYaw = p_PitchAndYaw
end

function IngameSpectator:_onPlayerRespawn(player)
	if not self:isEnabled() then
		return
	end

	-- Disable spectator when the local player spawns.
	local localPlayer = PlayerManager:GetLocalPlayer()

	if localPlayer == player then
		self:disable()
		return
	end

	-- If we have nobody to spectate and this player is spectatable
	-- then switch to them.
	if self._spectatedPlayer == nil then
		if not self._allowSpectateAll and player.teamId ~= localPlayer.teamId then
			return
		end

		self:spectatePlayer(player)
	end
end

function IngameSpectator:_onPlayerKilled(player)
	if not self:isEnabled() then
		return
	end

	-- Handle death of player being spectated.
	if player == self._spectatedPlayer then
		self:spectateNextPlayer()
	end
end

function IngameSpectator:_onPlayerDeleted(player)
	if not self:isEnabled() then
		return
	end

	-- Handle disconnection of player being spectated.
	if player == self._spectatedPlayer then
		self:spectateNextPlayer()
	end
end

function IngameSpectator:_findFirstPlayerToSpectate()
	local playerToSpectate = nil
	local players = PlayerManager:GetPlayers()
	local localPlayer = PlayerManager:GetLocalPlayer()

	for _, player in pairs(players) do
		-- We don't want to spectate the local player.
		if player == localPlayer then
			goto continue_enable
		end

		-- We don't want to spectate players who are dead.
		if player.soldier == nil then
			goto continue_enable
		end

		-- If we don't allow spectating everyone we should check the
		-- player's team to determine if we can spectate them.
		if not self._allowSpectateAll and player.teamId ~= localPlayer.teamId then
			goto continue_enable
		end

		-- Otherwise we're good to spectate this player.
		playerToSpectate = player
		break

		::continue_enable::
	end

	return playerToSpectate
end

function IngameSpectator:enable()
	if not kPMConfig.SpectatorEnabled then
		return
	end

	if self:isEnabled() then
		return
	end

	-- If we're alive we don't allow spectating.
	local localPlayer = PlayerManager:GetLocalPlayer()

	if localPlayer.soldier ~= nil then
		return
	end

	self:_createCamera()
	self:_takeControl()

	local playerToSpectate = self:_findFirstPlayerToSpectate()

    if playerToSpectate ~= nil then
        WebUI:ExecuteJS('SpectatorTarget("'.. tostring(playerToSpectate.name) .. '");')
        WebUI:ExecuteJS('SpectatorEnabled('.. tostring(true) .. ');')
		self:spectatePlayer(playerToSpectate)
		return
	end

	-- If we found no player to spectate then just do freecam.
	self:disable()
end

function IngameSpectator:disable()
	if not kPMConfig.SpectatorEnabled then
		return
	end
	
	if not self:isEnabled() then
		return
    end
    
    WebUI:ExecuteJS('SpectatorTarget("");')
    WebUI:ExecuteJS('SpectatorEnabled('.. tostring(false) .. ');')

	self._spectatedPlayer = nil

	self:_releaseControl()
	self:_destroyCamera()
end

function IngameSpectator:_destroyCamera()
	if self._entity == nil then
		return
	end

	-- Destroy the camera entity.
	self._entity:Destroy()
	self._entity = nil
	self._lookAtPos = nil
end

function IngameSpectator:_takeControl()
	-- By firing the "TakeControl" event on the camera entity we make the
	-- current player switch to this camera from their first person camera.
	self._active = true
	self._entity:FireEvent('TakeControl')
end


function IngameSpectator:_releaseControl()
	-- By firing the "ReleaseControl" event on the camera entity we return
	-- the player to whatever camera they were supposed to be using.
	self._active = false

	if self._entity ~= nil then
		self._entity:FireEvent('ReleaseControl')
	end
end

function IngameSpectator:_createCameraData()
	if self._data ~= nil then
		return
	end

	-- Create data for our camera entity.
	-- We set the priority very high so our game gets forced to use this camera.
	self._data = CameraEntityData()
	self._data.fov = 80
	self._data.enabled = true
	self._data.priority = 99999
	self._data.nameId = 'promod-spec-cam'
	self._data.transform = LinearTransform()
end

function IngameSpectator:_createCamera()
	if self._entity ~= nil then
		return
	end

	-- First ensure that we have create our camera data.
	self:_createCameraData()

	-- And then create the camera entity.
	self._entity = EntityManager:CreateEntity(self._data, self._data.transform)
	self._entity:Init(Realm.Realm_Client, true)
end

function IngameSpectator:spectatePlayer(p_Player)
	if not self:isEnabled() then
		return
	end

	if p_Player == nil then
		self:disable()
		return
	end

	local s_LocalPlayer = PlayerManager:GetLocalPlayer()

	-- We can't spectate the local player.
	if s_LocalPlayer == p_Player then
		return
	end

	-- If we don't allow spectating everyone make sure that this player
	-- is in the same team as the local player.
	if not self._allowSpectateAll and s_LocalPlayer.teamId ~= p_Player.teamId then
		return
	end

	print('Spectating player' .. p_Player.name)

	self._spectatedPlayer = p_Player
	--SpectatorManager:SpectatePlayer(self._spectatedPlayer, self._firstPerson)
end

function IngameSpectator:spectateNextPlayer()
	if not self:isEnabled() then
		return
	end

	-- If we are not spectating anyone just find the first player to spectate.
	if self._spectatedPlayer == nil then
		local playerToSpectate = self:_findFirstPlayerToSpectate()

		if playerToSpectate ~= nil then
			self:spectatePlayer(playerToSpectate)
		end

		return
	end

	-- Find the index of the current player.
	local currentIndex = 0
	local players = PlayerManager:GetPlayers()
	local localPlayer = PlayerManager:GetLocalPlayer()

	if players == nil then
		return
	end

	for i, player in pairs(players) do
		if player == self._spectatedPlayer then
			currentIndex = i
			break
		end
	end

	-- Increment so we start from the next player.
	currentIndex = currentIndex + 1

	if currentIndex > #players then
		currentIndex = 1
	end

	-- Find the next player we can spectate.
	local nextPlayer = nil

	for i = 1, #players do
		local playerIndex = (i - 1) + currentIndex

		if playerIndex > #players then
			playerIndex = playerIndex - #players
		end

		local player = players[playerIndex]

		if player.soldier ~= nil and player ~= localPlayer and (self._allowSpectateAll or player.teamId == localPlayer.teamId) then
			nextPlayer = player
			break
		end
	end

	-- If we didn't find any players to spectate then switch to freecam.
	if nextPlayer == nil then
		self:disable()
	else
		WebUI:ExecuteJS('SpectatorTarget("'.. tostring(nextPlayer.name) .. '");')
		self:spectatePlayer(nextPlayer)
	end
end

function IngameSpectator:spectatePreviousPlayer()
	if not self:isEnabled() then
		return
	end

	-- If we are not spectating anyone just find the first player to spectate.
	if self._spectatedPlayer == nil then
		local playerToSpectate = self:_findFirstPlayerToSpectate()

		if playerToSpectate ~= nil then
			self:spectatePlayer(playerToSpectate)
		end

		return
	end

	-- Find the index of the current player.
	local currentIndex = 0
	local players = PlayerManager:GetPlayers()
	local localPlayer = PlayerManager:GetLocalPlayer()

	if players == nil then
		return
	end

	for i, player in pairs(players) do
		if player == self._spectatedPlayer then
			currentIndex = i
			break
		end
	end

	-- Decrement so we start from the previous player.
	currentIndex = currentIndex - 1

	if currentIndex <= 0 then
		currentIndex = #players
	end

	-- Find the previous player we can spectate.
	local nextPlayer = nil

	for i = #players, 1, -1 do
		local playerIndex = (i - (#players - currentIndex))

		if playerIndex <= 0 then
			playerIndex = playerIndex + #players
		end

		local player = players[playerIndex]

		if player.soldier ~= nil and player ~= localPlayer and (self._allowSpectateAll or player.teamId == localPlayer.teamId) then
			nextPlayer = player
			break
		end
	end

	-- If we didn't find any players to spectate then switch to freecam.
	if nextPlayer == nil then
		self:disable()
	else
		WebUI:ExecuteJS('SpectatorTarget("'.. tostring(nextPlayer.name) .. '");')
		self:spectatePlayer(nextPlayer)
	end
end

function IngameSpectator:isEnabled()
	return self._active
end

function IngameSpectator:_onUpdate()
	if not self:isEnabled() then
		return
	end

	-- Don't update if we don't have a player with an alive soldier.
	local player = self._spectatedPlayer

	if player == nil or player.soldier == nil or player.id == nil then
		return
	end

	if self.m_PlayersPitchAndYaw[player.id] == nil then
		return
	end
	
	-- Get the soldier's aiming angles.
	--local yaw = -math.atan(player.soldier.worldTransform.forward.x, player.soldier.worldTransform.forward.z)
	--local pitch = 0.0
	local yaw = self.m_PlayersPitchAndYaw[player.id]["Yaw"]
	local pitch = self.m_PlayersPitchAndYaw[player.id]["Pitch"]

	--[[print("weaponTransform :")
	print(player.soldier.weaponsComponent.weaponTransform)

	print("currentWeaponSlot:")
	print(player.soldier.weaponsComponent.currentWeaponSlot)

	print("weapons:")
	print(player.soldier.weaponsComponent.weapons)

	print("currentWeapon:")
	print(player.soldier.weaponsComponent.currentWeapon)]]

	-- Fix angles so we're looking at the right thing.
	yaw = yaw - math.pi / 2
	pitch = pitch + math.pi / 2

	-- Set the look at position above the soldier's feet.
	self._lookAtPos = player.soldier.transform.trans:Clone()
	self._lookAtPos.y = self._lookAtPos.y + self._height

	-- Calculate where our camera has to be base on the angles.
	local cosfi = math.cos(yaw)
	local sinfi = math.sin(yaw)

	local costheta = math.cos(pitch)
	local sintheta = math.sin(pitch)

	local cx = self._lookAtPos.x + (self._distance * sintheta * cosfi)
	local cy = self._lookAtPos.y + (self._distance * costheta)
	local cz = self._lookAtPos.z + (self._distance * sintheta * sinfi)

	local cameraLocation = Vec3(cx, cy, cz)

	self._data.transform:LookAtTransform(cameraLocation, self._lookAtPos)
	--self._data.transform.left = self._data.transform.left * -1
	--self._data.transform.forward = self._data.transform.forward * -1
end

if g_IngameSpectator == nil then
	g_IngameSpectator = IngameSpectator()
end

return g_IngameSpectator
