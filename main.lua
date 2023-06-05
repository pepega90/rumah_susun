function love.load() 
    love.window.setTitle("Rumah Susun")
    love.window.setMode(480, 640)

    -- load assets
    img = {}
    img.block = love.graphics.newImage("assets/block.png")
    img.bg = love.graphics.newImage("assets/background.png")
    img.awan1 = love.graphics.newImage("assets/c1.png")
    img.awan2 = love.graphics.newImage("assets/c2.png")
    img.awan3 = love.graphics.newImage("assets/c3.png")

    snd = {}
    snd.dropSfx = love.audio.newSource("assets/drop.ogg", "static") 
    snd.bgm = love.audio.newSource("assets/sfx.ogg", "stream")
    snd.loseSfx = love.audio.newSource("assets/lost.ogg", "static")

    wf = require "lib/windfield"
    world = wf.newWorld(0,0,false)
    
    world:setQueryDebugDrawing(true)
    world:addCollisionClass("Kotak")
    world:addCollisionClass("Ground")

    -- import other code
    require("awan")
    require("player")

    -- game variabel
    scene = {
        play = 0, -- scene play game
        game_over = 1 -- scene saat game over
    }
    last_multiple = 0
    current_multiple = 0
    current_scene = scene.play -- scene yang saat ini sedang di mainkan
    death_count = 0 -- variabel ini akan menghitung berapa kali kotak yang mengantung jatuh ke "Ground", jika lebih dari 2 maka berarti permainan berakhir
    game_over_f = love.graphics.newFont("assets/Pixellari.ttf", 40)
    score = 0
    score_f = love.graphics.newFont("assets/Pixellari.ttf", 20)
    menu_show = true
    
    -- berisikan kotak yang saat ini sedang mengantung, jadi dia hanya menyimpan satu value saja
    kotaks = {}
    -- berisikan kotak-kotak yang sudah ter-drop
    blocks = {}

    -- kotak = world:newRectangleCollider(bob.x, bob.y, 50,50, {collision_class = "Kotak"})
    -- kotak:setFixedRotation(true)

    newKotak()

    ground = world:newRectangleCollider(0, love.graphics.getHeight(), love.graphics.getWidth(), 30, {collision_class = "Ground"})
    ground:setType("static")

end

function love.update(dt)
    
    world:update(dt)

    if current_scene == scene.play then
        
        -- kalkulasi untuk membuat pendulum
        updatePlayer(dt)

        -- jika attach true maka posisikan kotak pertama sesuai dengan pendulum
        if attach then
            kotaks[1]:setPosition(bob.x, bob.y)
        end
        -- jika tidak ter-attach, maka buat kotaknya jatuh
        if not attach then
            kotaks[1]:applyLinearImpulse(0, 500)
        end

        if kotaks[1]:enter("Ground") then
            death_count = death_count + 1
        end

        if death_count == 2 then
            current_scene = scene.game_over
            snd.bgm:stop()
            snd.loseSfx:play()
        end

        -- jika kotaks dengan index pertama [1], dia collide dengan kotak lain
        -- atau dia collide dengan ground
        if kotaks[1]:enter("Ground") or kotaks[1]:enter("Kotak") then
            score = score + 10
            drop = true
            animate = true
            -- play sfx drop
            snd.dropSfx:play()
            -- maka ubah type bodynya menjadi static, by default typenya dynamic
            kotaks[1]:setType("static")
            -- tambahkan kotak yang tadi mengantung ke dalam blocks list
            table.insert(blocks, kotaks[1])
            -- remove kotak yang udah jatuh
            table.remove(kotaks, 1)
        end


        -- jika drop bernilai true
        if drop then
            -- tambah kotak baru, yang nantinya mengantung
            newKotak()
            -- bikin attach jadi true lagi
            attach = true
            -- reset drop menjadi false
            drop = false
        end

        -- jika length dari blocks 3 maka, kita ubah drop_speed menjadi lebih cepat
        if #blocks >= 3 then
            drop_speed = 150
        else
            drop_speed = 100
        end

        -- jika animate true
        if animate then
            -- maka kita kurangi timer
            timer = timer - dt
            -- kita kurangi posisi koordinat y untuk background
            bg_y = bg_y + drop_speed * dt
            -- loop seluruh blocks, lalu update posisi koordinat y-nya agar turun
            for _, b in ipairs(blocks) do
                local bx, by = b:getPosition()
                b:setPosition(bx, by + drop_speed * dt)
            end
            -- jika timer sudah kurang dari sama dengan 1
            if timer <= 1 then
                -- reset animate dan timer
                animate = false
                timer = 1.5
            end
        end

        -- loop seluruh block, secara reverse
        for i = #blocks, 1, -1 do
            local _, by = blocks[i]:getPosition()
            -- lalu cek, jika tinggi dari block sudah melebihi lebar dari layar
            if by - img.block:getWidth()/2 * scale > love.graphics.getHeight() then
                blocks[i]:destroy() -- destroy body
                table.remove(blocks, i) -- maka hapus dari table
            end
        end

        -- check jika score sudah sampai 100, 200, 300 etc. kita cepatkan swing_speednya
        current_multiple = math.floor(score/100)
        if current_multiple > last_multiple then
            swing_speed = swing_speed + 1
            last_multiple = current_multiple
        end

        -- animate awan
        updateAwan(dt)
    end

end

function love.draw()
    
    -- love.graphics.print("death_count = " .. death_count, 50, 50)

    -- draw background
    love.graphics.setColor(1,1,1)
    love.graphics.draw(img.bg, -20,bg_y, nil, 0.7)
    
    love.graphics.setBackgroundColor(53/255, 81/255, 92/255)
    
    -- world:draw()
    if not menu_show and current_scene == scene.play then
        love.graphics.setFont(score_f)
        love.graphics.printf("Score = " .. score, 15, 15, love.graphics.getWidth(), "left")
    end

    if current_scene == scene.play then
        -- draw garis untuk pendulum
        love.graphics.line(love.graphics.getWidth()/2, 0, bob.x, bob.y)

        -- draw kotak yang sedang mengantung
        for _, k in ipairs(kotaks) do 
            love.graphics.draw(img.block, k:getX() - img.block:getWidth()/2 * scale, k:getY() - img.block:getHeight()/2 * scale, nil, scale)
        end
        
        -- draw kotak-kotak yang sudah jatuh
        for _, b in ipairs(blocks) do
            love.graphics.draw(img.block, b:getX() - img.block:getWidth() * scale/2, b:getY() - img.block:getHeight() * scale/2, nil, 0.5)
        end
    end

    -- draw awan
    drawAwan()

    -- draw menu text
    if menu_show then
        love.graphics.setColor(255/1, 255/1, 0)
        love.graphics.setFont(game_over_f)
        love.graphics.printf("Rumah Susun", 0, 80, love.graphics.getWidth(), "center")
        love.graphics.setFont(love.graphics.newFont(25))
        love.graphics.setColor(1,1,1)
        love.graphics.printf("Tekan \"SPACE\" untuk start!", 0, 215, love.graphics.getWidth(), "center")
        love.graphics.setFont(love.graphics.newFont(15))
        love.graphics.printf("created by aji mustofa @pepega90", 10, love.graphics.getHeight()-30, love.graphics.getWidth(), "left") 
    end
    
    if current_scene == scene.game_over then
        love.graphics.setColor(1,0,0)
        love.graphics.setFont(game_over_f)
        love.graphics.printf("Permainan Berakhir", 0, 120, love.graphics.getWidth(), "center") 
        love.graphics.setColor(1,1,1)
        love.graphics.setFont(love.graphics.newFont(35))
        love.graphics.printf("Score = " .. score, 0, 190, love.graphics.getWidth(), "center")
        love.graphics.printf("Tekan \"R\" untuk restart!", 0, 270, love.graphics.getWidth(), "center")
    end
    
    -- -- draw mouse position untuk utility
    -- love.graphics.print("mouse x = " .. love.mouse.getX(), 10, 10)  
    -- love.graphics.print("mouse y = " .. love.mouse.getY(), 10, 40)
end

-- function ini menambahkan kotak baru
function newKotak()
    local k = world:newRectangleCollider(bob.x, bob.y, img.block:getWidth() * scale,img.block:getHeight() * scale, {collision_class = "Kotak"})
    k:setFixedRotation(true)
    table.insert(kotaks, k)
end

function love.keypressed(key, scancode, isrepeat)
    -- exit game
    if key == "escape" then
       love.event.quit()
    end

    -- drop kotak
    if key == "space" then
        snd.bgm:play()
        attach = false
        menu_show = false
    end

    -- restart game
    if key == "r" and current_scene == scene.game_over then
        score = 0
        for i = #blocks, 1, -1 do
            blocks[i]:destroy() -- destroy body
            table.remove(blocks, i) -- maka hapus dari table
        end
        for i = #kotaks, 1, -1 do
            kotaks[i]:destroy() -- destroy body
            table.remove(kotaks, i) -- maka hapus dari table
        end
        -- reset awan
        for i, _ in ipairs(awans) do
            local a = awans[i]
            if a.dir == "kiri" then
                a.img = list_awan[math.random(1, #list_awan)]
                a.x = -130
            elseif a.dir == "kanan" then
                a.img = list_awan[math.random(1, #list_awan)]
                a.x = love.graphics.getWidth()
            end
        end
        bg_y = 0
        death_count = 0 
        attach = true
        drop = false
        animate = false
        swing_speed = 1
        newKotak()
        menu_show = true
        current_scene = scene.play
    end
 end
