ESX             = nil
local ShopItems = {}

TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)

AddEventHandler('onMySQLReady', function()
	hasSqlRun = true
	LoadShop()
end)

Citizen.CreateThread(function()
	Citizen.Wait(2000)

	if not hasSqlRun then
		LoadShop()
		hasSqlRun = true
	end
end)

function LoadShop()
	local itemResult = MySQL.Sync.fetchAll('SELECT * FROM items')
	local shopResult = MySQL.Sync.fetchAll('SELECT * FROM shops')

	local itemInformation = {}
	for i=1, #itemResult, 1 do

		if itemInformation[itemResult[i].name] == nil then
			itemInformation[itemResult[i].name] = {}
		end

		itemInformation[itemResult[i].name].label = itemResult[i].label
	end

	for i=1, #shopResult, 1 do
		if ShopItems[shopResult[i].store] == nil then
			ShopItems[shopResult[i].store] = {}
		end

		table.insert(ShopItems[shopResult[i].store], {
			label = itemInformation[shopResult[i].item].label,
			item  = shopResult[i].item,
			price = shopResult[i].price,
			imglink = shopResult[i].imglink
		})
	end
end

ESX.RegisterServerCallback('esx_shops:requestDBItems', function(source, cb)
	cb(ShopItems)
end)

RegisterServerEvent('esx_shops:buyItem')
AddEventHandler('esx_shops:buyItem', function(itemName, amount, zone)
	local _source = source
	local xPlayer = ESX.GetPlayerFromId(_source)

	amount = ESX.Math.Round(amount)

	-- is the player trying to exploit?
	if amount < 0 then
		print('esx_shops: ' .. xPlayer.identifier .. ' attempted to exploit the shop!')
		return
	end

	-- get price
	local price = 0
	local itemLabel = ''

	for i=1, #ShopItems[zone], 1 do
		if ShopItems[zone][i].item == itemName then
			price = ShopItems[zone][i].price
			itemLabel = ShopItems[zone][i].label
			break
		end
	end

	price = price * amount

	-- can the player afford this item?
	if xPlayer.getMoney() >= price then
		-- can the player carry the said amount of x item?
		if xPlayer.canCarryItem(itemName, amount) then
			xPlayer.removeMoney(price)
			xPlayer.addInventoryItem(itemName, amount)
			TriggerClientEvent('mythic_notify:client:SendAlert', source, { type = 'inform', text = 'You bought ' .. amount .. ' x ' .. itemName .. ' for ' .. price .. '$', length = 2500, style = { ['background-color'] = '#2f5c73', ['color'] = '#FFFFFF' } })
		else
			TriggerClientEvent('mythic_notify:client:SendAlert', source, { type = 'inform', text = 'Your backpack is too heavy to carry so many things.', length = 2500, style = { ['background-color'] = '#2f5c73', ['color'] = '#FFFFFF' } })
		end
	else
		local missingMoney = price - xPlayer.getMoney()
		TriggerClientEvent('mythic_notify:client:SendAlert', source, { type = 'inform', text = 'You dont have money, you lack ' .. ESX.Math.GroupDigits(missingMoney) .. "$", length = 2500, style = { ['background-color'] = '#2f5c73', ['color'] = '#FFFFFF' } })
	end
end)