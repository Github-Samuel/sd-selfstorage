# sd-selfstorage

sd-selfstorage is a comprehensive self-storage rental system for FiveM that allows players to rent or purchase storage units with advanced features including auto-renewal payments, access management, upgrades, and more. The system features a clean UI with payment management, collaborative access, and flexible configuration options for different banking systems.

## Features
- 🏢 **Rent or Purchase** - Players can either rent units weekly or buy them permanently
- 💳 **Auto-Renewal System** - Automatic payments from bank accounts (configurable)
- 👥 **Access Management** - Share storage access with other players
- ⬆️ **Storage Upgrades** - Purchase additional slots and weight capacity
- ⏰ **Grace Period System** - 48-hour grace period for overdue payments
- 🏦 **Banking Integration** - Works with banking systems that support static identifiers
- 🌍 **Multi-Language Support** - Easy localization system
- 📦 **ox_inventory Integration** - Full stash system with weight and slot limits

## UI Preview
![Storage Manager Menu]
![Payment Management]
![Access Control]

## 🔔 Contact

Author: Samuel#0008  
Discord: [Join the Discord](https://discord.gg/FzPehMQaBQ)  
Store: [Click Here](https://fivem.samueldev.shop)

## 💾 Installation

1. Download the latest release from the repository
2. Extract the downloaded file and rename the folder to `sd-selfstorage`
3. Place the `sd-selfstorage` folder into your server's `resources` directory
4. Configure your database:
   ```sql
   -- The script will automatically create the required table on first start
   ```
5. Add `ensure sd-selfstorage` to your `server.cfg`
6. Configure the banking functions in `server/main.lua` (lines 14-37)
7. Adjust the config file to your needs

## 📖 Dependencies
- [ox_inventory](https://github.com/overextended/ox_inventory)
- [ox_lib](https://github.com/overextended/ox_lib)
- [qbx_core](https://github.com/Qbox-project/qbx_core) or [qb-core](https://github.com/qbcore-framework/qb-core)
- oxmysql

## 📖 Configuration

### Banking System Setup
The script supports two modes depending on your banking system:

#### For Banking Systems with Static Identifiers (IBAN, Account Numbers)
```lua
Banking = {
    hasStaticIdentifiers = true,
    noIdentifierMessage = 'Your banking system does not support automatic payments'
}
```

#### For Banking Systems without Static Identifiers
```lua
Banking = {
    hasStaticIdentifiers = false,
    noIdentifierMessage = 'Your banking system does not support automatic payments'
}
```

When `hasStaticIdentifiers = false`:
- Auto-renewal features are disabled
- Bank account linking is hidden
- Only manual payments are available
- Grace period and deletion systems still work

### Banking Functions
Edit the banking functions in `server/main.lua` (lines 14-37):

```lua
-- Example Integration with RxBanking
Banking.GetPlayerAccount = function(identifier)
    local accountData = exports['RxBanking']:GetPlayerPersonalAccount(identifier)
    if type(accountData) == "table" then
        return accountData.iban
    elseif type(accountData) == "string" then
        return accountData
    end
    return nil
end

Banking.RemoveAccountMoney = function(accountId, amount, unitId)
    return exports['RxBanking']:RemoveAccountMoney(
        accountId, 
        amount, 
        'payment', 
        locale('storage_unit_autorenewal', { id = unitId }), 
        nil
    )
end
```

### Storage Configuration
Configure storage units in `config.lua`:

```lua
Storages = {
    { 
        name = 'storageunit1',  
        id = 1,  
        coords = vector3(-73.26, -1196.35, 27.66), 
        length = 5.0, 
        width = 5.4, 
        minZ = 25.86, 
        maxZ = 29.86, 
        heading = 0 
    },
    -- Add more units...
}
```

### Pricing Configuration
```lua
Pricing = {
    enableRent = true,  -- Allow renting
    enableBuy = true,   -- Allow purchasing
    rent = 1000,        -- Weekly rental price
    purchase = 25000,   -- One-time purchase price
    
    upgrades = {
        slots_tier1 = {
            name = "Extra Storage Slots",
            description = "Increase storage slots by 25",
            price = 2500,
            effect = { type = "slots", value = 25 },
            stackable = true,
            maxStack = 3
        },
        -- Add more upgrades...
    }
}
```

## 📖 Usage

### For Players
1. **Visit the Storage Manager** - Go to the configured location
2. **Rent or Buy** - Choose to rent weekly or purchase permanently
3. **Manage Your Unit**:
   - Access your storage
   - Share access with friends
   - Purchase upgrades
   - Manage payments (if renting)
4. **Payment Management** (for rentals):
   - Enable auto-renewal (if supported)
   - Make manual payments
   - View payment status

### Payment System
- **Early Payment**: Available 24 hours before due
- **Grace Period**: 48 hours after payment is due
- **Auto-Renewal**: Automatically deducts from linked bank account
- **Manual Payment**: Pay using cash or bank

## 📜 License

This resource is protected by copyright. Redistribution or modification without permission is prohibited.

## 🤝 Support

For support, join our [Discord](https://discord.gg/FzPehMQaBQ) or create an issue on GitHub.