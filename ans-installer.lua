local component = require('component')
local term = require('term')
local wget = loadfile('/bin/wget.lua')

local gpu = component.gpu
local width, height = gpu.getResolution()
local baseLink = 'https://raw.githubusercontent.com/HaXGamiG/OC-ANS/refs/heads/main/'

local function downloadFile(url, path)
	return wget('-fq', url, path)
end

gpu.fill(1, 1, width, height, ' ')

gpu.set(1, 1, 'ANS Installer')
gpu.set(1, 2, 'Choose what you want to install :')
gpu.set(1, 3, '1) ANS Server program')
gpu.set(1, 4, '2) ANS Client library')
gpu.set(1, 5, 'Your choice :')

term.setCursor(15, 5)

local choice = io.read()

if choice ~= '1' and choice ~= '2' then
	error('Acceptable choices are 1 and 2 only')
end

gpu.fill(1, 2, width, height, ' ')
gpu.set(1, 2, 'Downloading hg-utils.lua ...')

local result = downloadFile(baseLink .. 'hg-utils.lua', '/usr/lib/hg-utils.lua')
if not result then
	error('Error downloading hg-utils.lua file')
end

gpu.set(1, 3, 'hg-utils.lua download completed')

if choice == '1' then
	gpu.set(1, 4, 'Downloading ans-server.lua and ans-server.cfg ...')

	local luaResult = downloadFile(baseLink .. 'ans-server.lua', '/usr/bin/ans-server.lua')
	local cfgResult = downloadFile(baseLink .. 'ans-server.cfg', '/usr/bin/ans-server.cfg')
	if not luaResult or not cfgResult then
		error('Error downloading ans-server.lua and ans-server.cfg file')
	end

	local file = io.open('/home/.shrc', 'w')
	file:write('ans-server.lua')
	file:close()

	gpu.set(1, 5, 'ans-server.lua and ans-server.cfg download completed')
else
	gpu.set(1, 4, 'Downloading ans-client.lua and ans-client.cfg ...')

	local luaResult = downloadFile(baseLink .. 'ans-client.lua', '/usr/lib/ans-client.lua')
	local cfgResult = downloadFile(baseLink .. 'ans-client.cfg', '/usr/lib/ans-client.cfg')
	if not luaResult or not cfgResult then
		error('Error downloading ans-client.lua and ans-client.cfg file')
	end

	gpu.set(1, 5, 'ans-client.lua and ans-client.cfg download completed')
end

gpu.set(1, 6, 'All files downloaded, install successfully !')