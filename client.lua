local QBCore = exports["qb-core"]:GetCoreObject()
local approvalmenu = {}
local loanoptions = {}
local loancheck = {}
local debtoptions = {}

CreateThread(function()
    for k,v in pairs(Config.CreditStation) do
        local x, y, z, w = table.unpack(v['coords'])
        exports['qb-target']:AddBoxZone('Stall '.. k, vector3(x, y, z), 2, 2, {
            name='Stall '.. k,
            heading=heading,
            --debugPoly=true
                }, {
            options = {
            {
                type = "client",
                event = "k-credit:bankercheck",
                icon = "fas fa-credit-card",
                label = v['targetLabel'],
                banker = v['job']
            },
        },
        job = {v['job']},
        distance = 2.5
    }) 
    end
    for k,v in pairs(Config.Registers) do
        exports['qb-target']:AddBoxZone("register_"..k, v.coords, 1, 1, { -- vector3(0, 0, 0)
            name="register_"..k,
            debugPoly=false,
            heading=0,
            }, {
                options = {
                    {
                        event = "k-credit:bill",
                        icon = "fas fa-credit-card",
                        label = "Charge Customer"
                    },
                },
                job = {v.jobname},
                distance = 1.5
            })
    end
end)

RegisterNetEvent('k-credit:bill', function()
    local dialog = exports['qb-input']:ShowInput({
        header = "| Charge Player |",
        submitText = "submit",
        inputs = {
            {
                text = "Paypal ID",
                name = "Who",
                type = "text",
                isRequired = true,                
            },
            {
                text = "Price",
                name = "Amount",
                type = "text",
                isRequired = true,                
            }
        }
    })
    if dialog ~= nil then
        local who = tonumber(dialog['Who'])
        local price = tonumber(dialog['Amount'])
        TriggerServerEvent('k-credit:bill:player', who, price)
    else
        QBCore.Functions.Notify('You must set a valid amount!', 'error', 5000)
    end  
end)

RegisterNetEvent('k-credit:bill:player:menu', function(biller,amount,job)
    billaccept = {
        {
            header = "| Bill for $"..amount.." to "..job.." |",
            isMenuHeader = true
        },
        {
            header = "Aprrove",
            params = {
                event = 'k-credit:bill:player:menu:type',
                args = {
                    biller = biller,
                    amount = amount,
                    job = job
                }
            }
        },
        {
            header = "Deny",
            params = {
                event = 'k-credit:close',
                args = {
                    ply2 = biller
                }
            }
        }
    }
    exports['qb-menu']:openMenu(billaccept)
end)

RegisterNetEvent('k-credit:bill:player:menu:type', function(data)
    local amount = data.amount
    QBCore.Functions.TriggerCallback('k-credit:getcards', function(itemcredit)
        QBCore.Functions.TriggerCallback('k-credit:getdebits', function(itemdebits)
            if itemcredit and itemdebits then
                billaccept = {
                    {
                        header = "| Bill for $"..amount.." to "..data.job.." |",
                        isMenuHeader = true
                    },
                    {
                        header = "Use Cash",
                        params = {
                            event = 'k-credit:pay',
                            args = {
                                type = 'cash',
                                biller = data.biller,
                                amount = amount,
                                job = data.job
                            }
                        }
                    },
                    {
                        header = "Use Credit",
                        params = {
                            event = 'k-credit:pay',
                            args = {
                                type = 'credit',
                                biller = data.biller,
                                amount = amount,
                                job = data.job
                            }
                        }
                    },
                    {
                        header = "Use Debit",
                        params = {
                            event = 'k-credit:pay',
                            args = {
                                type = 'debit',
                                biller = data.biller,
                                amount = amount,
                                job = data.job
                            }
                        }
                    }
                }
                exports['qb-menu']:openMenu(billaccept)
            elseif itemcredit and not itemdebits then
                billaccept = {
                    {
                        header = "| Bill for $"..amount.." to "..data.job.." |",
                        isMenuHeader = true
                    },
                    {
                        header = "Use Cash",
                        params = {
                            event = 'k-credit:pay',
                            args = {
                                type = 'cash',
                                biller = data.biller,
                                amount = amount,
                                job = data.job
                            }
                        }
                    },
                    {
                        header = "Use Credit",
                        params = {
                            event = 'k-credit:pay',
                            args = {
                                type = 'credit',
                                biller = data.biller,
                                amount = amount,
                                job = data.job
                            }
                        }
                    }
                }
                exports['qb-menu']:openMenu(billaccept)
            elseif not itemcredit and itemdebits then
                billaccept = {
                    {
                        header = "| Bill for $"..amount.." to "..data.job.." |",
                        isMenuHeader = true
                    },
                    {
                        header = "Use Cash",
                        params = {
                            event = 'k-credit:pay',
                            args = {
                                type = 'cash',
                                biller = data.biller,
                                amount = amount,
                                job = data.job
                            }
                        }
                    },
                    {
                        header = "Use Debit",
                        params = {
                            event = 'k-credit:pay',
                            args = {
                                type = 'debit',
                                biller = data.biller,
                                amount = amount,
                                job = data.job
                            }
                        }
                    }
                }
                exports['qb-menu']:openMenu(billaccept)
            else
                billaccept = {
                    {
                        header = "| Bill for $"..amount.." to "..data.job.." |",
                        isMenuHeader = true
                    },
                    {
                        header = "Use Cash",
                        params = {
                            event = 'k-credit:pay',
                            args = {
                                type = 'cash',
                                biller = data.biller,
                                amount = amount,
                                job = data.job
                            }
                        }
                    }
                }
                exports['qb-menu']:openMenu(billaccept)
            end
        end, amount)
    end, amount)
end)

RegisterNetEvent('k-credit:pay',function(data)
    TriggerServerEvent('k-credit:player:pay', data)
end)

CreateThread(function()
    while true do
        QBCore.Functions.TriggerCallback('k-credit:getdebts', function(cb)
            for k,v in pairs(cb) do
                if tonumber(v.timer) < 1800000 and tonumber(v.paid) == tonumber(0) then
                    QBCore.Functions.Notify('You need to go pay at least $'..(v.balance * Config.Payment['minimum'])..' on your '..v.type, 'error', 5000)
                end
            end
        end, QBCore.Functions.GetPlayerData().source)
        local sleep = Config.Payment['refresh'] * 60000
        Wait(sleep)
    end
end)

RegisterNetEvent('k-credit:bankercheck', function(data)
    if data.banker ~= 'all' then
        local dialog = exports['qb-input']:ShowInput({
            header = "| Player ID |",
            submitText = "submit",
            inputs = {
                {
                    text = "ID",
                    name = "Amount",
                    type = "text",
                    isRequired = true,                
                }
            }
        })
        if dialog ~= nil then
            local entry = (dialog['Amount'])
            TriggerServerEvent('k-credit:creditcheckapproval', entry)
        else
            QBCore.Functions.Notify('You must set a valid amount!', 'error', 5000)
        end  
    else
        TriggerEvent('k-credit:buymenu', QBCore.Functions.GetPlayerData().source)
    end
end)


RegisterNetEvent('k-credit:creditcheckacceptance', function(ply2)
    loancheck = {
        {
            header = "| Apply For Credit? |",
            isMenuHeader = true
        },
        {
            header = "Aprrove Credit Check",
            params = {
                event = 'k-credit:doapp',
                args = {
                    check = true,
                    ply2 = ply2
                }
            }
        },
        {
            header = "Deny",
            params = {
                event = 'k-credit:doapp',
                args = {
                    check = false,
                    ply2 = ply2
                }
            }
        }
    }
    exports['qb-menu']:openMenu(loancheck)
end)

RegisterNetEvent('k-credit:doapp', function(data)
    if data.check then
        TriggerServerEvent('k-credit:approveapply', data.ply2)
    else
        TriggerServerEvent('k-credit:groupnotifycancel', data.ply2)
    end
end)

RegisterNetEvent('k-credit:buymenu', function(ply)
    loanoptions = {
        {
            header = "Check Credit Score",
            params = {
                event = 'k-credit:getscore',
                args = {
                    ply = ply
                }
            }
        },
        {
            header = "Pay Debts",
            params = {
                event = 'k-credit:managedebt',
                args = {
                    ply = ply
                }
            }
        },
        {
            header = "Apply For Credit",
            params = {
                event = 'k-credit:creditstation',
                args = {
                    ply = ply
                }
            }
        },
        {
            header = "Deposit Check",
            params = {
                event = 'k-credit:depositcheck',
                args = {
                    ply = ply
                }
            }
        }
          
    }
    exports['qb-menu']:openMenu(loanoptions)
end)

RegisterNetEvent('k-credit:depositcheck', function(data)
    local ply = data.ply
    QBCore.Functions.TriggerCallback('k-credit:returnitems', function(cb)
        for i = 1,#cb,1 do
            debtoptions[#debtoptions+1] = {
            header = cb[i].info.job,
            txt = cb[i].info.worth,
            params = {
                event = 'k-credit:deposit',
                args = {
                    ply = ply,
                    job = cb[i].info.job,
                    worth = cb[i].info.worth,
                    slot = cb[i].slot,
                    account = cb[i].info.loannumber
                }
            }
        }
        end
        exports['qb-menu']:openMenu(debtoptions)
        debtoptions = {}
    end, ply)
end)

RegisterNetEvent('k-credit:deposit', function(data)
    TriggerServerEvent('k-credit:checkexchange', data)
end)

RegisterNetEvent('k-credit:bankcheck', function()
    TriggerServerEvent('k-credit:checkbankforneg')
end)

RegisterNetEvent('k-credit:creditstation', function(data)
    local ply = data.ply
    local creditstation = {
        {
            header = "| Apply For Credit |",
            isMenuHeader = true
        },
        {
            header = "Credit Card",
            params = {
                event = 'k-credit:applyamount',
                args = {
                    ply = ply,
                    type = 'card'
                }
            }
        },
        {
            header = "Car Loan",
            params = {
                event = 'k-credit:applyamount',
                args = {
                    ply = ply,
                    type = 'auto'
                }
            }
        },
        {
            header = "House Loan",
            params = {
                event = 'k-credit:applyamount',
                args = {
                    ply = ply,
                    type = 'mortgage'
                }
            }
        }
    }
    exports['qb-menu']:openMenu(creditstation)
end)

RegisterNetEvent('k-credit:managedebt', function(data)
    local ply = data.ply
    local paydebtoptions = {
        {
            header = "| Current Debts |",
            isMenuHeader = true
        },
    }
    QBCore.Functions.TriggerCallback('k-credit:getdebts', function(cb)
        for i = 1,#cb,1 do
            if tonumber(cb[i].paid) == 0 then
                paid = "Not Paid"
            else 
                paid = "Paid"
            end
            paydebtoptions[#paydebtoptions + 1] = {
            header = "Balance: $"..cb[i].balance.." | Payment Status: "..paid,
            txt = cb[i].type.." #:"..cb[i].account,
            params = {
                event = 'k-credit:payinput',
                args = {
                    ply = ply,
                    balance = cb[i].balance,
                    account = cb[i].account,
                    type = cb[i].type
                }
            }
        }
        end
        exports['qb-menu']:openMenu(paydebtoptions)
    end, ply)
    local paydebtoptions = {}
end)

RegisterNetEvent('k-credit:payinput', function(data)
    local dialog = exports['qb-input']:ShowInput({
        header = "| Account: #"..data.account.." |",
        submitText = "submit",
        inputs = {
            {
                text = "Balance: $"..data.balance,
                name = "Amount",
                type = "text",
                isRequired = true,                
                default = data.balance -- Default text option, this is optional
            }
        }
    })
    local entry = (dialog['Amount'])
    if tonumber(entry) <= tonumber(data.balance) then
        TriggerServerEvent('k-credit:paybalance', data.ply, data.account, entry, data.type)
    else
        QBCore.Functions.Notify('You must set a valid amount!', 'error', 5000)
    end   
end)

RegisterNetEvent('k-credit:getscore', function(data)
    local ply = data.ply
    QBCore.Functions.TriggerCallback('k-credit:runcreditcheck', function(cb)
        exports['qb-menu']:openMenu({
            {
                header = "| Credit Score: "..math.floor(cb.score * 1).." |",
                isMenuHeader = true
            }
        })
    end, ply)
end)

RegisterNetEvent('k-credit:applyamount', function(data)
    TriggerServerEvent('k-credit:checkcreditamount', data)
end)

RegisterNetEvent('k-credit:creditapproved', function(ply, preapproval, interest, creditcost, type, deposit)
    local down = 0
    local dialog = exports['qb-input']:ShowInput({
        header = "| Deposit: %"..deposit.." Interest: %"..interest.." |",
        submitText = "submit",
        inputs = {
            {
                text = "Preapproval: $"..preapproval,
                name = "Amount",
                type = "text",
                isRequired = true,                
                default = preapproval -- Default text option, this is optional
            }
        }
    })
    if dialog ~= nil then
        local entry = (dialog['Amount'])
        TriggerServerEvent('k-credit:creditamount', ply, preapproval, interest, creditcost, deposit, type, entry)
    else
        QBCore.Functions.Notify('You must set a valid amount!', 'error', 5000)
    end        
end)

RegisterNetEvent('k-credit:acceptancemenu', function(ply, preapproval, interest, creditcost, deposit, type, amount, ply2)
    if tostring(deposit) ~= 'N/A' then
        local approvalmenu = {
            {
                header = "| You're Approved! (Secured Loan) |",
                isMenuHeader = true
            },
            {
                header = "Amount: $".. amount,
                isMenuHeader = true
            },
            {
                header = "Interest: %".. interest,
                isMenuHeader = true
            },
            {
                header = "Deposit: $".. (amount * (deposit/100)),
                isMenuHeader = true
            },
            {
                header = "Accept!",
                txt = "Payments are always %"..(Config.Payment['minimum'] * 100).." of balance.",
                params = {
                    event = 'k-credit:accept',
                    args = {
                        ply = ply,
                        preapproval = preapproval, 
                        interest = interest, 
                        creditcost = creditcost, 
                        deposit = deposit, 
                        type = type, 
                        amount = amount, 
                        ply2 = ply2
                    }
                }
            },
            {
                header = "Deny!",
                params = {
                    event = 'k-credit:close',
                    args = {
                        check = false,
                        ply2 = ply2 
                    }
                }
            }
        }
        exports['qb-menu']:openMenu(approvalmenu)
    else
        local approvalmenu = {
            {
                header = "| You're Approved! |",
                isMenuHeader = true
            },
            {
                header = "Amount: $".. amount,
                isMenuHeader = true
            },
            {
                header = "Interest: %".. interest,
                isMenuHeader = true
            },
            {
                header = "Accept!",
                txt = "Payments are always %"..(Config.Payment['minimum'] * 100).." of balance.",
                params = {
                    event = 'k-credit:accept',
                    args = {
                        ply = ply,
                        preapproval = preapproval, 
                        interest = interest, 
                        creditcost = creditcost, 
                        deposit = 0, 
                        type = type, 
                        amount = amount, 
                        ply2 = ply2
                    }
                }
            },
            {
                header = "Deny!",
                params = {
                    event = 'k-credit:close',
                    args = {
                        check = false,
                        ply2 = ply2 
                    }
                }
            }
        }
        exports['qb-menu']:openMenu(approvalmenu)
    end
end)

RegisterNetEvent('k-credit:accept', function(data)
    TriggerServerEvent('k-credit:getcredit', data)
    if data.deposit > 0 then
        QBCore.Functions.Notify('$'..data.deposit..' was removed from your bank as a security deposit.', 'success', 5000)
    end
end)

RegisterNetEvent('k-credit:usecard', function(limit, cardnumber, item)
    local dialog = exports['qb-input']:ShowInput({
        header = "| Person to Pay |",
        submitText = "submit",
        inputs = {
            {
                text = "ID",
                name = "Amount",
                type = "text",
                isRequired = true
            }
        }
    })
    if dialog ~= nil then
        local entry = (dialog['Amount'])
        TriggerServerEvent('k-credit:jobcheck', limit, tonumber(entry), item)
    else
        QBCore.Functions.Notify('You must set a valid amount!', 'error', 5000)
    end        
end)

RegisterNetEvent('k-credit:priceset', function(ply1, ply2, item, limit)
    local dialog = exports['qb-input']:ShowInput({
        header = "| Charge Amount |",
        submitText = "submit",
        inputs = {
            {
                text = "Amount",
                name = "Amount",
                type = "text",
                isRequired = true
            }
        }
    })
    if dialog ~= nil then
        local entry = (dialog['Amount'])
        if tonumber(entry) <= value then
            TriggerServerEvent('k-credit:priceset1', tonumber(entry), ply1, ply2, item, limit)    
        else
            QBCore.Functions.Notify('There is not enough on their card for that', 'error', 5000)
        end
    else
        QBCore.Functions.Notify('You must set a valid amount!', 'error', 5000)
    end
end)

RegisterNetEvent('k-credit:swipeui', function(price, ply1, ply2, item, limit)
    local dirtyoptions = {
        {
            header = "| Transaction Amount: $"..price.." |",
            isMenuHeader = true
        },
        {
            header = "Accept!",
            params = {
                event = 'k-credit:accept',
                args = {
                   price = price, 
                   ply1 = ply1, 
                   ply2 = ply2,  
                   item = item, 
                   limit = limit
                }
            }
        },
        {
            header = "Deny!",
            params = {
                event = 'k-credit:close',
                args = {
                    ply1 = ply1, 
                    ply2 = ply2
                }
            }
        }
    }
    exports['qb-menu']:openMenu(dirtyoptions)
end)

RegisterNetEvent('k-credit:close', function(data)
    TriggerServerEvent('k-credit:groupnotifycancel', data.ply2)
end)

RegisterNetEvent('k-credit:accept', function(data)
    TriggerServerEvent('k-credit:squareup', data)
end)