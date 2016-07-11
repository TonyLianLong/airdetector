require("i2c_transfer")
_G.plugin = {}
l = file.list()
for k,v in pairs(l) do
if string.find(k,"_plugin.lua$") then
pluginName = string.sub(k,0,-5);
print("name:"..pluginName..", size:"..v)
plugin[pluginName] = require(pluginName)
if plugin[pluginName].init() then
print("Loaded")
else
print("Error")
end
end
end
--print(plugin[1].getData())
