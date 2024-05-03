local cfg = {}

cfg.buy_banks = {x = 551.12188720703, y = -3125.3054199219, z = 5.9535965919495 }

cfg.taxes_in_min = 0 -- minimum % taxes for deposit money
cfg.taxes_in_max = 5 -- max % taxes for deposit money

cfg.taxes_out_min = 1 -- minimum % taxes for withdraw money
cfg.taxes_out_max = 10 -- max % taxes for withdraw money

cfg.state_taxes = 10  -- $ taxes from State, whne you taxe profit from your bank you pay taxes for bussines
cfg.min_withdraw = 1000 -- minimum amount to withdraw money from bank
cfg.min_deposit = 1000 -- minimum amount to deposit money from bank
cfg.min_profit_takes = 10000  -- minimum amount to withdraw money from profit bank
cfg.min_add_stacks = 10000 -- minimum amount to add package money to bank, for cash flow

cfg.banks = {
    {bank_id =1,bank_name = "Pillbox Hills",    price_bank = 1000, bank_entry = {x = 150.04544067383, y = -1040.7231445312, z = 29.374082565308}, bank_bussines_location = { x = 145.60704040527, y = -1044.0954589844, z = 29.377792358398 }}, 

    {bank_id =2,bank_name = "Rockford hills",   price_bank = 1000, bank_entry = {x = -1212.6329345703, y = -330.64373779297, z = 37.787029266357}, bank_bussines_location = { x = -1213.0358886719, y = -336.10363769531, z = 37.790725708008 }}, 
    
    {bank_id =3,bank_name = "Alta",             price_bank = 1000, bank_entry = {x = 313.92526245117, y = -278.77856445312, z = 54.17000579834}, bank_bussines_location = { x = 309.96499633789, y = -282.50509643555, z = 54.174480438232 }}, 

    {bank_id =4,bank_name = "Burton",           price_bank = 1000, bank_entry = {x = -350.98733520508, y = -49.871616363525, z = 49.036373138428}, bank_bussines_location = { x = -354.98892211914, y = -53.330612182617, z = 49.04626083374 }}, 

    {bank_id =5,bank_name = "Los Santos County",price_bank = 1000, bank_entry = {x = -2962.4655761719, y = 483.02499389648, z = 15.703091621399}, bank_bussines_location = { x = 2958.1877441406, y = 480.05841064453, z = 15.706806182861 }}, 

    {bank_id =6,bank_name = "Harmony",          price_bank = 1000, bank_entry = {x = 1175.0616455078, y = 2706.8581542969, z = 38.094009399414}, bank_bussines_location = { x = 1177.84765625, y = 2711.4108886719, z = 38.097724914551 }}, 

    {bank_id =7,bank_name = "Blaine County",    price_bank = 1500, bank_entry = {x = -112.31640625, y = 6469.40234375, z = 31.626703262329},      bank_bussines_location = { x = -105.38679504395, y = 6470.5366210938, z = 31.626703262329 }},  

}

cfg.upgrades = {
    {dep_lvl = 1, dep_price = 1000, max_add_stacks = 500000, max_money_in_bank = 1000000}, -- DEFAULT LEVEL
    {dep_lvl = 2, dep_price = 2000, max_add_stacks = 1000000, max_money_in_bank = 2000000},
    {dep_lvl = 3, dep_price = 3000, max_add_stacks = 2000000, max_money_in_bank = 3000000},
    {dep_lvl = 4, dep_price = 4000, max_add_stacks = 3000000, max_money_in_bank = 4000000}
}

return cfg
