---------------function Begin---------------
local function GetSeedSlotNum()
  for i=1,16 do
    local data=turtle.getItemDetail(i)
    if data then
	  local seed = string.format("%s_seeds",crop)
	  if string.find(data.name,seed) then
        return i
      end
    end
  end
  return false
end  
 

function SingleBlockFarm()
  turtle.select(15)
  local success,data = turtle.inspectDown()
  if success then
    if data.metadata==7 and string.find(data.name,crop) then 
	  turtle.digDown()
    end
  else
    turtle.digDown()
  end
  
  local seedSlotNum=GetSeedSlotNum()
  if seedSlotNum then
     turtle.select(seedSlotNum)
     turtle.placeDown()
  end
end


function LineFarm()
   for i=1,farmLenth-1 do
	 SingleBlockFarm()
	 Forward()
     recordData.curBlockNum = recordData.curBlockNum +1
     Record()
   end
   SingleBlockFarm()
end

function TurnRound()
   turtle.turnLeft()
   turtle.turnLeft()
end


----1:forward 2:back 3:left 4:right
function ToLeftNewLine()
   recordData.turtleFace = 2
   Record()
   turtle.turnLeft()
   recordData.turtleFace = 3
   Record()
   Forward()
   recordData.curBlockNum = recordData.curBlockNum + 1
   Record()
   turtle.turnLeft()
   recordData.turtleFace = 1
   Record()
end

function ToRightNewLine()
  recordData.turtleFace = 1
  Record()
  turtle.turnRight()
  recordData.turtleFace = 3
  Record()
  Forward()
  recordData.curBlockNum = recordData.curBlockNum +1
  Record()
  turtle.turnRight()
  recordData.turtleFace = 2
  Record()
 end
 
 

local function CheckCropInBackpack()   
     for i=1,16 do
        local data=turtle.getItemDetail(i)
        if data then
          if string.sub(data.name,11)==crop then
          return true
          end
        end
     end
     return false
end


function Forward()
  while true do
    if turtle.detect() then
	  sleep(2)
	else
	  break
	end
  end
  turtle.forward()
end


function Record()
  local h = fs.open("record","w")
  h.writeLine(tostring(recordData.curBlockNum))--当前所在块数 相对起点
  h.writeLine(tostring(recordData.turtleFace))--从起点所看到乌龟的面
  h.writeLine(recordData.isXBackUnload)--是否正在返回卸货区
  h.writeLine(tostring(recordData.xBackFirstBlockLenth))--水平方向返回到起点的块数
  h.writeLine(recordData.isOnUnloadBlock)--是否在卸货区
  h.writeLine(recordData.isUporDown)
  h.close()
end


function PowerCutBackOrigin1()

  print("recordData.curBlockNum:",recordData.curBlockNum)
  print("recordData.turtleFace:",recordData.turtleFace)

  local curLine =recordData.curBlockNum/farmLenth   ---根据记录的块数计算当前乌龟所在行数
  curLine = math.floor(curLine)
      
  if recordData.curBlockNum%farmLenth~=0 then ---所在块数/农场长度有余则行数加1
  curLine = curLine +1
  end
  print("curLine:",curLine)


  local yBackFirstBlockLenth = recordData.curBlockNum - (curLine-1)*farmLenth --计算乌龟需返回农场的长度
  if curLine%2==0 then  --如果行数为偶数 则需返回的长度为15-yBackFirstBlockLenth
    yBackFirstBlockLenth = farmLenth - yBackFirstBlockLenth
  else
    yBackFirstBlockLenth = yBackFirstBlockLenth - 1
  end
  print("yBackFirstBlockLenth:",yBackFirstBlockLenth)

  if     recordData.turtleFace=="2" then TurnRound()  --让乌龟面对原点
  elseif recordData.turtleFace=="3" then turtle.turnLeft() 
  elseif recordData.turtleFace=="4" then turtle.turnRight()
  end

  ---back to parallel lines of first block
  print("back to parallel lines of first block")
  if recordData.isUporDown==0 then turtle.up() end
  for i=1,yBackFirstBlockLenth do---横向返回第一块平行线
    turtle.forward()
  end
  
  ---back to first block
  print("back to first block")
  if curLine~=1 then --返回第一块
    turtle.turnLeft()
  end  
  for i=1,curLine-1 do 
    turtle.forward()
  end
  
  ---back to origin
  print("back to origin")
  if curLine~=1 then
    turtle.turnRight()  --返回原点
  end
  turtle.forward()
  recordData.curBlockNum = 0
  Record()
  TurnRound()
  turtle.down()
end

function PowerCutBackOrigin2() --recordData.isXBackUnload==true

  if recordData.turtleFace=="2" then turtle.turnRight()
  elseif recordData.turtleFace=="1" then turtle.turnLeft()
  end
  for i=1,recordData.xBackFirstBlockLenth do
    Forward()
  end
  turtle.turnRight()
  Forward()
  TurnRound()
  turtle.down()
  recordData.isXBackUnload = false
  recordData.turtleFace    = 2
  Record()
end

function PowerCutBackOrigin3()--recordData.isOnUnloadBlock==true
   if recordData.turtleFace=="1" then turtle.turnLeft() end
   Forward()
   turtle.turnLeft()
   recordData.isOnUnloadBlock = false
   recordData.turtleFace      = 2
   Record()
end


function AutoFarm()
  --big while
  while not turtle.detectUp() do
    ---down to horizon
	print("down to horizon")
    while not turtle.detectDown() do 
      turtle.down()
    end
	recordData.isUporDown = 0
	Record()
	if recordData.turtleFace=="4" then
	  turtle.turnLeft()
	  recordData.turtleFace=2
	  Record()
	end
	
	print("origin up")
    turtle.up()
	recordData.isUporDown = 1
	Record()
	print("Start")
    Forward()
	recordData.curBlockNum = recordData.curBlockNum + 1
	recordData.turtleFace  = 2
	Record()
 
    ---1-n line plant
    for i=1,farmLineNum-1 do      
	  print("The ",i," line plant")
      LineFarm()
      local data=i%2
      if  data~=0 then ToLeftNewLine()
      else
        ToRightNewLine()
      end
    end

    ---last line plant <
	print("last line plant")
    LineFarm()
	
	recordData.xBackFirstBlockLenth = farmLineNum - 1
    local value=farmLineNum%2
    if value==0 then     ---为偶数行
	  recordData.isXBackUnload = true
	  recordData.curBlockNum = 0
	  Record()
      turtle.turnLeft()
    else                 ---为奇数行
      for i=1,farmLenth-1 do
        turtle.back()
		recordData.curBlockNum = recordData.curBlockNum - 1
		Record()
      end
	  recordData.isXBackUnload = true
	  recordData.curBlockNum = 0
	  Record()
	  turtle.turnRight()
    end
	recordData.turtleFace = 4
	Record()

   ---back to unload
   
   print("back to unload!")
   for i=1,farmLineNum-2 do
     Forward()
	 recordData.xBackFirstBlockLenth = recordData.xBackFirstBlockLenth - 1
	 Record()
   end
   
   ----unload wheat
   print("unload wheat")
   turtle.turnRight()
   recordData.turtleFace=1
   Record()
   Forward()          -- to origin side
   recordData.isXBackUnload        = false
   recordData.xBackFirstBlockLenth = 0
   recordData.isOnUnloadBlock      = true
   Record()
   turtle.down()
   recordData.isUporDown = 0
   Record()
   while true do
     local result = CheckCropInBackpack()
     if not result then break end
     sleep(0)
   end
   turtle.up()
   recordData.isUporDown = 1

   ---back to origin
   print("back to origin")
   turtle.turnLeft()
   recordData.turtleFace=4
   Record()
   Forward()
   recordData.isOnUnloadBlock = false
   recordData.curBlockNum = 0
   Record()

   ---Restore default settings
   print("Restore default settings")
   turtle.turnLeft()
   recordData.turtleFace=2
   Record()
   turtle.down()
   recordData.isUporDown = 0
   turtle.select(1)
   
   
   ---sleep
   print("sleep 30s")
   sleep(30)
  end
end



function main()
  if fs.exists("record") then
    local h=fs.open("record","r")
    recordData.curBlockNum     = h.readLine()   ---当前所在块数
    recordData.turtleFace      = h.readLine()    ---1:乌龟正面面对原点 2：乌龟背面面对原点 3：左侧面面对原点 4：右侧面面对原点
	recordData.isXBackUnload   = h.readLine()
	recordData.xBackFirstBlockLenth = h.readLine()
    recordData.isOnUnloadBlock = h.readLine()
    h.close()
  end
  
  if tonumber(recordData.curBlockNum)~=0 and recordData.isXBackUnload=="false" and recordData.isOnUnloadBlock=="false" then
    print("PowerCutBackOrigin1!")
    PowerCutBackOrigin1()
	sleep(2)
  elseif recordData.isXBackUnload=="true" and recordData.isOnUnloadBlock=="false" then
    print("PowerCutBackOrigin2!")
    PowerCutBackOrigin2()
	sleep(2)
  elseif recordData.isOnUnloadBlock=="true" and recordData.isXBackUnload=="false" then
    print("PowerCutBackOrigin3!")
    PowerCutBackOrigin3()
	sleep(2)
  end
  
  AutoFarm()
end           
---------------function end----------------
----global parameter
crop         = "wheat"
farmLenth    = 15
farmLineNum  = 11

recordData = {
              curBlockNum  = 0,
              turtleFace   = 2,  ---Relative Origin1:forward  2:back 3:left 4:right
			  sXBackUnload = false,
			  xBackFirstBlockLenth = 0,
			  isOnUnloadBlock = false ,
			  isUporDown      = 0
			 }
			 




main()



