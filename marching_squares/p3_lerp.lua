local metaballs = {}
function create_metaball(x, y, vx, vy, r)
    local mb = {
        x=x,
        y=y,
        vx=vx,
        vy=vy,
        r=r
    }
    metaballs[#metaballs+1] = mb
    return mb
end

function _init()
    poke(0x5f2d, 0x01) -- enable cursor
    poke(0x5f5c, 0xff) -- disable btnp repeating
    poke(0x5f36, 0x08) -- make tile 0 opaque
    create_metaball(32, 32, 0.5, 1/3, 32)
    create_metaball(96, 96, 1/3, 0.5, 24)
    create_metaball(64, 64, -0.25, 0.5, 16)
end

function _update60()
    -- update positions
    for _, b in ipairs(metaballs) do
        if b.x < b.r or b.x > 128 - b.r then b.vx = -b.vx end
        if b.y < b.r or b.y > 128 - b.r then b.vy = -b.vy end
        b.x += b.vx
        b.y += b.vy
    end
end

function _draw()
    local sample = function(x, y)
        local result = 0
        for _, b in ipairs(metaballs) do
            local dx = abs(b.x - x)
            local dy = abs(b.y - y)
            if dx < b.r  and dy < b.r then
                result += linstep(b.r - dist(dx, dy))
            end
        end
        return result
    end

    -- sample corner points
    local samples = {}
    samples[288] = 0
    
    local k = 0
    for j=0,128,8 do
        for i=0,128,8 do
            samples[k] = sample(i, j)
            k += 1
        end
    end

    -- sample mid points
    local midpoints = {}
    midpoints[256] = 0

    k = 0
    for j=4,128,8 do
        for i=4,128,8 do
            midpoints[k] = sample(i, j)
            k += 1
        end
    end

    cls(0)
    for j=0,15 do
        for i=0,15 do     
            pset(i*8,j*8,5)
        end
    end

    for _, b in ipairs(metaballs) do
        circ(b.x, b.y, b.r, 1)
    end

    for j=0,15 do
        for i=0,15 do     
            local k = i+j*17
            color(12)
            marching_sq(i, j, samples[k], samples[k+1], samples[k+17], samples[k+17+1], midpoints[i+j*16])
        end
    end

    color(7)
    print(stat(1), 0, 0)
end

function marching_sq(cx, cy, a, b, c, d, e)
    local x, y = cx*8, cy*8
    local z = 8

    if d > z then
        if c > z then
            if b > z then
                if a > z then
                    -- case 15
                else
                    line(x+8*lroot(a, b, z), y+0, x+0, y+8*lroot(a, c, z)) -- case 14
                end
            else
                if a > z then
                    line(x+8, y+8*lroot(b, d, z), x+8*lroot(a, b, z), y+0) -- case 13
                else
                    line(x+8, y+8*lroot(b, d, z), x+0, y+8*lroot(a, c, z)) -- case 12
                end
            end
        else
            if b > z then
                if a > z then
                    line(x+0, y+8*lroot(a, c, z), x+8*lroot(c, d, z), y+8) -- case 11
                else
                    line(x+8*lroot(a, b, z), y+0, x+8*lroot(c, d, z), y+8) -- case 10
                end
            else
                if a > z then
                    if e > z then -- case 9, saddle point
                        line(x+0, y+8*lroot(a, c, z), x+8*lroot(c, d, z), y+8)
                        line(x+8, y+8*lroot(b, d, z), x+8*lroot(a, b, z), y+0)
                    else
                        line(x+0, y+8*lroot(a, c, z), x+8*lroot(a, b, z), y+0)
                        line(x+8, y+8*lroot(b, d, z), x+8*lroot(c, d, z), y+8)
                    end
                else
                    line(x+8, y+8*lroot(b, d, z), x+8*lroot(c, d, z), y+8) -- case 8
                end
            end
        end
    else
        if c > z then
            if b > z then
                if a > z then
                    line(x+8*lroot(c, d, z), y+8, x+8, y+8*lroot(b, d, z)) -- case 7
                else
                    if e > z then -- case 6, saddle point
                        line(x+8*lroot(c, d, z), y+8, x+8, y+8*lroot(b, d, z))
                        line(x+8*lroot(a, b, z), y+0, x+0, y+8*lroot(a, c, z))
                    else
                        line(x+8*lroot(c, d, z), y+8, x+0, y+8*lroot(a, c, z))
                        line(x+8*lroot(a, b, z), y+0, x+8, y+8*lroot(b, d, z))
                    end
                end
            else
                if a > z then
                    line(x+8*lroot(c, d, z), y+8, x+8*lroot(a, b, z), y+0) -- case 5
                else
                    line(x+8*lroot(c, d, z), y+8, x+0, y+8*lroot(a, c, z)) -- case 4
                end
            end
        else
            if b > z then
                if a > z then
                    line(x+0, y+8*lroot(a, c, z), x+8, y+8*lroot(b, d, z)) -- case 3
                else
                    line(x+8*lroot(a, b, z), y+0, x+8, y+8*lroot(b, d, z)) -- case 2
                end
            else
                if a > z then
                    line(x+0, y+8*lroot(a, c, z), x+8*lroot(a, b, z), y+0) -- case 1
                else
                    -- case 0
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