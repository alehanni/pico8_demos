function _init()
    poke(0x5f2d, 0x1) -- enable cursor
end

function _update60()
    -- noop
end

t = 0

function _draw()
    --local mx = stat(32) -- read mouse x
    --local my = stat(33) -- read mouse y
    
    t = t+0.003
    local mx = 64 + 48*cos(t)
    local my = 64 + 48*sin(t)

    cls(5)

    map(0, 0, 0, 0, 16, 16)

    local off_y = 0

    for x, y in bresenham_iter(64, 64, mx, my) do
        if colget(x, y+off_y) > 0 then 
            if colget(x, y+off_y-1) > 0 then
                break
            else
                off_y -= 1
            end
        end
        rect(x, y+off_y, x+7, y+off_y+7, 8)
    end

    rect(64, 64, 64+7, 64+7, 7)
    rect(mx, my, mx+7, my+7, 7)
end

function bresenham_iter(x0, y0, x1, y1)

    x0, y0, x1, y1 = flr(x0), flr(y0), flr(x1), flr(y1)

    local dx = abs(x1 - x0)
    local dy = abs(y1 - y0)

    local sx = x0 < x1 and 1 or -1
    local sy = y0 < y1 and 1 or -1

    local err = dx - dy

    return function()
        local x0_tmp = x0
        local y0_tmp = y0

        if x0 == x1 + sx or y0 == y1 + sy then return nil end

        local e2 = 2 * err

        if e2 > -dy then
            err = err - dy
            x0 = x0 + sx
        elseif e2 < dx then
            err = err + dx
            y0 = y0 + sy
        end

        return x0_tmp, y0_tmp
    end
end

function colget(x, y, fn)

    x &= 0xffff.0
    y &= 0xffff.0

    -- flag masks
    local is_solid = 0b00000001 -- if bit 0 (is_solid) is 0, flags can be used for other things
    local offset = 0b11111110 -- can index a total of 64 collision tiles

    -- start position of minkowski collision tiles in sprite memory
    local t0 = {x=0, y=112}

    -- get tile coordinates that contain (x, y)
    local cx = x \ 8 -- note: \ is integer division
    local cy = y \ 8

    -- since each graphics tile has 2x2 collision tiles, we need to sample 4 times
    local result = 0

    if nil == fn then fn = function() return true end end

    local f1 = fget(mget(cx, cy))
    if (f1 & is_solid != 0 and fn(f1 \ 2)) then
        result |= sget(
            t0.x + (f1 & offset) * 8 + x%8 + 8,
            t0.y + y%8 + 8
        )
    end

    local f2 = fget(mget(cx+1, cy))
    if (f2 & is_solid != 0 and fn(f2 \ 2)) then
        result |= sget(
            t0.x + (f2 & offset) * 8 + x%8,
            t0.y + y%8 + 8
        )
    end

    local f3 = fget(mget(cx, cy+1))
    if (f3 & is_solid != 0 and fn(f3 \ 2)) then
        result |= sget(
            t0.x + (f3 & offset) * 8 + x%8 + 8,
            t0.y + y%8
        )
    end

    local f4 = fget(mget(cx+1, cy+1))
    if (f4 & is_solid != 0 and fn(f4 \ 2)) then
        result |= sget(
            t0.x + (f4 & offset) * 8 + x%8,
            t0.y + y%8
        )
    end

    return result
end