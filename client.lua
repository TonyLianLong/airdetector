local path
local client_version="1.0"

require("pluginloader")
require("beep")

function upload_data()
    if wifi.sta.getip() and _G.server_ip then
        print("Upload data to ".._G.server_ip)
        dataString = "{"
        for k,v in pairs(_G.plugin) do
            v.prepareData()
        end
        tmr.delay(500000)
        for k,v in pairs(_G.plugin) do
            thisDataTable = v.getData()
            for key,thisData in pairs(thisDataTable) do
                if dataString == "{" then
                    dataString = dataString.."\""..key.."\":"..thisData
                else
                    dataString = dataString..",\""..key.."\":"..thisData
                end
            end
        end
        dataString = dataString.."}"
        print("Data string: "..dataString)
        srv=net.createConnection(net.TCP, false) 
		srv:on("receive", function(sck, pl)
            if double_debug then
			    print(pl)
            end
			if pl then
				lastchar = string.sub(pl,-1,-1)
				if lastchar == "s" then
					print("Succeed")
                elseif lastchar == "b" then
                    beep()
				else
					print(pl)
				end
			end
			sck:close()
		end)
		srv:on("disconnection", function(sck, c)
			print("disconnected")
		end)
		srv:on("sent", function(sck, c)
			print("sent")
		end)
		srv:on("connection", function(sck, c)
			print("connected")
			path = "/get.php?command=s&box_code="..boxcode.."&access_id="..access_id.."&&data="..dataString
			sck:send("GET "..path.." HTTP/1.1\r\nHost: "..domain.."\r\n".."Connection: keep-alive\r\nAccept: */*\r\nClient-Version:"..client_version.."\r\n\r\n")
		end)
		srv:on("reconnection", function(sck, c)
			print("reconnected")
		end)
        srv:connect(80,_G.server_ip)
    end
end
conn=net.createConnection(net.TCP, false) 
function save_ip(conn,ip)
    _G.server_ip = ip
    conn:close()
    tmr.alarm(1, update_interval, tmr.ALARM_AUTO, upload_data)
    upload_data()
    
end
conn:dns(domain,save_ip)
