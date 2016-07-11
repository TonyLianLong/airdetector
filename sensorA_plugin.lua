local moduleName = ... 
    local M = {}
    _G[moduleName] = M
    local index = 0
    
    --default value
    local data={}

    -- initialize plugin
    function M.init()
      print(moduleName.." inited!")
      return true
    end
    -- prepare data
    function M.prepareData()
        i2c_transfer.select(0x8,0,0)
        --for i=0,3,1 do
            for j=0,2,1 do --retry
                if(i2c_transfer.prepareDataForAll(0x8) == false) then
                    -- try init again because device can be removed
                    M.init()
                else
                    return true
                end
            end
            return false
        --end
    end
    --get data from sensor
    function M.getData()
      i2c_transfer.select(0x8,0,0)
      print("Get data")
      for i=0,3,1 do
        for j=0,2,1 do --retry
            data[i+1] = i2c_transfer.read_data(0x8,i)
            if(data[i+1]) ~= nil then
                break
            end
        end
      end
      return {["0"]=data[1],["1"]=data[2],["2"]=data[3],["3"]=data[4]}
    end

    return M
