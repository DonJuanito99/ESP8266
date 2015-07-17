function RxPl(conn,pl)
		--print("Rx:"..#pl.."B")
		--print(pl)
		if (pl == nil) then return end
		if (#pl == 0) then return end
		
		if (plFound == false) then
			for a,b,c,d,e in string.gmatch(pl, 'Date: (%a+), (%d+) (%a+) (%d+) (%d+:%d+)') do -- "Date: Fri, 10 Jul 2015 10:37:22 GMT"
				if (a == nil or b == nil or c == nil or d == nil) then
					updDOW = "?"
					updDate = "?/?"
					updHM = "??:?? GMT"
				else
					updDOW = string.lower(a)
					if (updDOW == nil) then updDOW="?" end
					updDate = b.."/"..c
					if (tonumber(UTC_OFFSET) < 0) then
						updHM = e.." "..UTC_OFFSET.."h"
					else
						updHM = e.." +"..UTC_OFFSET.."h"
					end
				end
			end
			print("Dat:"..updDOW..", "..updDate.." "..updHM)
			if (string.find(pl,"\r\n\r\n") ~= nil) then
				pl = string.sub(pl,string.find(pl,"\r\n\r\n") + 4)
				plFound = true
			end
		end
		
		if (plFound == true) then
			if (pv ~= nil) then pl = pv..pl end
			pv = nil
			if (it < 41) then
				local pa = false
				while (c < 4) and (#pl > 10) do
					if (c==1) then
						if (pa == true) then
							--print("*Reentry*")
							break
						end
						d, f, m, v = string.find(pl, '("temp"):(%d+)')
						if (v ~= nil) then
							tempt[it] = v
							pl = pl:sub(f)
							c = c + 1
						else
							pv = pl:sub(13-1,#pl)
							break
						end
					end
					if (c==2) then
						d, f, m, v = string.find(pl, '("icon"):"(%w+)"')
						if (v ~= nil) then
							xbm_data[it] = string.sub(v,1,3)
							pl = pl:sub(f)
							c = c + 1
						else
							pv = pl:sub(12-1,#pl)
							break
						end
					end
					if (c==3) then
						d, f, m, v = string.find(pl, '("dt_txt"):"(%w+-%w+-%w+ %w+:%w+)')
						if (v ~= nil) then
							timet[it] = v
							pl = pl:sub(f)
							it = it + 1
							pv = nil
							pa = false
							c = 1
						else
							pv = pl:sub(26-1,#pl)
							break
						end
					end
					if (c<1) then
						print("Err! c="..c)
						node.restart()
						while true do end
					end
				end
			end
		end
		d = nil
		f = nil
		m = nil
		v = nil
		pa = nil
		pl = nil
		collectgarbage()
end

function utcCorrect(month, day, hour)
	month = tonumber(month)
	day = tonumber(day)
	hour = tonumber(hour) + tonumber(UTC_OFFSET)
	if (hour > 23) then
		hour = hour - 24
		day = day + 1
		if (month==2) then
			if (day>28) then
				day=1
				month=3
			end
		elseif (month==4 or month==6 or month==9) then
			if (day>30) then
				day=1
				month=month+1
			end
		elseif (day>31) then
			day=1
			month=month+1
		end
		if (month>12) then
			month=1
		end
	end
	month = tostring(month)
	if (#month < 2) then month = "0"..month end
	day = tostring(day)
	if (#day < 2) then day = "0"..day end
	hour = tostring(hour)
	if (#hour < 2) then hour = "0"..hour end
	return month, day, hour
end

function updateWeather()
	print("B:"..node.heap())
	tmr.stop(1) -- Stop display updates
	tmr.delay(300) -- allow time for display to terminate
	pv = ""
	plFound = false
	it = 1
	c = 1
	timet = {}
	datet = {}
	tempt = {}
	xbm_data = {}
    local conn=net.createConnection(net.TCP, 0)
    conn:on("receive", RxPl)
	conn:on("disconnection", function(conn) 
        conn:close()
        conn = nil
		print("Disconnected")
		c = nil
		pv = nil
		collectgarbage()
		it = it - 1
		print("it="..it)
		if (it > 3) then
			-- read icons
			for i=1,it do
				if (file.open(xbm_data[i]..".MONO", "r") == nil) then
					file.open("xxx.MONO", "r")
					print("xbm:".."xxx.MONO")
				end
				xbm_data[i] = file.read()
				file.close()
			end
			-- convert time/date
			for i=1,it do
				for m, j, h, mi in string.gmatch(timet[i], '%w+-(%w+)-(%w+) (%w+):(%w+)') do
					m, j, h = utcCorrect(m, j, h)
					timet[i] =  h..":"..mi
					datet[i] = j.."/"..m
				end
			end
		
			plFound = nil
			c = nil
			collectgarbage("collect")
			ida = 1
			idb = ida + step
			idc = idb + step
			curstep = -1
			steps = (it / step) - 2
			if (steps < 1) then steps = 1 end
			idw = 128 / steps
			tmr.alarm(0, 60 * 60000, 0, CheckIP) -- 60min
			--tmr.alarm(0, 2 * 60000, 0, CheckIP) -- 2min *** DEBUG ONLY ***
			tmr.alarm(1, 5000, 1, ScrollDisp)
			ScrollDisp()
		else
			print("No forecast!")
			tmr.alarm(0, 5000, 0, CheckIP) -- 5s
		end
		print("A:"..node.heap())
    end )
    
    conn:connect(80,ipow)
    conn:send("GET /data/2.5/forecast?q="..CITY.."&units=metric&lang=fr&APPID="..APPID
      .." HTTP/1.1\r\n"
      .."Host: api.openweathermap.org\r\n"
      .."Connection: close\r\n"
      .."Accept: */*\r\n"
      .."User-Agent: Mozilla/4.0 (compatible; esp8266 Lua; Windows NT 5.1)\r\n"
      .."\r\n")
    conn = nil
end

function FontPos(fp)
     disp:setFont(fp)
     disp:setFontRefHeightExtendedText()
     disp:setDefaultForegroundColor()
     disp:setFontPosTop()
end

function drawWeather()
	local p = 0
	
	disp:firstPage()
	repeat
		if (idc ~=nil) then
			disp:drawXBM( 6 + 84, 0, 30, 30, xbm_data[idc] )
			p = 1 + (42 - #timet[idc] * 6) / 2
			disp:drawStr(p + 84, 43, timet[idc])
		end
		if (idb ~=nil) then
			disp:drawXBM( 6 + 42, 0, 30, 30, xbm_data[idb] )
			p = 1 + (42 - #timet[idb] * 6) / 2
			disp:drawStr(p + 42, 43, timet[idb])
		end
		if (ida ~=nil) then
			disp:drawXBM( 6, 0, 30, 30, xbm_data[ida] )
			p = 1 + (42 - #timet[ida] * 6) / 2
			disp:drawStr(p, 43, timet[ida])
		end
		FontPos(u8g.font_9x15)
		if (idc ~=nil) then 
			p = 1 + (42 - (#tempt[idc]+1) * 9) / 2
			disp:drawStr(p + 84, 30, tempt[idc].."°")
		end
		if (idb ~=nil) then 
			p = 1 + (42 - (#tempt[idb]+1) * 9) / 2
			disp:drawStr(p + 42, 30, tempt[idb].."°")
		end
		if (ida ~=nil) then 
			p = 1 + (42 - (#tempt[ida]+1) * 9) / 2
			disp:drawStr(p , 30, tempt[ida].."°")
		end
		FontPos(u8g.font_6x10)

		if (idb == nil) then
			-- a
			p = 1 + (42 - #datet[ida] * 6) / 2
			disp:drawStr(p , 43, datet[ida])
		elseif (idc == nil) then
				if (datet[ida]:sub(1,2) ~= datet[idb]:sub(1,2)) then
					--  a ~= b
					p = 1 + (42 - #datet[ida] * 6) / 2
					disp:drawStr(p , 51, datet[ida])
					p = 1 + (42 - #datet[idb] * 6) / 2
					disp:drawStr(p + 42, 51, datet[idb])
					disp:drawVLine( 42, 0, 60)
				else
					-- a == b
					p = 1 + (42 - #datet[ida] * 6) / 2
					disp:drawStr(p+21 , 51, datet[ida])
				end
		elseif (datet[ida]:sub(1,2) ~= datet[idb]:sub(1,2)) then
			-- a ~= b ...
			p = 1 + (42 - #datet[ida] * 6) / 2
			disp:drawStr(p , 51, datet[ida])
			disp:drawVLine( 42, 0, 60)
			if (datet[idb]:sub(1,2) ~= datet[idc]:sub(1,2)) then
				-- a ~= b ~= c
				p = 1 + (42 - #datet[idb] * 6) / 2
				disp:drawStr(p + 42, 51, datet[idb])
				p = 1 + (42 - #datet[idc] * 6) / 2
				disp:drawStr(p + 84, 51, datet[idc])
				disp:drawVLine( 84, 0, 60)
			else
				-- a ~= b == c
				p = 1 + (42 - #datet[idb] * 6) / 2
				disp:drawStr(p + 42+21, 51, datet[idb])
			end
		else
			-- a == b ...
			if (datet[idb]:sub(1,2) ~= datet[idc]:sub(1,2)) then
				-- a == b ~= c
				p = 1 + (42 - #datet[ida] * 6) / 2
				disp:drawStr(p+21 , 51, datet[ida])
				p = 1 + (42 - #datet[idc] * 6) / 2
				disp:drawStr(p + 84, 51, datet[idc])
				disp:drawVLine( 84, 0, 60)
			else
				-- a == b == c
				p = 1 + (42 - #datet[ida] * 6) / 2
				disp:drawStr(p + 42, 51, datet[ida])
			end
		end
		
		disp:drawBox(idp, 61, idw, 3) -- Cursor
		disp:drawVLine( 0, 61, 3)
		disp:drawHLine( 0, 62, 128)
		disp:drawVLine( 127, 61, 3)
	until disp:nextPage() == false
	p = nil
end

function drawInfo()
	disp:firstPage()
	repeat
		disp:drawFrame(0, 0, 128, 64)
		disp:drawFrame(1, 1, 127, 63)
		disp:setScale2x2()
		local p = 3 + (60 - (#updDOW + #updDate + 1) * 6) / 2
		disp:drawStr(p, 6, updDOW.." "..updDate)
		p = 3 + (60 - #updHM * 6) / 2
		disp:drawStr(p, 20, updHM)
		disp:undoScale()
		p = nil
	until disp:nextPage() == false
end

function ScrollDisp()
	if (curstep < 0) then
		curstep = curstep + 1
		drawInfo()
		return
	end
	idp = idw * curstep

	drawWeather()

	-- Scroll to next disp
	curstep = curstep + 1
	ida = ida + step
	idb = idb + step
	idc = idc + step
	if (idc > it) then
		ida = 1
		idb = ida + step
		idc = idb + step
		curstep = 0
	end
end

function CheckIP()
-- Get forecast
   ip = wifi.sta.getip()
   if ip=="0.0.0.0" or ip==nil then
      print("No IP!...") 
	  tmr.alarm(0, 10000, 0, CheckIP) -- 10s
   else
      print("Loading weather...")
      updateWeather()
   end
end

step = 2 -- Step between displayed forecasts
steps = 1
updDOW = "?" -- Day of week
updDate = "?/?"
updHM = "??:??"
curstep = 0
CheckIP()
