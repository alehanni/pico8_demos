#include "intersect.lua"

function _init()
    poke(0x5f2d, 0x1) -- enable cursor
    poke(0x5f5c, 0xff) -- disable btnp repeating
end

function _update60()
    -- noop
end

function _draw()
    local mx = stat(32) -- read mouse x
    local my = stat(33) -- read mouse y

    local c = {x=64.5, y=64.5}
    local r = 10.5

    local p1 = {
        x=64 + 48*cos(0.1 * time()) & 0xffff.0000,
        y=64 + 48*sin(0.1 * time()) & 0xffff.0000
    }

    local p2 = {
        x=64 + 8*cos(1.2 * time()) & 0xffff.0000,
        y=64 + 8*sin(1.2 * time()) & 0xffff.0000
    }

    cls(0)
    circ(c.x, c.y, r, 5)

    draw_line_circle_intersect(p1, p2, c, r, 8)
    pset(p2.x, p2.y, 8)

    draw_line_circle_intersect({x=32, y=32}, {x=mx, y=my}, c, r, 11)
    pset(mx, my, 11)

    draw_line_line_intersect({x=96, y=32}, {x=mx, y=my}, {x=64, y=32}, {x=96, y=64}, 10)
    line(64, 32, 96, 64, 5)

    --draw_line_line_intersect({x=96, y=32}, {x=mx, y=my}, {x=128, y=48}, {x=112, y=16}, 10)
    --line(112, 16, 128, 48, 5)
end

function draw_line_line_intersect(p1, q1, p2, q2, col)

    if nil == col then col=8 end

    local a = line_intersect_gg3(p1, q1, p2, q2)
    if nil != a then
        local ix = p1.x + (q1.x - p1.x) * a
        local iy = p1.y + (q1.y - p1.y) * a
        line(p1.x, p1.y, ix, iy, col)
    else
        line(p1.x, p1.y, q1.x, q1.y, col)
    end

    print('t=' .. tostr(a))
end

function draw_line_circle_intersect(p, q, center, radius, col)

    if nil == col then col=8 end

    local t = line_circle_intersect(p, q, center, radius)

    if nil != t then
        local ix = p.x + (q.x - p.x) * t
        local iy = p.y + (q.y - p.y) * t
        line(p.x, p.y, ix, iy, col)
    else
        line(p.x, p.y, q.x, q.y, col)
    end

    print('t=' .. tostr(t))
end