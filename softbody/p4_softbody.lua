#include "intersect.lua"

local points = {
    v2(16, 16),
    v2(112, 16),
    v2(112, 112),
    v2(16, 112),
    v2(16, 16)
}

local pebbles = {}

function create_pebble(x, y, r, c)
    local p = {
        x = x,
        y = y,
        prev_x = x,
        prev_y = y,
        next_x = x,
        next_y = y,
        ax = 0,
        ay = 0,
        radius = r,
        color = c
    }
    pebbles[#pebbles+1] = p
    return p
end

local links = {}

function create_link(p1, p2, d_tgt, kp, kd)
    local l = {
        p1 = p1,
        p2 = p2,
        d_tgt = d_tgt, -- target distance
        kp = kp, -- spring coefficient / p-term
        kd = kd, -- d-term
        prev_err_x = 0,
        prev_err_y = 0
    }
    links[#links+1] = l
    return l
end

function verlet(x, prev_x, ax, dt)
    return 2*x - prev_x + ax * dt*dt
end

function _init()
    poke(0x5f2d, 0x1) -- enable cursor
    poke(0x5f5c, 0xff) -- disable btnp repeating
    local p1, p2, p3, p4
    p1 = create_pebble(48, 48, 4, 0)
    p2 = create_pebble(80, 48, 4, 0)
    p3 = create_pebble(80, 64, 4, 0)
    p4 = create_pebble(48, 64, 4, 0)
    create_link(p1, p2, 24, 100, 2)
    create_link(p2, p3, 24, 100, 2)
    create_link(p3, p4, 24, 100, 2)
    create_link(p4, p1, 24, 100, 2)
    create_link(p1, p3, 34, 141, 3)
    create_link(p2, p4, 34, 141, 3)
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
    
    local dt = 1/60

    -- reset accelerations
    for b_id, b in ipairs(pebbles) do
        b.ax = 0
        b.ay = 100
    end

    -- apply force constraints
    for li_id, li in ipairs(links) do
        local dx = li.p2.x - li.p1.x
        local dy = li.p2.y - li.p1.y
        local err = sqrt(dx*dx + dy*dy)

        local cosa = dx/err
        local sina = dy/err

        local err_x = dx - cosa*li.d_tgt
        local err_y = dy - sina*li.d_tgt
        local derr_x_dt = (err_x - li.prev_err_x) / dt
        local derr_y_dt = (err_y - li.prev_err_y) / dt
        li.prev_err_x = err_x
        li.prev_err_y = err_y

        li.p1.ax += li.kp*err_x + li.kd*derr_x_dt
        li.p1.ay += li.kp*err_y + li.kd*derr_y_dt
        li.p2.ax -= li.kp*err_x + li.kd*derr_x_dt
        li.p2.ay -= li.kp*err_y + li.kd*derr_y_dt
    end

    -- integrate velocity, or set next_xy with cursor
    local mx = stat(32) -- read mouse x
    local my = stat(33) -- read mouse y
    local lb_down = stat(34) & 0x1

    for b_id, b in ipairs(pebbles) do
        if dist_to_point(mx, my, b.x, b.y) < b.radius and lb_down==0x1 then
            b.next_x = mx
            b.next_y = my
        else
            b.next_x = verlet(b.x, b.prev_x, b.ax, dt)
            b.next_y = verlet(b.y, b.prev_y, b.ay, dt)
        end
        b.prev_x = b.x
        b.prev_y = b.y
    end

    -- pebble-pebble collisions
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

    -- pebble-segment collisions
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
    local mx = stat(32) -- read mouse x
    local my = stat(33) -- read mouse y

    cls(5)
    color(7)
    line(points[1].x, points[1].y, points[1].x, points[1].y)
    for _, p in pairs(points) do
        line(p.x, p.y)
    end

    --print(t() * 60 & 0xffff.0000)

    for _, li in ipairs(links) do
        line(li.p1.x+1, li.p1.y, li.p2.x+1, li.p2.y, 0)
        line(li.p1.x, li.p1.y, li.p2.x, li.p2.y, 0)
    end

    for _, b in ipairs(pebbles) do
        circfill(b.x + 0.5, b.y + 0.5, b.radius - 0.5, b.color)
        if dist_to_point(mx, my, b.x, b.y) < b.radius then
            circ(b.x + 0.5, b.y + 0.5, b.radius - 0.5, 8)
        end
    end

    draw_cursor(mx, my)
end

function draw_cursor(x, y)
    local c = 7
    local lb_down = stat(34) & 0x1
    local y2 = y + lb_down
    pset(x, y2, c)
    line(x, y2+1, x+1, y2+1, c)
    line(x, y2+2, x+2, y2+2, c)
    line(x, y2+3, x+3, y2+3, c)
    line(x, y2+4, x+4, y2+4, c)
    line(x, y2+5, x+4, y2+5, 0)
    pset(x+3, y2+5, c)
end