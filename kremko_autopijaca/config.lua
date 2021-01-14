-- ModFreakz
-- For support, previews and showcases, head to https://discord.gg/ukgQa5K

vehsales = {}
local MFV = vehsales

MFV.Version = '1.0.10'

TriggerEvent('esx:getSharedObject', function(obj) ESX = obj; end)
Citizen.CreateThread(function(...)
  while not ESX do
    TriggerEvent('esx:getSharedObject', function(obj) ESX = obj; end)
    Citizen.Wait(0)
  end
end)

-- More config found in client.lua