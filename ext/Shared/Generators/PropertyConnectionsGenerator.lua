class "PropertyConnectionsGenerator"

function PropertyConnectionsGenerator:Create(source, target, sourceFieldId, targetFieldId)
	
    local PropertyConnection = PropertyConnection()
    PropertyConnection.source = source
    PropertyConnection.target = target
    PropertyConnection.sourceFieldId = tonumber(sourceFieldId) or MathUtils:FNVHash(sourceFieldId)
    PropertyConnection.targetFieldId = tonumber(targetFieldId) or MathUtils:FNVHash(targetFieldId)

    return PropertyConnection
end

return PropertyConnectionsGenerator()
