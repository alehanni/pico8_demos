

local s_player_idle_r = function()
    return function(self)
        palt(0b0000000000000100)
        spr(44, self.x, self.y+0) -- legs
        spr(10, self.x+1, self.y-7) -- torso
        spr(26, self.x-3, self.y-4)
        spr(27, self.x+4, self.y-4)
        palt(0)
    end
end

local s_player_idle_l = function()
    return function(self)
        palt(0b0000000000000100)
        spr(44, self.x, self.y+0, 1, 1, true) -- legs
        spr(10, self.x-1, self.y-7, 1, 1, true) -- torso
        spr(26, self.x+3, self.y-4, 1, 1, true)
        spr(27, self.x-4, self.y-4, 1, 1, true)
        palt(0)
    end
end

-- torso spr(+7, -4, -8)
-- legs spr(+7, -4, 0)

local s_player_walk_r = function()

    local co = cocreate(function(x, y)
        while true do
            for i=1, 4 do -- frame 1
                spr(40, x+0, y) --legs
                spr(10, x+1, y-7) -- torso
                spr(26, x-3, y-4)
                spr(27, x+4, y-4)
                x, y = yield()
            end
            for i=1, 4 do -- frame 2
                spr(41, x+0, y) --legs
                spr(10, x+1, y-8) -- torso
                spr(26, x-3, y-5)
                spr(27, x+4, y-5)
                x, y = yield()
            end
            for i=1, 4 do -- frame 3
                spr(42, x-3, y) --legs
                spr(43, x+5, y)
                spr(10, x+1, y-8) -- torso
                spr(26, x-3, y-5)
                spr(27, x+4, y-5)
                x, y = yield()
            end
        end
    end)

    return function(self)
        palt(0b0000000000000100)
        coresume(co, self.x, self.y)
        palt(0)
    end
end

local s_player_walk_l = function()

    local co = cocreate(function(x, y)
        while true do
            for i=1, 4 do -- frame 1
                spr(40, x+0, y, 1, 1, true) --legs
                spr(10, x-1, y-7, 1, 1, true) -- torso
                spr(26, x+3, y-4, 1, 1, true)
                spr(27, x-4, y-4, 1, 1, true)
                x, y = yield()
            end
            for i=1, 4 do -- frame 2
                spr(41, x+0, y, 1, 1, true) --legs
                spr(10, x-1, y-8, 1, 1, true) -- torso
                spr(26, x+3, y-5, 1, 1, true)
                spr(27, x-4, y-5, 1, 1, true)
                x, y = yield()
            end
            for i=1, 4 do -- frame 3
                spr(42, x+3, y, 1, 1, true) --legs
                spr(43, x-5, y, 1, 1, true)
                spr(10, x-1, y-8, 1, 1, true) -- torso
                spr(26, x+3, y-5, 1, 1, true)
                spr(27, x-4, y-5, 1, 1, true)
                x, y = yield()
            end
        end
    end)

    return function(self)
        palt(0b0000000000000100)
        coresume(co, self.x, self.y)
        palt(0)
    end
end

local s_player_jump_r = function()

    local co = cocreate(function(x, y)
        for i=1, 8 do
            spr(45, x-3, y+2) -- legs
            spr(46, x+4, y+2)
            spr(10, x+1, y-7) -- torso
            spr(26, x-3, y-4)
            spr(27, x+4, y-4)
            x, y = yield()
        end
        for i=1, 16 do
            spr(45, x-3, y+1) -- legs
            spr(46, x+5, y+1)
            spr(10, x+1, y-7) -- torso
            spr(26, x-3, y-4)
            spr(27, x+4, y-4)
            x, y = yield()
        end
        while true do
            spr(45, x-3, y+0) -- legs
            spr(46, x+4, y+2)
            spr(10, x+1, y-7) -- torso
            spr(26, x-3, y-4)
            spr(27, x+4, y-4)
            x, y = yield()
        end
    end)

    return function(self)
        palt(0b0000000000000100)
        coresume(co, self.x, self.y)
        palt(0)
    end
end

local s_player_jump_l = function()

    local co = cocreate(function(x, y)
        for i=1, 8 do
            spr(45, x+3, y+2, 1, 1, true) -- legs
            spr(46, x-4, y+2, 1, 1, true)
            spr(10, x-1, y-7, 1, 1, true) -- torso
            spr(26, x+3, y-4, 1, 1, true)
            spr(27, x-4, y-4, 1, 1, true)
            x, y = yield()
        end
        for i=1, 16 do
            spr(45, x+3, y+1, 1, 1, true) -- legs
            spr(46, x-5, y+1, 1, 1, true)
            spr(10, x-1, y-7, 1, 1, true) -- torso
            spr(26, x+3, y-4, 1, 1, true)
            spr(27, x-4, y-4, 1, 1, true)
            x, y = yield()
        end
        while true do
            spr(45, x+3, y+0, 1, 1, true) -- legs
            spr(46, x-4, y+2, 1, 1, true)
            spr(10, x-1, y-7, 1, 1, true) -- torso
            spr(26, x+3, y-4, 1, 1, true)
            spr(27, x-4, y-4, 1, 1, true)
            x, y = yield()
        end
    end)

    return function(self)
        palt(0b0000000000000100)
        coresume(co, self.x, self.y)
        palt(0)
    end
end