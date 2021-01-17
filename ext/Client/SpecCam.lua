class 'SpecCam'

require ("__shared/Util/RotationHelper")

function SpecCam:__init()
	self:RegisterVars()
	self:RegisterEvents()
end

function SpecCam:RegisterVars()
	self._targetPlayerId = nil
	self._targetIndex = 0

	self._data = nil
	self._entity = nil
	self._active = false
	self._lookAtPos = nil
end

function SpecCam:RegisterEvents()
	Events:Subscribe('Engine:Update', self, self._onUpdate)
	Events:Subscribe('Level:Destroy', self, self._onLevelDestroy)
end

--[[
function SpecCam:OnLevelDestroy()
	self:RegisterVars()
end

function SpecCam:SetCameraMode(p_Mode)
	SpectatorManager:SetCameraMode(p_Mode)
    self.m_Mode = p_Mode
end

function SpecCam:GetCameraMode()
    return self.m_Mode
end

function SpecCam:SetCameraTarget(p_Player)
	if p_Player == nil then
		return
	end

	if not p_Player.alive then
		return
	end

	if p_Player.soldier == nil then
		return
	end

	local s_LocalPlayer = PlayerManager:GetLocalPlayer()
	if s_LocalPlayer == nil then
		return
	end

	if p_Player.teamId ~= s_LocalPlayer.teamId then
		return
	end

	local s_SpectatedPlayer = SpectatorManager:GetSpectatedPlayer()

	if s_SpectatedPlayer == nil or s_SpectatedPlayer.id ~= p_Player.id then
		SpectatorManager:SpectatePlayer(p_Player, true)
	end

	print("Setting SpecCam target to " .. p_Player.name)

	WebUI:ExecuteJS('SpectatorEnabled('.. tostring(true) .. ');')
	WebUI:ExecuteJS('SpectatorTarget("'.. tostring(p_Player.name) .. '");')

	self.m_TargetPlayerId = p_Player.id
end

function SpecCam:GetRandomCameraTarget()
	local s_LocalPlayer = PlayerManager:GetLocalPlayer()
	if s_LocalPlayer == nil then
		return nil
	end

	local s_PlayersList = PlayerManager:GetPlayersByTeam(s_LocalPlayer.teamId)

	local s_Target = nil
	if #s_PlayersList > 1 then
		
		local s_AliveCount = 0
		--local s_AlivePlayers = {}
		for l_Index, l_Player in pairs(s_PlayersList) do
			if l_Player ~= nil and
				l_Player.alive and
				l_Player.soldier ~= nil and
				l_Player.id ~= s_LocalPlayer.id
			then
				s_AliveCount = s_AliveCount + 1
				--s_AlivePlayers:add(l_Player)
			end
		end

		if s_AliveCount > 0 then
			while s_Target == nil do
				local l_RandomIndex = math.random( #s_PlayersList )
				if s_PlayersList[l_RandomIndex] ~= nil and
					s_PlayersList[l_RandomIndex].alive and
					s_PlayersList[l_RandomIndex].soldier ~= nil and
					s_PlayersList[l_RandomIndex].id ~= s_LocalPlayer.id
				then
					s_Target = s_PlayersList[l_RandomIndex]
				end
			end
		else
			s_Target = s_LocalPlayer
		end
	end

	if s_Target == nil then
		s_Target = s_LocalPlayer
	end
  
	return s_Target
end

function SpecCam:GetNextCameraTarget()
	local s_LocalPlayer = PlayerManager:GetLocalPlayer()
	if s_LocalPlayer == nil then
		return nil
	end

	local s_PlayersList = PlayerManager:GetPlayersByTeam(s_LocalPlayer.teamId)

	local s_Target = nil
	if #s_PlayersList > 1 then
		
		local s_AliveCount = 0
		for l_Index, l_Player in pairs(s_PlayersList) do
			if l_Player ~= nil and
				l_Player.alive and
				l_Player.soldier ~= nil and
				l_Player.id ~= s_LocalPlayer.id
			then
				s_AliveCount = s_AliveCount + 1
			end
		end

		if s_AliveCount > 0 then

			while(s_Target == nil)
			do
				local l_Found = false
				for l_Index, l_Player in pairs(s_PlayersList) do
					if not l_Found and
						l_Index > self.m_TargetIndex and
						l_Player ~= nil and
						l_Player.alive and
						l_Player.soldier ~= nil and
						l_Player.id ~= s_LocalPlayer.id
					then
						l_Found = true
						self.m_TargetIndex = l_Index
						s_Target = l_Player
					end
				end

				if not l_Found then
					self.m_TargetIndex = 0
				end
			end
		else
			s_Target = s_LocalPlayer
		end
	end

	if s_Target == nil then
		s_Target = s_LocalPlayer
	end
  
	return s_Target
end

function SpecCam:GetCameraTarget()
	return self.m_TargetPlayerId
end

function SpecCam:OnUpdateInputHook(p_Hook, p_Cache, p_DeltaTime)
	local s_TargetPlayer = nil
	if self.m_TargetPlayerId ~= nil then
		s_TargetPlayer = PlayerManager:GetPlayerById(self.m_TargetPlayerId)
	end

	if s_TargetPlayer ~= nil and s_TargetPlayer.alive == false then
		local s_Target = self:GetRandomCameraTarget()
		if s_Target ~= nil then
			self:SetCameraTarget(s_Target)
		end
	end

	local s_LocalPlayer = PlayerManager:GetLocalPlayer()
	if s_LocalPlayer ~= nil and s_LocalPlayer.alive then
		self:Disable()
	end
end

function SpecCam:Create()
	local s_Entity = EntityManager:CreateEntity(self.m_CameraData, LinearTransform())

	if s_Entity == nil then
		print("Could not spawn camera")
		return
	end

	s_Entity:Init(Realm.Realm_Client, true);

	self.m_CameraData.transform = ClientUtils:GetCameraTransform()
	self.m_CameraData.fov = 90
	self.m_Camera = s_Entity
end

function SpecCam:TakeControl()
	if(self.m_Camera ~= nil) then
		self.m_Camera:FireEvent("TakeControl")
	end
end

function SpecCam:ReleaseControl()
	if(self.m_Camera ~= nil) then
		self.m_Camera:FireEvent("ReleaseControl")
	end
end

function SpecCam:Enable()
	if(self.m_Camera == nil) then
		self:Create()
	end

	local s_Target = self:GetRandomCameraTarget()
	if s_Target ~= nil then
		self:SetCameraTarget(s_Target)
		self:SetCameraMode(SpectatorCameraMode.FirstPerson)
		--self:TakeControl()
		SpectatorManager:SetSpectating(true)
		self.m_SpecCam = true
		WebUI:ExecuteJS('SpectatorEnabled('.. tostring(true) .. ');')
	end
end

function SpecCam:Disable()
	if self.m_SpecCam then
		local s_LocalPlayer = PlayerManager:GetLocalPlayer()
		self:SetCameraTarget(s_LocalPlayer)
		self:SetCameraMode(SpectatorCameraMode.Disabled)
		--self:ReleaseControl()
		SpectatorManager:SetSpectating(false)
		self.m_SpecCam = false
		WebUI:ExecuteJS('SpectatorEnabled('.. tostring(false) .. ');')
	end
end

function SpecCam:OnUpdateInput(p_Delta)
	if InputManager:WentKeyDown(InputDeviceKeys.IDK_Space) and self.m_SpecCam then
		local s_Target = self:GetNextCameraTarget()
		if s_Target ~= nil then
			self:SetCameraTarget(s_Target)
		end
	end
end

function SpecCam:GetRandomSpecWhenTeamSwitch()
	if self.m_SpecCam then
		local s_Target = self:GetRandomCameraTarget()
		if s_Target ~= nil then
			self:SetCameraTarget(s_Target)
		end
	end
end]]
function SpecCam:_createCameraData()
	if self._data ~= nil then
		return
	end

	-- Create data for our camera entity.
	-- We set the priority very high so our game gets forced to use this camera.
	self._data = CameraEntityData()
	self._data.fov = 100
	self._data.enabled = true
	self._data.priority = 99999
	self._data.nameId = 'promod-spec-cam'
	self._data.transform = LinearTransform()
end

function SpecCam:_createCamera()
	if self._entity ~= nil then
		return
	end

	-- First ensure that we have create our camera data.
	self:_createCameraData()

	-- And then create the camera entity.
	self._entity = EntityManager:CreateEntity(self._data, self._data.transform)
	self._entity:Init(Realm.Realm_Client, true)
end

function SpecCam:_onLevelDestroy()
	-- When the level is getting destroyed we should disable the camera.
	-- This will release control and destroy our entity.
	self:disable()
end

function SpecCam:_destroyCamera()
	if self._entity == nil then
		return
	end

	-- Destroy the camera entity.
	self._entity:Destroy()
	self._entity = nil
	self._lookAtPos = nil
end

function SpecCam:_takeControl()
	-- By firing the "TakeControl" event on the camera entity we make the
	-- current player switch to this camera from their first person camera.
	self._active = true
	self._entity:FireEvent('TakeControl')
end

function SpecCam:_releaseControl()
	-- By firing the "ReleaseControl" event on the camera entity we return
	-- the player to whatever camera they were supposed to be using.
	self._active = false

	if self._entity ~= nil then
		self._entity:FireEvent('ReleaseControl')
	end
end

-- Enables the spec camera.
function SpecCam:enable()
	self:_setCameraTarget()
	self:_createCamera()
	self:_takeControl()
end

-- Disables the spec camera.
function SpecCam:disable()
	self:_releaseControl()
	self:_destroyCamera()

	WebUI:ExecuteJS('SpectatorEnabled('.. tostring(false) .. ');')
end

function SpecCam:spectateNextPlayer()
	self:_setCameraTarget()
end

-- Returns `true` if the camera is currently active, `false` otherwise.
function SpecCam:isActive()
	return self._active
end

-- Main function
function SpecCam:_onUpdate(delta, simDelta)
	-- Don't update if the camera is not active.
	if not self._active then
		return
	end



	-- Don't update if we don't have a player with an alive soldier.
	local player = PlayerManager:getPlayerById(self._targetPlayerId)

	if player == nil or player.soldier == nil or player.input == nil then
		return
	end

	-- Get the soldier's aiming angles.
	local yaw = player.input.authoritativeAimingYaw
	local pitch = player.input.authoritativeAimingPitch

	-- Fix angles so we're looking at the right thing.
	yaw = yaw - math.pi / 2
	pitch = pitch + math.pi / 2

	-- Set the look at position above the soldier's feet.
	self._lookAtPos = player.soldier.transform.trans:Clone()
	self._lookAtPos.y = self._lookAtPos.y + 3.0

	-- Calculate where our camera has to be base on the angles.
	local cosfi = math.cos(yaw)
	local sinfi = math.sin(yaw)

	local costheta = math.cos(pitch)
	local sintheta = math.sin(pitch)

	local cx = self._lookAtPos.x + (5.0 * sintheta * cosfi)
	local cy = self._lookAtPos.y + (5.0 * costheta)
	local cz = self._lookAtPos.z + (5.0 * sintheta * sinfi)

	local cameraLocation = Vec3(cx, cy, cz)

	-- Calculate the LookAt transform.
	self._data.transform:LookAtTransform(cameraLocation, self._lookAtPos)

	-- Flip the camera angles so we're looking at the player.
	self._data.transform.left = self._data.transform.left * -1
	self._data.transform.forward = self._data.transform.forward * -1
end

function SpecCam:_setCameraTarget()
	local s_LocalPlayer = PlayerManager:GetLocalPlayer()
	if s_LocalPlayer == nil then
		return nil
	end

	local s_Target = nil

	local s_PlayersList = PlayerManager:GetPlayersByTeam(s_LocalPlayer.teamId)

	if #s_PlayersList > 1 then
		local s_AliveCount = 0
		for l_Index, l_Player in pairs(s_PlayersList) do
			if l_Player ~= nil and
				l_Player.alive and
				l_Player.soldier ~= nil and
				l_Player.id ~= s_LocalPlayer.id
			then
				s_AliveCount = s_AliveCount + 1
			end
		end

		if s_AliveCount > 0 then
			while(s_Target == nil)
			do
				local l_Found = false
				for l_Index, l_Player in pairs(s_PlayersList) do
					if not l_Found and
						l_Index > self._targetIndex and
						l_Player ~= nil and
						l_Player.alive and
						l_Player.soldier ~= nil and
						l_Player.id ~= s_LocalPlayer.id
					then
						l_Found = true
						self._targetIndex = l_Index
						s_Target = l_Player
					end
				end

				if not l_Found then
					self._targetIndex = 0
				end
			end
		else
			self:disable()
			return
		end
	end

	if s_Target == nil then
		self:disable()
		return
	end
  
	self._targetPlayerId = s_Target.id

	print("Setting SpecCam target to " .. s_Target.name)

	WebUI:ExecuteJS('SpectatorEnabled('.. tostring(true) .. ');')
	WebUI:ExecuteJS('SpectatorTarget("'.. tostring(s_Target.name) .. '");')
end

return SpecCam()
