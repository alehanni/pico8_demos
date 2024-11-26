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

    local p1 = v2(64 + 32 * cos(0.1 * t()), 64 + 32 * sin(0.1 * t()))
    local p2 = v2(64 - 32 * cos(0.1 * t()), 64 - 32 * sin(0.1 * t()))
    local offs = v2(8 * sin(-0.1 * t()), 8 * cos(-0.1 * t()))
    
    local offs2 = v2(16 * sin(0.5 * t()), -16 * sin(0.5 * t()))
    local r1 = v2(24 + offs2.x, 24 + offs2.y)
    local r2 = v2(96 + offs2.x, 96 + offs2.y)

    local t = line_capsule_intersect(r1, r2, p1, p2, 8)

    cls(0)
    circ(p1.x, p1.y, 8, 5)
    circ(p2.x, p2.y, 8, 5)
    line(p1.x + offs.x, p1.y + offs.y, p2.x + offs.x, p2.y + offs.y)
    line(p1.x - offs.x, p1.y - offs.y, p2.x - offs.x, p2.y - offs.y)
    --pset(p1.x, p1.y, 5)
    --pset(p2.x, p2.y, 5)

    if nil != t then
        local ix, iy
        ix = r1.x + (r2.x - r1.x) * t
        iy = r1.y + (r2.y - r1.y) * t
        line(r1.x, r1.y, ix, iy, 8)
    else
        line(r1.x, r1.y, r2.x, r2.y, 8)
    end
end