grav = 1
force = 0

bob = {
    x = 0,
    y = 0
}

angle = math.pi / 4
angle_v = 0
angle_a = 0
attach = true
drop = false
scale = 0.5
timer = 1.5
animate = false
swing_speed = 1
bg_y = 0
drop_speed = 100

function updatePlayer(dt)
    force = grav * math.sin(angle) / love.graphics.getWidth()/2
    angle_a = -1 * force
    angle_v = angle_v + angle_a * swing_speed
    angle = angle + angle_v

    bob.x = 300 * math.sin(angle) + love.graphics.getWidth()/2
    bob.y = 300 * math.cos(angle);
end