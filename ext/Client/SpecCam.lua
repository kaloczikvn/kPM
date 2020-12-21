class 'SpecCam'

require ("__shared/Util/RotationHelper")

CameraMode = {
	FirstPerson = 1,
	FreeCam = 2,
	Orbital = 3,
	Editor = 4
}

function SpecCam:__init()
	print("Initializing SpecCam module")
	self:RegisterVars()
end

function SpecCam:RegisterVars()
	self.m_SpecCam = false
	self.m_Mode = CameraMode.FirstPerson
	self.m_TargetPlayer = nil

	self.m_Camera = nil
	self.m_CameraData = CameraEntityData()
	self.m_LastTransform = nil

	self.m_MoveX = 0.0
	self.m_MoveY = 0.0
	self.m_MoveZ = 0.0
	self.m_SimTickCount = 0
	self.m_InverseTick = 0.0
	self.m_SpeedMultiplier = 1.917
	self.m_RotationSpeedMultiplier = 200
	self.m_Sprint = false

	self.m_CameraDistance = 1.0
	self.m_ThirdPersonRotX = 0.0
	self.m_ThirdPersonRotY = 0.0
end

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
		return false
	end

	if not p_Player.alive then
		return false
	end

	if p_Player.soldier == nil then
		return false
	end

	local s_LocalPlayer = PlayerManager:GetLocalPlayer()
	if s_LocalPlayer == nil then
		return false
	end

	if p_Player.teamId ~= s_LocalPlayer.teamId then
		return false
	end

	local s_SpectatedPlayer = SpectatorManager:GetSpectatedPlayer()

	if s_SpectatedPlayer == nil or s_SpectatedPlayer.id ~= p_Player.id then
		SpectatorManager:SpectatePlayer(p_Player, true)
	end

	print("Setting SpecCam target to " .. p_Player.name)

	WebUI:ExecuteJS('SpectatorEnabled('.. tostring(true) .. ');')
	WebUI:ExecuteJS('SpectatorTarget("'.. tostring(p_Player.name) .. '");')

	self.m_TargetPlayer = p_Player
	return true
end

function SpecCam:GetRandomCameraTarget()
	local s_LocalPlayer = PlayerManager:GetLocalPlayer()

	if s_LocalPlayer == nil then
		return
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

function SpecCam:GetCameraTarget()
	return self.m_TargetPlayer
end

function SpecCam:OnUpdateInputHook(p_Hook, p_Cache, p_DeltaTime)
	if self.m_TargetPlayer ~= nil and self.m_TargetPlayer.alive == false then
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
	self.m_CameraData.fov = 30
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
		self:SetCameraMode(CameraMode.FirstPerson)
		self:TakeControl()
		SpectatorManager:SetSpectating(true)
		self.m_SpecCam = true
		WebUI:ExecuteJS('SpectatorEnabled('.. tostring(self.m_SpecCam) .. ');')
	end
end

function SpecCam:Disable()
	if self.m_SpecCam then
		local s_LocalPlayer = PlayerManager:GetLocalPlayer()
		self:SetCameraTarget(s_LocalPlayer)
		self:SetCameraMode(SpectatorCameraMode.Disabled)
		self:ReleaseControl()
		SpectatorManager:SetSpectating(false)
		self.m_SpecCam = false
		WebUI:ExecuteJS('SpectatorEnabled('.. tostring(self.m_SpecCam) .. ');')
	end
end

function SpecCam:OnUpdateInput(p_Delta)
	if InputManager:WentKeyDown(InputDeviceKeys.IDK_Space) and self.m_SpecCam then
		local s_Target = self:GetRandomCameraTarget()
		if s_Target ~= nil then
			self:SetCameraTarget(s_Target)
		end
	end
end

return SpecCam()
