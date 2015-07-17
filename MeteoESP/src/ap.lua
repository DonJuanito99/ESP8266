dofile("apInit.lc")

html = {}
html.newssid = ""
html.lastStatus = lastStatus

function listAPs_callback(t)
	if(t==nil) then
		return
	end
	local i = 1
	for k,v in pairs(t) do
		if (i==1) then html.apa = k
		elseif (i==2) then html.apb = k
		elseif (i==3) then html.apc = k
		elseif (i==4) then html.apd = k
		elseif (i==5) then html.ape = k
		elseif (i==6) then html.apf = k
		elseif (i==7) then html.apg = k
		elseif (i==8) then html.aph = k
		else html.api = k end
		i = i + 1
	end
	i = nil
	print("APs copied")
end

function listAPs()
  wifi.sta.getap(listAPs_callback)
end

function url_decode(str)
  local s = string.gsub (str, "+", " ")
  s = string.gsub (s, "%%(%x%x)",
      function(h) return string.char(tonumber(h,16)) end)
  s = string.gsub (s, "\r\n", "\n")
  return s
end

function incoming_connection(conn, payload)
  if (string.find(payload, "GET /favicon.ico HTTP/1.1") ~= nil) then
    print("GET favicon request")
  elseif (string.find(payload, "GET / HTTP/1.1") ~= nil) then
    print("GET received: Serving")
	file.open("index.html", "r")
	repeat
		line = file.readline()
		-- replace html placeholders with table values
		if (line ~= nil) then
			line = string.gsub(line, "%$(.-)%$", html)
			if (string.find(line, "%$(.-)%$") == nil) then
				conn:send(line) 
			end
		end
		tmr.wdclr()
	until line==nil
	file.close()
	print("Served")
  else
    print("POST received")
    local blank, plStart = string.find(payload, "\r\n\r\n");
    if(plStart == nil) then
      return
    end
    payload = string.sub(payload, plStart+1)
    args={}
    args.passwd=""
    -- parse all POST args into the 'args' table
    for k,v in string.gmatch(payload, "([^=&]*)=([^&]*)") do
      args[k]=url_decode(v)
    end
    if(args.ssid ~= nil and args.ntpsrv ~="" and args.CITY ~=""and args.COUNTRY ~="" and args.UTC_OFFSET ~="" and args.APPID ~="") then
		print("B:"..node.heap())
		file.remove(nf)
		file.open(nf,"w")
		file.writeline('CITY="'..args.CITY..","..args.COUNTRY..'"')
		file.writeline('UTC_OFFSET="'..args.UTC_OFFSET..'"')
		file.writeline('APPID="'..args.APPID..'"')
		file.close()
		newssid = args.ssid
		wifi.sta.config(args.ssid, args.passwd)
		print("A:"..node.heap())
    end
    if(args.reboot ~= nil) then
		print("Rebooting")
		-- cleanup
		tmr.stop(0)
		args = nil
		html = nil
		lastStatus = nil

		conn:close()
		srv:close()

		listAPs_callback = nil
		listAPs = nil
		sendPage = nil
		url_decode = nil
		incoming_connection = nil
		collectgarbage()
		node.restart()
		while (1) do end -- Force reset wait or hard reset by watchdog
    end
    conn:send('HTTP/1.1 303 See Other\n')
    conn:send('Location: /\n')
  end
  k = nil
  v = nil
end

-- start a periodic scan for other nearby APs
tmr.alarm(0, 15000, 1, listAPs) -- interval in seconds to scan for updated AP info for the user
listAPs() -- and do it once to start with
  
-- Now we set up the Web Server
srv=net.createServer(net.TCP)
srv:listen(80,function(sock)
  sock:on("receive", incoming_connection)
  sock:on("sent", function(sock) 
    sock:close()
  end)
end)
