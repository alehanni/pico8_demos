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
    local mx = 64 + 56*cos(t)
    local my = 64 + 56*sin(t)

    cls(5)

    map(0, 0, 0, 0, 16, 16)

    for x, y in bresenham_iter(64, 64, mx, my) do
        if 0x9 == pget(x, y) then break end
        pset(x, y, 8)
    end

    circfill(64, 64, 1, 7)
    circfill(mx, my, 1, 7)
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