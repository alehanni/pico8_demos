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

    local sample = function(x, y)
        local result = 0
        for _, b in ipairs(metaballs) do
            local dx = abs(b.x - x)
            local dy = abs(b.y - y)
            if dx < b.r and dy < b.r then
                result += linstep(b.r - approx_dist(dx, dy))
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

    -- set map
    k = 0
    for j=0,15 do
        for i=0,15 do     
            local k = i + j*17
            local acc = 0
            local z = 8
            if samples[k] > z then acc += 1 end
            if samples[k+1] > z then acc += 2 end
            if samples[k+17] > z then acc += 16 end
            if samples[k+17+1] > z then acc += 32 end

            local b_mid = midpoints[i + j*16] > z
            if 18 == acc and not b_mid then
                mset(i, j, 64)
            elseif 33 == acc and not b_mid then
                mset(i, j, 65)
            else
                mset(i, j, acc)
            end
        end
    end
end

function _draw()
    cls(0)
    for _, b in ipairs(metaballs) do
        circ(b.x, b.y, b.r, 1)
    end
    
    map(0, 0, 0, 0, 16, 16)
    
    color(7)
    print(stat(1), 0, 0)
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