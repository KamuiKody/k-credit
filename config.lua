Config = {}

Config.CardItem = 'creditcard'
Config.CheckItem = 'check'
Config.MaxInvSlots = 41 -- how many slots does your inventory have
Config.Restricted = 'unemployed' -- a business the credit card cannot go to
Config.InvoiceCommand = 'invoice'
Config.Registers = {-- Registers has not been tested yet -- testing will ensue tonight 7/11/22
    ['burgershot'] = {
        coords = vector3(0,0,0),
        commission = 0.15
    }
}
Config.BankerWL = {
    ['active'] = false,
    ['name'] = 'banker',
    ['commission'] = 0.15
}
Config.Checks = {
    ['mortgage'] = {
        name = 'realestate',-- first is the type of loan second is the job for the check to be made out to
        commission = 0.15
    },
    ['auto'] = {
        name = 'cardealer',-- first is the type of loan second is the job for the check to be made out to
        commission = 0.15
    }
}
Config.CardCommission = {
    ['mechanic'] = 0.15,
    ['ambulance'] = 0.15

}
Config.CreditStation = { -- gift card buy options
    [1] = {
        ['coords'] = vector4(255.0, 210.63, 106.29, 143.93),
        ['job'] = 'all',
        ["targetLabel"] = 'Apply for Credit'
    },
    [2] = {
        ['coords'] = vector4(2676.12, 3499.13, 53.3, 50.74),
        ['job'] = 'all',
        ["targetLabel"] = 'Apply for Credit'
    }
}
Config.Payment = {
    ['minimum'] = 0.10, -- amount of the balance that must be payed to avoid penalty
    ['refresh'] = 5,-- time in minutes to refresh the time for payments
    ['time'] = 7, -- how many days before next payment is due
    ['rewards'] = {
        bank = 0.1, -- points for bank balance         --bank balance is per refresh time not ['time'] 
        credit = 1, -- points for on time payments          only set up for these 4 variables for now
        creditmort = 5, -- points for on time payments      only set up for these 4 variables for now
        creditauto = 2, -- points for on time payments    if you need more lmk ill set them up  only set up for these 3 variables for now
        ['mortgage'] = 50, -- points for paying off loan 
        ['auto'] = 10, -- points for paying off loan
        ['card'] = 2 -- points for keeping balance  in the correct area
    },
    ['reduce'] = {
        bank = 0.2, -- points for bank balance in the negative
        close = 10, -- score reduction for closing credit card with 0 balance
        latecharge = 1000, -- amount of money for late payments added to balance
        ['card'] = 5, -- late payments
        ['mortgage'] = 20, -- points for late payments on loan 
        ['auto'] = 10  
    },
    ['cardbalances'] = {
        high = 0.6, -- value between 0-1 at a random time between payment timers it will do a credit check and if between this will add the reward value if not with do the reduce value
        low = 0.2
    }
}
Config.CreditLevels = {
    [1] = {
        ['credit'] = 0,
        ['interest'] = {
            ['mortgage'] = 100,
            ['auto'] = 100,
            ['card'] = 100
        },
        ['approval'] = {
            search = 10, --cost to run the check in credit points
            cost = 0, -- cost for approval
            active = 'deny',
            ['mortgage'] = 0,
            ['auto'] = 0,
            ['card'] = 0
        }
        
    },
    [2] = {
        ['credit'] = 300,
        ['interest'] = {
            ['mortgage'] = 17,
            ['auto'] = 36,
            ['card'] = 50
        },
        ['approval'] = {
            search = 10, --cost to run the check in credit points
            cost = 50, -- cost for approval
            active = 'secured',
            security = 1.0,-- amount down toward credit limit between 0-1
            ['mortgage'] = 50000,
            ['auto'] = 10000,
            ['card'] = 10000
        }

    },
    [3] = {
        ['credit'] = 550,
        ['interest'] = {
            ['mortgage'] = 12,
            ['auto'] = 23,
            ['card'] = 48
        },
        ['approval'] = {
            search = 10, --cost to run the check in credit points
            cost = 40, -- cost for approval
            active = 'approve',
            ['mortgage'] = 100000,
            ['auto'] = 15000,
            ['card'] = 15000
        }

    },
    [4] = {
        ['credit'] = 620,
        ['interest'] = {
            ['mortgage'] = 10,
            ['auto'] = 14,
            ['card'] = 34
        },
        ['approval'] = {
            search = 10, --cost to run the check in credit points
            cost = 30, -- cost for approval
            active = 'approve',
            ['mortgage'] = 200000,
            ['auto'] = 30000,
            ['card'] = 30000
        }

    },
    [5] = {
        ['credit'] = 680,
        ['interest'] = {
            ['mortgage'] = 8,
            ['auto'] = 8,
            ['card'] = 26
        },
        ['approval'] = {
            search = 10, --cost to run the check in credit points
            cost = 20, -- cost for approval
            active = 'approve',
            ['mortgage'] = 500000,
            ['auto'] = 50000,
            ['card'] = 50000
        }

    },
    [6] = {
        ['credit'] = 740,
        ['interest'] = {
            ['mortgage'] = 6,
            ['auto'] = 6,
            ['card'] = 20
        },
        ['approval'] = {
            cost = 10, -- cost for approval
            search = 10, --cost to run the check in credit points
            active = 'approve',
            ['mortgage'] = 1000000,
            ['auto'] = 100000,
            ['card'] = 100000
        }

    }
}