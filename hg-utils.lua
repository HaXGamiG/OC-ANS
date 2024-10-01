local computer = require('computer')
local serial = require('serialization')

local hg = {}
hg.file = {}
hg.util = {}

function hg.error(data)
    error(data .. "\n")
    computer.beep()
end

-- file

function hg.file.read(loc)
    local file = io.open(loc)
    local data = file:read("*all")

    file:close()

    return data
end

function hg.file.write(file, data, overwrite)
    local tFile = assert(io.open(file, overwrite and "w" or "a"))

    tFile:write(data)
    tFile:close()

    return true
end

-- util

function hg.util.encode(data)
    return serial.serialize(data)
end

function hg.util.decode(data)
    return pcall(serial.unserialize, data)
end

return hg