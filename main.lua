
local W, H = 1280, 800
local STEP = 1 / 120
local accumulator = 0

local field = {
    left = 60, right = 1220,
    top = 100, bottom = 720,
    goalHalf = 72
}

local cfg = {
    acceleration = 1800,
    maxSpeed = 270,
    playerDrag = 6.5,
    ballDrag = 2.0,
    ballStopSpeed = 6,
    restitution = 0.76,
    wallBounce = 0.78,
    kickSpeed = 510
}

local player, ball
local goals, ownGoals, kicks = 0, 0, 0
local mode = "instant"
local charging, charge = false, 0
local queuedKick = nil
local cooldown = 0
local debugView = true

local function clamp(v, lo, hi)
    return math.max(lo, math.min(hi, v))
end

local function resetPositions()
    player = {
        x = field.left + (field.right - field.left) * 0.34,
        y = (field.top + field.bottom) / 2,
        vx = 0, vy = 0,
        r = 15, mass = 3
    }

    ball = {
        x = (field.left + field.right) / 2,
        y = (field.top + field.bottom) / 2,
        vx = 0, vy = 0,
        r = 8, mass = 1
    }

    charging = false
    charge = 0
    queuedKick = nil
    cooldown = 0
end

local function resetAll()
    goals, ownGoals, kicks = 0, 0, 0
    resetPositions()
end

local function resolvePlayerBall()
    local dx = ball.x - player.x
    local dy = ball.y - player.y
    local distance = math.sqrt(dx * dx + dy * dy)

    local target = player.r + ball.r
    if distance >= target then return end

    if distance < 0.0001 then
        dx, dy, distance = 1, 0, 1
    end

    local nx, ny = dx / distance, dy / distance
    local invP = 1 / player.mass
    local invB = 1 / ball.mass
    local invTotal = invP + invB

    -- Correzione della sovrapposizione.
    local penetration = target - distance

    player.x = player.x
        - nx * penetration * invP / invTotal
    player.y = player.y
        - ny * penetration * invP / invTotal

    ball.x = ball.x
        + nx * penetration * invB / invTotal
    ball.y = ball.y
        + ny * penetration * invB / invTotal

    -- Impulso lungo la normale di collisione.
    local rvx = ball.vx - player.vx
    local rvy = ball.vy - player.vy
    local normalSpeed = rvx * nx + rvy * ny

    if normalSpeed >= 0 then return end

    local impulse = -(1 + cfg.restitution)
        * normalSpeed / invTotal

    player.vx = player.vx - nx * impulse * invP
    player.vy = player.vy - ny * impulse * invP

    ball.vx = ball.vx + nx * impulse * invB
    ball.vy = ball.vy + ny * impulse * invB

    -- Attrito tangenziale semplice.
    local tx, ty = -ny, nx
    local tangentSpeed = rvx * tx + rvy * ty

    local frictionImpulse = clamp(
        -tangentSpeed / invTotal,
        -impulse * 0.12,
        impulse * 0.12
    )

    player.vx = player.vx
        - tx * frictionImpulse * invP
    player.vy = player.vy
        - ty * frictionImpulse * invP

    ball.vx = ball.vx
        + tx * frictionImpulse * invB
    ball.vy = ball.vy
        + ty * frictionImpulse * invB
end

local function collidePost(x, y)
    local dx = ball.x - x
    local dy = ball.y - y
    local distance = math.sqrt(dx * dx + dy * dy)
    local target = ball.r + 6

    if distance >= target then return end

    if distance < 0.0001 then
        dx, dy, distance = 1, 0, 1
    end

    local nx, ny = dx / distance, dy / distance

    ball.x = x + nx * target
    ball.y = y + ny * target

    local vn = ball.vx * nx + ball.vy * ny

    if vn < 0 then
        ball.vx = ball.vx
            - (1 + cfg.wallBounce) * vn * nx
        ball.vy = ball.vy
            - (1 + cfg.wallBounce) * vn * ny
    end
end

local function resolveField()
    local midY = (field.top + field.bottom) / 2

    -- Il giocatore non attraversa le linee.
    player.x = clamp(
        player.x,
        field.left + player.r,
        field.right - player.r
    )
    player.y = clamp(
        player.y,
        field.top + player.r,
        field.bottom - player.r
    )

    -- Sponde superiore e inferiore.
    if ball.y - ball.r < field.top then
        ball.y = field.top + ball.r
        ball.vy = math.abs(ball.vy) * cfg.wallBounce
    elseif ball.y + ball.r > field.bottom then
        ball.y = field.bottom - ball.r
        ball.vy = -math.abs(ball.vy) * cfg.wallBounce
    end

    -- Le linee laterali hanno un'apertura per le porte.
    local inGoal = math.abs(ball.y - midY)
        < field.goalHalf

    if not inGoal then
        if ball.x - ball.r < field.left then
            ball.x = field.left + ball.r
            ball.vx = math.abs(ball.vx) * cfg.wallBounce
        elseif ball.x + ball.r > field.right then
            ball.x = field.right - ball.r
            ball.vx = -math.abs(ball.vx) * cfg.wallBounce
        end
    end

    -- Pali circolari.
    for _, x in ipairs({field.left, field.right}) do
        collidePost(x, midY - field.goalHalf)
        collidePost(x, midY + field.goalHalf)
    end

    -- Rilevazione dei gol.
    if math.abs(ball.y - midY) < field.goalHalf then
        if ball.x > field.right + ball.r + 8 then
            goals = goals + 1
            resetPositions()
        elseif ball.x < field.left - ball.r - 8 then
            ownGoals = ownGoals + 1
            resetPositions()
        end
    end
end

local function tryKick(power)
    if cooldown > 0 then return end

    local dx = ball.x - player.x
    local dy = ball.y - player.y
    local distance = math.sqrt(dx * dx + dy * dy)

    if distance < 0.0001 then return end
    if distance > player.r + ball.r + 17 then
        return
    end

    local nx, ny = dx / distance, dy / distance

    -- La velocità di avvicinamento contribuisce al tiro.
    local approach = math.max(
        0, player.vx * nx + player.vy * ny
    )

    local speed = cfg.kickSpeed * power
        + approach * 0.18

    ball.vx = ball.vx + nx * speed
    ball.vy = ball.vy + ny * speed

    kicks = kicks + 1
    cooldown = 0.18
end

local function physicsStep(dt)
    cooldown = math.max(0, cooldown - dt)

    local dx, dy = 0, 0

    if love.keyboard.isDown("a", "left") then
        dx = dx - 1
    end
    if love.keyboard.isDown("d", "right") then
        dx = dx + 1
    end
    if love.keyboard.isDown("w", "up") then
        dy = dy - 1
    end
    if love.keyboard.isDown("s", "down") then
        dy = dy + 1
    end

    local length = math.sqrt(dx * dx + dy * dy)

    if length > 0 then
        dx, dy = dx / length, dy / length
    end

    if mode == "charge" and charging then
        charge = math.min(0.7, charge + dt)
    end

    local acceleration = cfg.acceleration
    local drag = math.exp(-cfg.playerDrag * dt)

    player.vx = (player.vx + dx * acceleration * dt)
        * drag
    player.vy = (player.vy + dy * acceleration * dt)
        * drag

    local maxSpeed = cfg.maxSpeed

    if charging then
        maxSpeed = maxSpeed * 0.85
    end

    local speed = math.sqrt(
        player.vx ^ 2 + player.vy ^ 2
    )

    if speed > maxSpeed then
        player.vx = player.vx / speed * maxSpeed
        player.vy = player.vy / speed * maxSpeed
    end

    player.x = player.x + player.vx * dt
    player.y = player.y + player.vy * dt

    local ballDrag = math.exp(-cfg.ballDrag * dt)

    ball.vx = ball.vx * ballDrag
    ball.vy = ball.vy * ballDrag

    -- Evita lunghi scivolamenti a velocita impercettibili.
    if ball.vx * ball.vx + ball.vy * ball.vy
        < cfg.ballStopSpeed * cfg.ballStopSpeed then
        ball.vx, ball.vy = 0, 0
    end

    ball.x = ball.x + ball.vx * dt
    ball.y = ball.y + ball.vy * dt

    resolvePlayerBall()

    if queuedKick then
        tryKick(queuedKick)
        queuedKick = nil
    end

    resolveField()
end

function love.load()
    love.window.setMode(W, H, {vsync = 1})
    love.window.setTitle("Football Physics Lab 01")
    love.graphics.setFont(love.graphics.newFont(15))
    resetAll()
end

function love.keypressed(key, _, isrepeat)
    if key == "escape" then
        love.event.quit()
    elseif key == "r" then
        resetAll()
    elseif key == "f1" then
        debugView = not debugView
    elseif key == "c" then
        mode = mode == "instant" and "charge" or "instant"
        charging = false
        queuedKick = nil
        charge = 0
    elseif key == "j" then
        cfg.ballDrag = math.max(0.4, cfg.ballDrag - 0.2)
    elseif key == "k" then
        cfg.ballDrag = math.min(6.0, cfg.ballDrag + 0.2)
    elseif key == "[" then
        cfg.kickSpeed = math.max(100, cfg.kickSpeed - 50)
    elseif key == "]" then
        cfg.kickSpeed = cfg.kickSpeed + 50
    elseif key == "space" and not isrepeat then
        if mode == "instant" then
            queuedKick = 1
        else
            charging = true
            charge = 0
        end
    end
end

function love.keyreleased(key)
    if key == "space" and mode == "charge"
        and charging then

        queuedKick = 0.65 + (charge / 0.7) * 0.65
        charging = false
        charge = 0
    end
end

function love.update(dt)
    accumulator = accumulator + math.min(dt, 0.05)

    while accumulator >= STEP do
        physicsStep(STEP)
        accumulator = accumulator - STEP
    end
end

function love.draw()
    local lg = love.graphics
    local midX = (field.left + field.right) / 2
    local midY = (field.top + field.bottom) / 2

    lg.clear(0.065, 0.085, 0.105)

    -- Campo.
    lg.setColor(0.12, 0.31, 0.25)
    lg.rectangle(
        "fill", field.left, field.top,
        field.right - field.left,
        field.bottom - field.top
    )

    lg.setColor(0.78, 0.88, 0.81)
    lg.setLineWidth(2)

    lg.rectangle(
        "line", field.left, field.top,
        field.right - field.left,
        field.bottom - field.top
    )

    lg.line(midX, field.top, midX, field.bottom)
    lg.circle("line", midX, midY, 96)

    lg.rectangle("line", field.left, midY - 120, 118, 240)
    lg.rectangle("line", field.right - 118, midY - 120, 118, 240)

    lg.rectangle(
        "line", field.left - 30,
        midY - field.goalHalf,
        30, field.goalHalf * 2
    )
    lg.rectangle(
        "line", field.right,
        midY - field.goalHalf,
        30, field.goalHalf * 2
    )

    -- Pali.
    for _, x in ipairs({field.left, field.right}) do
        for _, y in ipairs({
            midY - field.goalHalf,
            midY + field.goalHalf
        }) do
            lg.setColor(1, 0.86, 0.52)
            lg.circle("fill", x, y, 6)
        end
    end

    -- Disco controllato.
    lg.setColor(0.16, 0.52, 0.94)
    lg.circle("fill", player.x, player.y, player.r)

    lg.setColor(0.82, 0.92, 1)
    lg.circle("line", player.x, player.y, player.r)

    -- Pallone.
    lg.setColor(0.98, 0.97, 0.89)
    lg.circle("fill", ball.x, ball.y, ball.r)

    lg.setColor(0.20, 0.25, 0.26)
    lg.circle("line", ball.x, ball.y, ball.r)

    if debugView then
        lg.setColor(0.95, 0.70, 0.24, 0.55)
        lg.circle(
            "line", player.x, player.y,
            player.r + ball.r + 17
        )

        lg.setColor(1, 0.76, 0.28)
        lg.line(
            ball.x, ball.y,
            ball.x + ball.vx * 0.15,
            ball.y + ball.vy * 0.15
        )
    end

    lg.setColor(1, 1, 1)

    local shotMode = mode == "instant"
        and "IMMEDIATO" or "CARICATO"

    lg.print(
        "PHYSICS LAB 01   |   Gol: " .. goals
        .. "   |   Autogol: " .. ownGoals
        .. "   |   Calci: " .. kicks,
        30, 18
    )

    lg.print(
        "Tiro: " .. shotMode
        .. "   |   Potenza base: " .. cfg.kickSpeed
        .. "   |   Attrito palla: "
        .. string.format("%.1f", cfg.ballDrag),
        30, 44
    )

    lg.print(
        "WASD: muovi   SPAZIO: calcia   C: modalita tiro"
        .. "   [ ]: potenza   J/K: attrito palla"
        .. "   R: reset   F1: debug",
        30, 764
    )

    if mode == "charge" and charging then
        lg.setColor(0.22, 0.24, 0.28)
        lg.rectangle("fill", 430, 44, 160, 10)

        lg.setColor(1, 0.71, 0.28)
        lg.rectangle(
            "fill", 430, 44,
            160 * (charge / 0.7), 10
        )
    end

    if debugView then
        lg.setColor(1, 1, 1, 0.75)
        lg.print(
            string.format(
                "Palla: %.1f px/s",
                math.sqrt(ball.vx ^ 2 + ball.vy ^ 2)
            ),
            1060, 18
        )
    end
end
