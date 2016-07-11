    dofile("settings.lua")
    if wifi_enable then
	print("set up wifi mode")
	wifi.setmode(wifi.STATION)
	wifi.sta.config(wifi_SSID,wifi_password)
	wifi.sta.connect()
	cnt = 0
	tmr.alarm(1, 1000, 1, function() 
	    if (wifi.sta.getip() == nil) and (cnt < 20) then 
	    	print("IP unavaiable, Waiting...")
	    	cnt = cnt + 1 
	    else 
	    	tmr.stop(1)
	    	if (cnt < 20) then print("Config done, IP is "..wifi.sta.getip())
                if not safemode then
	    	        dofile("telnet.lua")
	    	        dofile("client.lua")
                else
                    print("Safe mode")
                end
	    	else
	    	    print("Wifi setup time more than 20s, Please verify wifi.sta.config() function. Then re-download the file.")
	    	end
	    end 
	 end)
    else
    print("Wifi is disabled, to enable Wifi, change settings.lua")
    end
