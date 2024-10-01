local fs = require('filesystem')
local component = require('component')
local event = require('event')
local hg = require('hg-utils')

local version = 1.0
local cfgFile = '/usr/bin/ans-server.cfg'

if not component.isAvailable('modem') then
    hg.error('You need to add a Wireless Network card (tier 1 or 2) !')
    return
end

if not fs.exists(cfgFile) then
    hg.error('The configuration file does not exist ! (Path : ' .. cfgFile .. ')')
    return
end

local configDecoded, config = hg.util.decode(hg.file.read(cfgFile))

if not configDecoded then
    hg.error('The configuration could not be decoded, please check the syntax')
    return
end

if version ~= config['version'] then
    hg.error('The configuration file and the program must have the same version to work !')
    return
end

if not fs.exists(config['ansDir']) then
    fs.makeDirectory(config['ansDir'])
end

local pathToAns = config['ansDir'] .. '/' .. config['ansFile']

local modem = component.modem
local gpu = component.gpu
local ans = {}
local rans = {}

local width, height = gpu.getResolution()
local colors = {
    bg = {
        default = 0x000000,
        border = 0x595857
    },
    txt = {
        default = 0xffffff
    }
}

modem.open(config['port'])

-- function

local function send(address, data)
    modem.send(address, config['port'], hg.util.encode(data))
end

local function register(address, name)
    ans[name] = address
    rans[address] = name

    hg.file.write(pathToAns, hg.util.encode(ans), true)
end

local function lookup(name)
    return ans[name]
end

local function rlookup(address)
    return rans[address]
end

-- GPU

local function drawBorder(x, y, w, h, title)
    local width = w + 2
    local height = h + 2
    local titleX = math.floor(x + (width / 2) - (#title / 2))

    gpu.setBackground(colors.bg.border)

    gpu.fill(x, y, width, 1, ' ')
    gpu.fill(x, y, 1, height, ' ')
    gpu.fill(x + width - 1, y, 1, height, ' ')
    gpu.fill(x, y + height - 1, width, 1, ' ')

    gpu.set(titleX, y, title)

    gpu.setBackground(colors.bg.default)
end

local function showLog(text)
    gpu.set(3, y, text)

    y = y + 1
end

-- Load ANS

if fs.exists(pathToAns) then
    result, data = hg.util.decode(hg.file.read(pathToAns))
    if result and data ~= false then
        ans = data

        for k, v in pairs(data) do
            rans[v] = k
        end
    end
end

--

y = 3

gpu.fill(1, 1, width, height, ' ')
drawBorder(1, 1, width - 2, height - 2, '=== ANS Server (V ' .. version .. ') ===')
showLog('Server started')

while true do 
    local _, _, address, _, _, encodedMessage = event.pull('modem_message')
    local messageResult, message = hg.util.decode(encodedMessage)

    if messageResult then

        if message['version'] == nil or message['version'] ~= version then
            send(address, { error = true, message = 'The server and client do not have the same version !' })
        end

        if message['name'] ~= nil and message['name'] ~= '' then
            if message['action'] == 'register' then
                register(address, message['name'])
                send(address, { action = message['action'], response = true })
            end

            if message['action'] == 'lookup' then
                local result = lookup(message['name'])

                send(address, { action = message['action'], response = result, found = result ~= nil })
            end
        end

        if message['action'] == 'rlookup' and message['address'] ~= nil and message['address'] ~= '' then
            local result = rlookup(message['address'])

            send(address, { action = message['action'], response = result, found = result ~= nil })
        end
    end
end