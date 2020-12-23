class 'UICleanup'

function UICleanup:__init()
	print("Initializing UICleanup")
    
    Hooks:Install('UI:PushScreen', 999, function(hook, screen, graphPriority, parentGraph)
        local screen = UIGraphAsset(screen)
        
        if screen.name == 'UI/Flow/Screen/SpawnScreenPC' or
            screen.name == 'UI/Flow/Screen/SpawnScreenTicketCounterTDMScreen' or
            --screen.name == 'UI/Flow/Screen/Scoreboards/ScoreboardTwoTeamsScreen' or
            screen.name == 'UI/Flow/Screen/Scoreboards/ScoreboardTwoTeamsHUD32Screen' or
            screen.name == 'UI/Flow/Screen/Scoreboards/ScoreboardTwoTeamsHUD16Screen' or
            screen.name == 'UI/Flow/Screen/Scoreboards/ScoreboardTwoTeamsHUD64Screen' or
            screen.name == 'UI/Flow/Screen/KillScreen' or
            screen.name == 'UI/Flow/Screen/SpawnButtonScreen' then
            hook:Return(nil)
            return
        end
        
	    if 	screen.name == 'UI/Flow/Screen/HudTDMScreen' then
            local clone = screen:Clone(screen.instanceGuid)
            local screenClone = UIGraphAsset(clone)

            for i = #screen.nodes, 1, -1 do
                local node = screen.nodes[i]
                if node ~= nil then
                    if node.name == 'TicketCounter' or
                        node.name == 'HudBackgroundWidget' then
                        screenClone.nodes:erase(i)
                    end
                end
            end

            hook:Pass(screenClone, graphPriority, parentGraph)
            return
        end
    end)

    Events:Subscribe('Partition:Loaded', function(partition)
        for _, instance in pairs(partition.instances) do
            if instance.instanceGuid == Guid('85453C26-DAB8-41F9-9ADF-515716041FB7') or 
                instance.instanceGuid == Guid('D4298FB7-2E41-4616-B713-A8BBCB211A53') or
                instance.instanceGuid == Guid('A3C5D8A5-1563-4F43-8FF4-034A8FF2DA90')
            then
                local s_Instance = SoundState(instance)
                s_Instance:MakeWritable()
                s_Instance.lpCutoffFrequency = 44000
                s_Instance.fadeSound = false
                s_Instance.mixer = nil
                s_Instance.bypassSound = nil
            end
            if instance.instanceGuid == Guid('9CDAC6C3-9D3E-48F1-B8D9-737DB28AE936') then -- menu UI/Assets/MenuVisualEnvironment
                local s_Instance = ColorCorrectionComponentData(instance)
                s_Instance:MakeWritable()
                s_Instance.enable = false
                s_Instance.brightness = Vec3(1, 1, 1)
                s_Instance.contrast = Vec3(1, 1, 1)
                s_Instance.saturation = Vec3(1, 1, 1)
            end
            if instance:Is('VignetteComponentData') then -- menu UI/Assets/MenuVisualEnvironment
                local s_Instance = VignetteComponentData(instance)
                s_Instance:MakeWritable()
                s_Instance.enable = false
                s_Instance.scale = Vec2(0, 0)
                s_Instance.opacity = 0.0
            end
            if instance.instanceGuid == Guid('52FD86B6-00BA-45FC-A87A-683F72CA6916') then -- menu UI/Assets/MenuVisualEnvironment
                local s_Instance = DofComponentData(instance)
                s_Instance:MakeWritable()
                s_Instance.enable = false
                s_Instance.blurAdd = 0.0
                s_Instance.scale = 0.0
                s_Instance.diffusionDofEnable = false
                s_Instance.excluded = true
            end
            if instance.instanceGuid == Guid('46FE1C37-5B7E-490C-8239-2EB2D6045D7B') then -- oob FX/VisualEnviroments/OutofCombat/OutofCombat
                local s_Instance = ColorCorrectionComponentData(instance)
                s_Instance:MakeWritable()
                s_Instance.enable = false
                s_Instance.brightness = Vec3(0.8, 0.8, 0.8)
                s_Instance.contrast = Vec3(1, 1, 1)
                s_Instance.saturation = Vec3(1, 1, 1)
            end
            if instance.instanceGuid == Guid('36C2CEAE-27D2-45F3-B3F5-B831FE40ED9B') then -- FX/VisualEnviroments/OutofCombat/OutofCombat
                local s_Instance = FilmGrainComponentData(instance)
                s_Instance:MakeWritable()
                s_Instance.enable = false
            end
        end
    end)
end

return UICleanup()
