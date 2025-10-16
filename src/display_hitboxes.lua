require "utils"

local changed

function create_display_config(name)
    return {
        name = name,
        hide_all = true,
        hitboxes = true,
        hurtboxes = true,
        pushboxes = true,
        throwboxes = true,
        throwhurtboxes = true,
        proximityboxes = true,
        uniqueboxes = true,
        properties = true,
        position = true,
        clashbox = true,
    }
end

display_p1 = create_display_config("Player 1")
display_p2 = create_display_config("Player 2")

function reversePairs(aTable)
    local keys = {}
    for k, v in pairs(aTable) do
        keys[#keys + 1] = k
    end
    table.sort(keys, function(a, b)
        return a > b
    end)

    local n = 0
    return function()
        n = n + 1
        if n > #keys then
            return nil, nil
        end
        return keys[n], aTable[keys[n]]
    end
end

function bitand(a, b)
    local result = 0
    local bitval = 1
    while a > 0 and b > 0 do
        if a % 2 == 1 and b % 2 == 1 then -- test the rightmost bits
            result = result + bitval -- set the current bit
        end
        bitval = bitval * 2 -- shift left
        a = math.floor(a / 2) -- shift right
        b = math.floor(b / 2)
    end
    return result
end

function draw_boxes(display, obj, actParam)
    if display.hide_all == true then
        return
    end

    local col = actParam.Collision
    for j, rect in reversePairs(col.Infos._items) do
        if rect ~= nil then
            local posX = rect.OffsetX.v / 6553600.0
            local posY = rect.OffsetY.v / 6553600.0
            local sclX = rect.SizeX.v / 6553600.0 * 2
            local sclY = rect.SizeY.v / 6553600.0 * 2
            posX = posX - sclX / 2
            posY = posY - sclY / 2

            local screenTL = draw.world_to_screen(Vector3f.new(posX - sclX / 2, posY + sclY / 2, 0))
            local screenTR = draw.world_to_screen(Vector3f.new(posX + sclX / 2, posY + sclY / 2, 0))
            local screenBL = draw.world_to_screen(Vector3f.new(posX - sclX / 2, posY - sclY / 2, 0))
            local screenBR = draw.world_to_screen(Vector3f.new(posX + sclX / 2, posY - sclY / 2, 0))

            if screenTL and screenTR and screenBL and screenBR then

                local finalPosX = (screenTL.x + screenTR.x) / 2
                local finalPosY = (screenBL.y + screenTL.y) / 2
                local finalSclX = (screenTR.x - screenTL.x)
                local finalSclY = (screenTL.y - screenBL.y)

                -- If the rectangle has a HitPos field, it falls under attack boxes
                if rect:get_field("HitPos") ~= nil then
                    -- TypeFlag > 0 indicates a regular hitbox
                    if rect.TypeFlag > 0 and display.hitboxes then
                        draw.outline_rect(finalPosX, finalPosY, finalSclX, finalSclY, 0xFF0040C0)
                        draw.filled_rect(finalPosX, finalPosY, finalSclX, finalSclY, 0x4D0040C0)
                        -- Identify hitbox properties
                        local hitboxExceptions = "Can't Hit "
                        local comboOnly = "Combo "
                        -- CondFlag: 16		(Can't hit standing opponent)
                        -- CondFlag: 32		(Can't hit crouching opponents)
                        -- CondFlag: 64		(Can't hit airborne)
                        -- CondFlag: 256	(Can't hit in front of the player)
                        -- CondFlag: 512	(Can't hit behind the player)
                        -- CondFlag: 262144	(Strike that can only hit a juggled/combo'd opponent)
                        -- CondFlag: 524288 (Projectile that can only hit a juggled/combo'd opponent)
                        if bitand(rect.CondFlag, 16) == 16 then
                            hitboxExceptions = hitboxExceptions .. "Standing, "
                        end
                        if bitand(rect.CondFlag, 32) == 32 then
                            hitboxExceptions = hitboxExceptions .. "Crouching, "
                        end
                        if bitand(rect.CondFlag, 64) == 64 then
                            hitboxExceptions = hitboxExceptions .. "Airborne, "
                        end
                        if bitand(rect.CondFlag, 256) == 256 then
                            hitboxExceptions = hitboxExceptions .. "Forward, "
                        end
                        if bitand(rect.CondFlag, 512) == 512 then
                            hitboxExceptions = hitboxExceptions .. "Backwards, "
                        end
                        if bitand(rect.CondFlag, 262144) == 262144 then
                            comboOnly = comboOnly .. "Only"
                        end
                        if bitand(rect.CondFlag, 524288) == 524288 then
                            comboOnly = comboOnly .. "Only"
                        end
                        if display.properties then
                            local fullString = ""
                            if string.len(hitboxExceptions) > 10 then
                                -- Remove final commma
                                hitboxExceptions = string.sub(hitboxExceptions, 0, -3)
                                fullString = fullString .. hitboxExceptions .. "\n"
                            end
                            if string.len(comboOnly) > 6 then
                                fullString = fullString .. comboOnly .. "\n"
                            end
                            draw.text(fullString, finalPosX, (finalPosY + finalSclY), 0xFFFFFFFF)
                        end
                        -- Throws almost* universally have a TypeFlag of 0 and a PoseBit > 0
                        -- Except for JP's command grab projectile which has neither and must be caught with CondFlag of 0x2C0
                    elseif ((rect.TypeFlag == 0 and rect.PoseBit > 0) or rect.CondFlag == 0x2C0) and display.throwboxes then
                        draw.outline_rect(finalPosX, finalPosY, finalSclX, finalSclY, 0xFFD080FF)
                        draw.filled_rect(finalPosX, finalPosY, finalSclX, finalSclY, 0x4DD080FF)
                        -- Identify hitbox properties
                        local hitboxExceptions = "Can't Hit "
                        local comboOnly = "Combo "
                        -- CondFlag: 16		(Can't hit standing opponent)
                        -- CondFlag: 32		(Can't hit crouching opponents)
                        -- CondFlag: 64		(Can't hit airborne)
                        -- CondFlag: 256	(Can't hit in front of the player)
                        -- CondFlag: 512	(Can't hit behind the player)
                        -- CondFlag: 262144	(Strike that can only hit a juggled/combo'd opponent)
                        -- CondFlag: 524288 (Projectile that can only hit a juggled/combo'd opponent)
                        if bitand(rect.CondFlag, 16) == 16 then
                            hitboxExceptions = hitboxExceptions .. "Standing, "
                        end
                        if bitand(rect.CondFlag, 32) == 32 then
                            hitboxExceptions = hitboxExceptions .. "Crouching, "
                        end
                        if bitand(rect.CondFlag, 64) == 64 then
                            hitboxExceptions = hitboxExceptions .. "Airborne, "
                        end
                        if bitand(rect.CondFlag, 256) == 256 then
                            hitboxExceptions = hitboxExceptions .. "Forward, "
                        end
                        if bitand(rect.CondFlag, 512) == 512 then
                            hitboxExceptions = hitboxExceptions .. "Backwards, "
                        end
                        if bitand(rect.CondFlag, 262144) == 262144 then
                            comboOnly = comboOnly .. "Only"
                        end
                        if bitand(rect.CondFlag, 524288) == 524288 then
                            comboOnly = comboOnly .. "Only"
                        end
                        -- Display hitbox properties
                        if display.properties then
                            local fullString = ""
                            if string.len(hitboxExceptions) > 10 then
                                -- Remove final commma
                                hitboxExceptions = string.sub(hitboxExceptions, 0, -3)
                                fullString = fullString .. hitboxExceptions .. "\n"
                            end
                            if string.len(comboOnly) > 6 then
                                fullString = fullString .. comboOnly .. "\n"
                            end
                            draw.text(fullString, finalPosX, (finalPosY + finalSclY), 0xFFFFFFFF)
                        end
                        -- Projectile Clash boxes have a GuardBit of 0 (while most other boxes have either 7 or some random, non-zero, positive integer)
                    elseif rect.GuardBit == 0 and display.clashbox then
                        draw.outline_rect(finalPosX, finalPosY, finalSclX, finalSclY, 0xFF3891E6)
                        draw.filled_rect(finalPosX, finalPosY, finalSclX, finalSclY, 0x403891E6)
                        -- Any remaining boxes are drawn as proximity boxes
                    elseif display.proximityboxes then
                        draw.outline_rect(finalPosX, finalPosY, finalSclX, finalSclY, 0xFF5b5b5b)
                        draw.filled_rect(finalPosX, finalPosY, finalSclX, finalSclY, 0x405b5b5b)
                    end
                    -- If the box contains the Attr field, then it is a pushbox
                elseif rect:get_field("Attr") ~= nil then
                    if display.pushboxes then
                        draw.outline_rect(finalPosX, finalPosY, finalSclX, finalSclY, 0xFF00FFFF)
                        draw.filled_rect(finalPosX, finalPosY, finalSclX, finalSclY, 0x4000FFFF)
                    end
                    -- If the rectangle has a HitNo field, the box falls under hurt boxes or throw hurt box
                elseif rect:get_field("HitNo") ~= nil then
                    -- TypeFlag > 0 indicates a hurt box
                    if rect.TypeFlag > 0 and display.hurtboxes then
                        -- Armor (Type: 1) & Parry (Type: 2) Boxes
                        if rect.Type == 2 or rect.Type == 1 then
                            draw.outline_rect(finalPosX, finalPosY, finalSclX, finalSclY, 0xFFFF0080)
                            draw.filled_rect(finalPosX, finalPosY, finalSclX, finalSclY, 0x40FF0080)
                            -- All other hurtboxes
                        else
                            draw.outline_rect(finalPosX, finalPosY, finalSclX, finalSclY, 0xFF00FF00)
                            draw.filled_rect(finalPosX, finalPosY, finalSclX, finalSclY, 0x4000FF00)
                        end
                        -- Identify HurtboxType as text (each at a unique height)
                        local hurtInvuln = ""
                        -- TypeFlag:	1	(Projectile Invuln)
                        -- TypeFlag:	2	(Strike Invuln)
                        if rect.TypeFlag == 1 then
                            hurtInvuln = hurtInvuln .. "Projectile"
                        end
                        if rect.TypeFlag == 2 then
                            hurtInvuln = hurtInvuln .. "Strike"
                        end
                        -- Identify Hurtbox Immunities as text (each at a unique height)
                        local hurtImmune = ""
                        -- Immune:		1	(Stand Attack Intangibility)
                        -- Immune:		2	(Crouch Attack Intangibility)
                        -- Immune:		4	(Air Attack Intangibility)
                        -- Immune:		64	(Cross-Up Attack Intangibility)
                        -- Immune:		128	(Reverse Hit Intangibility)
                        if bitand(rect.Immune, 1) == 1 then
                            hurtImmune = hurtImmune .. "Stand, "
                        end
                        if bitand(rect.Immune, 2) == 2 then
                            hurtImmune = hurtImmune .. "Crouch, "
                        end
                        if bitand(rect.Immune, 4) == 4 then
                            hurtImmune = hurtImmune .. "Air, "
                        end
                        if bitand(rect.Immune, 64) == 64 then
                            hurtImmune = hurtImmune .. "Behind, "
                        end
                        if bitand(rect.Immune, 128) == 128 then
                            hurtImmune = hurtImmune .. "Reverse, "
                        end
                        -- Display hurtbox properties
                        if display.properties then
                            local fullString = ""
                            if string.len(hurtInvuln) > 0 then
                                -- Remove final commma
                                hurtInvuln = hurtInvuln .. " Invulnerable"
                                fullString = fullString .. hurtInvuln .. "\n"
                            end
                            if string.len(hurtImmune) > 0 then
                                hurtImmune = string.sub(hurtImmune, 0, -3)
                                hurtImmune = hurtImmune .. " Attack Intangible"
                                fullString = fullString .. hurtImmune .. "\n"
                            end
                            draw.text(fullString, finalPosX, (finalPosY + finalSclY), 0xFFFFFFFF)
                        end
                        -- otherwise is a throw hurt box
                    elseif display.throwhurtboxes then
                        draw.outline_rect(finalPosX, finalPosY, finalSclX, finalSclY, 0xFFFF0000)
                        draw.filled_rect(finalPosX, finalPosY, finalSclX, finalSclY, 0x4DFF0000)
                    end
                    -- UniqueBoxes have a special field called KeyData
                elseif rect:get_field("KeyData") ~= nil and display.uniqueboxes then
                    draw.outline_rect(finalPosX, finalPosY, finalSclX, finalSclY, 0xFFEEFF00)
                    draw.filled_rect(finalPosX, finalPosY, finalSclX, finalSclY, 0x4DEEFF00)
                end
            end
        end
    end

    local objPos = draw.world_to_screen(Vector3f.new(obj.pos.x.v / 6553600.0, obj.pos.y.v / 6553600.0, 0))
    if objPos and display.position then
        draw.filled_circle(objPos.x, objPos.y, 10, 0xFFFFFFFF, 10);
    end
end

function player_gui(display)
    if imgui.tree_node(display.name) then
        changed, display.hide_all = imgui.checkbox("Hide Boxes", display.hide_all)
        changed, display.hitboxes = imgui.checkbox("Display Hitboxes", display.hitboxes)
        changed, display.hurtboxes = imgui.checkbox("Display Hurtboxes", display.hurtboxes)
        changed, display.pushboxes = imgui.checkbox("Display Pushboxes", display.pushboxes)
        changed, display.throwboxes = imgui.checkbox("Display Throw Boxes", display.throwboxes)
        changed, display.throwhurtboxes = imgui.checkbox("Display Throw Hurtboxes", display.throwhurtboxes)
        changed, display.proximityboxes = imgui.checkbox("Display Proximity Boxes", display.proximityboxes)
        changed, display.clashbox = imgui.checkbox("Display Projectile Clash Boxes", display.clashbox)
        changed, display.uniqueboxes = imgui.checkbox("Display Unique Boxes", display.uniqueboxes)
        changed, display.properties = imgui.checkbox("Display Properties", display.properties)
        changed, display.position = imgui.checkbox("Display Position", display.position)
        imgui.tree_pop()
    end
end

re.on_draw_ui(function()
    if imgui.tree_node("Hitbox Viewer") then
        player_gui(display_p1)
        player_gui(display_p2)
        imgui.tree_pop()
    end
end)

function draw_work()
    local sWork = Battle:Field("Work")
    local cWork = sWork.Global_work

    for i, obj in pairs(cWork) do
        local actParam = obj.mpActParam
        if actParam and not obj:get_IsR0Die() and obj:get_IsTeam1P() then
            draw_boxes(display_p1, obj, actParam)
        end
        if actParam and not obj:get_IsR0Die() and obj:get_IsTeam2P() then
            draw_boxes(display_p2, obj, actParam)
        end
    end
end

function draw_player()
    local sPlayer = Battle:Field("Player")
    local cPlayer = sPlayer.mcPlayer
    for i, player in pairs(cPlayer) do
        local actParam = player.mpActParam
        if i == 0 and actParam then
            draw_boxes(display_p1, player, actParam)
        end
        if i == 1 and actParam then
            draw_boxes(display_p2, player, actParam)
        end
    end
end

re.on_frame(function()
    if Battle:Update() then
        draw_work()
        draw_player()
    end
end)
