MAX_INT_16 = 65536
MAX_FIXED_FLOAT = MAX_INT_16 * 100.0

function fixed(value)
    return value / MAX_FIXED_FLOAT
end

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

function flagged(value, flag)
    return bitand(value, flag) == flag
end

function abs(num)
    return num < 0 and num * -1 or num
end

function parse_num(obj_v)
    return tonumber(obj_v:call("ToString()"))
end

function read_sfix(sfix_obj)
    if sfix_obj.w then
        return Vector4f.new(parse_num(sfix_obj.x), parse_num(sfix_obj.y), parse_num(sfix_obj.z), parse_num(sfix_obj.w))
    elseif sfix_obj.z then
        return Vector3f.new(parse_num(sfix_obj.x), parse_num(sfix_obj.y), parse_num(sfix_obj.z))
    elseif sfix_obj.y then
        return Vector2f.new(parse_num(sfix_obj.x), parse_num(sfix_obj.y))
    end
    return parse_num(sfix_obj)
end

function vec3(x, y, z)
    return Vector3f.new(x, y, z or 0)
end

function read_fixed_rect(rect)
    local posX = fixed(rect.OffsetX.v)
    local posY = fixed(rect.OffsetY.v)
    local sclX = fixed(rect.SizeX.v)
    local sclY = fixed(rect.SizeY.v)
    return posX, posY, sclX, sclY
end

function read_fixed_vec2(value)
    return fixed(value.x.v), fixed(value.y.v)
end

function draw_rect(posX, posY, sclX, sclY, color, fill_color)
    draw.outline_rect(posX, posY, sclX, sclY, color)
    if fill_color then
        draw.filled_rect(posX, posY, sclX, sclY, fill_color)
    end
end

function find_gBattle()
    return sdk.find_type_definition("gBattle")
end

function get_field_data(obj, name, data)
    if obj ~= nil then
        return obj:get_field(name):get_data(data)
    end
end

Battle = {
    Source = nil
}

function Battle:Update()
    Battle.Source = find_gBattle()
    return Battle.Source ~= nil
end

function Battle:Field(name)
    return get_field_data(Battle.Source, name, nil)
end

function isAttackBox(rect)
    -- If the rectangle has a HitPos field, it falls under attack boxes
    return rect:get_field("HitPos") ~= nil
end

function isThrowBox(rect)
    -- Throws almost* universally have a TypeFlag of 0 and a PoseBit > 0
    -- Except for JP's command grab projectile which has neither and must be caught with CondFlag of 0x2C0
    return (rect.TypeFlag == 0 and rect.PoseBit > 0) or rect.CondFlag == 0x2C0
end

function isHitBox(rect)
    -- TypeFlag > 0 indicates a regular hitbox
    return rect.TypeFlag > 0
end

function isHurtBox(rect)
    -- If the rectangle has a HitNo field, the box falls under hurt boxes
    return rect:get_field("HitNo") ~= nil
end

function isPushBox(rect)
    -- If the box contains the Attr field, then it is a pushbox
    return rect:get_field("Attr") ~= nil
end

function isUniqueBox(rect)
    -- UniqueBoxes have a special field called KeyData
    return rect:get_field("KeyData") ~= nil
end
