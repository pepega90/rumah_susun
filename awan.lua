list_awan = {img.awan1, img.awan2, img.awan3}

awan = {
        x = -130,
        y = -20,
        img = list_awan[math.random(1, #list_awan)],
        dir = "kiri",
    }

awan2 = {
    x = love.graphics.getWidth(),
    y = 300,
    img = list_awan[math.random(1, #list_awan)],
    dir = "kanan",
}

awans = {awan, awan2}

function updateAwan(dt) 
    if bg_y >= 300 and current_scene ~= scene.game_over then
        for i, _ in ipairs(awans) do
            local a = awans[i]
            if a.dir == "kiri" then
                if a.x > love.graphics.getWidth() then
                    a.img = list_awan[math.random(1, #list_awan)]
                    a.x = -10
                else
                    a.x = a.x + 30 * dt
                end
            elseif a.dir == "kanan" then
                if a.x < -a.img:getWidth() then
                    a.img = list_awan[math.random(1, #list_awan)]
                    a.x = love.graphics.getWidth()
                else
                    a.x = a.x - 30 * dt
                end
            end
        end
    end
end

function drawAwan() 
    for _, a in ipairs(awans) do
        love.graphics.draw(a.img, a.x, a.y, nil, 0.5)
    end
end