local moduleName = ... 
    local M = {}
    _G[moduleName] = M
    local id = 0
    -- initialize i2c, set pin1 as sda, set pin2 as scl
    i2c.setup(id, 1, 2, i2c.SLOW)
    function M.select(dev_addr,dev_id_high,dev_id_low)
        i2c.start(id)
        if i2c.address(id, dev_addr, i2c.TRANSMITTER) == false then
            print("No device on address "..dev_addr)
            return nil -- No device
        end
        i2c.write(0,0x02,dev_id_high,dev_id_low)
        i2c.stop(id)
        i2c.start(id)
        i2c.address(id, dev_addr, i2c.RECEIVER)
        tmr.delay(10)
        c = i2c.read(id, 17)
        print(string.byte(c,1,-1))
        i2c.stop(id)
        for i=2,17,2 do
            if (string.byte(string.sub(c,i,i+1)) + string.byte(string.sub(c,i+1,i+2))) ~= 0xFF then
                print("Data not valid")
                return nil
            end
        end
        print("selected")
        return true
    end
    function M.prepareData(dev_addr,subsensor_id)
        i2c.start(id)
        if i2c.address(id, dev_addr, i2c.TRANSMITTER) == false then
            return nil -- No device
        end
        i2c.write(0,0x0F,subsensor_id)
        i2c.stop(id)
        i2c.start(id)
        i2c.address(id, dev_addr, i2c.RECEIVER)
        tmr.delay(10)
        c = i2c.read(id, 1)
        print(string.byte(c))
        i2c.stop(id)
        if c == 0xAA then
            return true
        else
            return false
        end
    end
    function M.prepareDataForAll(dev_addr)
        i2c.start(id)
        if i2c.address(id, dev_addr, i2c.TRANSMITTER) == false then
            return nil -- No device
        end
        i2c.write(0,0x10)
        i2c.stop(id)
        i2c.start(id)
        i2c.address(id, dev_addr, i2c.RECEIVER)
        tmr.delay(10)
        c = string.byte(i2c.read(id, 1))
        print(c)
        i2c.stop(id)
        if c == 0xAA then
            return true
        else
            return false
        end
    end
    function M.read_data(dev_addr,subsensor_id)
        i2c.start(id)
        if i2c.address(id, dev_addr, i2c.TRANSMITTER) == false then
            return nil -- No device
        end
        i2c.write(0,0xF0,subsensor_id)
        i2c.stop(id)
        i2c.start(id)
        i2c.address(id, dev_addr, i2c.RECEIVER)
        tmr.delay(10)
        c = i2c.read(id, 5)
        print(string.byte(c,1,-1))
        i2c.stop(id)
        if string.byte(string.sub(c,1,2)) ~= 0xAA then
            return nil
        end
        for i=2,5,2 do
            if (string.byte(string.sub(c,i,i+1)) + string.byte(string.sub(c,i+1,i+2))) ~= 0xFF then
                print(string.byte(string.sub(c,i,i+1)))
                print(string.byte(string.sub(c,i+1,i+2)))
                return nil
            end
        end
        return string.byte(string.sub(c,2,3))*0x100+string.byte(string.sub(c,4,5))
    end
    
    return M
