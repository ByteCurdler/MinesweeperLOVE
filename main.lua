WIDTH = 8
HEIGHT = 8
SCALE = 64
HEADER_SCALE = 1.5
NUMBER_COLORS = {
  {0,   0,    255},
  {0,   255,  0},
  {255, 0,    0},
  {160, 32,   240},
  {0,   0,    0},
  {176, 48,   96},
  {255, 255,  255},
  {0,   255,  255}
}

function love.load(arg)
  for i=1,3 do
    if arg[i] then
      if i == 1 then
        WIDTH = tonumber(arg[1])
      elseif i == 2 then
        HEIGHT = tonumber(arg[2])
      elseif i == 3 then
        SCALE = tonumber(arg[3])
      end
    end
  end
  NUM_MINES = math.floor((WIDTH*HEIGHT) * (10/64))
  HEADER_SIZE = HEADER_SCALE * SCALE
  love.window.setMode(WIDTH*SCALE, HEIGHT*SCALE+HEADER_SIZE, {})
  love.window.setTitle("Minesweeper")
  love.graphics.setDefaultFilter("nearest", "nearest")
  images = {
    mine = love.graphics.newImage("images/mine.png"),
    covered = love.graphics.newImage("images/covered.png"),
    uncovered = love.graphics.newImage("images/uncovered.png"),
    smiley = love.graphics.newImage("images/smiley.png"),
    numbers = love.graphics.newImage("images/numbers.png"),
    flagged = love.graphics.newImage("images/flagged.png"),
    flagged_wrong = love.graphics.newImage("images/flagged-wrong.png")
  }
  sounds = {
    explode = love.audio.newSource("sounds/mine_explode.ogg", "static"),
    win = love.audio.newSource("sounds/win.ogg", "static")
  }
  smileyQuads = {}
  for y=0,1 do
    for x=0,1 do
      table.insert(smileyQuads,
                   love.graphics.newQuad(x*8, y*8, 8, 8, 16, 16))
    end
  end
  numberQuads = {}
  NUMBER_SCALE = 32
  for x=0,10 do
    table.insert(numberQuads,
                 love.graphics.newQuad(x*NUMBER_SCALE, 0, NUMBER_SCALE, NUMBER_SCALE, NUMBER_SCALE*11, NUMBER_SCALE))
  end
  beginGame()
end

function beginGame()
  MINE = -1

  FLAGGED_WRONG = -2
  FLAGGED = -1
  COVERED = 0
  VISIBLE = 1

  --[[
    -1: Mine
    0-8: Safe (revealed, value is number of mines nearby)
  ]]--
  map = {}
  revealed = {}
  for row=0,WIDTH-1 do
    table.insert(map, {})
    table.insert(revealed, {})
    for i=1,HEIGHT do
      map[#map][i] = 0
      revealed[#revealed][i] = 0
    end
  end

  mines = {}
  for i=1,NUM_MINES do
    x = love.math.random(WIDTH)
    y = love.math.random(HEIGHT)
    while map[x][y] == MINE do
      x = love.math.random(WIDTH)
      y = love.math.random(HEIGHT)
    end
    map[x][y] = MINE
  end

  for x=1,WIDTH do
    for y=1,HEIGHT do
      if map[x][y] ~= -1 then
        count = 0
        for ox=x-1,x+1 do
          for oy=y-1, y+1 do
            if not (ox < 1 or ox > WIDTH or oy < 1 or oy > HEIGHT) then
              if map[ox][oy] == MINE then
                count = count + 1
              end
            end
          end
        end
        map[x][y] = count
      end
    end
  end
  smileyLook = 1

  GAMESTATE_ALIVE = 1
  GAMESTATE_WIN = 2
  GAMESTATE_DEAD = 3

  gameState = GAMESTATE_ALIVE
  timer = 0
end

function ZeroSpread(x, y)
  dirs = {}
  for i=-1, 1 do
    for j=-1, 1 do
      if i ~= 0 or j ~= 0 then
        table.insert(dirs, {i, j})
      end
    end
  end

  for _, dir in pairs(dirs) do
    x2 = x + dir[1]
    y2 = y + dir[2]
    if not (x2 < 1 or x2 > WIDTH or y2 < 1 or y2 > HEIGHT) then
      if revealed[x2][y2] ~= 1 then
        revealed[x2][y2] = 1
        if map[x2][y2] == 0 then
          ZeroSpread(x2, y2)
        end
      end
    end
  end
end

function xor(a,b)
  if a and b then
    return false
  elseif a or b then
    return true
  else
    return false
  end
end

function HasWon()
  for x=1,WIDTH do
    for y=1,HEIGHT do
      if xor(map[x][y] == -1, revealed[x][y] == -1) then
        return false
      end
    end
  end
  return true
end

function Lose ()
  sounds.explode:play()
  gameState = GAMESTATE_DEAD
  for i=1,WIDTH do
    for j=1,HEIGHT do
      if revealed[i][j] == COVERED then
        revealed[i][j] = VISIBLE
      elseif revealed[i][j] == FLAGGED and map[i][j] ~= MINE then
        revealed[i][j] = FLAGGED_WRONG
      end
    end
  end
end

function love.mousereleased(x, y, button, isTouch)
  if gameState == GAMESTATE_ALIVE then
    if y >= HEADER_SIZE then
      cellX = math.floor(x / SCALE)+1
      cellY = math.floor((y-HEADER_SIZE) / SCALE)+1
      if button == 1 and revealed[cellX][cellY] ~= -1 then
        revealed[cellX][cellY] = 1
        if map[cellX][cellY] == 0 then
          ZeroSpread(cellX, cellY)
        end
        if map[cellX][cellY] == -1 then
          Lose()
        end
      elseif button == 2 then
        if revealed[cellX][cellY] == 0 then
          revealed[cellX][cellY] = -1
        elseif revealed[cellX][cellY] == -1 then
          revealed[cellX][cellY] = 0
        end
        if HasWon() then
          gameState = GAMESTATE_WIN
          sounds.win:play()
          for i=1,WIDTH do
            for j=1,HEIGHT do
              if revealed[i][j] == 0 then
                revealed[i][j] = 1
              end
            end
          end
        end
      end
    end
  elseif gameState == GAMESTATE_WIN or gameState == GAMESTATE_DEAD then
    beginGame()
  end
end

function love.update(dt)
  if gameState == GAMESTATE_ALIVE then
    timer = timer + dt
  end
  --smileyLook = 1 + math.floor(timer)%4
  mouseX, mouseY = love.mouse.getPosition()
  if gameState == GAMESTATE_ALIVE then
    if love.mouse.isDown(1) and mouseY >= HEADER_SIZE then
      smileyLook = 2
    else
      smileyLook = 1
    end
  elseif gameState == GAMESTATE_WIN then
    smileyLook = 3
  else
    smileyLook = 4
  end
  mouseX, mouseY = love.mouse.getPosition()

  x = math.floor(mouseX / SCALE)+1
  y = math.floor((mouseY-HEADER_SIZE) / SCALE)+1
  if (love.mouse.isDown(1) and love.mouse.isDown(2)) or
     love.mouse.isDown(3) then
    if revealed[x][y] == VISIBLE then
      local count = 0
      for ox=x-1,x+1 do
        for oy=y-1, y+1 do
          if not (ox < 1 or ox > WIDTH or oy < 1 or oy > HEIGHT) then
            if revealed[ox][oy] == FLAGGED then
              count = count + 1
            end
          end
        end
      end
      if count == map[x][y] then
        for ox=x-1,x+1 do
          for oy=y-1, y+1 do
            if not (ox < 1 or ox > WIDTH or oy < 1 or oy > HEIGHT) then
              if revealed[ox][oy] ~= FLAGGED then
                revealed[ox][oy] = VISIBLE
                if map[ox][oy] == MINE then
                  Lose()
                elseif map[ox][oy] == 0 then
                  ZeroSpread(ox,oy)
                end
              end
            end
          end
        end
      end
    end
  end
  flaggedCount = 0
  for x=1,WIDTH do
    for y=1,HEIGHT do
      if revealed[x][y] == FLAGGED then
        flaggedCount = flaggedCount + 1
      end
    end
  end
end

function CustomPrint(x,y,n,pad)
  for place=1,pad do
  	if n < 0 then
  	  if place == 1 then
  	  	number = 11
  	  else
  	  	number = math.floor(math.abs(n)/(10^(pad-place))) % 10 + 1
  	  end
  	else
  	  number = math.floor(n/(10^(pad-place))) % 10 + 1
  	end
    love.graphics.draw(images.numbers, numberQuads[number],
                       (x+((place-1)/1.75))*SCALE, y*SCALE,
                       0, SCALE/48, SCALE/48)
    --print((x+((place-1)/1.75))*SCALE, y*SCALE,math.floor(n/(10^(pad-place))) % 10)
  end
end

function love.draw()
  --[[for x=0,7 do
    for y=0,7 do
    end
  end]]--
  mouseX, mouseY = love.mouse.getPosition()

  mouseCellX = math.floor(mouseX / SCALE)
  mouseCellY = math.floor((mouseY-HEADER_SIZE) / SCALE)

  for x=0,WIDTH-1 do
    for y=0,HEIGHT-1 do
      local tile = map[x+1][y+1]
      local tileRevealed = revealed[x+1][y+1]
      if tileRevealed == COVERED then
        love.graphics.draw(images.covered, x*SCALE, y*SCALE+HEADER_SIZE,
                           0, SCALE/64, SCALE/64)
      elseif tileRevealed == FLAGGED then
        love.graphics.draw(images.flagged, x*SCALE, y*SCALE+HEADER_SIZE,
                          0, SCALE/64, SCALE/64)
     elseif tileRevealed == FLAGGED_WRONG then
       love.graphics.draw(images.flagged_wrong, x*SCALE, y*SCALE+HEADER_SIZE,
                         0, SCALE/64, SCALE/64)
      else
        if tile == MINE then
          love.graphics.draw(images.mine, x*SCALE, y*SCALE+HEADER_SIZE,
                             0, SCALE/64, SCALE/64)
        else
          love.graphics.draw(images.uncovered, x*SCALE, y*SCALE+HEADER_SIZE,
                             0, SCALE/64, SCALE/64)
          if tile >= 1 then
            love.graphics.setColor(NUMBER_COLORS[tile][1]/255,
                                   NUMBER_COLORS[tile][2]/255,
                                   NUMBER_COLORS[tile][3]/255)
            love.graphics.draw(images.numbers, numberQuads[tile+1],
                               (x+(11/32))*SCALE, (y+(8/32))*SCALE+HEADER_SIZE,
                               0, SCALE/64, SCALE/64)
            love.graphics.setColor(1,1,1)
          end
        end
      end
      if (love.mouse.isDown(1) and love.mouse.isDown(2)) or
         love.mouse.isDown(3) then
        if math.abs(x-mouseCellX) <= 1 and math.abs(y-mouseCellY) <= 1 then
          love.graphics.setColor(255,255,255)
        else
          love.graphics.setColor(0,0,0)
        end
      else
        love.graphics.setColor(0,0,0)
      end
      love.graphics.rectangle("line", x*SCALE+0.5, y*SCALE+HEADER_SIZE+0.5,
                              SCALE-1, SCALE-1)
      love.graphics.setColor(1,1,1)
    end
  end
  love.graphics.draw(images.smiley, smileyQuads[smileyLook],
                     (WIDTH-2)*SCALE/2, (HEADER_SIZE-SCALE)/2,
                     0, SCALE/8, SCALE/8)
  CustomPrint(3/8,3/8,math.floor(timer),3)
  CustomPrint((WIDTH+0.75)/2,3/8,NUM_MINES-flaggedCount,3)
  --love.graphics.print(timer_format:format(math.floor(timer)), timer_font,
  --                    SCALE/4, SCALE/8 - SCALE/4)
end
