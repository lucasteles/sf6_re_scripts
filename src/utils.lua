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

function find_gBattle()
    return sdk.find_type_definition("gBattle")
end

function get_data_field(obj, name)
    if obj ~= nil then
        return obj.get_field(name):get_data(nil)
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
    return get_data_field(Battle.Source, name)
end
