#include "player_fsm.lua"

function _init()
    poke(0x5f2d, 0x1) -- enable cursor
    poke(0x5f5c, 0xff) -- disable btnp repeating
end

function _update60()
    -- noop
    player_update()
end

function _draw()
    cls(5)
    map(0, 0, 0, 0, 16, 16)
    player_draw()
end

function bresenham_turtle(x0, y0, x1, y1, xfunc, yfunc)

    local dx = abs(x1 - x0)
    local dy = abs(y1 - y0)

    local sx = x0 < x1 and 1 or -1
    local sy = y0 < y1 and 1 or -1

    local err = dx - dy

    while true do
        if x0 == x1 and y0 == y1 then break end

        local e2 = 2 * err

        if e2 > -dy then
            xfunc()
            err = err - dy
            x0 = x0 + sx
        end
        
        if e2 < dx then
            yfunc()
            err = err + dx
            y0 = y0 + sy
        end
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

o_player = {
    x=0x40.0, y=0x40.0,
    vx=0, vy=0, -- pixels/second
    sprite=s_player_idle_r(),
}

function player_update()
    
    local is_grounded = colget(o_player.x, o_player.y+1) > 0 -- definitely related to electrical safety
    local wall_on_left = colget(o_player.x-1, o_player.y, function(x) return x==0 end) > 0
    local wall_on_right = colget(o_player.x+1, o_player.y, function(x) return x==0 end) > 0
    local ceiling_touch = colget(o_player.x, o_player.y-1) > 0
    
    -- get velocity
    local _, result = coresume(player_fsm, is_grounded, wall_on_left, wall_on_right, ceiling_touch)
    o_player.vx, o_player.vy, o_player.sprite = unpack(result)

    -- minkowski collision
    local xstep = ((o_player.x + o_player.vx) & 0xffff.0) - (o_player.x & 0xffff.0)
    local ystep = ((o_player.y + o_player.vy) & 0xffff.0) - (o_player.y & 0xffff.0)

    o_player.x += o_player.vx
    if (xstep != 0) then o_player.x -= xstep end

    o_player.y += o_player.vy
    if (ystep != 0) then o_player.y -= ystep end

    function xfunc()
        local dx = sgn(xstep)
        if colget(o_player.x + dx, o_player.y) > 0 then
            if colget(o_player.x + dx, o_player.y - 1) > 0 then -- check if hard stop or moving up slope
                o_player.vx = 0
            else
                o_player.x += dx
                o_player.y -= 1
            end
        else
            o_player.x += dx -- no x-axis collision
    
            -- check if moving down slope
            if o_player.vy >= 0 and is_grounded \
            and colget(o_player.x, o_player.y + 1) == 0 \
            and colget(o_player.x, o_player.y + 2) > 0 \
            then 
                o_player.y += 1
            end
        end
    end
    
    function yfunc()
        local dy = sgn(ystep)
        if colget(o_player.x, o_player.y + dy) > 0 then
            o_player.vy = 0
        else
            o_player.y += dy -- no y-axis collision
        end
    end

    bresenham_turtle(o_player.x, o_player.y, o_player.x + xstep, o_player.y + ystep, xfunc, yfunc)
end

function player_draw()
    --print((60*time()) & 0xffff.0000)
    o_player:sprite()
    rect(o_player.x, o_player.y, o_player.x+7, o_player.y+7, 14)
end