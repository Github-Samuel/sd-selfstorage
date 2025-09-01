# sd-selfstorage

sd-selfstorage is a comprehensive self-storage rental system for FiveM that allows players to rent or purchase storage units with advanced features including auto-renewal payments, access management, upgrades, and more.
## Features
- 🏢 **Rent or Purchase** - Players can either rent units weekly or buy them permanently
- 💳 **Auto-Renewal System** - Automatic payments from bank accounts (configurable)
- 👥 **Access Management** - Share storage access with other players
- ⬆️ **Storage Upgrades** - Purchase additional slots and weight capacity
- ⏰ **Grace Period System** - 48-hour grace period for overdue payments
- 🏦 **Banking Integration** - Works with banking systems that support static identifiers
- 🌍 **Multi-Language Support** - Easy localization system
- 📦 **ox_inventory Integration** - Full stash system with weight and slot limits

## Preview
<img width="1920" height="1080" alt="image" src="https://github.com/user-attachments/assets/fd9b534a-89c9-4931-846d-b4d079fa8e7c" />

![FiveM_GTAProcess_GMUO1cRVPE](https://github.com/user-attachments/assets/f38e24d3-713d-477b-b1c1-66834e828e3d)
![FiveM_GTAProcess_aNNN2aegP8](https://github.com/user-attachments/assets/969b86bc-90b1-4c12-bc24-e291499ef179)
<img width="1920" height="1080" alt="FiveM_GTAProcess_Wk93zMVrwo" src="https://github.com/user-attachments/assets/2727e1d3-c744-4c35-abb0-5da62e4f332f" />


## 🔔 Contact

Author: Samuel#0008  
Discord: [Join the Discord](https://discord.gg/FzPehMQaBQ)  
Store: [Click Here](https://fivem.samueldev.shop)

## 💾 Installation

1. Download the latest release from the repository
2. Extract the downloaded file and rename the folder to `sd-selfstorage`
3. Place the `sd-selfstorage` folder into your server's `resources` directory
4. Add `ensure sd-selfstorage` to your `server.cfg`
5. Configure the banking functions in `server/main.lua` (lines 14-37), if you want auto-renewal to work.
6. Adjust the config file to your needs

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

## 📜 License
This resource is protected by copyright. Redistribution or modification without permission is prohibited.

## 🤝 Support
For support, join our [Discord](https://discord.gg/FzPehMQaBQ) or create an issue on GitHub.




