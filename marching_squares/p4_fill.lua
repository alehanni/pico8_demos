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

    cls(0)
    for j=0,15 do
        for i=0,15 do     
            pset(i*8,j*8,5)
        end
    end

    for _, b in ipairs(metaballs) do
        circ(b.x, b.y, b.r, 1)
    end
--
--    for _, b in ipairs(metaballs) do
--        local xmin, xmax, ymin, ymax
--        xmin = (b.x - b.r) \ 8 * 8
--        xmax = (b.x + b.r) \ 8 * 8 + 8
--        ymin = (b.y - b.r) \ 8 * 8
--        ymax = (b.y + b.r) \ 8 * 8 + 8
--        rect(xmin, ymin, xmax-1, ymax-1, 8)
--    end

    color(14)
    draw_marching_squares(function(x, y)
        local result = 0
        for _, b in ipairs(metaballs) do
            local dx = abs(b.x - x)
            local dy = abs(b.y - y)
            if dx < b.r and dy < b.r then
                result += linstep(b.r - dist(dx, dy))
            end
        end
        return result
    end)

    color(7)
    print(stat(1), 0, 0)
end

function draw_marching_squares(f_sample)

    local col = peek(0x5f25) & 0xf

    -- sample corner  and middle points
    local corners = {}
    corners[288] = 0
    setmetatable(corners, {__index = function() return 0 end})

    local midpoints = {}
    midpoints[288] = 0
    setmetatable(midpoints, {__index = function() return 0 end})

    for _, b in ipairs(metaballs) do
        local xmin, xmax, ymin, ymax
        xmin = (b.x - b.r) \ 8
        xmax = (b.x + b.r) \ 8 + 1
        ymin = (b.y - b.r) \ 8
        ymax = (b.y + b.r) \ 8 + 1
        
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