pico-8 cartridge
version 42
__lua__
function v2(x, y)
    return {x=x, y=y}
end
function line_eq_gg3(p, q)
    return function(x, y)
        return (x - p.x)*(q.y - p.y) - (y - p.y)*(q.x - p.x)
    end
end
function dist_to_point(x1, y1, x2, y2)
    local dx = x2 - x1
    local dy = y2 - y1
    return sqrt(dx*dx + dy*dy)
end
function dist_to_line_sq_gg2(p, a, b)
    local py_ay, bx_ax, px_ax, by_ay, a2, d2_sq
    py_ay = p.y - a.y
    bx_ax = b.x - a.x
    px_ax = p.x - a.x
    by_ay = b.y - a.y
    a2 = py_ay*bx_ax - px_ax*by_ay
    d2_sq = (a2*a2) / (bx_ax*bx_ax + by_ay*by_ay)
    return d2_sq
end
function dist_to_seg_sq_gg2(p, a, b)
    local py_ay, bx_ax, px_ax, by_ay, bx_px, by_py, a2, t, d2_sq
    py_ay = p.y - a.y
    bx_ax = b.x - a.x
    px_ax = p.x - a.x
    by_ay = b.y - a.y
    t = px_ax*bx_ax + py_ay*by_ay
    if t < 0 then
        d2_sq = px_ax*px_ax + py_ay*py_ay
    else
        bx_px = b.x - p.x
        by_py = b.y - p.y
        t = bx_px*bx_ax + by_py*by_ay
        if t < 0 then
            d2_sq = bx_px*bx_px + by_py*by_py
        else
            a2 = py_ay*bx_ax - px_ax*by_ay
            --d2_sq = (a2*a2) / (bx_ax*bx_ax + by_ay*by_ay)
            --split operation to avoid overflow
            d2_sq = a2 / (bx_ax*bx_ax + by_ay*by_ay)
            d2_sq = (d2_sq * a2) & 0xffff.0000
        end
    end
    return d2_sq
end
function dist_to_seg_sq_n(p, a, b)
    local py_ay, bx_ax, px_ax, by_ay, bx_px, by_py, a2, t, d2_sq
    py_ay = p.y - a.y
    bx_ax = b.x - a.x
    px_ax = p.x - a.x
    by_ay = b.y - a.y
    local nx, ny -- not normal, but collinear with normal
    t = px_ax*bx_ax + py_ay*by_ay
    if t < 0 then
        -- dist to a
        d2_sq = px_ax*px_ax + py_ay*py_ay
        nx = px_ax
        ny = py_ay
    else
        bx_px = b.x - p.x
        by_py = b.y - p.y
        t = bx_px*bx_ax + by_py*by_ay
        if t < 0 then
            -- dist to b
            d2_sq = bx_px*bx_px + by_py*by_py
            nx = -bx_px
            ny = -by_py
        else
            --
            a2 = py_ay*bx_ax - px_ax*by_ay
            --d2_sq = (a2*a2) / (bx_ax*bx_ax + by_ay*by_ay)
            --split operation to avoid overflow
            d2_sq = a2 / (bx_ax*bx_ax + by_ay*by_ay)
            d2_sq = (d2_sq * a2) & 0xffff.0000
            nx = -by_ay
            ny = bx_ax
        end
    end
    return d2_sq, nx, ny
end
function nearest_seg_xy(p, a, b)
    local py_ay, bx_ax, px_ax, by_ay, bx_px, by_py, t
    py_ay = p.y - a.y
    bx_ax = b.x - a.x
    px_ax = p.x - a.x
    by_ay = b.y - a.y
    t = px_ax*bx_ax + py_ay*by_ay
    if t < 0 then
        -- a is nearest
        return a.x, a.y
    else
        bx_px = b.x - p.x
        by_py = b.y - p.y
        t = bx_px*bx_ax + by_py*by_ay
        if t < 0 then
            -- b is nearest
            return b.x, b.y
        else
            -- p_proj is nearest
            t = (px_ax*bx_ax + py_ay*by_ay) / (bx_ax*bx_ax + by_ay*by_ay)
            return a.x + t * bx_ax, a.y + t * by_ay
        end
    end
end
function line_circle_intersect_bisection(p, q, center, radius)
    local qx_px, qy_py, px_cx, py_cy
    qx_px = q.x - p.x
    qy_py = q.y - p.y
    px_cx = p.x - center.x
    py_cy = p.y - center.y
    -- calculate the coefficients for the quadratic equation
    local a, b, c
    a = qx_px*qx_px + qy_py*qy_py
    b = 2 * (px_cx*qx_px + py_cy*qy_py)
    c = px_cx*px_cx + py_cy*py_cy - radius*radius
    local function f(t) return a * t * t + c end
    local function g(t) return -b * t end
    -- use bisection method to find t
    local tol = 1.5/16 -- tolerance for convergence
    local left, right, mid = 0, 1
    repeat
        mid = (left + right) / 2
        local f_mid = f(mid)
        local g_mid = g(mid)
        if f_mid < g_mid then
            right = mid -- root is in [left, mid]
        else
            left = mid -- root is in [mid, right]
        end
    until abs(f_mid - g_mid) < tol
    return mid
end
function line_circle_intersect(p, q, center, radius)
    local qx_px, qy_py, px_cx, py_cy
    qx_px = (q.x - p.x) >> 8
    qy_py = (q.y - p.y) >> 8
    px_cx = (p.x - center.x) >> 8
    py_cy = (p.y - center.y) >> 8
    radius = radius >> 8
    local a, b, c
    a = qx_px*qx_px + qy_py*qy_py
    b = 2 * (px_cx*qx_px + py_cy*qy_py)
    c = px_cx*px_cx + py_cy*py_cy - radius*radius
    local discriminant = b*b - 4*a*c
    if discriminant < 0 then
        return nil
    end
    local t1 = (-b - sqrt(discriminant)) / (2*a)
    if t1 >= 0 and t1 <= 1 then
        return t1
    else
        return nil
    end
end
function line_intersect_gg3(p1, q1, p2, q2)
    -- IV.6 "faster line segment intersection" from gg3
    local ax, ay, bx, by, cx, cy
    ax = q1.x - p1.x
    ay = q1.y - p1.y
    bx = p2.x - q2.x
    by = p2.y - q2.y
    cx = p1.x - p2.x
    cy = p1.y - p2.y
    local num_a, denom_a
    num_a = by*cx - bx*cy
    denom_a = ay*bx - ax*by
    if denom_a > 0 then
        if num_a < 0 or num_a > denom_a then
            return nil
        elseif num_a > 0 or num_a < denom_a then
            return nil
        end
    end
    if denom_a == 0 then return nil end
    local alpha, beta
    alpha = num_a / denom_a
    if (alpha < 0 or alpha > 1) then return nil end
    beta = (ax*cy - ay*cx) / (ay*bx - ax*by)
    if (beta < 0 or beta > 1) then return nil end
    return alpha, beta
end
function line_capsule_intersect(p1, q1, p2, q2, r)
    local inf = 0x7fff.ffff -- note: only remotely true on the pico-8
    local t1, t2, t3, t4
    t1 = line_circle_intersect(p1, q1, p2, r)
    t1 = (nil == t1) and inf or t1
    t2 = line_circle_intersect(p1, q1, q2, r)
    t2 = (nil == t2) and inf or t2
    local offs = v2(-(q2.y - p2.y), q2.x - p2.x) -- get perpendicular line
    local offs_len = sqrt(offs.x*offs.x + offs.y*offs.y)
    offs.x = r * offs.x / offs_len -- normalize and multiply by r
    offs.y = r * offs.y / offs_len
    --print(offs.x)
    --print(offs.y)
    --assert(false)
    local p2_o1, q2_o1, p2_o2, q2_o2
    p2_o1 = v2(p2.x + offs.x, p2.y + offs.y)
    q2_o1 = v2(q2.x + offs.x, q2.y + offs.y)
    p2_o2 = v2(p2.x - offs.x, p2.y - offs.y)
    q2_o2 = v2(q2.x - offs.x, q2.y - offs.y)
    t3, _ = line_intersect_gg3(p1, q1, q2_o1, p2_o1)
    t3 = (nil == t3) and inf or t3
    t4, _ = line_intersect_gg3(p1, q1, p2_o2, q2_o2)
    t4 = (nil == t4) and inf or t4
    local t_min = min(t1, min(t2, min(t3, t4)))
    if inf == t_min then
        return nil
    else
        return t_min
    end
end
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
__gfx__
__gff__
__map__
