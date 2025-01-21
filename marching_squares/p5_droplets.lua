#include "../softbody/intersect.lua"

local points = {
    v2(112, 64),
    v2(108, 82),
    v2(98, 98),
    v2(82, 108),
    v2(64, 112),
    v2(46, 108),
    v2(30, 98),
    v2(20, 82),
    v2(16, 64),
    v2(20, 46),
    v2(30, 30),
    v2(46, 20),
    v2(64, 16),
    v2(82, 20),
    v2(98, 30),
    v2(108, 46),
    v2(112, 64)
}

local pebbles = {}

function create_pebble(x, y, r, c)
    pebbles[#pebbles+1] = {
        x = x,
        y = y,
        prev_x = x,
        prev_y = y,
        next_x = x,
        next_y = y,
        r = r,
        mb_r = 16,
        color = c
    }
end

function verlet(x, prev_x, ax, dt)
    return 2*x - prev_x + ax * dt*dt
end

function _init()
    poke(0x5f2d, 0x1) -- enable cursor
    poke(0x5f5c, 0xff) -- disable btnp repeating
    create_pebble(32, 64, 6, 12)
    --create_pebble(40, 56, 6, 12)
    create_pebble(48, 64, 6, 12)
    create_pebble(56, 56, 6, 12)
    create_pebble(64, 64, 6, 12)
    create_pebble(72, 56, 6, 12)
    create_pebble(80, 64, 6, 12)
    --create_pebble(88, 56, 6, 12)
    create_pebble(96, 64, 6, 12)
    --create_pebble(96, 48, 6, 12)
    --create_pebble(64, 32, 6, 12)
    --create_pebble(96, 64, 6, 12)
end

function get_segment_contact(x, y, r)
    local min_len = 0x7fff.ffff
    local result = nil

    for i, p in ipairs(points) do
        local q = points[i+1]
        if nil == q then break end

        local d_sq = dist_to_seg_sq_gg2(v2(x, y), p, q)
        if d_sq < min_len and d_sq < r*r then
            result = v2(nearest_seg_xy(v2(x, y), p, q))
            min_len = d_sq
        end
    end

    return result
end

function _update60()
    
    -- move
    local dt = 1/60

    local ax = (btn(1) and 200 or 0) - (btn(0) and 200 or 0)
    local ay = (btn(3) and 200 or 0) - (btn(2) and 200 or 0)

    for b_id, b in ipairs(pebbles) do
        b.next_x = verlet(b.x, b.prev_x, ax, dt)
        b.next_y = verlet(b.y, b.prev_y, ay + 100, dt)
        b.prev_x = b.x
        b.prev_y = b.y
    end

    for i=1, #pebbles do
        local b1 = pebbles[i]
        for j=i+1, #pebbles do
            local b2 = pebbles[j]

            local dx = b2.next_x - b1.next_x
            local dy = b2.next_y - b1.next_y
            local d_sq = dx*dx + dy*dy
            local r = b1.r + b2.r

            if d_sq < r*r then
                local d = sqrt(d_sq)
                local dir = v2(dx / d, dy / d)
                local midpoint = v2((b1.next_x + b2.next_x) / 2, (b1.next_y + b2.next_y) / 2)
                local r2 = r/2
                b1.next_x = midpoint.x - dir.x * r2
                b1.next_y = midpoint.y - dir.y * r2
                b2.next_x = midpoint.x + dir.x * r2
                b2.next_y = midpoint.y + dir.y * r2
            end
        end
    end

    for b_id, b in ipairs(pebbles) do
        while true do
            local contact = get_segment_contact(b.next_x, b.next_y, b.r)

            if nil == contact then break end

            local delta = v2(contact.x - b.next_x, contact.y - b.next_y)
            local len = sqrt(delta.x*delta.x + delta.y*delta.y)
            local dir = v2(delta.x / len, delta.y / len)
            b.next_x = contact.x - dir.x*(b.r + 0.001)
            b.next_y = contact.y - dir.y*(b.r + 0.001)
        end

        b.x = b.next_x
        b.y = b.next_y
    end
end

function _draw()
    cls(5)
    color(7)

--    line(points[1].x, points[1].y, points[1].x, points[1].y)
--    for _, p in pairs(points) do
--        line(p.x, p.y)
--    end

--    for _, b in ipairs(pebbles) do
--        circ(b.x + 0.5, b.y + 0.5, b.r - 0.5, b.color)
--    end

    color(12)
    draw_marching_squares(function(x, y)
        local result = 0
        for _, b in ipairs(pebbles) do
            local dx = abs(b.x - x)
            local dy = abs(b.y - y)
            if dx < b.mb_r and dy < b.mb_r then
                result += linstep(b.mb_r - dist(dx, dy))
            end
        end
        return result
    end)

    poke(0x5f34, 0x2)
    circfill(64, 64, 48, 0 | 0x1800)
    poke(0x5f34, 0x0)
    circ(64, 64, 48, 7)

    color(7)
    print(stat(1), 0, 0)
end

-- MARCHING SQUARES CODE --

function draw_marching_squares(f_sample)

    local col = peek(0x5f25) & 0xf

    -- sample corner  and middle points
    local corners = {}
    corners[288] = 0
    setmetatable(corners, {__index = function() return 0 end})

    local midpoints = {}
    midpoints[288] = 0
    setmetatable(midpoints, {__index = function() return 0 end})

    for _, b in ipairs(pebbles) do
        local xmin, xmax, ymin, ymax
        xmin = (b.x - b.mb_r) \ 8
        xmax = (b.x + b.mb_r) \ 8 + 1
        ymin = (b.y - b.mb_r) \ 8
        ymax = (b.y + b.mb_r) \ 8 + 1
        
        for cy=ymin,ymax do
            for cx=xmin,xmax do
                local k = cx+cy*17
                corners[k] = f_sample(cx*8, cy*8)
                midpoints[k] = f_sample(cx*8 + 4, cy*8 + 4)
            end
        end
    end

    for j=0,15 do
        for i=0,15 do     
            local k = i+j*17
            color(col)
            marching_sq(i, j, corners[k], corners[k+1], corners[k+17], corners[k+17+1], midpoints[k])
        end
    end
end

function marching_sq(cx, cy, a, b, c, d, e)
    local x, y = cx*8, cy*8
    local z = 8

    local col = peek(0x5f25) & 0xf

    if d > z then
        if c > z then
            if b > z then
                if a > z then
                    -- case 15
                    rectfill(x, y, x+7, y+7, col)
                else -- case 14
                    local x0, y0, x1, y1 = x+8*lroot(a, b, z), y+0, x+0, y+8*lroot(a, c, z)
                    p01_triangle_163(x0, y0, x+8, y+8, x+8, y+0, col)
                    p01_triangle_163(x0, y0, x1, y1, x+8, y+8, col)
                    p01_triangle_163(x1, y1, x+0, y+8, x+8, y+8, col)
                    line(x0, y0, x1, y1, 7)
                end
            else
                if a > z then -- case 13
                    local x0, y0, x1, y1 = x+8, y+8*lroot(b, d, z), x+8*lroot(a, b, z), y+0
                    p01_triangle_163(x1, y1, x+0, y+0, x+0, y+8, col)
                    p01_triangle_163(x0, y0, x1, y1, x+0, y+8, col)
                    p01_triangle_163(x0, y0, x+0, y+8, x+8, y+8, col)
                    line(x0, y0, x1, y1, 7)
                else -- case 12
                    local x0, y0, x1, y1 = x+8, y+8*lroot(b, d, z), x+0, y+8*lroot(a, c, z)
                    p01_triangle_163(x0, y0, x1, y1, x+0, y+8, col)
                    p01_triangle_163(x0, y0, x+0, y+8, x+8, y+8, col)
                    line(x0, y0, x1, y1, 7)
                end
            end
        else
            if b > z then
                if a > z then -- case 11
                    local x0, y0, x1, y1 = x+0, y+8*lroot(a, c, z), x+8*lroot(c, d, z), y+8
                    p01_triangle_163(x0, y0, x+8, y+0, x+0, y+0, col)
                    p01_triangle_163(x0, y0, x1, y1, x+8, y+0, col)
                    p01_triangle_163(x1, y1, x+8, y+8, x+8, y+0, col)
                    line(x0, y0, x1, y1, 7)
                else -- case 10
                    local x0, y0, x1, y1 = x+8*lroot(a, b, z), y+0, x+8*lroot(c, d, z), y+8
                    p01_triangle_163(x0, y0, x1, y1, x+8, y+0, col)
                    p01_triangle_163(x1, y1, x+8, y+8, x+8, y+0, col)
                    line(x0, y0, x1, y1, 7)
                end
            else
                if a > z then
                    if e > z then -- case 9, saddle point
                        local x0, y0, x1, y1 = x+0, y+8*lroot(a, c, z), x+8*lroot(c, d, z), y+8
                        local x2, y2, x3, y3 = x+8, y+8*lroot(b, d, z), x+8*lroot(a, b, z), y+0
                        p01_triangle_163(x0, y0, x1, y1, x3, y3, col)
                        p01_triangle_163(x1, y1, x2, y2, x3, y3, col)
                        p01_triangle_163(x0, y0, x3, y3, x+0, y+0, col)
                        p01_triangle_163(x1, y1, x+8, y+8, x2, y2, col)
                        line(x0, y0, x1, y1, 7)
                        line(x2, y2, x3, y3, 7)
                    else
                        local x0, y0, x1, y1 = x+0, y+8*lroot(a, c, z), x+8*lroot(a, b, z), y+0
                        local x2, y2, x3, y3 = x+8, y+8*lroot(b, d, z), x+8*lroot(c, d, z), y+8
                        p01_triangle_163(x0, y0, x1, y1, x+0, y+0, col)
                        p01_triangle_163(x2, y2, x3, y3, x+8, y+8, col)
                        line(x+0, y+8*lroot(a, c, z), x+8*lroot(a, b, z), y+0, 7)
                        line(x+8, y+8*lroot(b, d, z), x+8*lroot(c, d, z), y+8, 7)
                    end
                else -- case 8 
                    local x0, y0, x1, y1 = x+8, y+8*lroot(b, d, z), x+8*lroot(c, d, z), y+8
                    p01_triangle_163(x0, y0, x1, y1, x+8, y+8, col)
                    line(x0, y0, x1, y1, 7)
                end
            end
        end
    else
        if c > z then
            if b > z then
                if a > z then -- case 7
                    local x0, y0, x1, y1 = x+8*lroot(c, d, z), y+8, x+8, y+8*lroot(b, d, z)
                    p01_triangle_163(x+0, y+8, x0, y0, x+0, y+0, col)
                    p01_triangle_163(x0, y0, x1, y1, x+0, y+0, col)
                    p01_triangle_163(x1, y1, x+8, y+0, x+0, y+0, col)
                    line(x0, y0, x1, y1, 7)
                else
                    if e > z then -- case 6, saddle point
                        local x0, y0, x1, y1 = x+8*lroot(c, d, z), y+8, x+8, y+8*lroot(b, d, z)
                        local x2, y2, x3, y3 = x+8*lroot(a, b, z), y+0, x+0, y+8*lroot(a, c, z)
                        p01_triangle_163(x0, y0, x1, y1, x2, y2, col)
                        p01_triangle_163(x2, y2, x3, y3, x0, y0, col)
                        p01_triangle_163(x0, y0, x3, y3, x+0, y+8, col)
                        p01_triangle_163(x1, y1, x+8, y+0, x2, y2, col)
                        line(x0, y0, x1, y1, 7)
                        line(x2, y2, x3, y3, 7)
                    else
                        local x0, y0, x1, y1 = x+8*lroot(c, d, z), y+8, x+0, y+8*lroot(a, c, z)
                        local x2, y2, x3, y3 = x+8*lroot(a, b, z), y+0, x+8, y+8*lroot(b, d, z)
                        p01_triangle_163(x0, y0, x1, y1, x+0, y+8, col)
                        p01_triangle_163(x2, y2, x3, y3, x+8, y+0, col)
                        line(x0, y0, x1, y1, 7)
                        line(x2, y2, x3, y3, 7)
                    end
                end
            else
                if a > z then -- case 5
                    local x0, y0, x1, y1 = x+8*lroot(c, d, z), y+8, x+8*lroot(a, b, z), y+0
                    p01_triangle_163(x0, y0, x1, y1, x+0, y+8, col)
                    p01_triangle_163(x1, y1, x+0, y+0, x+0, y+8, col)
                    line(x0, y0, x1, y1, 7)
                else -- case 4
                    local x0, y0, x1, y1 = x+8*lroot(c, d, z), y+8, x+0, y+8*lroot(a, c, z)
                    p01_triangle_163(x0, y0, x1, y1, x+0, y+8, col)
                    line(x0, y0, x1, y1, 7)
                end
            end
        else
            if b > z then
                if a > z then -- case 3
                    local x0, y0, x1, y1 = x+0, y+8*lroot(a, c, z), x+8, y+8*lroot(b, d, z)
                    p01_triangle_163(x0, y0, x1, y1, x+8, y+0, col)
                    p01_triangle_163(x0, y0, x+8, y+0, x+0, y+0, col)
                    line(x0, y0, x1, y1, 7)
                else -- case 2
                    local x0, y0, x1, y1 = x+8*lroot(a, b, z), y+0, x+8, y+8*lroot(b, d, z)
                    p01_triangle_163(x0, y0, x1, y1, x+8, y+0, col)
                    line(x0, y0, x1, y1, 7)
                end
            else
                if a > z then -- case 1
                    local x0, y0, x1, y1 = x+0, y+8*lroot(a, c, z), x+8*lroot(a, b, z), y+0
                    p01_triangle_163(x0, y0, x1, y1, x+0, y+0, col)
                    line(x0, y0, x1, y1, 7)
                else -- case 0
                    -- no op
                end
            end
        end
    end
end

function lroot(y1, y2, z)
    local dy = y2 - y1
    assert(dy != 0)
    local res = (z - y1) / dy
    return max(0, min(res, 1))
end

function linstep(x)
    return min(max(0, x), 16)
end

function dist(dx, dy)
    return sqrt(dx*dx + dy*dy)
end

function approx_dist(dx, dy)
    return 0.98340*max(dx, dy) + 0.43066*min(dx, dy)
end

--@p01
function p01_triangle_163(x0,y0,x1,y1,x2,y2,col)
    color(col)
    if(y1<y0)x0,x1,y0,y1=x1,x0,y1,y0
    if(y2<y0)x0,x2,y0,y2=x2,x0,y2,y0
    if(y2<y1)x1,x2,y1,y2=x2,x1,y2,y1
    col=x0+(x2-x0)/(y2-y0)*(y1-y0)
    p01_trapeze_h(x0,x0,x1,col,y0,y1)
    p01_trapeze_h(x1,col,x2,x2,y1,y2)
end

function p01_trapeze_h(l,r,lt,rt,y0,y1)
    lt,rt=(lt-l)/(y1-y0),(rt-r)/(y1-y0)
    if(y0<0)l,r,y0=l-y0*lt,r-y0*rt,0
    y1=min(y1,128)
    for y0=y0,y1 do
        rectfill(l,y0,r,y0)
        l+=lt
        r+=rt
    end
end