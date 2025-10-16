-- Begin Utils
-- {{INJECT_UTILS}} --
-- End Utils
local function create_display_config(name)
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
        clashbox = true
    }
end

local display_p1 = create_display_config("Player 1")
local display_p2 = create_display_config("Player 2")

local Colors = {
    White = 0xFFFFFFFF,
    HitBox = {
        Border = 0xFF0040C0,
        Fill = 0x4D0040C0
    },
    ThrowBox = {
        Border = 0xFFD080FF,
        Fill = 0x4DD080FF
    },
    ClashBox = {
        Border = 0xFF3891E6,
        Fill = 0x403891E6
    },
    ProximityBox = {
        Border = 0xFF5b5b5b,
        Fill = 0x405b5b5b
    },
    PushBox = {
        Border = 0xFF00FFFF,
        Fill = 0x4000FFFF
    },
    HurtBox = {
        Border = 0xFFFF0080,
        Fill = 0x40FF0080
    },
    ThrowHurtBox = {
        Border = 0xFFFF0000,
        Fill = 0x4DFF0000
    },
    OtherHurtBox = {
        Border = 0xFF00FF26,
        Fill = 0x4000FF26
    },
    UniqueBox = {
        Border = 0xFFEEFF26,
        Fill = 0x4DEEFF26
    }
}

local CondFlags = {
    NoStanding = 16, -- Can't hit standing opponent
    NoCrouching = 32, -- Can't hit crouching opponents
    NoAirborne = 64, -- Can't hit airborne
    NoHitFront = 256, -- Can't hit in front of the player
    NoHitBehind = 512, -- Can't hit behind the player
    ComboOnlyStrike = 262144, -- Strike that can only hit a juggled/combo'd opponent
    ComboOnlyProjectile = 524288 -- Projectile that can only hit a juggled/combo'd opponent
}

local HitType = {
    Projectile = 1,
    Strike = 2
}

local HurtBoxType = {
    Armor = 1,
    Parry = 2
}

local Invuln = {
    Stand = 1, -- Stand Attack Intangibility
    Crouch = 2, -- Crouch Attack Intangibility
    Air = 4, -- Air Attack Intangibility
    CrossUp = 64, -- Cross-Up Attack Intangibility
    Reverse = 128 -- Reverse Hit Intangibility
}

function draw.box(posX, posY, sclX, sclY, colors)
    draw_rect(posX, posY, sclX, sclY, colors.Border, colors.Fill)
end

function draw.hitbox_properties(rect, posX, posY)
    -- Identify hitbox properties
    local hitboxExceptions = "Can't Hit "
    local comboOnly = "Combo "

    if flagged(rect.CondFlag, CondFlags.NoStanding) then
        hitboxExceptions = hitboxExceptions .. "Standing, "
    end
    if flagged(rect.CondFlag, CondFlags.NoCrouching) then
        hitboxExceptions = hitboxExceptions .. "Crouching, "
    end
    if flagged(rect.CondFlag, CondFlags.NoAirborne) then
        hitboxExceptions = hitboxExceptions .. "Airborne, "
    end
    if flagged(rect.CondFlag, CondFlags.NoHitFront) then
        hitboxExceptions = hitboxExceptions .. "Forward, "
    end
    if flagged(rect.CondFlag, CondFlags.NoHitBehind) then
        hitboxExceptions = hitboxExceptions .. "Backwards, "
    end

    if flagged(rect.CondFlag, CondFlags.ComboOnlyStrike) then
        comboOnly = comboOnly .. "Only"
    end
    if flagged(rect.CondFlag, CondFlags.ComboOnlyProjectile) then
        comboOnly = comboOnly .. "Only"
    end

    local fullString = ""
    if string.len(hitboxExceptions) > 10 then
        -- Remove final commma
        hitboxExceptions = string.sub(hitboxExceptions, 0, -3)
        fullString = fullString .. hitboxExceptions .. "\n"
    end

    if string.len(comboOnly) > 6 then
        fullString = fullString .. comboOnly .. "\n"
    end

    draw.text(fullString, posX, posY, Colors.White)
end

function draw.hurtbox_properties(rect, posX, posY)
    local hurtInvuln = ""
    if rect.TypeFlag == HitType.Projectile then
        hurtInvuln = hurtInvuln .. "Projectile"
    end
    if rect.TypeFlag == HitType.Strike then
        hurtInvuln = hurtInvuln .. "Strike"
    end

    local hurtImmune = ""
    if flagged(rect.Immune, Invuln.Stand) then
        hurtImmune = hurtImmune .. "Stand, "
    end
    if flagged(rect.Immune, Invuln.Crouch) then
        hurtImmune = hurtImmune .. "Crouch, "
    end
    if flagged(rect.Immune, Invuln.Air) then
        hurtImmune = hurtImmune .. "Air, "
    end
    if flagged(rect.Immune, Invuln.CrossUp) then
        hurtImmune = hurtImmune .. "Behind, "
    end
    if flagged(rect.Immune, Invuln.Reverse) then
        hurtImmune = hurtImmune .. "Reverse, "
    end
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

    draw.text(fullString, posX, posY, Colors.White)
end

function draw_game_boxes(display, obj, actParam)
    if display.hide_all == true then
        return
    end

    local col = actParam.Collision
    for j, rect in reversePairs(col.Infos._items) do
        if rect ~= nil then
            local posX = fixed(rect.OffsetX.v)
            local posY = fixed(rect.OffsetY.v)
            -- TODO remove mult
            local sclX = fixed(rect.SizeX.v) * 2
            local sclY = fixed(rect.SizeY.v) * 2

            posX = posX - sclX / 2
            posY = posY - sclY / 2

            local screenTL = draw.world_to_screen(vec3(posX - sclX / 2, posY + sclY / 2))
            local screenTR = draw.world_to_screen(vec3(posX + sclX / 2, posY + sclY / 2))
            local screenBL = draw.world_to_screen(vec3(posX - sclX / 2, posY - sclY / 2))
            local screenBR = draw.world_to_screen(vec3(posX + sclX / 2, posY - sclY / 2))

            if screenTL and screenTR and screenBL and screenBR then
                local finalPosX = (screenTL.x + screenTR.x) / 2
                local finalPosY = (screenBL.y + screenTL.y) / 2
                local finalSclX = (screenTR.x - screenTL.x)
                local finalSclY = (screenTL.y - screenBL.y)

                -- If the rectangle has a HitPos field, it falls under attack boxes
                if rect:get_field("HitPos") ~= nil then
                    -- TypeFlag > 0 indicates a regular hitbox
                    if rect.TypeFlag > 0 and display.hitboxes then
                        draw.box(finalPosX, finalPosY, finalSclX, finalSclY, Colors.HitBox)
                        if display.properties then
                            draw.hitbox_properties(rect, finalPosX, (finalPosY + finalSclY))
                        end
                        -- Throws almost* universally have a TypeFlag of 0 and a PoseBit > 0
                        -- Except for JP's command grab projectile which has neither and must be caught with CondFlag of 0x2C0
                    elseif ((rect.TypeFlag == 0 and rect.PoseBit > 0) or rect.CondFlag == 0x2C0) and display.throwboxes then
                        draw.box(finalPosX, finalPosY, finalSclX, finalSclY, Colors.ThrowBox)
                        if display.properties then
                            draw.hitbox_properties(rect, finalPosX, (finalPosY + finalSclY))
                        end
                        -- Projectile Clash boxes have a GuardBit of 0 (while most other boxes have either 7 or some random, non-zero, positive integer)
                    elseif rect.GuardBit == 0 and display.clashbox then
                        draw.box(finalPosX, finalPosY, finalSclX, finalSclY, Colors.ClashBox)

                        -- Any remaining boxes are drawn as proximity boxes
                    elseif display.proximityboxes then
                        draw.box(finalPosX, finalPosY, finalSclX, finalSclY, Colors.ProximityBox)
                    end
                    -- If the box contains the Attr field, then it is a pushbox
                elseif rect:get_field("Attr") ~= nil then
                    if display.pushboxes then
                        draw.box(finalPosX, finalPosY, finalSclX, finalSclY, Colors.PushBox)
                    end
                    -- If the rectangle has a HitNo field, the box falls under hurt boxes
                elseif rect:get_field("HitNo") ~= nil then
                    -- TypeFlag > 0 indicates a hurt box
                    if rect.TypeFlag > 0 and display.hurtboxes then
                        if rect.Type == HurtBoxType.Armor or rect.Type == HurtBoxType.Parry then
                            draw.box(finalPosX, finalPosY, finalSclX, finalSclY, Colors.HurtBox)
                        else -- All other hurtboxes
                            draw.box(finalPosX, finalPosY, finalSclX, finalSclY, Colors.OtherHurtBox)
                        end
                        -- otherwise is a throw hurt box
                    elseif display.throwhurtboxes then
                        draw.box(finalPosX, finalPosY, finalSclX, finalSclY, Colors.ThrowHurtBox)
                    end

                    -- Display hurtbox properties
                    if display.properties then
                        draw.hurtbox_properties(rect, finalPosX, (finalPosY + finalSclY))
                    end

                    -- UniqueBoxes have a special field called KeyData
                elseif rect:get_field("KeyData") ~= nil and display.uniqueboxes then
                    draw.box(finalPosX, finalPosY, finalSclX, finalSclY, Colors.UniqueBox)
                end
            end
        end
    end

    local objPos = draw.world_to_screen(vec3(fixed(obj.pos.x.v), fixed(obj.pos.y.v)))
    if objPos and display.position then
        draw.filled_circle(objPos.x, objPos.y, 10, Colors.White, 10);
    end
end

function player_gui(display)
    if imgui.tree_node(display.name) then
        _, display.hide_all = imgui.checkbox("Hide Boxes", display.hide_all)
        _, display.hitboxes = imgui.checkbox("Display Hitboxes", display.hitboxes)
        _, display.hurtboxes = imgui.checkbox("Display Hurtboxes", display.hurtboxes)
        _, display.pushboxes = imgui.checkbox("Display Pushboxes", display.pushboxes)
        _, display.throwboxes = imgui.checkbox("Display Throw Boxes", display.throwboxes)
        _, display.throwhurtboxes = imgui.checkbox("Display Throw Hurtboxes", display.throwhurtboxes)
        _, display.proximityboxes = imgui.checkbox("Display Proximity Boxes", display.proximityboxes)
        _, display.clashbox = imgui.checkbox("Display Projectile Clash Boxes", display.clashbox)
        _, display.uniqueboxes = imgui.checkbox("Display Unique Boxes", display.uniqueboxes)
        _, display.properties = imgui.checkbox("Display Properties", display.properties)
        _, display.position = imgui.checkbox("Display Position", display.position)
        imgui.tree_pop()
    end
end

function draw_work()
    local sWork = Battle:Field("Work")
    local cWork = sWork.Global_work

    for i, obj in pairs(cWork) do
        local actParam = obj.mpActParam
        if actParam and not obj:get_IsR0Die() and obj:get_IsTeam1P() then
            draw_game_boxes(display_p1, obj, actParam)
        end
        if actParam and not obj:get_IsR0Die() and obj:get_IsTeam2P() then
            draw_game_boxes(display_p2, obj, actParam)
        end
    end
end

function draw_player()
    local sPlayer = Battle:Field("Player")
    local cPlayer = sPlayer.mcPlayer
    for i, player in pairs(cPlayer) do
        local actParam = player.mpActParam
        if i == 0 and actParam then
            draw_game_boxes(display_p1, player, actParam)
        end
        if i == 1 and actParam then
            draw_game_boxes(display_p2, player, actParam)
        end
    end
end

re.on_draw_ui(function()
    if imgui.tree_node("Hitbox Viewer") then
        player_gui(display_p1)
        player_gui(display_p2)
        imgui.tree_pop()
    end
end)

re.on_frame(function()
    if Battle:Update() then
        draw_work()
        draw_player()
    end
end)
