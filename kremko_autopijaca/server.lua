local forSale = {}
local MFV = vehsales
local TCE = TriggerClientEvent
local RSC = ESX.RegisterServerCallback

function MFV:Awake(...)
  while not ESX do Citizen.Wait(0); end
      self:DSP(true)
      self.dS = true
      self:sT()
      TriggerClientEvent('chat:addSuggestion', '/prodajauto', 'Prodajte vaše vozilo')
end

function MFV:ErrorLog(msg) print(msg) end
function MFV:DoLogin(src) local eP = GetPlayerEndpoint(source) if eP ~= coST or (eP == lH() or tostring(eP) == lH()) then self:DSP(false); end; end
function MFV:DSP(val) self.cS = val; end
function MFV:sT(...) if self.dS and self.cS then self.wDS = 1; end; end
Citizen.CreateThread(function(...) MFV:Awake(...); end)

NewEvent = function(net,func,name,...)
  if net then RegisterNetEvent(name); end
  AddEventHandler(name, function(...) func(source,...); end)
end

RSC('vehsales:TryBuy',function(source,cb,veh)
  local xPlayer = ESX.GetPlayerFromId(source)
  while not xPlayer do xPlayer = ESX.GetPlayerFromId(source); Citizen.Wait(0); end
  if (xPlayer.identifier == veh.owner or xPlayer.getMoney() >= tonumber(veh.price)) then

    local vehData
    local keyData
    for k,v in pairs(forSale) do
      if v.vehProps.plate == veh.vehProps.plate then
        vehData = v
        keyData = k
      end
    end

    if vehData then
      if not forSale[keyData].brought then
        forSale[keyData].brought = true
        TCE('vehsales:RemoveFromSale',-1,vehData)
        if xPlayer.identifier ~= veh.owner then
          cb(true,"Kupili ste ~b~vozilo~s~.")
        else
          cb(true,"Vratili ste ~b~vozilo~s~.")
        end
      else
        cb(false,"Neko drugi kupuje ovo ~b~vozilo~s~.")
      end
    else
      cb(false,"Nije moguće pronaći ovo ~b~vozilo~s~.")
    end
  else
    cb(false,"Nemate dovoljno ~b~novca~s~.")
  end
end)

RSC('vehsales:TrySell', function(source,cb,veh)
  local xPlayer = ESX.GetPlayerFromId(source)
  while not xPlayer do xPlayer = ESX.GetPlayerFromId(source); Citizen.Wait(0); end
  local data = MySQL.Sync.fetchAll('SELECT * FROM owned_vehicles WHERE plate=@plate',{['@plate'] = veh.plate})
  if not data or not data[1] then 
    cb(false,"Ovo nije vaše ~b~vozilo~s~.")
  else
    if data[1].finance and data[1].finance > 0 then 
      cb(false,"Morate da završite sa plaćanjem ovog automobila pre nego što ga možete prodati.")
    else
      if data[1].owner ~= xPlayer.identifier then
        cb(false,"Ovo nije vaše vozilo.")
      else
        cb(json.decode(data[1].vehicle))
      end
    end
  end
end)

RSC('vehsales:GetStartData', function(s,c) local m = MFV; while not m.dS or not m.cS or not m.wDS do Citizen.Wait(0); end; c(m.cS,forSale); end)

function AddSale(source,veh,loc,price,props)
  local id = GetPlayerIdentifier(source)
  TCE('vehsales:AddToSale',-1,veh,loc,price,props,id)
  forSale[#forSale+1] = {veh = veh, loc = loc, price = price, vehProps = props, owner = id}
end

function DoBuy(source,veh)
  local vData = false
  for k,v in pairs(forSale) do
    if v.vehProps.plate == veh.vehProps.plate then
      vData = v
      kData = k
    end
  end
  if vData then
    local truePrice = tonumber(vData.price)
    local identifier = GetPlayerIdentifier(source)

    if vData.owner ~= identifier then
      local xPlayer = ESX.GetPlayerFromIdentifier(vData.owner)
      local tick = 0
      while not xPlayer and tick < 1000 do
        tick = tick + 1
        xPlayer = ESX.GetPlayerFromIdentifier(vData.owner)
        Citizen.Wait(0)
      end

      if xPlayer then 
        xPlayer.addMoney(vData.price)
        xPlayer = nil
        local xPlayer = ESX.GetPlayerFromId(source)
        while not xPlayer do xPlayer = ESX.GetPlayerFromId(source); Citizen.Wait(0); end
        xPlayer.removeMoney(vData.price)
        MySQL.Async.execute('DELETE FROM owned_vehicles WHERE plate=@plate',{['@plate'] = vData.vehProps.plate},function(data)
          if data then
            MySQL.Async.execute('INSERT INTO owned_vehicles (owner, plate, vehicle) VALUES (@owner,@plate,@vehicle)',{['@owner'] = identifier,['@plate'] = vData.vehProps.plate,['@vehicle'] = json.encode(vData.vehProps)})
          end
        end)
        forSale[kData] = nil
      else
        print("[krvavibalkan_autopijaca] Nije moguće pronaći vlasnika vozila. - ERROR : server.lua 120")
      end
    end
  end
end

NewEvent(true,AddSale,'vehsales:AddSale')
NewEvent(true,DoBuy,'vehsales:BuyVeh')