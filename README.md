--Updates to come 
-- tracking system to track player transactions for police to use to track stolen cards
-- Pin Entering if you choose debit through the till system 
-- WARNING MADE THE TILL SYSTEM THIS MORNING THE COMMAND PORTION IS TESST AND WORKING I HAVENT TESTED THE TARGETTING BUT IT SHOULD WORK--

EXPORTS --
type = 'card', 'mortgage', or 'auto'
player = player id number of the player in question or source if player is running it on himself
--server
exports['k-credit]:AddScore(citizenid,amount) --adds credit score
exports['k-credit]:ReduceScore(citizenid,amount) --reduces credit score
exports['k-credit]:MakePayment(type,amount,account) --makes payments  
exports['k-credit]:RunCredit(player) --credit check 
exports['k-credit]:InsertCredit(type,player,account,balance,interest,limit) --insert credit
exports['k-credit]:ApplyForCredit(player,type) --insert credit
exports['k-credit]:Deposit(ply,job,commission,worth) --deposit funds with commission commision should be percentage of deposit it will auto do the math

CALLBACK
'k-credit:getcards'-- arg = cost-- returns true if you have credit card and enough limit left to cover cost
'k-credit:getdebits'-- arg = cost-- returns true if you have debit card and enough in bank left to cover cost

QBSHARED.ITEMS

["creditcard"] 				= {["name"] = "creditcard", 			  		["label"] = "Credit Card", 					["weight"] = 100, 		["type"] = "item", 		["image"] = "creditcard.png", 				["unique"] = true, 	["useable"] = true, 	["shouldClose"] = true,	   ["combinable"] = nil,   ["description"] = ""},
	["check"] 				= {["name"] = "check", 			  		["label"] = "Bank Check", 					["weight"] = 100, 		["type"] = "item", 		["image"] = "check.png", 				["unique"] = true, 	["useable"] = true, 	["shouldClose"] = true,	   ["combinable"] = nil,   ["description"] = ""},



In qb-inventory app.js around line 562
find this line and start a new line after it


        } else if (itemData.name == "moneybag") {
            $(".item-info-title").html("<p>" + itemData.label + "</p>");
            $(".item-info-description").html(
                "<p><strong>Amount of cash: </strong><span>$" +
                itemData.info.cash +
                "</span></p>"
            );
        } else if (itemData.name == "markedbills") {
            $(".item-info-title").html("<p>" + itemData.label + "</p>");
            $(".item-info-description").html(
                "<p><strong>Worth: </strong><span>$" +
                itemData.info.worth +
                "</span></p>"
            );

Add this


        } else if (itemData.name == "check") {
            $(".item-info-title").html("<p>" + itemData.label + "</p>");
            $(".item-info-description").html(
                "<p><strong>For: </strong><span>" +
                itemData.info.job +
                "</span></p>" +
                "<p><strong>Value : </strong><span>$" +
                itemData.info.worth +
                "</span></p>" +
                "<p><strong>Account#: </strong><span>" +
                itemData.info.loannumber +
                "</span></p>"
            );
        } else if (itemData.name == "creditcard") {
            $(".item-info-title").html("<p>" + itemData.label + "</p>");
            $(".item-info-description").html(
                "<p><strong>#: </strong><span>" +
                itemData.info.displaynumber +
                "</span></p>" +
                "<p><strong>CVV: </strong><span>" +
                itemData.info.cvv +
                "</span></p>" 




So all together including a few lines below it it should look like this



 } else if (itemData.name == "moneybag") {
            $(".item-info-title").html("<p>" + itemData.label + "</p>");
            $(".item-info-description").html(
                "<p><strong>Amount of cash: </strong><span>$" +
                itemData.info.cash +
                "</span></p>"
            );
        } else if (itemData.name == "markedbills") {
            $(".item-info-title").html("<p>" + itemData.label + "</p>");
            $(".item-info-description").html(
                "<p><strong>Worth: </strong><span>$" +
                itemData.info.worth +
                "</span></p>"
            );
        } else if (itemData.name == "check") {
            $(".item-info-title").html("<p>" + itemData.label + "</p>");
            $(".item-info-description").html(
                "<p><strong>For: </strong><span>" +
                itemData.info.job +
                "</span></p>" +
                "<p><strong>Value : </strong><span>$" +
                itemData.info.worth +
                "</span></p>" +
                "<p><strong>Account#: </strong><span>$" +
                itemData.info.loannumber +
                "</span></p>"
            );
        } else if (itemData.name == "creditcard") {
            $(".item-info-title").html("<p>" + itemData.label + "</p>");
            $(".item-info-description").html(
                "<p><strong>#: </strong><span>" +
                itemData.info.displaynumber +
                "</span></p>" +
                "<p><strong>CVV: </strong><span>" +
                itemData.info.cvv +
                "</span></p>" +
                "<p><strong>Exp: </strong><span>" +
                itemData.info.exp +
                "</span></p>"
            );
        } else if (itemData.name == "visa" || itemData.name == "mastercard") {
            $(".item-info-title").html('<p>'+itemData.label+'</p>')
            var str = ""+ itemData.info.cardNumber + "";
            var res = str.slice(12);
            var cardNumber = "************" + res;
            $(".item-info-description").html('<p><strong>Card Holder: </strong><span>' + itemData.info.name + '</span></p><p><strong>Citizen ID: </strong><span>' + itemData.info.citizenid + '</span></p><p><strong>Card Number: </strong><span>' + cardNumber + '</span></p>');			
        } else if (itemData.name == "labkey") {
            $(".item-info-title").html("<p>" + itemData.label + "</p>");
            $(".item-info-description").html("<p>Lab: " + itemData.info.lab + "</p>");
        } else {
            $(".item-info-title").html("<p>" + itemData.label + "</p>");
            $(".item-info-description").html("<p>" + itemData.description + "</p>");
        }


Next if you want your qb-shops to automatically pull from the credit card if you have no cash and there is a card on you change qb-inventory server around line 1288 you will find the first line replace that part of the event all the way down to where it picks up from where i left off. This also forces players to have a debit card  to have shops pull from their bank !!PAY ATTENTION TO ITEM NAMES MAKE SURE THEY ARE THE SAME IN THESE RESOURCES AS THE K_CREDIT RESOURCE OR YOULL BE IN TROUBLE!!


	elseif QBCore.Shared.SplitStr(shopType, "_")[1] == "Itemshop" then
			if Player.Functions.RemoveMoney("cash", price, "itemshop-bought-item") then
				if QBCore.Shared.SplitStr(itemData.name, "_")[1] == "weapon" then
					itemData.info.serie = tostring(QBCore.Shared.RandomInt(2) .. QBCore.Shared.RandomStr(3) .. QBCore.Shared.RandomInt(1) .. QBCore.Shared.RandomStr(2) .. QBCore.Shared.RandomInt(3) .. QBCore.Shared.RandomStr(4))
				end
				Player.Functions.AddItem(itemData.name, fromAmount, toSlot, itemData.info)
				TriggerClientEvent('qb-shops:client:UpdateShop', src, QBCore.Shared.SplitStr(shopType, "_")[2], itemData, fromAmount)
				TriggerClientEvent('QBCore:Notify', src, itemInfo["label"] .. " bought!", "success")
				TriggerEvent("qb-log:server:CreateLog", "shops", "Shop item bought", "green", "**"..GetPlayerName(src) .. "** bought a " .. itemInfo["label"] .. " for $"..price)
			elseif Player.Functions.GetItemByName('creditcard') ~= nil then
				local item = Player.Functions.GetItemByName('creditcard')
				local charge = exports['k-credit']:ChargeCard(item.info.cardnumber,price)
				if charge then
					if QBCore.Shared.SplitStr(itemData.name, "_")[1] == "weapon" then
						itemData.info.serie = tostring(QBCore.Shared.RandomInt(2) .. QBCore.Shared.RandomStr(3) .. QBCore.Shared.RandomInt(1) .. QBCore.Shared.RandomStr(2) .. QBCore.Shared.RandomInt(3) .. QBCore.Shared.RandomStr(4))
					end
					Player.Functions.AddItem(itemData.name, fromAmount, toSlot, itemData.info)
					TriggerClientEvent('qb-shops:client:UpdateShop', src, QBCore.Shared.SplitStr(shopType, "_")[2], itemData, fromAmount)
					TriggerClientEvent('QBCore:Notify', src, itemInfo["label"] .. " bought!", "success")
					TriggerEvent("qb-log:server:CreateLog", "shops", "Shop item bought", "green", "**"..GetPlayerName(src) .. "** bought a " .. itemInfo["label"] .. " for $"..price)
				end
			elseif bankBalance >= price then
				local item1 = Player.Functions.GetItemByName('visa')
				local item2 = Player.Functions.GetItemByName('mastercard')
				if item1 ~=	nil or item2 ~= nil then
					Player.Functions.RemoveMoney("bank", price, "itemshop-bought-item")
					if QBCore.Shared.SplitStr(itemData.name, "_")[1] == "weapon" then
						itemData.info.serie = tostring(QBCore.Shared.RandomInt(2) .. QBCore.Shared.RandomStr(3) .. QBCore.Shared.RandomInt(1) .. QBCore.Shared.RandomStr(2) .. QBCore.Shared.RandomInt(3) .. QBCore.Shared.RandomStr(4))
					end
					Player.Functions.AddItem(itemData.name, fromAmount, toSlot, itemData.info)
					TriggerClientEvent('qb-shops:client:UpdateShop', src, QBCore.Shared.SplitStr(shopType, "_")[2], itemData, fromAmount)
					TriggerClientEvent('QBCore:Notify', src, itemInfo["label"] .. " bought!", "success")
					TriggerEvent("qb-log:server:CreateLog", "shops", "Shop item bought", "green", "**"..GetPlayerName(src) .. "** bought a " .. itemInfo["label"] .. " for $"..price)
				else
					TriggerClientEvent('QBCore:Notify', src, "You don't have a debit card..", "error")
				end
			end
		else
			if Player.Functions.RemoveMoney("cash", price, "unknown-itemshop-bought-item") then
				if QBCore.Shared.SplitStr(itemData.name, "_")[1] == "weapon" then
					itemData.info.serie = tostring(QBCore.Shared.RandomInt(2) .. QBCore.Shared.RandomStr(3) .. QBCore.Shared.RandomInt(1) .. QBCore.Shared.RandomStr(2) .. QBCore.Shared.RandomInt(3) .. QBCore.Shared.RandomStr(4))
				end
				Player.Functions.AddItem(itemData.name, fromAmount, toSlot, itemData.info)
				TriggerClientEvent('qb-shops:client:UpdateShop', src, QBCore.Shared.SplitStr(shopType, "_")[2], itemData, fromAmount)
				TriggerClientEvent('QBCore:Notify', src, itemInfo["label"] .. " bought!", "success")
				TriggerEvent("qb-log:server:CreateLog", "shops", "Shop item bought", "green", "**"..GetPlayerName(src) .. "** bought a " .. itemInfo["label"] .. " for $"..price)
			elseif Player.Functions.GetItemByName('creditcard') ~= nil then
				local item = Player.Functions.GetItemByName('creditcard')
				local charge = exports['k-credit']:ChargeCard(item.info.cardnumber,price)
				if charge then
					if QBCore.Shared.SplitStr(itemData.name, "_")[1] == "weapon" then
						itemData.info.serie = tostring(QBCore.Shared.RandomInt(2) .. QBCore.Shared.RandomStr(3) .. QBCore.Shared.RandomInt(1) .. QBCore.Shared.RandomStr(2) .. QBCore.Shared.RandomInt(3) .. QBCore.Shared.RandomStr(4))
					end
					Player.Functions.AddItem(itemData.name, fromAmount, toSlot, itemData.info)
					TriggerClientEvent('qb-shops:client:UpdateShop', src, QBCore.Shared.SplitStr(shopType, "_")[2], itemData, fromAmount)
					TriggerClientEvent('QBCore:Notify', src, itemInfo["label"] .. " bought!", "success")
					TriggerEvent("qb-log:server:CreateLog", "shops", "Shop item bought", "green", "**"..GetPlayerName(src) .. "** bought a " .. itemInfo["label"] .. " for $"..price)
				end
			elseif bankBalance >= price then
				local item1 = Player.Functions.GetItemByName('visa')
				local item2 = Player.Functions.GetItemByName('mastercard')
				if item1 ~=	nil or item2 ~= nil then
					Player.Functions.RemoveMoney("bank", price, "unknown-itemshop-bought-item")
					if QBCore.Shared.SplitStr(itemData.name, "_")[1] == "weapon" then
						itemData.info.serie = tostring(QBCore.Shared.RandomInt(2) .. QBCore.Shared.RandomStr(3) .. QBCore.Shared.RandomInt(1) .. QBCore.Shared.RandomStr(2) .. QBCore.Shared.RandomInt(3) .. QBCore.Shared.RandomStr(4))
					end
					Player.Functions.AddItem(itemData.name, fromAmount, toSlot, itemData.info)
					TriggerClientEvent('qb-shops:client:UpdateShop', src, QBCore.Shared.SplitStr(shopType, "_")[2], itemData, fromAmount)
					TriggerClientEvent('QBCore:Notify', src, itemInfo["label"] .. " bought!", "success")
					TriggerEvent("qb-log:server:CreateLog", "shops", "Shop item bought", "green", "**"..GetPlayerName(src) .. "** bought a " .. itemInfo["label"] .. " for $"..price)
				else
					TriggerClientEvent('QBCore:Notify', src, "You don't have a debit card..", "error")
				end
			end
		end	