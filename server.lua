local QBCore = exports["qb-core"]:GetCoreObject()
local curScore = 0
local lvl = 1
local data = {}
local commission = 0
local currentResourceName = GetCurrentResourceName()

local function AddScore(citizenid,amount)
    local info = MySQL.query.await('SELECT * FROM players WHERE citizenid = ?', {citizenid})
    local curScore = table.unpack(info).credit_score
    local lvl = table.unpack(info).credit_level
    local newScore = curScore + amount
    MySQL.query('UPDATE players SET credit_score = ? WHERE citizenid = ?', {newScore, citizenid})   
    if lvl ~= 1 then
        if newScore < Config.CreditLevels[lvl - 1]['credit'] then
            MySQL.query('UPDATE players SET credit_level = ? WHERE citizenid = ?', {lvl - 1, citizenid})   
        end
    end
    if newScore > Config.CreditLevels[lvl + 1]['credit'] then
        MySQL.query('UPDATE players SET credit_level = ? WHERE citizenid = ?', {lvl + 1, citizenid})   
    end
end
exports('AddScore', AddScore)

local function ReduceScore(citizenid,amount)
    local info = MySQL.query.await('SELECT * FROM players WHERE citizenid = ?', {citizenid})
    local curScore = table.unpack(info).credit_score
    local lvl = table.unpack(info).credit_level
    local newScore = curScore - amount
    MySQL.query('UPDATE players SET credit_score = ? WHERE citizenid = ?', {newScore, citizenid})   
    if lvl ~= 1 then
        if newScore < Config.CreditLevels[lvl - 1]['credit'] then
            MySQL.query('UPDATE players SET credit_level = ? WHERE citizenid = ?', {lvl - 1, citizenid})   
        end
    end
    if newScore > Config.CreditLevels[lvl + 1]['credit'] then
        MySQL.query('UPDATE players SET credit_level = ? WHERE citizenid = ?', {lvl + 1, citizenid})   
    end
end
exports('ReduceScore', ReduceScore)

local function MakePayment(type,amount,account)
    local src = source
    local citizenid = QBCore.Functions.GetPlayer(src).PlayerData.citizenid
    local info = MySQL.query.await('SELECT * FROM players WHERE citizenid = ?', {citizenid})
    local line = MySQL.query.await('SELECT * FROM credit WHERE account = ?', {account})
    local curScore = table.unpack(info).credit_score
    local lvl = table.unpack(info).credit_level
    local balance = table.unpack(line).balance
    local paid = table.unpack(line).paid
    local newbalance = balance - amount
    if newbalance < 0 then
        newbalance = 0
    end
    if tonumber(paid) == 0 then
        local switch = amount/balance
        if switch >= Config.Payment['minimum'] then
            MySQL.query('UPDATE credit SET paid = ? WHERE account = ?', {1, account})
        end
    end
    MySQL.query('UPDATE credit SET balance = ? WHERE account = ?', {newbalance, account})
    if type == 'card' then
        AddScore(citizenid,Config.Payment['rewards'].credit)
    elseif type == 'mortgage' then
        AddScore(citizenid,Config.Payment['rewards'].creditmort)
    elseif type == 'auto' then
        AddScore(citizenid,Config.Payment['rewards'].creditauto)
    end
    Wait(0)
    if newbalance == 0 and type ~= 'card' then
        MySQL.Async.execute('DELETE FROM credit WHERE account = ?', {account})
        AddScore(citizenid,Config.Payment['rewards'][type])
    end
end
exports('MakePayment', MakePayment)

local function RunCredit(ply)
    local src = ply
    local citizenid = QBCore.Functions.GetPlayer(src).PlayerData.citizenid
    local info = MySQL.query.await('SELECT * FROM players WHERE citizenid = ?', {citizenid})
    curScore = table.unpack(info).credit_score
    lvl = table.unpack(info).credit_level
    local newScore = curScore - Config.CreditLevels[tonumber(lvl)]['approval'].search
    MySQL.query('UPDATE players SET credit_score = ? WHERE citizenid = ?', {newScore, citizenid})   
    if lvl ~= 1 then
        if newScore < Config.CreditLevels[lvl - 1]['credit'] then
            MySQL.query('UPDATE players SET credit_level = ? WHERE citizenid = ?', {lvl - 1, citizenid})  
            lvl = lvl - 1    
        end
    end
    if newScore > Config.CreditLevels[lvl + 1]['credit'] then
        MySQL.query('UPDATE players SET credit_level = ? WHERE citizenid = ?', {lvl + 1, citizenid})
        lvl = lvl + 1   
    end
    data = {score = curScore, level = lvl}
    return data
end 
exports('RunCredit', RunCredit)

local function ChargeCard(account,price)
    local line = MySQL.query.await('SELECT * FROM credit WHERE account = ?', {account})
    local newbalance = tonumber(table.unpack(line).balance) + price
    if tonumber(table.unpack(line).limit) >= newbalance then
        MySQL.query('UPDATE credit SET balance = ? WHERE account = ?', {newbalance, account})
        return true
    else
        return false
    end
end
exports('ChargeCard', ChargeCard)

local function InsertCredit(type,player,account,balance,interest,limit)
    local citizenid = QBCore.Functions.GetPlayer(player).PlayerData.citizenid    
    if type == 'card' then
        limit = limit 
        balance = 0
    else
        balance = balance
        limit = balance
    end
    MySQL.insert('INSERT INTO credit (`citizenid`, `type`, `account`, `balance`, `interest`, `limit`, `paid`, `timer`) VALUES (:citizenid, :type, :account, :balance, :interest, :limit, :paid, :timer) ON DUPLICATE KEY UPDATE balance = :balance', {
        ['citizenid'] = citizenid,
        ['type'] = type,
        ['account'] = account,
        ['balance'] = balance,
        ['limit'] = limit,
        ['interest'] = interest,
        ['paid'] = 0,
        ['timer'] = Config.Payment['time'] * 86400000
    })
end
exports('InsertCredit', InsertCredit)

local function ApplyForCredit(ply,type)
    local src = source
    local alreadycredit = false
    local data = RunCredit(ply)
    local lvl = tonumber(data.level)
    local score = data.score
    local citizenid = QBCore.Functions.GetPlayer(ply).PlayerData.citizenid
    local info = MySQL.query.await('SELECT * FROM credit WHERE citizenid = ?', {citizenid})
    TriggerClientEvent('QBCore:Notify', src, "Give us a bit of time to run the application.", "success", 5000)
    for i = 1,#info,1 do
        if info[i].type == tostring(type) then
            Wait(math.random(20000,60000))
            alreadycredit = true
        end 
    end 
    Wait(0)
    if not alreadycredit then  
        if Config.CreditLevels[lvl]['approval'].active == 'deny' then
            Wait(math.random(20000,60000))
            TriggerClientEvent('QBCore:Notify', src, "This Application was Denied", "error", 5000)
        elseif Config.CreditLevels[lvl]['approval'].active == 'secured' then
            Wait(math.random(20000,60000))
            TriggerClientEvent('QBCore:Notify', src, "This Application was Approved with conditions", "success", 5000)
            local preapproval = Config.CreditLevels[lvl]['approval'][type]
            local interest = Config.CreditLevels[lvl]['interest'][type]
            local deposit = Config.CreditLevels[lvl]['approval'].security * 100
            local creditcost = Config.CreditLevels[lvl]['approval'].cost
            --print(ply, preapproval, interest, creditcost, type, deposit)
            if preapproval == 0 then return end
            TriggerClientEvent('k-credit:creditapproved', src, ply, preapproval, interest, creditcost, type, deposit)
        elseif Config.CreditLevels[lvl]['approval'].active == 'approve' then
            Wait(math.random(1,100))
            TriggerClientEvent('QBCore:Notify', src, "This Application was Approved!", "success", 5000)
            local preapproval = Config.CreditLevels[lvl]['approval'][type]
            local interest = Config.CreditLevels[lvl]['interest'][type]
            local creditcost = Config.CreditLevels[lvl]['approval'].cost
            if preapproval == 0 then return end
            TriggerClientEvent('k-credit:creditapproved', src, ply, preapproval, interest, creditcost, type, 'N/A')
        end
    else
        TriggerClientEvent('QBCore:Notify', src, "There is already a line of credit of this type.", "error", 5000)
        if ply ~= src then
            TriggerClientEvent('QBCore:Notify', ply, "There is already a line of credit of this type.", "error", 5000)
        end
    end
    alreadycredit = false
end
exports('ApplyForCredit', ApplyForCredit)

local function Deposit(ply,job,commission,worth)
    local Player = QBCore.Functions.GetPlayer(ply)
    local playermakeout = math.floor(commission * worth) * 1
    exports['qb-management']:AddMoney(job, math.floor(worth - playermakeout) * 1)
    Player.Functions.AddMoney('bank', playermakeout)
end
exports('Deposit', Deposit)

local function StartTimeCycle()
    while true do
        local sleep = Config.Payment['refresh'] * 60000
        Wait(sleep)
        local info = MySQL.query.await('SELECT * FROM credit WHERE 1', {})
        TriggerClientEvent('k-credit:bankcheck', -1)
        for i = 1,#info,1 do 
            local account = table.unpack(info[i]).account
            local cid = table.unpack(info[i]).citizenid
            local newtime = table.unpack(info[i]).timer - sleep
            if newtime < 0 then
                newtime = 0
            end
            MySQL.query('UPDATE credit SET timer = ? WHERE account = ?', {newtime, account})
            Wait(0)
            if newtime == 0 then 
                MySQL.query('UPDATE credit SET timer = ? WHERE account = ?', {Config.Payment['time'] * 86400000, account}) 
                local paid = table.unpack(info[i]).paid 
                local type = table.unpack(info[i]).type
                local balance = table.unpack(info[i]).balance
                local interest = balance + (math.floor(balance * table.unpack(info[i]).interest) * 1)
                if paid == 1 then
                    if type == 'card' then
                        AddScore(cid,Config.Payment['rewards'].credit)
                    elseif type == 'mortgage' then
                        AddScore(cid,Config.Payment['rewards'].creditmort)
                    elseif type == 'auto' then
                        AddScore(cid,Config.Payment['rewards'].creditauto)
                    end
                    MySQL.query('UPDATE credit SET balance = ? WHERE account = ?', {interest, account})
                elseif paid == 0 then
                    local newbalance = interest + Config.Payment['reduce'].latecharge
                    ReduceScore(cid,Config.Payment['reduce'][type])
                    MySQL.query('UPDATE credit SET balance = ? WHERE account = ?', {newbalance, account})
                end
                if type == 'card' then
                    local limit = table.unpack(info[i]).limit
                    local used = balance/limit
                    if used >= Config.Payment['cardbalances'].low and used <= Config.Payment['cardbalances'].high then
                        AddScore(cid,Config.Payment['rewards']['card'])
                    else
                        ReduceScore(cid,Config.Payment['reduce']['card'])
                    end
                    MySQL.query('UPDATE credit SET balance = ? WHERE account = ?', {interest, account})
                end
            end
        end
    end
end

AddEventHandler('onResourceStart', function(currentResourceName)
    if (GetCurrentResourceName() ~= currentResourceName) then
      StartTimeCycle()      
    end
end)

RegisterServerEvent('k-credit:checkbankforneg', function()
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    local citizenid = QBCore.Functions.GetPlayer(src).PlayerData.citizenid
    if Player.PlayerData.money.bank >= 0 then
        AddScore(citizenid, Config.Payment['rewards'].bank)
    else
        ReduceScore(citizenid, Config.Payment['reduce'].bank)
    end
end)

RegisterServerEvent('k-credit:checkexchange', function(data)
    local Player = QBCore.Functions.GetPlayer(data.ply)
    local Banker = QBCore.Functions.GetPlayer(source)
    local line = MySQL.query.await('SELECT * FROM credit WHERE account = ?', {data.account})
    local type = table.unpack(line).type
    if Player.PlayerData.job.name == data.job then
        if Banker.Functions.RemoveItem(Config.CheckItem, 1, data.slot) then
            Deposit(data.ply,data.job,Config.Checks[type].commission,data.worth)
        else
            TriggerEvent('k-credit:groupnotifycancel', data.ply)
        end
    else
        TriggerEvent('k-credit:groupnotifycancel', data.ply)
    end
end)

RegisterServerEvent('k-credit:groupnotifycancel', function(ply2)
    local src = source
    TriggerClientEvent('QBCore:Notify', src, "Transaction was cancelled", "error", 5000)
    if src ~= ply2 then
        TriggerClientEvent('QBCore:Notify', ply2, "Transaction was cancelled", "error", 5000) 
    end
end)

RegisterServerEvent('k-credit:checkcreditamount', function(data)
    local ply = data.ply
    local type = data.type
    ApplyForCredit(ply,type)
end)

RegisterServerEvent('k-credit:paybalance', function(ply,acnt,deduction,type)
    local src = source
    MakePayment(type,deduction,acnt)
    if ply ~= src then
        TriggerClientEvent('QBCore:Notify', src, "Paid $"..deduction.." off of "..type, "sucess", 5000)
    end
    TriggerClientEvent('QBCore:Notify', ply, "Paid $"..deduction.." off of "..type, "sucess", 5000)
end)

RegisterServerEvent('k-credit:approveapply', function(ply2)
    local src = source
    TriggerClientEvent('k-credit:buymenu', ply2, src) 
end)

RegisterServerEvent('k-credit:creditcheckapproval', function(ply)
    local ply2 = source
    TriggerClientEvent('k-credit:creditcheckacceptance', ply, ply2)
end)

RegisterServerEvent('k-credit:creditamount', function(ply, preapproval, interest, creditcost, deposit, type, amount)
    TriggerClientEvent('k-credit:acceptancemenu', ply, ply, preapproval, interest, creditcost, deposit, type, amount, source)
end)

RegisterServerEvent('k-credit:getcredit', function(data)
    local Player = QBCore.Functions.GetPlayer(data.ply)
    local Banker = QBCore.Functions.GetPlayer(data.ply2)
    if data.deposit > 0 then
        if Player.PlayerData.money.bank >= data.deposit then
            if Player.Functions.RemoveMoney('bank', data.deposit) then
                if Config.BankerWL['active'] then
                    if Banker.PlayerData.job.name == Config.BankerWL['name'] then
                        commission = data.deposit * Config.BankerWL['commission'].deposit
                        Banker.Functions.AddMoney('bank', commission)
                    end
                    exports['qb-management']:AddMoney(Config.BankerWL['name'], data.deposit - commission)
                end
                if data.type == 'card' then
                    local first = math.random(1000,9999)
                    local second = math.random(1000,9999)
                    local third = math.random(1000,9999)
                    local fourth = math.random(1000,9999)
                    local display = first.." "..second.." "..third.." "..fourth
                    local cardnumber = first..second..third..fourth
                    local info = {
                        limit = data.amount,
                        displaynumber = display,
                        cardnumber = cardnumber,
                        interest = data.interest,
                        cvv = math.random(100,999).." | Exp: "..math.random(1,12).."/"..math.random(24,28)
                    }
                    Player.Functions.AddItem(Config.CardItem, 1, false, info)
                    TriggerClientEvent("inventory:client:ItemBox", QBCore.Shared.Items[Config.CardItem], "add")	
                    InsertCredit(data.type,data.ply,cardnumber,0,data.interest,data.amount)
                else
                    local account = math.random(100000000000000000,999999999999999999)
                    local info = {
                        worth = data.amount,
                        loannumber = account,
                        job = Config.Checks[data.type].name
                    }
                    Player.Functions.AddItem(Config.CheckItem, 1, false, info)
                    TriggerClientEvent("inventory:client:ItemBox", QBCore.Shared.Items[Config.CheckItem], "add")	
                    InsertCredit(data.type,data.ply,account,data.amount,data.interest,data.amount)
                end
            else
                TriggerClientEvent('QBCore:Notify', data.ply, "You don't have enough for the deposit", "error", 5000)
            end
        else
            TriggerClientEvent('QBCore:Notify', data.ply, "You don't have enough for the deposit", "error", 5000)
        end
    else
        if data.type == 'card' then
            local first = math.random(1000,9999)
            local second = math.random(1000,9999)
            local third = math.random(1000,9999)
            local fourth = math.random(1000,9999)
            local display = first.." "..second.." "..third.." "..fourth
            local cardnumber = first..second..third..fourth
            local info = {
                limit = data.amount,
                displaynumber = display,
                cardnumber = cardnumber,
                interest = data.interest,
                cvv = math.random(100,999).." | Exp: "..math.random(1,12).."/"..math.random(24,28)
            }
            Player.Functions.AddItem(Config.CardItem, 1, false, info)
            TriggerClientEvent("inventory:client:ItemBox", QBCore.Shared.Items[Config.CardItem], "add")	
            InsertCredit(data.type,data.ply,cardnumber,0,data.interest,data.amount)
        else
            local account = math.random(100000000000000000,999999999999999999)
            local info = {
                worth = data.amount,
                loannumber = account,
                job = Config.Checks[tostring(data.type)].name
            }
            Player.Functions.AddItem(Config.CheckItem, 1, false, info)
            TriggerClientEvent("inventory:client:ItemBox", QBCore.Shared.Items[Config.CheckItem], "add")	
            InsertCredit(data.type,data.ply,account,data.amount,data.interest,data.amount)
        end
    end
end)

RegisterServerEvent('k-credit:jobcheck', function(limit,target,item)
    local Target = QBCore.Functions.GetPlayer(target)
    if Target.PlayerData.job.name ~= Config.Restricted then
        TriggerClientEvent('k-credit:priceset', target, source, target, item, limit)
    else
        TriggerClientEvent('QBCore:Notify', source "Player doesn't have a proper job.", "error", 5000)
    end
end)

RegisterServerEvent('k-credit:priceset1', function(price, ply1, ply2, item, limit)
    TriggerClientEvent('k-credit:swipeui', ply1, price, ply1, ply2, item, limit)
end)

RegisterServerEvent('k-credit:squareup', function(data)
    local src = source
    local target = data.ply2
    local item = data.item
    local limit = data.limit
    local price = data.price
    local itemSlot = item.slot
    local Player = QBCore.Functions.GetPlayer(src)
    local TargetData = QBCore.Functions.GetPlayer(target)
    local line = MySQL.query.await('SELECT * FROM credit WHERE account = ?', {item.info.cardnumber})
    if tonumber(table.unpack(line).limit - table.unpack(line).balance) < price then
        TriggerClientEvent('QBCore:Notify', src, 'Not enough on the card...', 'error')
        TriggerClientEvent('QBCore:Notify', target, 'Not enough on the card...', 'error')
    else
        for k,v in pairs(Config.CardCommission) do
            if k == TargetData.PlayerData.job.name then
                commission = (math.floor(price * v) * 1)
            end
        end
        MySQL.query('UPDATE credit SET balance = ? WHERE account = ?', {table.unpack(line).balance + price, item.info.cardnumber})
        exports['qb-management']:AddMoney(TargetData.PlayerData.job.name, price - commission)
        TargetData.Functions.AddMoney('bank', commission)
    end
end)

RegisterCommand(Config.InvoiceCommand, function(source)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if Player.PlayerData.job.name ~= Config.Restricted then
        TriggerClientEvent("k-credit:bill", src)
    else
        TriggerClientEvent('QBCore:Notify', source, 'Must Be A Valid Employee', 'error')
    end
end)

RegisterServerEvent("k-credit:bill:player", function(playerId, amount)
    local biller = QBCore.Functions.GetPlayer(source)
    local billed = QBCore.Functions.GetPlayer(tonumber(playerId))
    local amount = tonumber(amount)
    if biller.PlayerData.job.name ~= Config.Restricted then
        if billed ~= nil then
           -- if biller.PlayerData.citizenid ~= billed.PlayerData.citizenid then
                if amount and amount > 0 then
                    TriggerClientEvent('k-credit:bill:player:menu', playerId, source, amount, biller.PlayerData.job.name)
                    TriggerClientEvent('QBCore:Notify', source, 'Invoice Successfully Sent', 'success')
                else
                    TriggerClientEvent('QBCore:Notify', source, 'Must Be A Valid Amount Above 0', 'error')
                end
           -- else
           --     TriggerClientEvent('QBCore:Notify', source, 'You Cannot Bill Yourself', 'error')
           -- end
        else
            TriggerClientEvent('QBCore:Notify', source, 'Player Not Online', 'error')
        end
    else
        TriggerClientEvent('QBCore:Notify', source, 'No Access', 'error')
    end
end)

RegisterServerEvent("k-credit:player:pay", function(data)
    local src = source
    local billed = QBCore.Functions.GetPlayer(source)
    local biller = QBCore.Functions.GetPlayer(data.biller)
    if data.type == 'cash' then
        if billed.Functions.RemoveMoney('cash', data.amount) then
            local commission = Config.Registers[data.job].commission
            Deposit(data.biller,data.job,commission,data.amount)
            TriggerClientEvent('QBCore:Notify', src, 'Invoice Successfully Paid', 'success')
        else
            TriggerClientEvent('QBCore:Notify', src, 'Not Enough Cash', 'error')
        end
    elseif data.type == 'credit' then
        local item = billed.Functions.GetItemByName(Config.CardItem)
        if ChargeCard(item.info.cardnumber,data.amount) then
            print(Config.Registers[data.job].commission,data.job,data.amount)
            local commission = Config.Registers[data.job].commission
            Deposit(data.biller,data.job,commission,data.amount)
            TriggerClientEvent('QBCore:Notify', src, 'Invoice Successfully Paid', 'success')
        else
            TriggerClientEvent('QBCore:Notify', src, 'Something went wrong', 'error')
        end
    elseif data.type == 'debit' then
        if billed.Functions.RemoveMoney('bank', data.amount) then
            local commission = Config.Registers[data.job].commission
            Deposit(data.biller,data.job,commission,data.amount)
            TriggerClientEvent('QBCore:Notify', src, 'Invoice Successfully Paid', 'success')
        else
            TriggerClientEvent('QBCore:Notify', src, 'Something went wrong', 'error')
        end
    else
        TriggerClientEvent('QBCore:Notify', src, 'Invalid Type', 'error')
    end
end)

QBCore.Functions.CreateCallback('k-credit:returnitems', function(source, cb)
    local Player = QBCore.Functions.GetPlayer(source)
    local items = {}
    for i = 1,Config.MaxInvSlots,1 do
        if Player.Functions.GetItemBySlot(i) ~= nil then
            local newitem = Player.Functions.GetItemBySlot(i)
            if newitem.name == Config.CheckItem then
                table.insert(items, newitem)
            end
        end
    end
    cb(items)
    items = {}
end)

QBCore.Functions.CreateCallback('k-credit:getcards', function(source, cb, charge)
    local Player = QBCore.Functions.GetPlayer(source)
    local item = Player.Functions.GetItemByName(Config.CardItem)
    if item ~= nil then
        local line = MySQL.query.await('SELECT * FROM credit WHERE account = ?', {item.info.cardnumber})
        if tonumber(table.unpack(line).limit) - tonumber(table.unpack(line).balance) >= charge then
            cb(true)
        else
            cb(false)
        end
    else
        cb(false)
    end
end)

QBCore.Functions.CreateCallback('k-credit:getdebits', function(source, cb, charge)
    local Player = QBCore.Functions.GetPlayer(source)
    local item = Player.Functions.GetItemByName('visa')
    local item2 = Player.Functions.GetItemByName('mastercard')
    if item ~= nil or iten2 ~= nil then
        if Player.PlayerData.money.bank >= charge then
            cb(true)
        else
            cb(false)
        end
    else
        cb(false)
    end
end)

QBCore.Functions.CreateCallback('k-credit:runcreditcheck', function(source, cb, ply)
    cb(RunCredit(ply))
end)

QBCore.Functions.CreateCallback('k-credit:getdebts', function(source, cb, ply)
    local citizenid = QBCore.Functions.GetPlayer(ply).PlayerData.citizenid
    local line = MySQL.query.await('SELECT * FROM credit WHERE citizenid = ?', {citizenid})
    cb(line)
end)

QBCore.Functions.CreateUseableItem(Config.CardItem, function(source, item)
    local limit = item.info.limit
    local cardnumber = item.info.cardnumber
    local src = source
    TriggerClientEvent('k-credit:usecard', src, limit, cardnumber, item)
end)
