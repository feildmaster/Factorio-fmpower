script.on_event(defines.events.on_built_entity, function(event)
    local player = game.players[event.player_index]
    local entity = event.created_entity
    local eType = "electric-pole"
    if entity.type ~= eType then return end

    local s = settings.get_player_settings(player);
    -- Does this user have the mod disabled?
    if s["fm-pole-override-disabled"].value then return end
    
    -- Search surface area for poles inside "supply_area_distance"
    local area = entity.prototype.supply_area_distance
    local poles = entity.surface.find_entities_filtered{type = eType, area = {{entity.position.x - area, entity.position.y - area}, {entity.position.x + area, entity.position.y + area}}}
    if poles then
        local count = 0
        for _,pole in ipairs(poles) do
            -- Fix: Medium Poles kill Big Poles
            -- supply area is worse and not wired
            if pole.prototype.supply_area_distance < area and not wired(pole) then
                if s["fm-pole-override-mode"].value then
                    if deconstruct(pole) then count = count + 1 end
                else
                    if destroy(pole, player) then count = count + 1 end
                end
            end
        end
        -- Send message?
        if s["fm-pole-override-debug"].value and count > 0 then
            player.print((s["fm-pole-override-mode"].value and "Marked" or "Removed") .." " .. count .. " entities")
        end
    end 
end)

function deconstruct(e)
    -- Already marked for deconstruction
    if e.to_be_deconstructed(e.force) or e.has_flag("not-deconstructable") then 
        return false
    end
    
    return e.order_deconstruction(e.force)
end

function destroy(e, p)
    -- Add the entity to the inventory
    if p.get_inventory(defines.inventory.player_main).insert({name = e.name, count = 1}) then
        e.destroy()
        return true
    end
    return false
end

function wired(e)
    return next(e.circuit_connected_entities.red) ~= nil or next(e.circuit_connected_entities.green) ~= nil
end