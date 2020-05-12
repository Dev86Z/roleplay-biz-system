/*
		*****************
		BUSINESS COMMANDS
		*****************
*/

new bcQuery[1024];

CMD:createbiz(playerid, params[])
{
	new type, Float:x, Float:y, Float:z, Float:a;

    if(PlayerInfo[playerid][pAdmin] < 7)
	{
	    return SendClientMessage(playerid, COLOR_GREY, "You are not authorized to use this command.");
	}
	if(sscanf(params, "i", type))
	{
	    SendClientMessage(playerid, COLOR_WHITE, "USAGE: /createbiz [type]");
	    SendClientMessage(playerid, COLOR_WHITE, "List of options: (1) 24/7 (2) Gun Shop (3) Clothes Shop (4) Gym (5) Restaurant (6) Ad Agency (7) Club/Bar");
	    return 1;
	}
	if(!(1 <= type <= sizeof(bizInteriors)))
	{
	    return SendClientMessage(playerid, COLOR_GREY, "Invalid type.");
	}
	if(GetNearbyBusiness(playerid) >= 0)
	{
	    return SendClientMessage(playerid, COLOR_GREY, "There is a business in range. Find somewhere else to create this one.");
	}

	GetPlayerPos(playerid, x, y, z);

	type--;

 	for(new b = 0; b < MAX_BUSINESSES; b ++)
	{
	    if(!BusinessInfo[b][bExists])
	    {
			mysql_format(Database, bcQuery, sizeof(bcQuery), "INSERT INTO businesses (type, price, pos_x, pos_y, pos_z, int_x, int_y, int_z, interior, outsideint, outsidevw) VALUES(%i, %i, '%f', '%f', '%f', '%f', '%f', '%f', %i, %i, %i)", type, bizInteriors[type][intPrice], x, y, z,
				bizInteriors[type][intX], bizInteriors[type][intY], bizInteriors[type][intZ], bizInteriors[type][intID], GetPlayerInterior(playerid), GetPlayerVirtualWorld(playerid));
			mysql_tquery(Database, bcQuery, "OnAdminCreateBusiness", "iiiffff", playerid, b, type, x, y, z, a);
			return 1;
		}
	}

	SendClientMessage(playerid, COLOR_GREY, "Business slots are currently full. Ask developers to increase the internal limit.");
	return 1;
}


CMD:editbiz(playerid, params[])
{
	new businessid, option[14], param[32];

	if(PlayerInfo[playerid][pAdmin] < 7)
	{
	    return SendClientMessage(playerid, COLOR_GREY, ERROR_UNAUTHORIZED);
	}
	if(sscanf(params, "is[14]S()[32]", businessid, option, param))
	{
	    SendClientMessage(playerid, COLOR_WHITE, "USAGE: /editbiz [businessid] [option]");
	    SendClientMessage(playerid, COLOR_WHITE, "List of options: Entrance, Exit, Interior, World, Type, Owner, Price, Stock, Locked");
	    return 1;
	}
	if(!(0 <= businessid < MAX_BUSINESSES) || !BusinessInfo[businessid][bExists])
	{
	    return SendClientMessage(playerid, COLOR_GREY, ERROR_INVALID_BIZ);
	}

	if(!strcmp(option, "entrance", true))
	{
	    GetPlayerPos(playerid, BusinessInfo[businessid][bPosX], BusinessInfo[businessid][bPosY], BusinessInfo[businessid][bPosZ]);

	    BusinessInfo[businessid][bOutsideInt] = GetPlayerInterior(playerid);
	    BusinessInfo[businessid][bOutsideVW] = GetPlayerVirtualWorld(playerid);

	    mysql_format(Database, bcQuery, sizeof(bcQuery), "UPDATE businesses SET pos_x = '%f', pos_y = '%f', pos_z = '%f', outsideint = %i, outsidevw = %i WHERE id = %i", BusinessInfo[businessid][bPosX], BusinessInfo[businessid][bPosY], BusinessInfo[businessid][bPosZ], BusinessInfo[businessid][bOutsideInt], BusinessInfo[businessid][bOutsideVW], BusinessInfo[businessid][bID]);
	    mysql_tquery(Database, bcQuery);

	    businessReload(businessid);
	    SendClientMessageEx(playerid, COLOR_AQUA, "** You've changed the entrance of business %i.", businessid);
	}
	else if(!strcmp(option, "exit", true))
	{
	    new type = -1;

	    for(new b = 0; b < sizeof(bizInteriors); b ++)
	    {
	        if(IsPlayerInRangeOfPoint(playerid, 100.0, bizInteriors[b][intX], bizInteriors[b][intY], bizInteriors[b][intZ]))
	        {
	            type = b;
			}
	    }

	    GetPlayerPos(playerid, BusinessInfo[businessid][bIntX], BusinessInfo[businessid][bIntY], BusinessInfo[businessid][bIntZ]);

	    BusinessInfo[businessid][bInterior] = GetPlayerInterior(playerid);
		BusinessInfo[businessid][bType] = type;

	    mysql_format(Database, bcQuery, sizeof(bcQuery), "UPDATE businesses SET type = %i, int_x = '%f', int_y = '%f', int_z = '%f', interior = %i WHERE id = %i", type, BusinessInfo[businessid][bIntX], BusinessInfo[businessid][bIntY], BusinessInfo[businessid][bIntZ], BusinessInfo[businessid][bInterior], BusinessInfo[businessid][bID]);
	    mysql_tquery(Database, bcQuery);

		businessReload(businessid);
	    SendClientMessageEx(playerid, COLOR_AQUA, "** You've changed the exit of business %i.", businessid);
	}
	else if(!strcmp(option, "world", true))
	{
	    new worldid;

	    if(sscanf(param, "i", worldid))
	    {
	        return SendClientMessage(playerid, COLOR_WHITE, "USAGE: /editbiz [businessid] [world] [vw]");
		}

		BusinessInfo[businessid][bWorld] = worldid;

		mysql_format(Database, bcQuery, sizeof(bcQuery), "UPDATE businesses SET world = %i WHERE id = %i", BusinessInfo[businessid][bWorld], BusinessInfo[businessid][bID]);
	    mysql_tquery(Database, bcQuery);

		businessReload(businessid);
	    SendClientMessageEx(playerid, COLOR_AQUA, "** You've changed the virtual world of business %i to %i.", businessid, worldid);
	}
	else if(!strcmp(option, "type", true))
	{
	    new type;

	    if(sscanf(param, "i", type))
	    {
	        SendClientMessageEx(playerid, COLOR_WHITE, "USAGE: /editbiz [businessid] [type] [value (1-%i)]", sizeof(bizInteriors));
	        SendClientMessage(playerid, COLOR_WHITE, "List of options: (1) 24/7 (2) Gun Shop (3) Clothes Shop (4) Gym (5) Restaurant (6) Ad Agency (7) Club/Bar");
	        return 1;
		}
		if(!(1 <= type <= sizeof(bizInteriors)))
		{
		    return SendClientMessage(playerid, COLOR_GREY, "Invalid type.");
		}

		BusinessInfo[businessid][bType] = type-1;
		BusinessInfo[businessid][bInterior] = bizInteriors[type][intID];
		BusinessInfo[businessid][bIntX] = bizInteriors[type][intX];
		BusinessInfo[businessid][bIntY] = bizInteriors[type][intY];
		BusinessInfo[businessid][bIntZ] = bizInteriors[type][intZ];

		mysql_format(Database, bcQuery, sizeof(bcQuery), "UPDATE businesses SET type = %i, int_x = '%f', int_y = '%f', int_z = '%f', interior = %i, world = %i WHERE id = %i", type-1, BusinessInfo[businessid][bIntX], BusinessInfo[businessid][bIntY], BusinessInfo[businessid][bIntZ], BusinessInfo[businessid][bInterior], BusinessInfo[businessid][bWorld], BusinessInfo[businessid][bID]);
	    mysql_tquery(Database, bcQuery);

		businessReload(businessid);
	    SendClientMessageEx(playerid, COLOR_AQUA, "** You've changed the type of business %i to %i.", businessid, type);
	}
	else if(!strcmp(option, "owner", true))
	{
	    new targetid;

	    if(sscanf(param, "u", targetid))
	    {
	        return SendClientMessageEx(playerid, COLOR_WHITE, "USAGE: /editbiz [businessid] [owner] [playerid]");
		}
		if(!IsPlayerConnected(targetid))
		{
		    return SendClientMessage(playerid, COLOR_GREY, "The player specified is disconnected.");
		}
		if(!PlayerTemp[targetid][pLoggedIn])
		{
		    return SendClientMessage(playerid, COLOR_GREY, "That player hasn't logged in yet.");
		}

        SetBusinessOwner(businessid, targetid);
	    SendClientMessageEx(playerid, COLOR_AQUA, "** You've changed the owner of business %i to %s.", businessid, GetRPName(targetid));
	}
	else if(!strcmp(option, "price", true))
	{
	    new price;

	    if(sscanf(param, "i", price))
	    {
	        return SendClientMessage(playerid, COLOR_WHITE, "USAGE: /editbiz [businessid] [price] [value]");
		}
		if(price < 0)
		{
		    return SendClientMessage(playerid, COLOR_GREY, "The price can't be below $0.");
		}

		BusinessInfo[businessid][bPrice] = price;

		mysql_format(Database, bcQuery, sizeof(bcQuery), "UPDATE businesses SET price = %i WHERE id = %i", BusinessInfo[businessid][bPrice], BusinessInfo[businessid][bID]);
	    mysql_tquery(Database, bcQuery);

		businessReload(businessid);
	    SendClientMessageEx(playerid, COLOR_AQUA, "** You've changed the price of business %i to $%i.", businessid, price);
	}
	else if(!strcmp(option, "products", true))
	{
	    new amount;

	    if(sscanf(param, "i", amount))
	    {
	        return SendClientMessage(playerid, COLOR_WHITE, "USAGE: /editbiz [businessid] [products] [value]");
		}

		BusinessInfo[businessid][bProducts] = amount;

		mysql_format(Database, bcQuery, sizeof(bcQuery), "UPDATE businesses SET products = %i WHERE id = %i", BusinessInfo[businessid][bProducts], BusinessInfo[businessid][bID]);
	    mysql_tquery(Database, bcQuery);

		businessReload(businessid);
	    SendClientMessageEx(playerid, COLOR_AQUA, "** You've changed the products amount of business %i to %i.", businessid, amount);
	}
    else if(!strcmp(option, "locked", true))
	{
	    new locked;

	    if(sscanf(param, "i", locked) || !(0 <= locked <= 1))
	    {
	        return SendClientMessage(playerid, COLOR_WHITE, "USAGE: /editbiz [businessid] [locked] [0/1]");
		}

		BusinessInfo[businessid][bLocked] = locked;

		mysql_format(Database, bcQuery, sizeof(bcQuery), "UPDATE businesses SET locked = %i WHERE id = %i", BusinessInfo[businessid][bLocked], BusinessInfo[businessid][bID]);
	    mysql_tquery(Database, bcQuery);

		businessReload(businessid);
	    SendClientMessageEx(playerid, COLOR_AQUA, "** You've changed the lock state of business %i to %i.", businessid, locked);
	}

	return 1;
}

CMD:removebiz(playerid, params[])
{
	new businessid;

	if(PlayerInfo[playerid][pAdmin] < 7)
	{
	    return SendClientMessage(playerid, COLOR_GREY, ERROR_UNAUTHORIZED);
	}
	if(sscanf(params, "i", businessid))
	{
	    return SendClientMessage(playerid, COLOR_WHITE, "Usage: /removebiz [businessid]");
	}
	if(!(0 <= businessid < MAX_HOUSES) || !BusinessInfo[businessid][bExists])
	{
	    return SendClientMessage(playerid, COLOR_GREY, ERROR_INVALID_BIZ);
	}

	DestroyDynamic3DTextLabel(BusinessInfo[businessid][bText]);
	DestroyDynamicPickup(BusinessInfo[businessid][bPickup]);
	DestroyDynamicMapIcon(BusinessInfo[businessid][bMapIcon]);

	mysql_format(Database, bcQuery, sizeof(bcQuery), "DELETE FROM businesses WHERE id = %i", BusinessInfo[businessid][bID]);
	mysql_tquery(Database, bcQuery);

	BusinessInfo[businessid][bExists] = 0;
	BusinessInfo[businessid][bID] = 0;
	BusinessInfo[businessid][bOwnerID] = 0;

	SendClientMessageEx(playerid, COLOR_AQUA, "** You have removed business %i.", businessid);
	return 1;
}

CMD:gotobiz(playerid, params[])
{
	new businessid;

	if(PlayerInfo[playerid][pAdmin] < 5)
	{
	    return SendClientMessage(playerid, COLOR_GREY, ERROR_UNAUTHORIZED);
	}
	if(sscanf(params, "i", businessid))
	{
	    return SendClientMessage(playerid, COLOR_WHITE, "Usage: /gotobiz [businessid]");
	}
	if(!(0 <= businessid < MAX_HOUSES) || !BusinessInfo[businessid][bExists])
	{
	    return SendClientMessage(playerid, COLOR_GREY, ERROR_INVALID_BIZ);
	}

	GameTextForPlayer(playerid, "~w~Teleported", 5000, 1);

	SetPlayerPos(playerid, BusinessInfo[businessid][bPosX], BusinessInfo[businessid][bPosY], BusinessInfo[businessid][bPosZ]);
	SetCameraBehindPlayer(playerid);
	return 1;
}
CMD:bizhelp(playerid, params[])
{
	SendClientMessage(playerid, COLOR_BLUE, "** BUSINESS: /buybiz, /lock, /bwithdraw, /bdeposit, /sellbiz, /sellmybiz, /bizinfo.");
	return 1;
}

CMD:buybiz(playerid, params[])
{
	new businessid;

	if((businessid = GetNearbyBusiness(playerid)) == -1)
	{
	    return SendClientMessage(playerid, COLOR_GREY, "There is no business in range. You must be near a business.");
	}
	if(strcmp(params, "confirm", true) != 0)
	{
	    return SendClientMessage(playerid, COLOR_WHITE, "Usage: /buybiz [confirm]");
	}
	if(BusinessInfo[businessid][bOwnerID])
	{
	    return SendClientMessage(playerid, COLOR_GREY, "This business already has an owner.");
	}
	if(PlayerInfo[playerid][pMoney] < BusinessInfo[businessid][bPrice])
	{
	    return SendClientMessage(playerid, COLOR_GREY, "You can't afford to purchase this business.");
	}

	SetBusinessOwner(businessid, playerid);
	PlayerInfo[playerid][pMoney] = -BusinessInfo[businessid][bPrice];

	SendClientMessageEx(playerid, COLOR_YELLOW, "You paid $%i for this %s. /bizhelp for a list of commands.", BusinessInfo[businessid][bPrice], bizInteriors[BusinessInfo[businessid][bType]][intType]);
	return 1;
}

CMD:bwithdraw(playerid, params[])
{
	new businessid = GetInsideBusiness(playerid), amount;

	if(businessid == -1 || !IsBusinessOwner(playerid, businessid))
	{
	    return SendClientMessage(playerid, COLOR_GREY, "Non sei in nessuno dei tuoi negozi.");
	}
	if(sscanf(params, "i", amount))
	{
	    return SendClientMessageEx(playerid, COLOR_WHITE, "Usage: /bwithdraw [amount] ($%i available)", BusinessInfo[businessid][bCash]);
	}
	if(amount < 1 || amount > BusinessInfo[businessid][bCash])
	{
	    return SendClientMessage(playerid, COLOR_GREY, "Insufficient amount.");
	}

	BusinessInfo[businessid][bCash] -= amount;
	PlayerInfo[playerid][pMoney] = amount;

	mysql_format(Database, queryBuffer, sizeof(queryBuffer), "UPDATE businesses SET cash = %i WHERE id = %i", BusinessInfo[businessid][bCash], BusinessInfo[businessid][bID]);
	mysql_tquery(Database, queryBuffer);

	SendClientMessageEx(playerid, COLOR_AQUA, "** You have withdrawn $%i from the business vault. There is now $%i remaining.", amount, BusinessInfo[businessid][bCash]);
	return 1;
}

CMD:bdeposit(playerid, params[])
{
	new businessid = GetInsideBusiness(playerid), amount;

	if(businessid == -1 || !IsBusinessOwner(playerid, businessid))
	{
	    return SendClientMessage(playerid, COLOR_GREY, "Non sei in nessuno dei tuoi negozi.");
	}
	if(sscanf(params, "i", amount))
	{
	    return SendClientMessageEx(playerid, COLOR_WHITE, "Usage: /bdeposit [amount] ($%i available)", BusinessInfo[businessid][bCash]);
	}
	if(amount < 1 || amount > PlayerInfo[playerid][pMoney])
	{
	    return SendClientMessage(playerid, COLOR_GREY, "Insufficient amount.");
	}

	BusinessInfo[businessid][bCash] += amount;
	PlayerInfo[playerid][pMoney] = -amount;

	mysql_format(Database, queryBuffer, sizeof(queryBuffer), "UPDATE businesses SET cash = %i WHERE id = %i", BusinessInfo[businessid][bCash], BusinessInfo[businessid][bID]);
	mysql_tquery(Database, queryBuffer);

	SendClientMessageEx(playerid, COLOR_AQUA, "** You have deposited $%i in the business vault. There is now $%i available.", amount, BusinessInfo[businessid][bCash]);
	return 1;
}

CMD:sellbiz(playerid, params[])
{
	new businessid = GetNearbyBusinessEx(playerid), targetid, amount;

	if(businessid == -1 || !IsBusinessOwner(playerid, businessid))
	{
	    return SendClientMessage(playerid, COLOR_GREY, "Non sei in nessuno dei tuoi negozi.");
	}
	if(sscanf(params, "ui", targetid, amount))
	{
	    return SendClientMessage(playerid, COLOR_WHITE, "Usage: /sellbiz [playerid] [amount]");
	}
	if(!IsPlayerConnected(targetid) || !IsPlayerInRangeOfPlayer(playerid, targetid, 5.0))
	{
	    return SendClientMessage(playerid, COLOR_GREY, "The player specified is disconnected or out of range.");
	}
	if(targetid == playerid)
	{
	    return SendClientMessage(playerid, COLOR_GREY, "You can't sell to yourself.");
	}
	if(amount < 1)
	{
	    return SendClientMessage(playerid, COLOR_GREY, "You must specify an amount above zero.");
	}

	PlayerInfo[targetid][pBizOffer] = playerid;
	PlayerInfo[targetid][pBizOffered] = businessid;
	PlayerInfo[targetid][pBizPrice] = amount;

	SendClientMessageEx(targetid, COLOR_AQUA, "** %s offered you their business for $%i (/accept business).", GetRPName(playerid), amount);
	SendClientMessageEx(playerid, COLOR_AQUA, "** You have offered %s to buy your business for $%i.", GetRPName(targetid), amount);
	return 1;
}

CMD:sellmybiz(playerid, params[])
{
	new businessid = GetNearbyBusinessEx(playerid);

	if(businessid == -1 || !IsBusinessOwner(playerid, businessid))
	{
	    return SendClientMessage(playerid, COLOR_GREY, "Non sei in nessuno dei tuoi negozi.");
	}
	if(strcmp(params, "confirm", true) != 0)
	{
	    SendClientMessage(playerid, COLOR_WHITE, "Usage: /sellmybiz [confirm]");
	    SendClientMessageEx(playerid, COLOR_WHITE, "This command sells your business back to the state. You will receive $%i back.", percent(BusinessInfo[businessid][bPrice], 75));
	    return 1;
	}

	SetBusinessOwner(businessid, INVALID_PLAYER_ID);
	PlayerInfo[playerid][pMoney] = percent(BusinessInfo[businessid][bPrice], 75);

	SendClientMessageEx(playerid, COLOR_YELLOW, "You have sold your business to the state and received $%i back.", percent(BusinessInfo[businessid][bPrice], 75));
	return 1;
}

CMD:bizinfo(playerid, params[])
{
    new businessid = GetNearbyBusinessEx(playerid);

	if(businessid == -1 || !IsBusinessOwner(playerid, businessid))
	{
	    return SendClientMessage(playerid, COLOR_GREY, "Non sei in nessuno dei tuoi negozi.");
	}

    SendClientMessageEx(playerid, COLOR_RED, "Business ID %i:", businessid);
	SendClientMessageEx(playerid, COLOR_WHITE, "(Value: $%i) - (Type: %s) - (Status: %s)", BusinessInfo[businessid][bPrice], bizInteriors[BusinessInfo[businessid][bType]][intType], (BusinessInfo[businessid][bLocked]) ? ("Closed") : ("Opened"));
	SendClientMessageEx(playerid, COLOR_WHITE, "(Vault: $%i) - (Products: %i)", BusinessInfo[businessid][bCash], BusinessInfo[businessid][bProducts]);
	return 1;
}

CMD:buy(playerid, params[])
{
	new businessid = GetInsideBusiness(playerid), title[64];
	if(businessid == -1)
	{
	    return SendClientMessage(playerid, COLOR_GREY, "You are not inside of any business where you can buy stuff.");
	}
	if(BusinessInfo[businessid][bProducts] <= 0)
 	{
	 	return SendClientMessage(playerid, COLOR_GREY, "This business is out of stock.");
   	}

	format(title, sizeof(title), "%s's %s [%i products]", BusinessInfo[businessid][bOwner], bizInteriors[BusinessInfo[businessid][bType]][intType], BusinessInfo[businessid][bProducts]);

	switch(BusinessInfo[businessid][bType])
	{
	    case BUSINESS_STORE:
	    {
	        Dialog_Show(playerid, DIALOG_BUY, DIALOG_STYLE_LIST, title, "($100) Bread\n($100) Water", "Select", "Cancel");
		}
		case BUSINESS_GUNSHOP:
		{
		    Dialog_Show(playerid, DIALOG_BUY, DIALOG_STYLE_LIST, title, "($100) Pistol\n($100) M4A1", "Select", "Cancel");
		}
		case BUSINESS_CLOTHES:
		{
		    Dialog_Show(playerid, DIALOG_BUY, DIALOG_STYLE_INPUT, title, "Please type a Skin ID from 1-308.", "Select", "Cancel");
		}
		case BUSINESS_ELECTRONICS:
		{
		    Dialog_Show(playerid, DIALOG_BUY, DIALOG_STYLE_LIST, title, "($25000) Phone\n($150000) TV", "Select", "Cancel");
		}
		case BUSINESS_RESTAURANT:
		{
		    Dialog_Show(playerid, DIALOG_BUY, DIALOG_STYLE_LIST, title, "($1500) Steak\n($100) Tea", "Select", "Cancel");
		}
		case BUSINESS_BARCLUB:
		{
		    Dialog_Show(playerid, DIALOG_BUY, DIALOG_STYLE_LIST, title, "($1500) Wine\n($1500) Beer", "Select", "Cancel");
		}
	}

	return 1;
}

CMD:benter(playerid, params[]) return bizEnter(playerid);
CMD:bexit(playerid, params[]) return bizExit(playerid);
