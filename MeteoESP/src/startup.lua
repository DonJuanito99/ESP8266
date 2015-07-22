-- Adapted from user "draco"'s source (http://www.esp8266.com/viewtopic.php?p=16176)
cC = 0
nf = "cfg.txt"
sts = {		[0]="Attente",
            [1]="Connection",
            [2]="Erreur de mot de passe",
            [3]="AP introuvable",
            [4]="Echec de connection",
            [5]="IP recue",
            [255]="Pas STATION"}

function init_i2c_display()
     -- SDA and SCL can be assigned freely to available GPIOs
     sda = 4 -- GPIO2
     scl = 3 -- GPIO0
     sla = 0x3c
     i2c.setup(0, sda, scl, i2c.SLOW)
     disp = u8g.ssd1306_128x64_i2c(sla)
end

function prepare()
     disp:setFont(u8g.font_6x10)
     disp:setFontRefHeightExtendedText()
     disp:setDefaultForegroundColor()
     disp:setFontPosTop()
end

function drawStatus(stat1, stat2, stat3)
	if (xbm_splash == nil) then return end
	disp:firstPage()
	repeat
		disp:drawXBM( 0, 0, 128, 30, xbm_splash )
		local x = 64 - (#stat1 * 3)
		if (x < 1) then x = 0 end
		disp:drawStr(x, 31, stat1)
		x = 64 - (#stat2 * 3)
		if (x < 1) then x = 0 end
		disp:drawStr(x, 42, stat2)
		x = 64 - (#stat3 * 3)
		if (x < 1) then x = 0 end
		disp:drawStr(x, 53, stat3)
	until disp:nextPage() == false
	x = nil
end

function checkStatus()
  cC = cC + 1
  if(cC >= 15) then -- seconds to wait for connect before going to AP mode
    startServer()
    return
  end
  local s=wifi.sta.status()
  print("Stat = " .. s .. " (" .. sts[s] .. ")")  
  if(s==5) then -- successful connect
    getIP()
    return
  elseif(s==2 or s==3 or s==4) then -- failed
    startServer()
    return
  end
end

function getIP()
	print("Open "..nf)
	if (file.open(nf, "r") ~= nil) then 
		print("CFG:---")
		repeat
			l = file.readline()
			if (l ~= nil) then
				--for k,v in string.gmatch(l, "(%w-)=(%C+).*") do
				--for k,v in string.gmatch(l, "(%w-)=.(%C+).+") do
				for k,v in string.gmatch(l, "(%w-)=%W?(%w*%W?%w+)") do
					print(k.."="..v)
					if (k=="CITY") then CITY=v
					elseif (k=="UTC_OFFSET") then UTC_OFFSET=v
					elseif (k=="APPID") then APPID=v end
				end
			end
		until l==nil
		print("-------")
		file.close()
	else
		print("No config file!")
	end
	sk=net.createConnection(net.TCP, 0)
	sk:dns(srvURL,launchApp)
	sk = nil
end

function launchApp(conn,ip)
  print("CITY="..CITY)
  print("UTC_OFFSET="..UTC_OFFSET)
  print("APPID="..APPID)
  drawStatus("", string.sub(CITY:match("(.-),"),1,10), "")
  tmr.delay(1500) -- allow time for a last display refresh
  ipow = ip
  lastStatus = nil
  nf = nil
  srvURL = nil
  cleanup()
  print("BSSID OK. Lancement...")
  dofile("weatherStation.lc")
end

function startServer()
  print("Serveur injoignable => AP mode")
  drawStatus("* AP Mode * - V"..vers, "SSID: Meteo-"..string.sub(wifi.ap.getmac(),13),"http://192.168.4.1/")
  lastStatus = sts[wifi.sta.status()]
  cleanup()
  dofile("ap.lc")
end

function cleanup()
  -- stop our alarm
  tmr.stop(0)
  -- nil out all global vars we created
  sts = nil
  cC = nil
  xbm_splash = nil
  vers = nil
  srvURL = nil
  -- nil out any functions we defined
  init_i2c_display = nil
  prepare = nil
  drawStatus = nil
  checkStatus = nil
  launchApp = nil
  startServer = nil
  cleanup = nil
  -- take out the trash
  collectgarbage()
  -- pause a few seconds to allow garbage to collect and free up heap
  tmr.delay(3000)
end

-- read input button (GPIO2 --100R-- GPIO0)
tmr.delay(200)
gpio.mode(3,gpio.INPUT,gpio.FLOAT)
gpio.mode(4,gpio.OUTPUT)
gpio.write(4,gpio.HIGH)
if (gpio.read(3) == 1) then
	gpio.write(4,gpio.LOW)
	if (gpio.read(3) == 0) then
		-- Go to AP mode
		--print("But!")
		cC = 100
		while (gpio.read(3) == 0) do
			tmr.wdclr()
		end -- Wait for release
		tmr.delay(200)
		gpio.mode(4,gpio.INPUT,gpio.PULLUP)
		--print("End!")
	end
end

-- make sure we are trying to connect as clients
wifi.setmode(wifi.STATION)
wifi.sta.autoconnect(1)

-- OLED display --
init_i2c_display()
prepare()
file.open("splash.MONO", "r")
xbm_splash = file.read()
file.close()
drawStatus(" - Scan - V"..vers, "Wait... Patientez...","Espere...")

-- Splash screen
tmr.delay(2000)

-- every second, check our status
tmr.alarm(0, 1000, 1, checkStatus)
