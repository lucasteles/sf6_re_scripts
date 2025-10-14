local gBattle
local changed

function create_player_config(pl_no, opponent_no)
    return {
        display_info = false,
        pl_no = pl_no,
        opponent_no = opponent_no,
        absolute_range = 0,
        relative_range = 0
    }
end

local p1 = create_player_config(0, 1)
local p2 = create_player_config(1, 0)

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

function abs(num)
    return num < 0 and num * -1 or num
end

function num(obj_v)
    return tonumber(obj_v:call("ToString()"))
end

function read_sfix(sfix_obj)
    if sfix_obj.w then
        return Vector4f.new(num(sfix_obj.x), num(sfix_obj.y), num(sfix_obj.z), num(sfix_obj.w))
    elseif sfix_obj.z then
        return Vector3f.new(num(sfix_obj.x), num(sfix_obj.y), num(sfix_obj.z))
    elseif sfix_obj.y then
        return Vector2f.new(num(sfix_obj.x), num(sfix_obj.y))
    end
    return num(sfix_obj)
end

-- imgui.colored_and_white_text = function(color_text, white_text)
function imgui.multi_color(color_text, white_text)
    imgui.text_colored(color_text, 0xFFAAFFFF)
    imgui.same_line()
    imgui.text(white_text)
end

local get_hitbox_range = function(p)
    -- local facingRight = bitand(player.BitValue, 128) == 128
    local player = p.cPlayer
    local actParam = player.mpActParam
    local facingRight = player.rl_dir
    local maxHitboxEdgeX = nil
    if actParam ~= nil then
        local col = actParam.Collision
        for j, rect in reversePairs(col.Infos._items) do
            if rect ~= nil then
                local posX = rect.OffsetX.v / 6553600.0
                local posY = rect.OffsetY.v / 6553600.0
                local sclX = rect.SizeX.v / 6553600.0
                local sclY = rect.SizeY.v / 6553600.0
                if rect:get_field("HitPos") ~= nil then
                    local hitbox_X
                    if rect.TypeFlag > 0 or (rect.TypeFlag == 0 and rect.PoseBit > 0) then
                        if facingRight then
                            hitbox_X = posX + sclX / 2
                            -- log.debug(hitbox_X)
                        else
                            hitbox_X = posX - sclX / 2
                        end
                        if maxHitboxEdgeX == nil then
                            maxHitboxEdgeX = hitbox_X
                        end
                        if maxHitboxEdgeX ~= nil then
                            if facingRight then
                                if hitbox_X > maxHitboxEdgeX then
                                    maxHitboxEdgeX = hitbox_X
                                end
                            else
                                if hitbox_X < maxHitboxEdgeX then
                                    maxHitboxEdgeX = hitbox_X
                                end
                            end
                        end
                    end
                end
            end
        end
        if maxHitboxEdgeX ~= nil then
            local playerPosX = player.pos.x.v / 6553600.0
            -- Replace start_pos because it can fail to track the actual starting location of an action (e.g., DJ 2MK)
            -- local playerStartPosX = player.start_pos.x.v / 6553600.0
            local playerStartPosX = player.act_root.x.v / 6553600.0
            p.absolute_range = abs(maxHitboxEdgeX - playerStartPosX)
            p.relative_range = abs(maxHitboxEdgeX - playerPosX)
        end
    end
end

re.on_draw_ui(function()
    if imgui.tree_node("Info Display") then
        changed, p1.display_info = imgui.checkbox("Display P1 Battle Info", p1.display_info)
        changed, p2.display_info = imgui.checkbox("Display P2 Battle Info", p2.display_info)
        imgui.tree_pop()
    end
end)

function update_player(p, cPlayer, storageData, battleTeam)
    local cTeam = battleTeam.mcTeam
    local chargeInfo = storageData.UserEngines[p.pl_no].m_charge_infos
    local player = cPlayer[p.pl_no]
    p.cPlayer = player

    -- ActEngine
    -- Player ActID, Current Frame, Final Frame, IASA Frame

    local actParam = player.mpActParam
    if actParam ~= nil then
        local engine = actParam.ActionPart._Engine
        if engine ~= nil then
            p.mActionId = engine:get_ActionID()
            p.mActionFrame = engine:get_ActionFrame()
            p.mEndFrame = engine:get_ActionFrameNum()
            p.mMarginFrame = engine:get_MarginFrame()
        end
    end

    -- HitDT
    -- if cPlayer.vs_player ~= nil then
    --     p.hitDT = cPlayer.vs_player.cPlayer.pDmgHitDT
    -- end
    p.hitDT = cPlayer[p.opponent_no].pDmgHitDT

    --[[ DEPRECATED (improved, direct method found)
    -- local engine = gBattle:get_field("Rollback"):get_data():GetLatestEngine().ActEngines[0]._Parent._Engine
    -- p1.mActionId = cPlayer.mActionId
    --]]

    -- Player Data
    p.HP_cap = player.heal_new
    p.current_HP = player.vital_new
    p.HP_cooldown = player.healing_wait
    p.dir = bitand(player.BitValue, 128) == 128
    p.curr_hitstop = player.hit_stop
    p.max_hitstop = player.hit_stop_org
    p.curr_hitstun = player.damage_time
    p.max_hitstun = player.damage_info.time
    p.curr_blockstun = player.guard_time
    p.stance = player.pose_st
    p.throw_invuln = player.catch_muteki
    p.full_invuln = player.muteki_time
    p.juggle = player.combo_dm_air
    p.drive = player.focus_new
    p.drive_cooldown = player.focus_wait
    p.super = cTeam.mSuperGauge
    p.buff = player.style_timer
    p.poison_timer = player.damage_cond.timer
    p.chargeInfo = chargeInfo
    p.posX = player.pos.x.v / 6553600.0
    p.posY = player.pos.y.v / 6553600.0
    p.spdX = player.speed.x.v / 6553600.0
    p.spdY = player.speed.y.v / 6553600.0
    p.aclX = player.alpha.x.v / 6553600.0
    p.aclY = player.alpha.y.v / 6553600.0
    p.pushback = player.vector_zuri.speed.v / 6553600.0
    p.self_pushback = player.vs_vec_zuri.zuri.speed.v / 6553600.0
    p.vs_distance = read_sfix(player.vs_distance)

    --[[ DEPRECATED (found a variable that does the same thing)
    -- Max hitstop tracker
    if p.max_hitstop == nil then
        p.max_hitstop = 0
    end
    if p.curr_hitstop > p.max_hitstop then
        p.max_hitstop = p.curr_hitstop
    elseif p.curr_hitstop == 0 then
        p.max_hitstop = 0
    end
    --]]

    -- Max blockstun tracker
    if p.max_blockstun == nil then
        p.max_blockstun = 0
    end
    if p.curr_blockstun > p.max_blockstun then
        p.max_blockstun = p.curr_blockstun
    elseif p.curr_blockstun == 0 then
        p.max_blockstun = 0
    end
end

function draw_projectile_gui(cWork, pl_no)
    if imgui.tree_node("Projectiles") then
        for i, obj in pairs(cWork) do
            if obj.owner_add ~= nil and obj.pl_no == pl_no then
                local objEngine = obj.mpActParam.ActionPart._Engine
                if imgui.tree_node("[" .. i .. "] " .. obj.mActionId) then
                    imgui.multi_color("Action ID:", obj.mActionId)
                    imgui.multi_color("Action Frame:",
                        math.floor(read_sfix(objEngine:get_ActionFrame())) .. " / " ..
                            math.floor(read_sfix(objEngine:get_MarginFrame())) .. " (" ..
                            math.floor(read_sfix(objEngine:get_ActionFrameNum())) .. ")")
                    imgui.multi_color("Position X:", obj.pos.x.v / 6553600.0)
                    imgui.multi_color("Position Y:", obj.pos.y.v / 6553600.0)
                    imgui.multi_color("Speed X:", obj.speed.x.v / 6553600.0)
                    imgui.multi_color("Speed Y:", obj.speed.y.v / 6553600.0)
                    imgui.tree_pop()
                end
            end
        end
        imgui.tree_pop()
    end
end

function draw_info_gui(p)
    if imgui.tree_node("General Info") then
        imgui.multi_color("Current HP:", p.current_HP)
        imgui.multi_color("HP Cap:", p.HP_cap)
        imgui.multi_color("HP Regen Cooldown:", p.HP_cooldown)
        imgui.multi_color("Drive Gauge:", p.drive)
        imgui.multi_color("Drive Cooldown:", p.drive_cooldown)
        imgui.multi_color("Super Gauge:", p.super)
        imgui.multi_color("Buff Duration:", p.buff)
        imgui.multi_color("Poison Duration:", p.poison_timer)

        imgui.tree_pop()
    end
    if imgui.tree_node("State Info") then
        imgui.multi_color("Action ID:", p.mActionId)
        imgui.multi_color("Action Frame:",
            math.floor(read_sfix(p.mActionFrame)) .. " / " .. math.floor(read_sfix(p.mMarginFrame)) .. " (" ..
                math.floor(read_sfix(p.mEndFrame)) .. ")")
        imgui.multi_color("Current Hitstop:", p.curr_hitstop .. " / " .. p.max_hitstop)
        imgui.multi_color("Current Hitstun:", p.curr_hitstun .. " / " .. p.max_hitstun)
        imgui.multi_color("Current Blockstun:", p.curr_blockstun .. " / " .. p.max_blockstun)
        imgui.multi_color("Throw Protection Timer:", p.throw_invuln)
        imgui.multi_color("Intangible Timer:", p.full_invuln)

        imgui.tree_pop()
    end
    if imgui.tree_node("Movement Info") then
        if p.dir == true then
            imgui.multi_color("Facing:", "Right")
        else
            imgui.multi_color("Facing:", "Left")
        end
        if p.stance == 0 then
            imgui.multi_color("Stance:", "Standing")
        elseif p.stance == 1 then
            imgui.multi_color("Stance:", "Crouching")
        else
            imgui.multi_color("Stance:", "Jumping")
        end
        imgui.multi_color("VS Distance:", p.vs_distance)
        imgui.multi_color("Position X:", p.posX)
        imgui.multi_color("Position Y:", p.posY)
        imgui.multi_color("Speed X:", p.spdX)
        imgui.multi_color("Speed Y:", p.spdY)
        imgui.multi_color("Acceleration X:", p.aclX)
        imgui.multi_color("Acceleration Y:", p.aclY)
        imgui.multi_color("Pushback:", p.pushback)
        imgui.multi_color("Self Pushback:", p.self_pushback)

        imgui.tree_pop()
    end
    if imgui.tree_node("Attack Info") then
        get_hitbox_range(p)
        imgui.multi_color("Absolute Range:", p.absolute_range)
        imgui.multi_color("Relative Range:", p.relative_range)
        imgui.multi_color("Juggle Counter:", p2.juggle)
        if imgui.tree_node("Latest Attack Info") then
            if p.hitDT == nil then
                imgui.text_colored("No hit yet", 0xFFAAFFFF)
            else
                imgui.multi_color("Damage:", p.hitDT.DmgValue)
                imgui.multi_color("Self Drive Gain:", p.hitDT.FocusOwn)
                imgui.multi_color("Opponent Drive Gain:", p.hitDT.FocusTgt)
                imgui.multi_color("Self Super Gain:", p.hitDT.SuperOwn)
                imgui.multi_color("Opponent Super Gain:", p.hitDT.SuperTgt)
                imgui.multi_color("Self Hitstop:", p.hitDT.HitStopOwner)
                imgui.multi_color("Opponent Hitstop:", p.hitDT.HitStopTarget)
                imgui.multi_color("Stun:", p.hitDT.HitStun)
                imgui.multi_color("Knockdown Duration:", p.hitDT.DownTime)
                imgui.multi_color("Juggle Limit:", p.hitDT.JuggleLimit)
                imgui.multi_color("Juggle Increase:", p.hitDT.JuggleAdd)
                imgui.multi_color("Juggle Start:", p.hitDT.Juggle1st)
            end

            imgui.tree_pop()
        end

        imgui.tree_pop()
    end
    if p.chargeInfo:get_Count() > 0 then
        if imgui.tree_node("Charge Info") then
            for i = 0, p.chargeInfo:get_Count() - 1 do
                local value = p.chargeInfo:get_Values()._dictionary._entries[i].value
                if value ~= nil then
                    imgui.multi_color("Move " .. i + 1 .. " Charge Time:", value.charge_frame)
                    imgui.multi_color("Move " .. i + 1 .. " Charge Keep Time:", value.keep_frame)
                end
            end

            imgui.tree_pop()
        end
    end
end

function render_player_info_window(title, p, cWork)
    if not p.display_info then
        return
    end

    imgui.begin_window(title, true, 0)
    draw_info_gui(p)
    draw_projectile_gui(cWork, p.pl_no)
    imgui.end_window()
end

re.on_frame(function()
    gBattle = sdk.find_type_definition("gBattle")
    if gBattle then
        local sPlayer = gBattle:get_field("Player"):get_data(nil)
        local cPlayer = sPlayer.mcPlayer
        local battleTeam = gBattle:get_field("Team"):get_data(nil)
        local storageData = gBattle:get_field("Command"):get_data(nil).StorageData
        local sWork = gBattle:get_field("Work"):get_data(nil)
        local cWork = sWork.Global_work

        -- if sPlayer.move_ctr > 0 then
        update_player(p1, cPlayer, storageData, battleTeam)
        update_player(p2, cPlayer, storageData, battleTeam)

        render_player_info_window("Player 1", p1, cWork)
        render_player_info_window("Player 2", p2, cWork)
    end
end)
