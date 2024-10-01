local fs = require('filesystem')
local component = require('component')
local event = require('event')
local hg = require('hg-utils')

local version = 1.0
local cfgFile = '/usr/lib/ans-client.cfg'

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

local modem = component.modem
local ans = {}

local function broadcast(data)
    modem.open(config['port'])
    modem.broadcast(config['port'], hg.util.encode(data))
end

local function catchError(message)
    if message['error'] then
        hg.error(message['message'])
    end
end

local function pullMessage()
    local _, _, address, _, _, encodedMessage = event.pull('modem_message')
    result, message = hg.util.decode(encodedMessage)

    modem.close(config['port'])

    if result then
        catchError(message)

        return message
    end

    return nil
end

function ans.version()
    return version
end

function ans.register(name)
    local response = false

    broadcast({ action = 'register', name = name, version = version })

    local message = pullMessage()

    if message and message['action'] == 'register' then
            found = message.found
            response = message.response
        end

    return response
end

function ans.lookup(name)
    local found = false
    local response = nil

    broadcast({ action = 'lookup', name = name, version = version })

    local message = pullMessage()

    if message and message['action'] == 'lookup' then
        found = message.found
        response = message.response
    end

    return found, response
end

function ans.rlookup(address)
    local found = false
    local response = nil

    broadcast({ action = 'rlookup', address = address, version = version })

    local message = pullMessage()

    if message and message['action'] == 'rlookup' then
        found = message.found
        response = message.response
    end
    
    return found, response
end

return ans