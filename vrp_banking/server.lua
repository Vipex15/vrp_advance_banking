local Banking = class("Banking", vRP.Extension)

Banking.User = class("User")

Banking.cfg = module("vrp_banking", "cfg/cfg")

Banking.event = {}
Banking.tunnel = {}

local htmlEntities = module("lib/htmlEntities")

local function formatNumber(number)
    if type(number) == "number" then
        local _, _, minus, int, fraction = tostring(number):find('([-]?)(%d+)([.]?%d*)')
        int = int:reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,", "")
        return minus .. int .. fraction
    else
        return number
    end
end

local function taxes_in(menu) -- set taxes for deposite money amounts
    local user = vRP.users_by_source[menu.user.source]
    local user_id = user.id
    local character_id = user.cid
    local taxes_values = parseInt(user:prompt("Percentage of fees for depositing money ("..Banking.cfg.taxes_in_min.."% - "..Banking.cfg.taxes_in_max.."%)", ""))
    if user then 
    if taxes_values >= Banking.cfg.taxes_in_min and taxes_values <= Banking.cfg.taxes_in_max then
        vRP:execute("vRP/taxes_in", {character_id = character_id, taxes_percent = taxes_values})
        vRP.EXT.Base.remote._notify(user_id, "You set "..taxes_values.."% taxes for deposit money")
        user:actualizeMenu(menu)
    else
        vRP.EXT.Base.remote._notify(user_id, "Taxes value must be between "..Banking.cfg.taxes_in_min.."% and "..Banking.cfg.taxes_in_max.."%.")
    end
end
end

local function taxes_out(menu)   -- set taxes for withdrawn money
    local user = vRP.users_by_source[menu.user.source]
    local user_id = user.id
    local character_id = user.cid
    local taxes_values = parseInt(user:prompt("Percentage of fees for depositing money ("..Banking.cfg.taxes_out_min.."% - "..Banking.cfg.taxes_out_max.."%)", ""))
    if user then 
    if taxes_values >= Banking.cfg.taxes_out_min and taxes_values <= Banking.cfg.taxes_out_max then
        vRP:execute("vRP/taxes_out", {character_id = character_id, taxes_percent = taxes_values})
        vRP.EXT.Base.remote._notify(user_id, "You set "..taxes_values.."% taxes for withdrawn money")
        user:actualizeMenu(menu)
    else
        vRP.EXT.Base.remote._notify(user_id, "Taxes value must be between "..Banking.cfg.taxes_out_min.."% and "..Banking.cfg.taxes_out_max.."%.")
    end
end 
end 

local function create_acc(menu) -- price for create an account 
    local user = vRP.users_by_source[menu.user.source]
    local user_id = user.id
    local character_id = user.cid
    local acc_value = tonumber(user:prompt("Enter the price for opening an account at your bank: ($"..Banking.cfg.acc_price_min.." - $"..Banking.cfg.acc_price_max..")", ""))
    if acc_value then
        if acc_value >= Banking.cfg.acc_price_min and acc_value <= Banking.cfg.acc_price_max then
            vRP:execute("vRP/create_acc", {character_id = character_id, acc_price = acc_value})
            vRP.EXT.Base.remote._notify(user_id, "You set the price to $"..acc_value.." for opening an account.")
            user:actualizeMenu(menu)
        else
            vRP.EXT.Base.remote._notify(user_id, "Price must be between $"..Banking.cfg.acc_price_min.." and $"..Banking.cfg.acc_price_max..".")
        end
    else
        vRP.EXT.Base.remote._notify(user_id, "Invalid input. Please enter a valid number.")
    end
end


local function profit_taxes(menu) -- make profit from your bank
    local user = vRP.users_by_source[menu.user.source]
    if user then
        local user_id = user.id
        local character_id = user.cid
        local bankData = Banking:BanksInfo(character_id) 
        if bankData then
            local profit = bankData.taxes_profit
            local amount = tonumber(user:prompt("Enter the amount to withdraw from taxes profit: (Minimum: "..Banking.cfg.min_profit_takes.."$)", ""))
            if amount and amount >= Banking.cfg.min_profit_takes then
                if amount <= profit then
                    local taxed_amount = math.floor(amount / Banking.cfg.state_taxes) 
                    local final_amout = amount - taxed_amount
                    if user:tryGiveItem("money", final_amout) then
                        local transaction_date = os.date("%Y-%m-%d %H:%M:%S")
                        local transaction_type = "Withdraw Bussines"
                        exports.oxmysql:execute("INSERT IGNORE INTO vrp_banks_transactions (character_id, bank_id, transaction_type, amount, transaction_date) VALUES (?, ?, ?, ?, ?)", {character_id, bankData.bank_id, transaction_type, final_amout, transaction_date}, function()
                            vRP:execute("vRP/take_taxes_profit", {character_id = character_id, taxes_profit = amount})
                            vRP.EXT.Base.remote._notify(user_id, "Withdrawn: $" .. final_amout .. " | State taxes: " .. Banking.cfg.state_taxes.."%")
                            user:actualizeMenu(menu)
                        end)
                    else
                        vRP.EXT.Base.remote._notify(user_id, "Failed to add taxed amount to your bank account.")
                    end
                else
                    vRP.EXT.Base.remote._notify(user_id, "Amount exceeds available money in taxes profit.")
                end
            else
                vRP.EXT.Base.remote._notify(user_id, "Please enter a valid amount greater than "..formatNumber(Banking.cfg.min_profit_takes).."$")
            end
        end
    end
end

local function add_stacks(menu) -- add money in bank for player
    local user = vRP.users_by_source[menu.user.source]
    if user then
        local user_id = user.id
        local character_id = user.cid
        local bankData = Banking:BanksInfo(character_id) 
        if bankData then
            local lvl_dep = bankData.deposit_level
            if lvl_dep then
                local infos_upgrade = Banking.cfg.upgrades[lvl_dep] 
                local max_money = infos_upgrade.max_add_stacks
                local money_bank = bankData.money
                
                local money_binder = user:getItemAmount("money")
                local amount = tonumber(user:prompt("Enter the amount to deposit into your bank:<br>Packaged Money: "..formatNumber(money_binder), ""))
                
                if amount and amount >= Banking.cfg.min_deposit then
                    local total_bank_money = money_bank + amount
                    if total_bank_money <= max_money then
                        if amount >= Banking.cfg.min_add_stacks then
                            if tonumber(money_bank) < Banking.cfg.upgrades[lvl_dep].max_add_stacks then
                                if amount <= money_binder then
                                    if user:tryTakeItem("money", amount) then
                                        local transaction_date = os.date("%Y-%m-%d %H:%M:%S")
                                        local transaction_type = "Deposit Bussines"
                                        exports.oxmysql:execute("INSERT IGNORE INTO vrp_banks_transactions (character_id, bank_id, transaction_type, amount, transaction_date) VALUES (?, ?, ?, ?, ?)", {character_id, bankData.bank_id, transaction_type, amount, transaction_date}, function()
                                            vRP:execute("vRP/update_bank_money", {character_id = character_id, amount = amount})
                                            vRP.EXT.Base.remote._notify(user_id, "Added $" .. amount .. " to your bank.")
                                            user:actualizeMenu(menu)
                                        end)
                                    else
                                        vRP.EXT.Base.remote._notify(user_id, "Failed to make the deposit.")
                                    end
                                else
                                    vRP.EXT.Base.remote._notify(user_id, "Amount exceeds your money stacks.")
                                end
                            else
                                vRP.EXT.Base.remote._notify(user_id, "You have reached the maximum amount of stacks allowed in your bank.")
                            end
                        else
                            vRP.EXT.Base.remote._notify(user_id, "Please enter a valid amount greater than "..tonumber(Banking.cfg.min_add_stacks).."$")
                        end
                    else
                        vRP.EXT.Base.remote._notify(user_id, "The amount exceeds the maximum stacks allowed in your bank.")
                    end
                end
            end
        end
    end
end

local function upgrades_dep()
    vRP.EXT.GUI:registerMenuBuilder("upgrades", function(menu)
        menu.title = "Upgrade Deposit"
        menu.css.header_color = "rgba(255,125,0,0.75)"
        local user = vRP.users_by_source[menu.user.source]
        local user_id = user.id

        if user_id and #Banking.cfg.upgrades > 0 then 
            local character_id = user.cid
            local bankData = Banking:BanksInfo(character_id)
            local current_deposit_level = bankData.deposit_level
            local next_deposit_level = current_deposit_level + 1
            local next_upgrade = Banking.cfg.upgrades[next_deposit_level]

            if next_upgrade then
                local display_text = "Next Upgrade: Level " .. next_upgrade.dep_lvl .. " ( " .. formatNumber(next_upgrade.dep_price) .. "$ )\n" ..
                                     "<br>Max Additional Stacks: " .. formatNumber(next_upgrade.max_add_stacks) .. "\n" ..
                                     "<br>Max Money in Bank: " .. formatNumber(next_upgrade.max_money_in_bank)
                menu:addOption("LVL: "..next_upgrade.dep_lvl .. " ($" .. next_upgrade.dep_price .. ")", function()
                    if user:tryPayment(next_upgrade.dep_price) then
                        vRP.EXT.Base.remote._notify(user_id, "You upgraded the depot to level: " .. next_upgrade.dep_lvl)
                        exports.oxmysql:execute("UPDATE vrp_banks SET deposit_level = ? WHERE owner_id = ?", {next_upgrade.dep_lvl, character_id})
                        user:actualizeMenu(menu)
                        user:actualizeMenu(menu)
                    else
                        vRP.EXT.Base.remote._notify(user_id, "Not enough money to purchase " .. next_upgrade.dep_lvl)
                    end
                end, display_text)
            else
                menu:addOption("Max level", nil, "Maximum deposit level reached.")
            end
        end
    end)
end

local function upg_dep(menu)
    local user = menu.user
    user:openMenu("upgrades")
end

local function Bank_Info()
    vRP.EXT.GUI:registerMenuBuilder("Bank Info", function(menu)
        menu.title = "Bank Info"
        menu.css.header_color = "rgba(0,255,0,0.75)"

        local user = vRP.users_by_source[menu.user.source]
        if user then
            local character_id = user.cid
            local bankData = Banking:BanksInfo(character_id)
            local identity = vRP.EXT.Identity:getIdentity(character_id)
            local money_binder = user:getItemAmount("money")
            if bankData and identity and #Banking.cfg.upgrades > 0 then
                local bank_name = bankData.bank_name
                local money = formatNumber(bankData.money)
                local Profit = formatNumber(bankData.taxes_profit)
                local taxesIn = bankData.taxes_in
                local taxesOut = bankData.taxes_out
                local acc_price = bankData.create_acc
                local lvl_dep = bankData.deposit_level
                local infos_upgrade = Banking.cfg.upgrades[lvl_dep]

                menu:addOption("Info", nil, "Owner: "..identity.name.." "..identity.firstname.."<br>Bank: "..bank_name.."<br>Money: "..formatNumber(money).."<br>Account Price: "..acc_price.."$<br>Taxes In: "..taxesIn.."<br>Taxes Out: "..taxesOut..
                                            "<br>Deposit Level: "..lvl_dep.. "<br>Max Stacks: " .. formatNumber(infos_upgrade.max_add_stacks).."<br>Max Money: " ..formatNumber(infos_upgrade.max_money_in_bank).."<br> Profit: "..Profit)

                menu:addOption("Account Price", create_acc, "Price for create an account for your bank ("..Banking.cfg.acc_price_min.."% - "..Banking.cfg.acc_price_max.."%)")
                menu:addOption("Taxes In", taxes_in, "Fees for deposits the money ("..Banking.cfg.taxes_in_min.."% - "..Banking.cfg.taxes_in_max.."%)")
                menu:addOption("Taxes Out", taxes_out, "Fees for withdraws money ("..Banking.cfg.taxes_out_min.."% - "..Banking.cfg.taxes_out_max.."%)")
                menu:addOption("Stacks", add_stacks,"Add stack: "..formatNumber(money_binder))
                menu:addOption("Profit", profit_taxes,"Take your profit from the bank ("..Profit.."$)")
                menu:addOption("Upgrade", upg_dep,"Upgrade bank deposit")
            end
        end
    end)
end

local function transactions_menu(self)
    vRP.EXT.GUI:registerMenuBuilder("Your Transactions", function(menu)
        menu.title = "Your Transactions"
        menu.css.header_color = "rgba(255,125,0,0.75)"
        
        local user = vRP.users_by_source[menu.user.source]
        local character_id = user.cid

        if character_id then 
            local transactions = Banking:GetUserTransactions(character_id)
            
            if next(transactions) then
                table.sort(transactions, function(a, b)
                    if a.transaction_date == b.transaction_date then
                        return a.transaction_hours > b.transaction_hours
                    else
                        return a.transaction_date > b.transaction_date
                    end
                end)

                for index = 1, #transactions do
                    local transaction = transactions[index]
                    local transaction_info = string.format("Transaction %d:<br>Type: %s<br>Amount: %s$<br>Date: %s <br>Hours:%s", index, transaction.transaction_type, transaction.amount, transaction.transaction_date, transaction.transaction_hours)
                    menu:addOption("Transaction " .. index, nil, transaction_info)
                end
            else
                menu:addOption("No Transactions", nil, "You have no transactions.")
            end
        end
    end)
end

local function see_transactions(menu)
    local user = menu.user
    user:openMenu("Your Transactions")
end

local function menu_police_pc_trans(self)
    vRP.EXT.GUI:registerMenuBuilder("Transactions", function(menu)
        local user = menu.user
        local reg = user:prompt("Enter character ID:", "")
        if reg then 
            local cid = vRP.EXT.Identity:getByRegistration(reg)
            if cid then
                local identity = vRP.EXT.Identity:getIdentity(cid)
                if identity then
                    local character_id = identity.character_id 
                    menu.title = identity.firstname.." "..identity.name
                    menu.css.header_color = "rgba(0,255,0,0.75)"           
                     
                    if character_id then
                        local transactions = Banking:GetUserTransactions(character_id)
                        if next(transactions) then
                            table.sort(transactions, function(a, b)
                                if a.transaction_date == b.transaction_date then
                                    return a.transaction_hours > b.transaction_hours
                                else
                                    return a.transaction_date > b.transaction_date
                                end
                            end)
                            for index = 1, #transactions do
                                local transaction = transactions[index]
                                local transaction_info = string.format("Transaction %d:<br>Type: %s<br>Amount: %s$<br>Date: %s <br>Hours:%s", index, transaction.transaction_type, transaction.amount, transaction.transaction_date, transaction.transaction_hours)
                                menu:addOption("Transaction " .. index, nil, transaction_info)
                            end
                        else
                            menu:addOption("No Transaction " , nil, identity.firstname.." "..identity.name.." has no transaction")
                            vRP.EXT.Base.remote._notify(user.source, "No transactions found for this player.")
                        end
                    else
                        vRP.EXT.Base.remote._notify(user.source, "Character ID not found for this player.")
                    end
                else
                    vRP.EXT.Base.remote._notify(user.source, "Identity not found for this registration.")
                end
            else
                vRP.EXT.Base.remote._notify(user.source, "No character found with this registration.")
            end
        else
            vRP.EXT.Base.remote._notify(user.source, "Character ID not entered.")
        end
    end)

    local function police_se_transactions(menu)
        local user = menu.user
        user:openMenu("Transactions")
    end

    vRP.EXT.GUI:registerMenuBuilder("police_pc", function(menu)
        local user = menu.user
        if user:hasGroup("police") then 
            menu:addOption("Transactions", police_se_transactions, "See player information")
        end
    end)
end

function Banking:getUserBank(user)
    local banks = Banking.cfg.banks
    for bank_id, bankData in pairs(banks) do
        local area_id = "vRP:vrp_banking:BankFuncitons:" .. bank_id
        if user:inArea(area_id) then
            return bank_id, bankData.bank_name
        end
    end
    return nil, "Unknown Bank"
end

function Banking:withdraw(amount)
    local user = vRP.users_by_source[source]
    if user then
        local user_id = user.id
        local character_id = user.cid
        local bank_id = Banking:getUserBank(user)
        if bank_id then
            local bankData = Banking:IDBankInfo(bank_id) 
            if bankData then 
                local taxes_out_percent = bankData.taxes_out
                local balance = user:getBank()
                amount = tonumber(amount)
                if amount and amount >= Banking.cfg.min_withdraw and amount <= balance then
                    local taxed_amount = math.floor(amount * (taxes_out_percent / 100)) 
                    if tonumber(amount) <= tonumber(bankData.money) then
                        if user:tryWithdraw(amount) and user:tryPayCard(taxed_amount) then
                            local transaction_date = os.date("%Y-%m-%d %H:%M:%S")
                            local transaction_type = "Withdraw"
                            exports.oxmysql:execute("INSERT IGNORE INTO vrp_banks_transactions (character_id, bank_id, transaction_type, amount, transaction_date) VALUES (?, ?, ?, ?, ?)",  {character_id, bank_id, transaction_type, amount, transaction_date}, function()
                                vRP:execute("vRP/add_taxes_profit", {character_id = character_id, taxed_amount = taxed_amount}) 
                                vRP.EXT.Base.remote._notify(user_id, "Withdrawn: $" .. formatNumber(amount) .. " (Taxed: " .. formatNumber(taxed_amount).."$)")
                            end)
                            exports.oxmysql:execute("UPDATE vrp_banks SET money = money - ? WHERE bank_id = ?", {amount, bank_id})
                        else
                            vRP.EXT.Base.remote._notify(user_id, "Failed to withdraw funds.")
                        end
                    else
                        vRP.EXT.Base.remote._notify(user_id, "Not enough funds in the bank")
                    end
                else
                    vRP.EXT.Base.remote._notify(user_id, "Invalid withdrawal amount.")
                end
            end
        end
    end
end

function Banking:deposit(amount)-- DEPOSIT MONEY INTO YOUR ACCOUNT AND BANK
    local user = vRP.users_by_source[source]
    if user then
        local user_id = user.id
        local character_id = user.cid
        local bank_id = Banking:getUserBank(user)
        if bank_id then
            local bankData = Banking:IDBankInfo(bank_id) 
            if bankData then
                local lvl_dep = bankData.deposit_level
                local infos_upgrade = Banking.cfg.upgrades[lvl_dep] 
                local max_money = infos_upgrade.max_money_in_bank
                local money_bank = bankData.money
                local balance = user:getWallet()
                amount = tonumber(amount)
                if amount and amount >= Banking.cfg.min_deposit and amount <= balance then
                    local taxes_in_percent = bankData.taxes_in
                    local taxed_amount = math.floor(amount * (taxes_in_percent / 100)) 
                    if money_bank + amount <= max_money then
                        if user:tryDeposit(amount) and user:tryPayCard(taxed_amount) then
                            local transaction_date = os.date("%Y-%m-%d %H:%M:%S")
                            local transaction_type = "Deposit"
                            exports.oxmysql:execute("INSERT IGNORE INTO vrp_banks_transactions (character_id, bank_id, transaction_type, amount, transaction_date) VALUES (?, ?, ?, ?, ?)",  {character_id, bankData.bank_id, transaction_type, amount, transaction_date}, function()
                                vRP:execute("vRP/add_taxes_profit", {character_id = character_id, taxed_amount = taxed_amount}) 
                                exports.oxmysql:execute("UPDATE vrp_banks SET money = money + ? WHERE bank_id = ?", {amount, bankData.bank_id})
                                vRP.EXT.Base.remote._notify(user_id, "Deposited: $" .. formatNumber(amount) .. " (Taxed: " ..formatNumber(taxed_amount).."$)")
                            end)
                        else
                            vRP.EXT.Base.remote._notify(user_id, "Failed to deposit funds.")
                        end
                    else
                        vRP.EXT.Base.remote._notify(user_id, "Bank is full.")
                    end
                else
                    vRP.EXT.Base.remote._notify(user_id, "Invalid deposit amount or insufficient balance.")
                end
            end
        end
    end
end

local function BankFunctions(self)
    vRP.EXT.GUI:registerMenuBuilder("Bank Functions", function(menu)
        local user = vRP.users_by_source[menu.user.source]
        local character_id = user.cid
        local bank_id, bank_name = Banking:getUserBank(user)
        if bank_id then
            local bankData = Banking:IDBankInfo(bank_id)
            if bankData then
                local taxes_out_percent = bankData.taxes_out
                local taxes_in_percent = bankData.taxes_in
                local acc_price = bankData.create_acc

                menu.title = bank_name.." Bank"
                menu.css.header_color = "rgba(0,255,0,0.75)"

                if character_id then
                    local identity = vRP.EXT.Identity:getIdentity(character_id)

                    local account = Banking:getBankAccount(character_id, bank_id)
                    if not account then
                        menu:addOption("Create Account", function()
                            local try = user:request("Create an account for "..bank_name.." bank ("..acc_price.."$)", 10)
                            if try then
                            if user:tryPayment(acc_price) then 
                            exports.oxmysql:executeSync("INSERT INTO vrp_banks_accounts (character_id, bank_id, bank_name) VALUES (?, ?, ?)", {character_id, bank_id, bank_name})
                            exports.oxmysql:executeSync("UPDATE vrp_banks SET taxes_profit = taxes_profit + ? WHERE bank_id = ?", {acc_price, bank_id})
                            vRP.EXT.Base.remote._notify(user.source, "Bank account created successfully.")
                            user:actualizeMenu(menu)
                            else
                            vRP.EXT.Base.remote._notify(user.source, "Not enough money to create an account. Account creation costs " .. acc_price .. "$")
                        end
                    end
                    end, "Create an account for "..bank_name.." bank ($" .. acc_price .. ")")
                else
                        local deposit_message = "Deposit funds into your bank account: <br>Taxes: "..taxes_in_percent.."%"
                        if Banking.cfg.min_deposit > 0 then
                            deposit_message = deposit_message .. "<br> Min. deposit: $" .. formatNumber(Banking.cfg.min_deposit)
                        end

                        local withdraw_message = "Withdraw funds from your bank account: <br>Taxes: "..taxes_out_percent.."%"
                        if Banking.cfg.min_withdraw > 0 then
                            withdraw_message = withdraw_message .. "<br> Min. withdrawal: $" .. formatNumber(Banking.cfg.min_withdraw)
                        end

                        menu:addOption("Account Info", nil, string.format(identity.firstname.." "..identity.name.." account:<br>Wallet Balance: %s<br>Bank Balance: %s",
                            htmlEntities.encode(formatNumber(user:getWallet())), htmlEntities.encode(formatNumber(user:getBank()))))

                        menu:addOption("Transactions", see_transactions, "Your Transactions")

                        menu:addOption("Deposit Money", function()
                            local deposit_amount = user:prompt("Enter the amount to deposit:", "")
                            Banking:deposit(deposit_amount)
                            user:actualizeMenu(menu)
                        end, deposit_message)

                        menu:addOption("Withdraw Funds", function()
                            local withdraw_amount = user:prompt("Enter the amount to withdraw:", "")
                            Banking:withdraw(withdraw_amount)
                            user:actualizeMenu(menu)
                        end, withdraw_message)
                    end
                end
            end
        end
    end)
end

local function buy_bank() -- BUY BANKS
    vRP.EXT.GUI:registerMenuBuilder("Buy Banks", function(menu)
        menu.title = "Buy Banks"
        menu.css.header_color = "rgba(0,255,0,0.75)"
        local user = vRP.users_by_source[menu.user.source]
        local user_id = user.id
        local character_id = user.cid
        local bankData = Banking:BanksInfo(character_id)

        if character_id then 
            for _, bankData in ipairs(Banking.cfg.banks) do
                if not user:HasAnyBank() then
                    if not Banking:IsBankOwnedByOthers(bankData.bank_id, character_id) then
                        menu:addOption(bankData.bank_name .. " ($" .. bankData.price_bank .. ")", function()
                            if user:tryPayment(bankData.price_bank) then
                                vRP.EXT.Base.remote._notify(user_id, "Factory purchased: " .. bankData.bank_name)
                                for i, f in ipairs(Banking.cfg.banks) do
                                    if f.bank_id == bankData.bank_id then
                                        table.remove(Banking.cfg.banks, i)
                                        break
                                    end
                                end
                                user:AddBank(bankData.bank_id)
                                print("ID: "..character_id.." bought "..bankData.bank_name)
                                user:actualizeMenu(menu)
                            else
                                vRP.EXT.Base.remote._notify(user_id, "Not enough money to purchase " .. bankData.bank_name)
                            end
                        end) 
                    end
                end
            end 
            if bankData then
                local bankName = bankData.bank_name
                menu:addOption(bankName .. " (Owned)", function()
                    vRP.EXT.Base.remote._notify(user_id, "You already own the " ..bankName.. " bank")
                end, user_id)
            end
        end
    end)
end           

local function cards()
    vRP.EXT.GUI:registerMenuBuilder("cards", function(menu)
        menu.title = "Bank Accounts"
        menu.css.header_color = "rgba(0,255,0,0.75)"
        local user = menu.user
        local character_id = user.cid

        if character_id then
            local accounts = exports.oxmysql:executeSync("SELECT character_id, bank_id, bank_name FROM vrp_banks_accounts WHERE character_id = ?", {character_id})
            if accounts and #accounts > 0 then
                for _, account in ipairs(accounts) do
                    menu:addOption(account.bank_name, function()
                    end)
                end
            else
                menu:addOption("No accounts", nil, "You have no bank accounts.")
            end
        end
    end)
end

local function m_cards(menu)
    menu.user:openMenu("cards")
  end

  vRP.EXT.GUI:registerMenuBuilder("main", function(menu)
    menu:addOption("Bank Accounts", m_cards, "Your banks accounts")
  end)

function Banking:__construct()
    vRP.Extension.__construct(self)
    
    self.cfg = module("vrp_banking", "cfg/cfg")

    -- load async
    async(function()
        vRP:prepare("vRP/banks", [[
                CREATE TABLE IF NOT EXISTS vrp_banks (
                    owner_id INT NOT NULL DEFAULT 0,
                    bank_id INT AUTO_INCREMENT PRIMARY KEY,
                    bank_name VARCHAR(255) NOT NULL,
                    money DECIMAL(12) NOT NULL DEFAULT 1000,
                    taxes_profit INT NOT NULL DEFAULT 0,
                    taxes_in INT NOT NULL DEFAULT 0,
                    taxes_out INT NOT NULL DEFAULT 0,
                    create_acc INT NOT NULL DEFAULT 0,
                    deposit_level INT NOT NULL DEFAULT 1
                );
                CREATE TABLE IF NOT EXISTS vrp_banks_transactions (
                    id INT AUTO_INCREMENT PRIMARY KEY,
                    character_id INT NOT NULL, 
                    bank_id INT NOT NULL,
                    transaction_type ENUM('Deposit', 'Withdraw', 'Transfer', 'Deposit Bussines','Withdraw Bussines') NOT NULL,
                    amount DECIMAL(12) NOT NULL,
                    transaction_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                    FOREIGN KEY (character_id) REFERENCES vrp_users(id),
                    FOREIGN KEY (bank_id) REFERENCES vrp_banks(bank_id) 
                );
                CREATE TABLE IF NOT EXISTS vrp_banks_accounts (
                    id INT AUTO_INCREMENT PRIMARY KEY,
                    character_id INT NOT NULL, 
                    bank_id INT NOT NULL,
                    bank_name VARCHAR(255) NOT NULL,
                    FOREIGN KEY (character_id) REFERENCES vrp_users(id),
                    FOREIGN KEY (bank_id) REFERENCES vrp_banks(bank_id) 
                );
            ]])
            vRP:execute("vRP/banks")
            end)
			vRP:prepare("vRP/insert_bank", "UPDATE vrp_banks SET owner_id = @character_id WHERE bank_id = @bank_id")
			vRP:prepare("vRP/select_bank", "SELECT bank_id FROM vrp_banks WHERE owner_id = @character_id")
            vRP:prepare("vRP/delete_bank", "UPDATE vrp_banks SET owner_id = 0 WHERE owner_id = @character_id AND bank_id = @bank_id")

            vRP:prepare("vRP/taxes_in", "UPDATE vrp_banks SET taxes_in = @taxes_percent WHERE owner_id = @character_id")
            vRP:prepare("vRP/taxes_out", "UPDATE vrp_banks SET taxes_out = @taxes_percent WHERE owner_id = @character_id")

            vRP:prepare("vRP/create_acc", "UPDATE vrp_banks SET create_acc = @acc_price WHERE owner_id = @character_id")


            vRP:prepare("vRP/add_taxes_profit", "UPDATE vrp_banks SET taxes_profit = taxes_profit + @taxed_amount WHERE owner_id = @character_id")
            vRP:prepare("vRP/take_taxes_profit", "UPDATE vrp_banks SET taxes_profit = taxes_profit - @amount WHERE owner_id = @character_id")

            vRP:prepare("vRP/update_bank_money", "UPDATE vrp_banks SET money = money + @amount WHERE owner_id = @character_id")
 

    cards(self)        
	buy_bank(self) 
    Bank_Info(self)
    BankFunctions(self)
    transactions_menu(self)
    upgrades_dep(self)

    menu_police_pc_trans(self)

    for _, bankData in ipairs(self.cfg.banks) do
        exports.oxmysql:execute("INSERT IGNORE INTO vrp_banks (bank_id, bank_name) VALUES (?, ?)",  {bankData.bank_id, bankData.bank_name},  function()
            end)
		end
end

function Banking:getBankAccount(character_id, bank_id)
    local rows = exports.oxmysql:executeSync("SELECT character_id, bank_id, bank_name FROM vrp_banks_accounts WHERE character_id = ? AND bank_id = ?", {character_id, bank_id})
    if rows and #rows > 0 then
        return rows[1] 
    else
        return nil
    end
end


function Banking:GetUserTransactions(character_id)
    local transactions = {} 
    local rows = exports.oxmysql:executeSync("SELECT transaction_type, amount, DATE_FORMAT(transaction_date, '%d-%m-%Y') AS formatted_date, DATE_FORMAT(transaction_date, '%H:%i:%s') AS formatted_hours FROM vrp_banks_transactions WHERE character_id = ?", {character_id})
    if rows then
        for _, row in ipairs(rows) do
            local transaction = {
                transaction_type = row.transaction_type,
                amount = row.amount,
                transaction_date = row.formatted_date,
                transaction_hours = row.formatted_hours
            }
            table.insert(transactions, transaction) 
        end
    end
    return transactions
end

function Banking:IDBankInfo(bank_id)
    local rows = exports.oxmysql:executeSync("SELECT * FROM vrp_banks WHERE bank_id = ?", {bank_id})
    if rows and #rows > 0 then
        local bankData = rows[1]
        local bankId = bankData.bank_id
        local bankName = bankData.bank_name
        local money = bankData.money
        local Profit = bankData.taxes_profit
        local taxesIn = bankData.taxes_in
        local taxesOut = bankData.taxes_out
        local acc_price = bankData.create_acc
        local dep_lvl = bankData.deposit_level
        return { bank_id = bankId, bank_name = bankName, money = money, taxes_in = taxesIn, taxes_out = taxesOut, taxes_profit = Profit, create_acc = acc_price, deposit_level = dep_lvl}
    else
        return nil
    end
end


function Banking:BanksInfo(character_id)
    local rows = exports.oxmysql:executeSync("SELECT * FROM vrp_banks WHERE owner_id = ?", {character_id })
    if rows and #rows > 0 then
        local bankData = rows[1]
        local bankId = bankData.bank_id
        local bankName = bankData.bank_name
        local money = bankData.money
        local Profit = bankData.taxes_profit
        local taxesIn = bankData.taxes_in
        local taxesOut = bankData.taxes_out
        local acc_price = bankData.create_acc
        local dep_lvl = bankData.deposit_level
        return { bank_id = bankId, bank_name = bankName, money = money, taxes_in = taxesIn, taxes_out = taxesOut, taxes_profit = Profit, create_acc = acc_price, deposit_level = dep_lvl}
    else
        return nil
    end
end

function Banking:IsBankOwnedByOthers(bank_id, character_id)
    local rows = exports.oxmysql:executeSync("SELECT owner_id FROM vrp_banks WHERE bank_id = ?", {bank_id})
    if rows and #rows > 0 then
        local owner_id = rows[1].owner_id
        return owner_id ~= 0 and owner_id ~= character_id
    else
        return false
    end
end

function Banking.User:HasBank(bank_id)
    local character_id = self.cid
    local rows = vRP:query("vRP/select_bank", {character_id = character_id})
    for _, row in ipairs(rows) do
        if row.bank_id == bank_id then
            return true
        end
    end
    return false
end

function Banking.User:HasAnyBank()
    local rows = vRP:query("vRP/select_bank", {character_id = self.cid})
    for _, row in pairs(rows) do
        if row.bank_id then
            return true
        end
    end
    return false  
end

function Banking.User:AddBank(bank_id)
    if not self:HasAnyBank() then
        vRP:execute("vRP/insert_bank", {character_id =  self.cid, bank_id = bank_id})
    end
end


function Banking.User:RemoveBank(bank_id)
	if self:HasAnyBank() then
    vRP:execute("vRP/delete_bank", {character_id =  self.cid, bank_id = bank_id})
	end
end

local buy_bank = { x = -68.705848693848, y = -799.89520263672, z = 44.227291107178} 

function Banking.event:playerSpawn(user, first_spawn)
    if first_spawn then
        for k,v in pairs(self.cfg.banks) do
            local buyx, buyy, buyz = buy_bank.x, buy_bank.y, buy_bank.z  -- BUY BANKS
            
            local enter_buy = function(user)
                user:openMenu("Buy Banks")
            end
            
            local leave_buy = function(user)
                user:closeMenu("Buy Banks")
            end
            
            local bank_blip = {"PoI", {blip_id = 500, blip_color = 46, marker_id = 1}}
            local mentBuy = clone(bank_blip)
            mentBuy[2].pos = {buyx, buyy, buyz - 1}
            vRP.EXT.Map.remote._addEntity(user.source, mentBuy[1], mentBuy[2])
        
            user:setArea("vRP:vrp_banking:buy_banks", buyx, buyy, buyz, 1, 1.5, enter_buy, leave_buy)

            -------------------------------------------------------------------------------------------

            local bank_locations = v.bank_entry
            local bank_id = v.bank_id
            local bank_name = v.bank_name

            local Bankx, Banky, Bankz = bank_locations.x, bank_locations.y, bank_locations.z -- ENTER BANKS FUCNTIONALITY DEPOSIT / WITHDRAWS

            local function BankFuncitons(user)
                user:openMenu("Bank Functions")
            end
    
            local function BankFuncitonsLeave(user)
                user:closeMenu("Bank Functions")
            end

            local bank_info = {"PoI", {blip_id = 108, blip_color = 69, marker_id = 1}}
            local ment = clone(bank_info)
            ment[2].pos = {Bankx, Banky, Bankz - 1}
            vRP.EXT.Map.remote._addEntity(user.source, ment[1], ment[2])
    
            user:setArea("vRP:vrp_banking:BankFuncitons:" .. k, Bankx, Banky, Bankz, 1, 1.5, BankFuncitons, BankFuncitonsLeave)
            
            -------------------------------------------------------------------------------------------

            -- INFO
            local bank_bussines_location = v.bank_bussines_location -- BUSSINES BANKS LOCAITONS 
            local x, y, z = bank_bussines_location.x, bank_bussines_location.y, bank_bussines_location.z
        
            local function BankInfo(user)
                if user:HasBank(bank_id) then
                    user:openMenu("Bank Info")
                    end
                end
        
            local function BankInfoLeave(user)
                user:closeMenu("Bank Info")
            end

            local bank_info = {"PoI", {marker_id = 1}}
            local ment = clone(bank_info)
            ment[2].pos = {x, y, z - 1}
            vRP.EXT.Map.remote._addEntity(user.source, ment[1], ment[2])
        
                user:setArea("vRP:vrp_banking:info:" .. k, x, y, z, 1, 1.5, BankInfo, BankInfoLeave)
            end
        end
    end

vRP:registerExtension(Banking)
