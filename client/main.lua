local Config = require('config')
local managerPed = nil
local managerBlip = nil
local locale = Locale.T

Locale.LoadLocale('en')

--- Create manager blip
---@return nil
local CreateManagerBlip = function()
    if Config.Manager.blip and Config.Manager.blip.enabled then
        managerBlip = AddBlipForCoord(Config.Manager.coords.x, Config.Manager.coords.y, Config.Manager.coords.z)
        SetBlipSprite(managerBlip, Config.Manager.blip.sprite)
        SetBlipColour(managerBlip, Config.Manager.blip.color)
        SetBlipScale(managerBlip, Config.Manager.blip.scale)
        SetBlipAsShortRange(managerBlip, Config.Manager.blip.shortRange)
        BeginTextCommandSetBlipName('STRING')
        AddTextComponentString(Config.Manager.blip.label)
        EndTextCommandSetBlipName(managerBlip)
    end
end

--- Create ox_target zones for all storage units
CreateThread(function()
    CreateManagerBlip()
    for _, storage in pairs(Config.Storages) do
        exports.ox_target:addBoxZone({
            coords = storage.coords,
            size = vec3(storage.length, storage.width, storage.maxZ - storage.minZ),
            rotation = storage.heading,
            debug = false,
            options = {
                {
                    name = 'check_storage_' .. storage.id,
                    icon = 'fas fa-box',
                    label = locale('storage_unit', { id = storage.id }),
                    onSelect = function()
                        OpenStorageMenu(storage.id)
                    end,
                    distance = 2.0
                }
            }
        })
    end
end)

--- Manager ped proximity system
CreateThread(function()
    while true do
        local playerCoords = GetEntityCoords(PlayerPedId())
        local distance = #(playerCoords - Config.Manager.coords)

        if distance <= Config.Manager.spawnDistance and not managerPed then
            SpawnManagerPed()
        elseif distance > Config.Manager.spawnDistance and managerPed then
            DespawnManagerPed()
        end

        Wait(1000)
    end
end)

--- Spawn manager ped
---@return nil
SpawnManagerPed = function()
    lib.requestModel(Config.Manager.model)
    managerPed = CreatePed(4, GetHashKey(Config.Manager.model), Config.Manager.coords.x, Config.Manager.coords.y,
        Config.Manager.coords.z - 1.0, Config.Manager.heading, false, true)

    SetEntityInvincible(managerPed, true)
    SetBlockingOfNonTemporaryEvents(managerPed, true)
    FreezeEntityPosition(managerPed, true)

    exports.ox_target:addLocalEntity(managerPed, {
        {
            name = 'storage_manager',
            icon = 'fas fa-warehouse',
            label = locale('talk_to_storage_manager'),
            onSelect = function()
                OpenManagerMenu()
            end,
            distance = Config.Manager.interactDistance
        }
    })
end

--- Despawn manager ped
---@return nil
DespawnManagerPed = function()
    if managerPed then
        exports.ox_target:removeLocalEntity(managerPed, 'storage_manager')
        DeleteEntity(managerPed)
        managerPed = nil
    end
end

--- Open manager menu
---@return nil
OpenManagerMenu = function()
    ---@param rentalInfo table|nil Rental information for the player
    lib.callback('storage:getRentalInfo', false, function(rentalInfo)
        local options = {}

        if rentalInfo then
            ---@param paymentInfo table|nil Payment information for the rental
            lib.callback('storage:getPaymentInfo', false, function(paymentInfo)
                local roleText = rentalInfo.isOwner and locale('owner') or locale('user_with_access')
                local autoRenewalText = rentalInfo.autoRenewal and locale('enabled') or locale('disabled')
                local ownershipText = rentalInfo.purchased and locale('owned') or ""
                
                -- Only show auto-renewal status for rented units, not purchased ones
                local autoRenewalDisplay = ""
                if rentalInfo.isOwner and not rentalInfo.purchased then
                    autoRenewalDisplay = ' | ' .. locale('auto_renewal') .. ': ' .. autoRenewalText
                end

                table.insert(options, {
                    title = locale('current_access', { role = roleText, ownership = ownershipText }),
                    description = locale('storage_unit', { id = rentalInfo.unitId }) .. autoRenewalDisplay,
                    icon = rentalInfo.isOwner and 'fas fa-crown' or 'fas fa-key'
                })

                if rentalInfo.isOwner and not rentalInfo.purchased then
                    table.insert(options, {
                        title = locale('payment_management'),
                        description = locale('manage_payments_desc'),
                        icon = 'fas fa-credit-card',
                        onSelect = function()
                            OpenPaymentMenu(rentalInfo.unitId)
                        end
                    })
                end

                if rentalInfo.isOwner then
                    table.insert(options, {
                        title = locale('manage_storage_unit'),
                        description = locale('manage_access_desc'),
                        icon = 'fas fa-cog',
                        onSelect = function()
                            OpenManagementMenu(rentalInfo.unitId)
                        end
                    })
                else
                    -- User has access but isn't owner - still allow them to rent/purchase
                    if Config.Pricing.enableRent then
                        table.insert(options, {
                            title = locale('rent_your_own_storage'),
                            description = locale('rent_storage_desc', { price = Config.Pricing.rent }),
                            icon = 'fas fa-dollar-sign',
                            onSelect = function()
                                ShowAvailableUnits(rentalInfo.unitId)
                            end
                        })
                    end
                    
                    if Config.Pricing.enableBuy then
                        table.insert(options, {
                            title = locale('purchase_your_own_storage'),
                            description = locale('purchase_storage_desc', { price = Config.Pricing.purchase }),
                            icon = 'fas fa-home',
                            onSelect = function()
                                ShowPurchaseUnits(rentalInfo.unitId)
                            end
                        })
                    end
                end

                lib.registerContext({
                    id = 'storage_manager_menu',
                    title = locale('storage_manager'),
                    options = options
                })

                lib.showContext('storage_manager_menu')
            end)
        else
            if Config.Pricing.enableRent then
                table.insert(options, {
                    title = locale('rent_storage_unit'),
                    description = locale('rent_for_weekly', { price = Config.Pricing.rent }),
                    icon = 'fas fa-dollar-sign',
                    onSelect = function()
                        ShowAvailableUnits()
                    end
                })
            end

            if Config.Pricing.enableBuy then
                table.insert(options, {
                    title = locale('purchase_storage_unit'),
                    description = locale('buy_permanently', { price = Config.Pricing.purchase }),
                    icon = 'fas fa-home',
                    onSelect = function()
                        ShowPurchaseUnits()
                    end
                })
            end
        end

        lib.registerContext({
            id = 'storage_manager_menu',
            title = 'Storage Manager',
            options = options
        })

        lib.showContext('storage_manager_menu')
    end)
end

--- Show available units for rent
---@param excludeUnitId number|nil Unit ID to exclude from list
---@return nil
ShowAvailableUnits = function(excludeUnitId)
    ---@param availableUnits table[] List of available storage units
    lib.callback('storage:getAvailableUnits', false, function(availableUnits)
        local options = {}

        for _, unit in pairs(availableUnits) do
            if unit.id ~= excludeUnitId and unit.available then
                table.insert(options, {
                    title = locale('storage_unit', { id = unit.id }),
                    description = locale('rent_for', { price = Config.Pricing.rent }),
                    icon = 'fas fa-warehouse',
                    onSelect = function()
                        RentStorageUnit(unit.id)
                    end
                })
            end
        end

        if #options == 0 then
            table.insert(options, {
                title = locale('no_available_units'),
                description = locale('all_units_full'),
                icon = 'fas fa-exclamation-triangle'
            })
        end

        lib.registerContext({
            id = 'available_units',
            title = locale('available_units_rent'),
            menu = 'storage_manager_menu',
            options = options
        })

        lib.showContext('available_units')
    end)
end

--- Show available units for purchase
---@param excludeUnitId number|nil Unit ID to exclude from list
---@return nil
ShowPurchaseUnits = function(excludeUnitId)
    ---@param availableUnits table[] List of available storage units
    lib.callback('storage:getAvailableUnits', false, function(availableUnits)
        local options = {}

        for _, unit in pairs(availableUnits) do
            if unit.id ~= excludeUnitId and unit.available then
                table.insert(options, {
                    title = locale('storage_unit', { id = unit.id }),
                    description = locale('purchase_for', { price = Config.Pricing.purchase }),
                    icon = 'fas fa-home',
                    onSelect = function()
                        ConfirmPurchaseUnit(unit.id)
                    end
                })
            end
        end

        if #options == 0 then
            table.insert(options, {
                title = locale('no_units_available_purchase'),
                description = locale('all_units_owned_rented'),
                icon = 'fas fa-exclamation-triangle'
            })
        end

        lib.registerContext({
            id = 'purchase_units',
            title = locale('available_units_purchase'),
            menu = 'storage_manager_menu',
            options = options
        })

        lib.showContext('purchase_units')
    end)
end

--- Management menu - owner only
---@param unitId number Storage unit ID
---@return nil
OpenManagementMenu = function(unitId)
    local options = {
        {
            title = locale('manage_access'),
            description = locale('view_remove_users'),
            icon = 'fas fa-users',
            onSelect = function()
                ShowAccessList(unitId)
            end
        },
        {
            title = locale('grant_access'),
            description = locale('give_player_access'),
            icon = 'fas fa-user-plus',
            onSelect = function()
                GrantPlayerAccess(unitId)
            end
        },
        {
            title = locale('upgrade_storage'),
            description = locale('increase_capacity'),
            icon = 'fas fa-arrow-up',
            onSelect = function()
                ShowUpgradeMenu(unitId)
            end
        },
        {
            title = locale('delete_storage_unit'),
            description = locale('permanently_delete'),
            icon = 'fas fa-trash',
            onSelect = function()
                ConfirmDeleteUnit(unitId)
            end
        }
    }

    lib.registerContext({
        id = 'management_menu',
        title = locale('storage_management'),
        menu = 'storage_manager_menu',
        options = options
    })

    lib.showContext('management_menu')
end

--- Show upgrade menu
---@param unitId number Storage unit ID
---@return nil
ShowUpgradeMenu = function(unitId)
    ---@param upgradeData table|false Upgrade information or false on error
    lib.callback('storage:getAvailableUpgrades', false, function(upgradeData)
        if not upgradeData then
            ShowNotification(locale('failed_get_upgrade_info'), 'error')
            return
        end

        local options = {}

        table.insert(options, {
            title = locale('current_storage_limits'),
            description = locale('limits_format', { slots = upgradeData.currentLimits.slots, weight = (upgradeData.currentLimits.weight / 1000) }),
            icon = 'fas fa-info-circle'
        })

        for _, upgrade in pairs(upgradeData.upgrades) do
            local stackText = ""
            if upgrade.maxStack > 1 then
                stackText = " (" .. upgrade.currentCount .. "/" .. upgrade.maxStack .. ")"
            end

            table.insert(options, {
                title = upgrade.name .. stackText,
                description = locale('upgrade_price', { description = upgrade.description, price = upgrade.price }),
                icon = 'fas fa-arrow-up',
                onSelect = function()
                    ConfirmUpgrade(unitId, upgrade.id, upgrade.price, upgrade.name)
                end
            })
        end

        if #upgradeData.upgrades == 0 then
            table.insert(options, {
                title = locale('no_upgrades_available'),
                description = locale('all_upgrades_purchased'),
                icon = 'fas fa-check-circle'
            })
        end

        lib.registerContext({
            id = 'upgrade_menu',
            title = locale('storage_upgrades'),
            menu = 'management_menu',
            options = options
        })

        lib.showContext('upgrade_menu')
    end, unitId)
end

--- Grant player access - instant, no invitation
---@param unitId number Storage unit ID
---@return nil
GrantPlayerAccess = function(unitId)
    local input = lib.inputDialog(locale('grant_access_title'), {
        {
            type = 'number',
            label = locale('player_id'),
            description = locale('enter_player_id'),
            required = true,
            min = 1
        }
    })

    if input and input[1] then
        local alert = lib.alertDialog({
            header = locale('grant_access_title'),
            content = locale('grant_access_confirm', { id = input[1] }),
            centered = true,
            cancel = true
        })

        if alert == 'confirm' then
            ---@param success boolean Whether the operation succeeded
            ---@param message string Response message
            lib.callback('storage:grantAccess', false, function(success, message)
                ShowNotification(message, success and 'success' or 'error')
            end, unitId, input[1])
        end
    end
end

--- Show access list - renamed from collaborators
---@param unitId number Storage unit ID
---@return nil
ShowAccessList = function(unitId)
    ---@param users table[] List of users with access
    lib.callback('storage:getCollaborators', false, function(users)
        local options = {}

        for _, user in pairs(users) do
            local roleIcon = user.isOwner and 'fas fa-crown' or 'fas fa-user'
            local roleText = user.isOwner and 'Owner' or 'User'

            table.insert(options, {
                title = user.name .. ' (' .. roleText .. ')',
                description = user.isOwner and locale('storage_owner') or locale('has_access'),
                icon = roleIcon,
                onSelect = not user.isOwner and function()
                    ConfirmRemoveAccess(unitId, user.identifier, user.name)
                end or nil
            })
        end

        if #options == 0 then
            table.insert(options, {
                title = locale('no_other_users'),
                description = locale('only_user_with_access'),
                icon = 'fas fa-info-circle'
            })
        end

        lib.registerContext({
            id = 'access_list_menu',
            title = locale('storage_access_list'),
            menu = 'management_menu',
            options = options
        })

        lib.showContext('access_list_menu')
    end, unitId)
end

--- Confirm remove access - renamed from collaborator
---@param unitId number Storage unit ID
---@param targetIdentifier string Target player identifier
---@param targetName string Target player name
---@return nil
ConfirmRemoveAccess = function(unitId, targetIdentifier, targetName)
    local alert = lib.alertDialog({
        header = locale('remove_access'),
        content = locale('remove_access_confirm', { name = targetName }),
        centered = true,
        cancel = true
    })

    if alert == 'confirm' then
        ---@param success boolean Whether the operation succeeded
        ---@param message string Response message
        lib.callback('storage:removeCollaborator', false, function(success, message)
            lib.notify({
                title = locale('storage_management'),
                description = message,
                type = success and 'success' or 'error'
            })

            if success then
                ShowAccessList(unitId)
            end
        end, unitId, targetIdentifier)
    end
end

--- Confirm upgrade
---@param unitId number Storage unit ID
---@param upgradeId string Upgrade identifier
---@param price number Price of the upgrade
---@param upgradeName string Name of the upgrade
---@return nil
ConfirmUpgrade = function(unitId, upgradeId, price, upgradeName)
    local input = lib.inputDialog(locale('select_payment_method'), {
        {
            type = 'select',
            label = locale('payment_method'),
            description = locale('choose_payment'),
            required = true,
            options = {
                { value = 'cash', label = locale('cash') },
                { value = 'bank', label = locale('bank') }
            }
        }
    })

    if not input or not input[1] then return end
    
    local paymentMethod = input[1]
    
    local alert = lib.alertDialog({
        header = locale('confirm_upgrade'),
        content = locale('upgrade_confirm_text', { name = upgradeName, price = price, method = paymentMethod:gsub("^%l", string.upper) }),
        centered = true,
        cancel = true
    })

    if alert == 'confirm' then
        ---@param success boolean Whether the operation succeeded
        ---@param message string Response message
        lib.callback('storage:purchaseUpgrade', false, function(success, message)
            lib.notify({
                title = locale('storage_management'),
                description = message,
                type = success and 'success' or 'error'
            })

            if success then
                ShowUpgradeMenu(unitId)
            end
        end, unitId, upgradeId, paymentMethod)
    end
end

--- Confirm purchase unit
---@param unitId number Storage unit ID
---@return nil
ConfirmPurchaseUnit = function(unitId)
    local input = lib.inputDialog(locale('select_payment_method'), {
        {
            type = 'select',
            label = locale('payment_method'),
            description = locale('choose_payment'),
            required = true,
            options = {
                { value = 'cash', label = locale('cash') },
                { value = 'bank', label = locale('bank') }
            }
        }
    })

    if not input or not input[1] then return end
    
    local paymentMethod = input[1]
    
    local alert = lib.alertDialog({
        header = locale('purchase_storage_unit'),
        content = locale('purchase_unit_confirm_text', { id = unitId, price = Config.Pricing.purchase, method = paymentMethod:gsub("^%l", string.upper) }),
        centered = true,
        cancel = true
    })

    if alert == 'confirm' then
        ---@param success boolean Whether the operation succeeded
        ---@param message string Response message
        lib.callback('storage:purchaseUnit', false, function(success, message)
            ShowNotification(message, success and 'success' or 'error')

            if success then
                lib.hideContext()
            end
        end, unitId, paymentMethod)
    end
end

--- Confirm delete unit
---@param unitId number Storage unit ID
---@return nil
ConfirmDeleteUnit = function(unitId)
    local alert = lib.alertDialog({
        header = locale('delete_storage_unit'),
        content = locale('delete_unit_confirm'),
        centered = true,
        cancel = true
    })

    if alert == 'confirm' then
        ---@param success boolean Whether the operation succeeded
        ---@param message string Response message
        lib.callback('storage:deleteUnit', false, function(success, message)
            lib.notify({
                title = locale('storage_management'),
                description = message,
                type = success and 'success' or 'error'
            })

            if success then
                lib.hideContext()
            end
        end, unitId)
    end
end

--- Toggle auto-renewal
---@param unitId number Storage unit ID
---@return nil
ToggleAutoRenewal = function(unitId)
    ---@param success boolean Whether the operation succeeded
    ---@param message string Response message
    lib.callback('storage:toggleAutoRenewal', false, function(success, message)
        ShowNotification(message, success and 'success' or 'error')

        if success then
            OpenPaymentMenu(unitId)
        end
    end)
end

--- Rent storage unit
---@param unitId number Storage unit ID
---@return nil
RentStorageUnit = function(unitId)
    local input = lib.inputDialog(locale('select_payment_method'), {
        {
            type = 'select',
            label = locale('payment_method'),
            description = locale('choose_payment'),
            required = true,
            options = {
                { value = 'cash', label = locale('cash') },
                { value = 'bank', label = locale('bank') }
            }
        }
    })

    if not input or not input[1] then return end
    
    local paymentMethod = input[1]
    
    local alert = lib.alertDialog({
        header = locale('rent_storage_unit'),
        content = locale('rent_unit_confirm_text', { id = unitId, price = Config.Pricing.rent, method = paymentMethod:gsub("^%l", string.upper) }),
        centered = true,
        cancel = true
    })

    if alert == 'confirm' then
        ---@param success boolean Whether the operation succeeded
        ---@param message string Response message
        lib.callback('storage:rentUnit', false, function(success, message)
            ShowNotification(message, success and 'success' or 'error')

            if success then
                lib.hideContext()
            end
        end, unitId, paymentMethod)
    end
end

--- Open storage menu with all available accesses
---@param unitId number Storage unit ID
---@return nil
OpenStorageMenu = function(unitId)
    ---@param storages table[] List of accessible storages
    lib.callback('storage:getUnitAccesses', false, function(storages)
        if #storages == 0 then
            ShowNotification(locale('no_access_to_unit'), 'error')
            return
        elseif #storages == 1 then
            lib.callback('storage:validateAndOpenStash', false, function(canOpen)
                if canOpen then
                    exports.ox_inventory:openInventory('stash', storages[1].stashId)
                else
                    ShowNotification(locale('access_denied'), 'error')
                end
            end, storages[1].stashId)
            return
        end
        
        local options = {}
        for _, storage in ipairs(storages) do
            table.insert(options, {
                title = storage.label,
                description = storage.isOwner and locale('your_personal_storage') or locale('shared_access'),
                icon = storage.isOwner and 'fas fa-crown' or 'fas fa-key',
                onSelect = function()
                    lib.callback('storage:validateAndOpenStash', false, function(canOpen)
                        if canOpen then
                            exports.ox_inventory:openInventory('stash', storage.stashId)
                        else
                            ShowNotification(locale('access_denied'), 'error')
                        end
                    end, storage.stashId)
                end
            })
        end
        
        lib.registerContext({
            id = 'storage_access_menu',
            title = locale('select_access', { id = unitId }),
            options = options
        })
        
        lib.showContext('storage_access_menu')
    end, unitId)
end

--- Open storage unit (backwards compatibility)
---@param unitId number Storage unit ID
---@return nil
OpenStorageUnit = function(unitId)
    OpenStorageMenu(unitId)
end

--- Handle access granted notification
---@param data table Event data with unitId and ownerName
RegisterNetEvent('storage:accessGranted', function(data)
    ShowNotification(locale('access_granted', { ownerName = data.ownerName, id = data.unitId }), 'success')
end)

--- Make payment
---@param paymentMethod string Payment method ('cash' or 'bank')
---@return nil
MakePayment = function(paymentMethod)
    ---@param success boolean Whether the operation succeeded
    ---@param message string Response message
    lib.callback('storage:makePayment', false, function(success, message)
        ShowNotification(message, success and 'success' or 'error')

        if success then
            OpenManagerMenu()
        end
    end, paymentMethod)
end

--- Handle payment overdue notification
---@param data table Event data with unitId
RegisterNetEvent('storage:paymentOverdue', function(data)
    ShowNotification(locale('payment_overdue', { id = data.unitId }), 'error')
end)

--- Handle unit deletion notification
---@param data table Event data with unitId and reason
RegisterNetEvent('storage:unitDeleted', function(data)
    ShowNotification(locale('unit_deleted', { id = data.unitId, reason = data.reason }), 'error')
end)

--- Handle auto-renewal success notification
---@param data table Event data with unitId, amount, and nextPayment
RegisterNetEvent('storage:autoRenewalSuccess', function(data)
    ShowNotification(locale('auto_renewal_success', { id = data.unitId, amount = data.amount, nextPayment = data.nextPayment }), 'success')
end)

--- Handle auto-renewal failure notification
---@param data table Event data with unitId, reason, and graceEnds
RegisterNetEvent('storage:autoRenewalFailed', function(data)
    ShowNotification(locale('auto_renewal_failed', { id = data.unitId, reason = data.reason, graceEnds = data.graceEnds }), 'error')
end)

--- Open payment management menu
---@param unitId number Storage unit ID
---@return nil
OpenPaymentMenu = function(unitId)
    ---@param paymentInfo table|nil Payment information
    lib.callback('storage:getPaymentInfo', false, function(paymentInfo)
        if not paymentInfo then
            ShowNotification(locale('no_payment_info'), 'error')
            return
        end

        local options = {}

        local statusTitle = locale('payment_status')
        local statusDescription = ""
        local statusIcon = "fas fa-info-circle"

        if paymentInfo.inGracePeriod then
            statusTitle = locale('payment_overdue_urgent')
            local hoursLeft = math.floor(paymentInfo.timeUntilDeletion / 3600)
            local minutesLeft = math.floor((paymentInfo.timeUntilDeletion % 3600) / 60)
            statusDescription = locale('grace_period_ends', { hours = hoursLeft, minutes = minutesLeft })
            statusIcon = "fas fa-exclamation-triangle"
        elseif paymentInfo.isOverdue then
            statusTitle = locale('payment_overdue_urgent')
            local hoursInGrace = math.floor(Config.Rental.paymentGracePeriod / 3600)
            statusDescription = locale('payment_overdue_hours', { hours = hoursInGrace })
            statusIcon = "fas fa-exclamation-triangle"
        else
            local daysLeft = math.floor(paymentInfo.timeUntilPayment / 86400)
            local hoursLeft = math.floor((paymentInfo.timeUntilPayment % 86400) / 3600)
            local minutesLeft = math.floor((paymentInfo.timeUntilPayment % 3600) / 60)

            if paymentInfo.timeUntilPayment <= Config.Rental.earlyPaymentWindow then
                statusTitle = locale('payment_due_soon')
                statusDescription = locale('due_in_hours', { hours = hoursLeft, minutes = minutesLeft })
                statusIcon = "fas fa-clock"
            else
                statusDescription = locale('next_payment_due_days', { days = daysLeft, hours = hoursLeft })
            end
        end

        table.insert(options, {
            title = statusTitle,
            description = statusDescription,
            icon = statusIcon
        })

        table.insert(options, {
            title = locale('payment_details'),
            description = locale('payment_details_desc', { price = Config.Pricing.rent, due = paymentInfo.nextPaymentDue }),
            icon = 'fas fa-dollar-sign'
        })
        
        if Config.Banking.hasStaticIdentifiers then
            if paymentInfo.bankAccount then
                table.insert(options, {
                    title = locale('linked_bank_account'),
                    description = locale('bank_account_desc', { account = paymentInfo.bankAccount }),
                    icon = 'fas fa-university',
                    onSelect = function()
                        lib.callback('storage:updateBankAccount', false, function(success, message)
                            ShowNotification(message, success and 'success' or 'error')
                            if success then
                                OpenPaymentMenu(unitId)
                            end
                        end)
                    end
                })
            else
                table.insert(options, {
                    title = locale('link_bank_account'),
                    description = locale('link_bank_desc'),
                    icon = 'fas fa-link',
                    onSelect = function()
                        lib.callback('storage:updateBankAccount', false, function(success, message)
                            ShowNotification(message, success and 'success' or 'error')
                            if success then
                                OpenPaymentMenu(unitId)
                            end
                        end)
                    end
                })
            end
        end

        ---@param rentalInfo table Rental information
        lib.callback('storage:getRentalInfo', false, function(rentalInfo)
            if Config.Banking.hasStaticIdentifiers then
                local autoRenewalStatus = rentalInfo.autoRenewal and locale('enabled') or locale('disabled')
                local autoRenewalIcon = rentalInfo.autoRenewal and "fas fa-toggle-on" or "fas fa-toggle-off"

                table.insert(options, {
                    title = locale('auto_renewal_status', { status = autoRenewalStatus }),
                    description = rentalInfo.autoRenewal and locale('auto_payments') or locale('manual_payment_required'),
                    icon = autoRenewalIcon,
                    onSelect = function()
                        ToggleAutoRenewal(unitId)
                    end
                })
            else
                table.insert(options, {
                    title = locale('auto_renewal_unavailable'),
                    description = Config.Banking.noIdentifierMessage or locale('banking_no_static_ids'),
                    icon = 'fas fa-ban',
                    disabled = true
                })
            end

            -- Show payment option if within early payment window, overdue, or in grace period
            if paymentInfo.inGracePeriod or paymentInfo.isOverdue or paymentInfo.timeUntilPayment <= Config.Rental.earlyPaymentWindow then
                local paymentDescription = locale('pay_next_period', { price = Config.Pricing.rent })
                if paymentInfo.timeUntilPayment > 0 and paymentInfo.timeUntilPayment <= Config.Rental.earlyPaymentWindow and not paymentInfo.isOverdue then
                    paymentDescription = paymentDescription .. locale('early_payment')
                elseif paymentInfo.inGracePeriod then
                    paymentDescription = paymentDescription .. locale('urgent_avoid_deletion')
                end
                
                table.insert(options, {
                    title = locale('make_payment_now'),
                    description = paymentDescription,
                    icon = 'fas fa-credit-card',
                    onSelect = function()
                        ConfirmPayment()
                    end
                })
            end

            -- Only show auto-renewal info if banking system supports it
            if Config.Banking.hasStaticIdentifiers then
                if not rentalInfo.autoRenewal then
                    table.insert(options, {
                        title = locale('manual_payment_info'),
                        description = locale('manual_payment_desc'),
                        icon = 'fas fa-info'
                    })
                else
                    table.insert(options, {
                        title = locale('auto_renewal_info'),
                        description = locale('auto_renewal_desc'),
                        icon = 'fas fa-info'
                    })
                end
            else
                -- Show manual payment info only when auto-renewal is not supported
                table.insert(options, {
                    title = locale('manual_payment_info'),
                    description = locale('manual_payment_required_no_auto'),
                    icon = 'fas fa-info'
                })
            end

            lib.registerContext({
                id = 'payment_management_menu',
                title = locale('payment_management_unit', { id = unitId }),
                menu = 'storage_manager_menu',
                options = options
            })

            lib.showContext('payment_management_menu')
        end)
    end)
end

--- Confirm payment
---@return nil
ConfirmPayment = function()
    local input = lib.inputDialog(locale('select_payment_method'), {
        {
            type = 'select',
            label = locale('payment_method'),
            description = locale('choose_payment'),
            required = true,
            options = {
                { value = 'cash', label = locale('cash') },
                { value = 'bank', label = locale('bank') }
            }
        }
    })

    if not input or not input[1] then return end
    
    local paymentMethod = input[1]
    
    local alert = lib.alertDialog({
        header = locale('confirm_payment'),
        content = locale('confirm_payment_text', { price = Config.Pricing.rent, method = paymentMethod:gsub("^%l", string.upper) }),
        centered = true,
        cancel = true
    })

    if alert == 'confirm' then
        MakePayment(paymentMethod)
    end
end

--- Cleanup on resource stop
AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        DespawnManagerPed()
        if managerBlip then
            RemoveBlip(managerBlip)
        end
    end
end)