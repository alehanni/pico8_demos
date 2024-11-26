#include "intersect.lua"

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
        radius = r,
        color = c
    }
end

function verlet(x, prev_x, ax, dt)
    return 2*x - prev_x + ax * dt*dt
end

function _init()
    poke(0x5f2d, 0x1) -- enable cursor
    poke(0x5f5c, 0xff) -- disable btnp repeating
    create_pebble(32, 64, 8, 8)
    create_pebble(96, 48, 8, 10)
    create_pebble(64, 32, 8, 11)
    create_pebble(96, 64, 8, 12)
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
            local r = b1.radius + b2.radius

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
            local contact = get_segment_contact(b.next_x, b.next_y, b.radius)

            if nil == contact then break end

            local delta = v2(contact.x - b.next_x, contact.y - b.next_y)
            local len = sqrt(delta.x*delta.x + delta.y*delta.y)
            local dir = v2(delta.x / len, delta.y / len)
            b.next_x = contact.x - dir.x*(b.radius + 0.001)
            b.next_y = contact.y - dir.y*(b.radius + 0.001)
        end

        b.x = b.next_x
        b.y = b.next_y
    end
end

function _draw()
    cls(5)
    color(7)
    line(points[1].x, points[1].y, points[1].x, points[1].y)
    for _, p in pairs(points) do
        line(p.x, p.y)
    end

    print(t() * 60 & 0xffff.0000)

    for _, b in ipairs(pebbles) do
        circ(b.x + 0.5, b.y + 0.5, b.radius - 0.5, b.color)
    end
end