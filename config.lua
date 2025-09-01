return {
    Storages = {
        { name = 'storageunit1',  id = 1,  coords = vector3(-73.26, -1196.35, 27.66), length = 5.0, width = 5.4, minZ = 25.86, maxZ = 29.86, heading = 0 },
        { name = 'storageunit2',  id = 2,  coords = vector3(-66.61, -1198.67, 27.74), length = 5.0, width = 5.4, minZ = 25.94, maxZ = 29.94, heading = 314 },
        { name = 'storageunit3',  id = 3,  coords = vector3(-60.88, -1204.31, 27.79), length = 5.0, width = 5.4, minZ = 25.99, maxZ = 29.99, heading = 313 },
        { name = 'storageunit4',  id = 4,  coords = vector3(-55.63, -1209.76, 28.28), length = 5.0, width = 5.4, minZ = 26.48, maxZ = 30.48, heading = 314 },
        { name = 'storageunit5',  id = 5,  coords = vector3(-51.84, -1216.39, 28.7),  length = 5.0, width = 5.4, minZ = 26.9,  maxZ = 30.9,  heading = 270 },
        { name = 'storageunit6',  id = 6,  coords = vector3(-55.88, -1229.75, 28.76), length = 5.0, width = 5.4, minZ = 26.96, maxZ = 30.96, heading = 227 },
        { name = 'storageunit7',  id = 7,  coords = vector3(-60.08, -1234.31, 28.89), length = 5.0, width = 5.4, minZ = 27.09, maxZ = 31.09, heading = 226 },
        { name = 'storageunit8',  id = 8,  coords = vector3(-65.34, -1240.06, 29.03), length = 5.0, width = 5.4, minZ = 27.23, maxZ = 31.23, heading = 226 },
        { name = 'storageunit9',  id = 9,  coords = vector3(-73.77, -1243.99, 29.11), length = 5.0, width = 5.4, minZ = 27.31, maxZ = 31.31, heading = 179 },
        { name = 'storageunit10', id = 10, coords = vector3(-73.07, -1233.18, 29.02), length = 5.0, width = 5.4, minZ = 27.22, maxZ = 31.22, heading = 51 },
        { name = 'storageunit11', id = 11, coords = vector3(-67.51, -1226.06, 28.86), length = 5.0, width = 5.4, minZ = 27.06, maxZ = 31.06, heading = 51 },
        { name = 'storageunit12', id = 12, coords = vector3(-66.55, -1212.4, 28.31),  length = 5.0, width = 5.4, minZ = 26.51, maxZ = 30.51, heading = 316 },
        { name = 'storageunit13', id = 13, coords = vector3(-71.74, -1207.16, 27.89), length = 5.0, width = 5.4, minZ = 25.94, maxZ = 29.94, heading = 316 },
        { name = 'storageunit14', id = 14, coords = vector3(-78.6, -1205.21, 27.63),  length = 5.0, width = 5.4, minZ = 25.94, maxZ = 29.94, heading = 0 },
    },

    Manager = {
        coords = vec3(-82.63, -1197.53, 27.54), 
        heading = 87.72,
        model = 'a_m_m_business_01',
        spawnDistance = 100.0,
        interactDistance = 3.0,
        blip = {
            enabled = true,
            sprite = 473,
            color = 7,
            scale = 0.7,
            label = 'Self Storage',
            shortRange = true
        }
    },

    Rental = {
        price = 1000,
        duration = 7 * 24 * 60 * 60, -- 7 days in seconds
        maxRentersPerUnit = 15, -- Max users per owner's storage
        maxOwnersPerUnit = 15, -- Max separate owners per physical unit
        paymentGracePeriod = 48 * 60 * 60, -- 48 hours grace period after payment is due
        earlyPaymentWindow = 24 * 60 * 60 -- Allow payment 24 hours before due
    },
    
    Banking = { -- You can modify the banking functions in the server.lua at the top.
        -- Set to true if your banking system supports static account identifiers (IBAN, account numbers, etc.)
        -- If false, auto-renewal features will be disabled
        hasStaticIdentifiers = false,
        
        -- If hasStaticIdentifiers is false, you can optionally provide a message explaining why
        noIdentifierMessage = 'Your banking system does not support automatic payments'
    },
    
    Pricing = {
        -- Feature toggles
        enableRent = true, -- Allow players to rent storage units
        enableBuy = true, -- Allow players to purchase storage units permanently
        
        -- Rental prices
        rent = 1000,
        
        -- Purchase prices (one-time payment, permanent ownership)
        purchase = 25000,
        
        -- Available upgrades (can purchase multiple)
        upgrades = {
            slots_tier1 = {
                name = "Extra Storage Slots",
                description = "Increase storage slots by 25",
                price = 2500,
                effect = { type = "slots", value = 25 },
                stackable = true,
                maxStack = 3
            },
            weight_tier1 = {
                name = "Weight Capacity",
                description = "Increase weight capacity by 100kg",
                price = 4000,
                effect = { type = "weight", value = 100000 },
                stackable = true,
                maxStack = 3
            },
        }
    },
    
    -- Default storage limits
    DefaultLimits = {
        slots = 25,
        weight = 500000 -- 500kg
    }
}
