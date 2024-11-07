#include "player_sprites.lua"

player_fsm = cocreate(function()

    -- constants
    local GRAVITY_AY = 0x0.2000 -- y-acceleration due to gravity
    local JUMP_GRAVITY_AY = 0x0.1000 -- y-acceleration due to gravity when holding jump
    local JUMP_VY = -0x0002.2000 -- jump velocity
    local JUMP_RELEASE_VY = -0x0000.8000 -- jump velocity when releasing jump
    local WALK_SPEED = 1
    local SLIDE_SPEED = 0x0001.8000
    local SLIDE_DURATION = 20 -- duration of slide in frames
    local WALL_JUMP_DURATION = 5 -- "kickback" duration when wall jumping

    -- events
    local e_on_ground, e_left_wall, e_right_wall, e_ceiling_touch

    -- variables
    local vx, vy, t = 0, 0, 0
    
    local sprite
    local sprite_iter
    function set_sprite(iter)
        if iter != sprite_iter then
            sprite_iter = iter
            sprite = sprite_iter()
        end
    end

::walk_r::
    if not btn(0) and btn(1) then set_sprite(s_player_walk_r) else set_sprite(s_player_idle_r) end
    vx = not btn(0) and btn(1) and WALK_SPEED or 0
    vy = 0
    e_on_ground, _, _, _ = yield({vx, vy, sprite})
    if not e_on_ground then goto jump_r end
    if btn(0) and not btn(1) then goto walk_l end
    if btn(4) then
        if btn(3) then 
            t = 0
            goto slide_r 
        end
        -- entering jump state
        vy = JUMP_VY
        if btn(0) then goto jump_l end
        goto jump_r
    end
    goto walk_r

::walk_l::
    if not btn(1) and btn(0) then set_sprite(s_player_walk_l) else set_sprite(s_player_idle_l) end
    vx = not btn(1) and btn(0) and -WALK_SPEED or 0
    vy = 0
    e_on_ground, _, _, _ = yield({vx, vy, sprite})
    if not e_on_ground then goto jump_l end
    if btn(1) and not btn(0) then
        sprite = s_player_walk_r()
        goto walk_r
    end
    if btn(4) then
        if btn(3) then 
            t = 0
            goto slide_l
        end
        -- entering jump state
        vy = JUMP_VY
        if btn(1) then goto jump_r end
        goto jump_l
    end
    goto walk_l

::jump_r::
    set_sprite(s_player_jump_r)
    vx = not btn(0) and btn(1) and WALK_SPEED or 0
    vy = vy < JUMP_RELEASE_VY and (vy + JUMP_GRAVITY_AY) or (vy + GRAVITY_AY)
    if not btn(4) and vy < JUMP_RELEASE_VY then vy = JUMP_RELEASE_VY end
    e_on_ground, _, e_right_wall, e_ceiling_touch = yield({vx, vy, sprite})
    if btnp(4) and e_right_wall then
        vy = JUMP_VY
        t = 0
        goto wall_jump_l -- flips direction to point out from wall
    end
    if btn(0) and not btn(1) then goto jump_l end
    if e_on_ground then goto walk_r end
    if e_on_ground and btn(0) then goto walk_l end
    if e_ceiling_touch then vy = 0 end
    goto jump_r

::jump_l::
    set_sprite(s_player_jump_l)
    vx = not btn(1) and btn(0) and -WALK_SPEED or 0
    vy = vy < JUMP_RELEASE_VY and (vy + JUMP_GRAVITY_AY) or (vy + GRAVITY_AY)
    if not btn(4) and vy < JUMP_RELEASE_VY then vy = JUMP_RELEASE_VY end
    e_on_ground, e_left_wall, _, e_ceiling_touch = yield({vx, vy, sprite})
    if btnp(4) and e_left_wall then
        vy = JUMP_VY
        t = 0
        goto wall_jump_r -- flips direction to point out from wall
    end
    if btn(1) and not btn(0) then goto jump_r end
    if e_on_ground then goto walk_l end
    if e_on_ground and btn(1) then goto walk_r end
    if e_ceiling_touch then vy = 0 end
    goto jump_l

::wall_jump_r::
    set_sprite(s_player_idle_r)
    vx = WALK_SPEED
    vy = vy < JUMP_RELEASE_VY and (vy + JUMP_GRAVITY_AY) or (vy + GRAVITY_AY)
    t = t+1
    e_on_ground, _, _, e_ceiling_touch = yield({vx, vy, sprite})
    if not btn(4) and vy < JUMP_RELEASE_VY then vy = JUMP_RELEASE_VY end
    if e_on_ground then goto walk_r end
    if e_on_ground and btn(0) then goto walk_l end
    if t > WALL_JUMP_DURATION then goto jump_r end
    if e_ceiling_touch then vy = 0 end
    goto wall_jump_r

::wall_jump_l::
    set_sprite(s_player_idle_l)
    vx = -WALK_SPEED
    vy = vy < JUMP_RELEASE_VY and (vy + JUMP_GRAVITY_AY) or (vy + GRAVITY_AY)
    t = t+1
    e_on_ground, _, _, e_ceiling_touch = yield({vx, vy, sprite})
    if not btn(4) and vy < JUMP_RELEASE_VY then vy = JUMP_RELEASE_VY end
    if e_on_ground then goto walk_l end
    if e_on_ground and btn(1) then goto walk_r end
    if t > WALL_JUMP_DURATION then goto jump_l end
    if e_ceiling_touch then vy = 0 end
    goto wall_jump_l

::slide_r::
    set_sprite(s_player_idle_r)
    vx = SLIDE_SPEED
    vy = 0
    t = t+1
    e_on_ground, _, _, _ = yield({vx, vy, sprite})
    if btnp(4) then
        vy = JUMP_VY
        goto jump_r
    end
    if not e_on_ground then goto jump_r end
    if t > SLIDE_DURATION then goto walk_r end
    goto slide_r

::slide_l::
    set_sprite(s_player_idle_l)
    vx = -SLIDE_SPEED
    vy = 0
    t = t+1
    e_on_ground, _, _, _ = yield({vx, vy, sprite})
    if btnp(4) then
        vy = JUMP_VY
        goto jump_l
    end
    if not e_on_ground then goto jump_l end
    if t > SLIDE_DURATION then goto walk_l end
    goto slide_l
end)