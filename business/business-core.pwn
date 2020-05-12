/*
		================
		BUSINESS SYSTEM
		===============

		TO DO LIST:
		- Create/Load/Save [ ]
		- Enter Exit [ ]
		- Buyable [ ]
		- Buy Products [ ]
		- Business Types [ ]
		- Interiors [ ]
		- Products [ ]
		- Sellable [ ]
		- Restock [ ]

*/
#define MAX_BUSINESSES	100

new queryBuffer[1024];

enum bizInt
{
	intType[24],
	intPrice,
	intID,
	Float:intX,
	Float:intY,
	Float:intZ,
	Float:intA
};

new const bizInteriors[][bizInt] =
{
    {"Supermarket", 		  100000, 6, -27.4377, -57.6114, 1003.5469, 0.0000},
	{"Gun Shop",    		  100000, 6,  316.2873, -169.6470, 999.6010, 0.0000},
	{"Clothes Shop",    	  150000, 14, 204.3860, -168.4586, 1000.5234, 0.0000},
	{"Gym",         		  100000, 7,  773.7802, -78.2581, 1000.6619, 0.0000},
	{"Restaurant",  		  100000, 10, 363.3276, -74.6505, 1001.5078, 315.0000},
	{"Advertisement Agency",  175000, 3,  834.1517, 7.4096, 1004.1870, 90.0000},
	{"Club/Bar",              175000, 11, 501.8694, -68.0046, 998.7578, 179.6117}
};

enum BusinessData {
	bID,
	bExists,
	bName[32],
	bOwnerID,
	bOwner[24],
	bType,
	bProducts,
	bPrice,
	bUsed,
	Float:bPosX,
	Float:bPosY,
	Float:bPosZ,
	Float:bIntX,
	Float:bIntY,
	Float:bIntZ,
	bInterior,
	bWorld,
	bOutsideInt,
	bOutsideVW,
	bCash,
	bLocked,
	Text3D:bText,
	bMapIcon,
	bPickup
};
new BusinessInfo[MAX_BUSINESSES][BusinessData];

#define 	BUSINESS_STORE			0
#define 	BUSINESS_GUNSHOP		1
#define 	BUSINESS_CLOTHES		2
#define 	BUSINESS_ELECTRONICS	3
#define 	BUSINESS_RESTAURANT		4
#define 	BUSINESS_AGENCY			5
#define 	BUSINESS_BARCLUB		6
#define 	BUSINESS_BETTING		7

forward BusinessInit();
public BusinessInit()
{
	new rows; 
	cache_get_row_count(rows);

	for(new b = 0; b < rows && b < MAX_BUSINESSES; b ++)
	{
        cache_get_value_name(b, "owner", BusinessInfo[b][bOwner], MAX_PLAYER_NAME);

        cache_get_value_name_int(b, "id", BusinessInfo[b][bID]);
        cache_get_value_name_int(b, "ownerid", BusinessInfo[b][bOwnerID]);
        cache_get_value_name_int(b, "type", BusinessInfo[b][bType]);
        cache_get_value_name_int(b, "price", BusinessInfo[b][bPrice]);
        cache_get_value_name_int(b, "locked", BusinessInfo[b][bLocked]);
        cache_get_value_name_float(b, "pos_x", BusinessInfo[b][bPosX]);
        cache_get_value_name_float(b, "pos_y", BusinessInfo[b][bPosY]);
        cache_get_value_name_float(b, "pos_z", BusinessInfo[b][bPosZ]);
        cache_get_value_name_float(b, "int_x", BusinessInfo[b][bIntX]);
        cache_get_value_name_float(b, "int_y", BusinessInfo[b][bIntY]);
        cache_get_value_name_float(b, "int_z", BusinessInfo[b][bIntZ]);
        cache_get_value_name_int(b, "interior", BusinessInfo[b][bInterior]);
        cache_get_value_name_int(b, "world", BusinessInfo[b][bWorld]);
        cache_get_value_name_int(b, "cash", BusinessInfo[b][bCash]);
        cache_get_value_name_int(b, "products", BusinessInfo[b][bProducts]);
        cache_get_value_name_int(b, "outsideint", BusinessInfo[b][bOutsideInt]);
		cache_get_value_name_int(b, "outsidevw", BusinessInfo[b][bOutsideVW]);
		BusinessInfo[b][bText] = Text3D:INVALID_3DTEXT_ID;
		BusinessInfo[b][bExists] = 1;

		businessReload(b);
	}
	printf("[Script] %i businesses loaded.", rows);
}

forward OnAdminCreateBusiness(playerid, businessid, type, Float:x, Float:y, Float:z, Float:angle);
public OnAdminCreateBusiness(playerid, businessid, type, Float:x, Float:y, Float:z, Float:angle)
{
	strcpy(BusinessInfo[businessid][bOwner], "Nobody", MAX_PLAYER_NAME);

	BusinessInfo[businessid][bExists] = 1;
	BusinessInfo[businessid][bID] = cache_insert_id();
	BusinessInfo[businessid][bOwnerID] = 0;
	BusinessInfo[businessid][bType] = type;
	BusinessInfo[businessid][bPrice] = bizInteriors[type][intPrice];
	BusinessInfo[businessid][bLocked] = 0;
	BusinessInfo[businessid][bPosX] = x;
	BusinessInfo[businessid][bPosY] = y;
	BusinessInfo[businessid][bPosZ] = z;
	BusinessInfo[businessid][bIntX] = bizInteriors[type][intX];
	BusinessInfo[businessid][bIntY] = bizInteriors[type][intY];
	BusinessInfo[businessid][bIntZ] = bizInteriors[type][intZ];
	BusinessInfo[businessid][bInterior] = bizInteriors[type][intID];
	BusinessInfo[businessid][bOutsideInt] = GetPlayerInterior(playerid);
	BusinessInfo[businessid][bOutsideVW] = GetPlayerVirtualWorld(playerid);
	BusinessInfo[businessid][bWorld] = BusinessInfo[businessid][bID] + 3000000;
	BusinessInfo[businessid][bCash] = 0;
	BusinessInfo[businessid][bProducts] = 500;
	BusinessInfo[businessid][bText] = Text3D:INVALID_3DTEXT_ID;
	BusinessInfo[businessid][bPickup] = -1;
	BusinessInfo[businessid][bMapIcon] = -1;

	mysql_format(Database, queryBuffer, sizeof(queryBuffer), "UPDATE businesses SET products = %i, world = %i WHERE id = %i", BusinessInfo[businessid][bProducts], BusinessInfo[businessid][bWorld], BusinessInfo[businessid][bID]);
	mysql_tquery(Database, queryBuffer);

	businessReload(businessid);
	SendClientMessageEx(playerid, COLOR_RED, "Business %i created successfully.", businessid);
}

businessReload(businessid)
{
	if(BusinessInfo[businessid][bExists])
	{
	    new
	        string[128];

		DestroyDynamic3DTextLabel(BusinessInfo[businessid][bText]);
		DestroyDynamicPickup(BusinessInfo[businessid][bPickup]);
        DestroyDynamicMapIcon(BusinessInfo[businessid][bMapIcon]);

        if(BusinessInfo[businessid][bOwnerID] == 0)
        {
	        format(string, sizeof(string), "[Business]\nPrice: %s\nType: %s\nStatus: %s", FormatNumber(BusinessInfo[businessid][bPrice]), bizInteriors[BusinessInfo[businessid][bType]][intType], (BusinessInfo[businessid][bLocked]) ? ("{ffff00}Closed") : ("{00AA00}Opened"));
		}
		else
		{
		    format(string, sizeof(string), "[Business]\nOwner: %s\nType: %s\nStatus: %s", BusinessInfo[businessid][bOwner], bizInteriors[BusinessInfo[businessid][bType]][intType], (BusinessInfo[businessid][bLocked]) ? ("{FFFF00}Closed") : ("{00AA00}Opened"));
		}

		BusinessInfo[businessid][bText] = CreateDynamic3DTextLabel(string, COLOR_RED, BusinessInfo[businessid][bPosX], BusinessInfo[businessid][bPosY], BusinessInfo[businessid][bPosZ] + 0.1, 10.0, .worldid = BusinessInfo[businessid][bOutsideVW], .interiorid = BusinessInfo[businessid][bOutsideInt]);
        BusinessInfo[businessid][bPickup] = CreateDynamicPickup(1272, 1, BusinessInfo[businessid][bPosX], BusinessInfo[businessid][bPosY], BusinessInfo[businessid][bPosZ], .worldid = BusinessInfo[businessid][bOutsideVW], .interiorid = BusinessInfo[businessid][bOutsideInt]);

		switch(BusinessInfo[businessid][bType])
		{
		    case BUSINESS_STORE: 		{ BusinessInfo[businessid][bMapIcon] = CreateDynamicMapIcon(BusinessInfo[businessid][bPosX], BusinessInfo[businessid][bPosY], BusinessInfo[businessid][bPosZ], 17, 0, .worldid = BusinessInfo[businessid][bOutsideVW], .interiorid = BusinessInfo[businessid][bOutsideInt], .style = MAPICON_GLOBAL); }
		    case BUSINESS_GUNSHOP: 		{ BusinessInfo[businessid][bMapIcon] = CreateDynamicMapIcon(BusinessInfo[businessid][bPosX], BusinessInfo[businessid][bPosY], BusinessInfo[businessid][bPosZ], 6, 0, .worldid = BusinessInfo[businessid][bOutsideVW], .interiorid = BusinessInfo[businessid][bOutsideInt], .style = MAPICON_GLOBAL); }
		    case BUSINESS_CLOTHES: 		{ BusinessInfo[businessid][bMapIcon] = CreateDynamicMapIcon(BusinessInfo[businessid][bPosX], BusinessInfo[businessid][bPosY], BusinessInfo[businessid][bPosZ], 45, 0, .worldid = BusinessInfo[businessid][bOutsideVW], .interiorid = BusinessInfo[businessid][bOutsideInt], .style = MAPICON_GLOBAL); }
		    case BUSINESS_RESTAURANT: 	{ BusinessInfo[businessid][bMapIcon] = CreateDynamicMapIcon(BusinessInfo[businessid][bPosX], BusinessInfo[businessid][bPosY], BusinessInfo[businessid][bPosZ], 10, 0, .worldid = BusinessInfo[businessid][bOutsideVW], .interiorid = BusinessInfo[businessid][bOutsideInt], .style = MAPICON_GLOBAL); }
		    case BUSINESS_ELECTRONICS: 	{ BusinessInfo[businessid][bMapIcon] = CreateDynamicMapIcon(BusinessInfo[businessid][bPosX], BusinessInfo[businessid][bPosY], BusinessInfo[businessid][bPosZ], 54, 0, .worldid = BusinessInfo[businessid][bOutsideVW], .interiorid = BusinessInfo[businessid][bOutsideInt], .style = MAPICON_GLOBAL); }
		    case BUSINESS_AGENCY: 		{ BusinessInfo[businessid][bMapIcon] = CreateDynamicMapIcon(BusinessInfo[businessid][bPosX], BusinessInfo[businessid][bPosY], BusinessInfo[businessid][bPosZ], 58, 0, .worldid = BusinessInfo[businessid][bOutsideVW], .interiorid = BusinessInfo[businessid][bOutsideInt], .style = MAPICON_GLOBAL); }
		    case BUSINESS_BARCLUB: 		{ BusinessInfo[businessid][bMapIcon] = CreateDynamicMapIcon(BusinessInfo[businessid][bPosX], BusinessInfo[businessid][bPosY], BusinessInfo[businessid][bPosZ], 49, 0, .worldid = BusinessInfo[businessid][bOutsideVW], .interiorid = BusinessInfo[businessid][bOutsideInt], .style = MAPICON_GLOBAL); }
		}
	}
}

stock GetClosestBusiness(playerid, type)
{
	new
	    Float:distance[2] = {99999.0, 0.0},
	    index = -1;

	for(new b = 0; b < MAX_BUSINESSES; b ++)
	{
		if((BusinessInfo[b][bExists] && BusinessInfo[b][bType] == type) && (BusinessInfo[b][bOutsideInt] == 0 && BusinessInfo[b][bOutsideVW] == 0))
		{
			distance[1] = GetPlayerDistanceFromPoint(playerid, BusinessInfo[b][bPosX], BusinessInfo[b][bPosY], BusinessInfo[b][bPosZ]);

			if(distance[0] > distance[1])
			{
			    distance[0] = distance[1];
			    index = b;
			}
		}
	}

	return index;
}

GetNearbyBusinessEx(playerid)
{
	return GetNearbyBusiness(playerid) == -1 ? GetInsideBusiness(playerid) : GetNearbyBusiness(playerid);
}

stock GetNearbyBusiness(playerid, Float:radius = 2.0)
{
	for(new b = 0; b < MAX_BUSINESSES; b ++)
	{
	    if(BusinessInfo[b][bExists] && IsPlayerInRangeOfPoint(playerid, radius, BusinessInfo[b][bPosX], BusinessInfo[b][bPosY], BusinessInfo[b][bPosZ]) && GetPlayerInterior(playerid) == BusinessInfo[b][bOutsideInt] && GetPlayerVirtualWorld(playerid) == BusinessInfo[b][bOutsideVW])
	    {
	        return b;
		}
	}

	return -1;
}

stock GetInsideBusiness(playerid)
{
	for(new b = 0; b < MAX_BUSINESSES; b ++)
	{
	    if(BusinessInfo[b][bExists] && IsPlayerInRangeOfPoint(playerid, 100.0, BusinessInfo[b][bIntX], BusinessInfo[b][bIntY], BusinessInfo[b][bIntZ]) && GetPlayerInterior(playerid) == BusinessInfo[b][bInterior] && GetPlayerVirtualWorld(playerid) == BusinessInfo[b][bWorld])
	    {
	        return b;
		}
	}

	return -1;
}

SetBusinessOwner(businessid, playerid)
{
	if(playerid == INVALID_PLAYER_ID)
	{
	    strcpy(BusinessInfo[businessid][bOwner], "Nobody", MAX_PLAYER_NAME);
	    BusinessInfo[businessid][bOwnerID] = 0;
	}
	else
	{
     	GetPlayerName(playerid, BusinessInfo[businessid][bOwner], MAX_PLAYER_NAME);
	    BusinessInfo[businessid][bOwnerID] = PlayerInfo[playerid][pUID];
	}

	mysql_format(Database, queryBuffer, sizeof(queryBuffer), "UPDATE businesses SET ownerid = %i, owner = '%s' WHERE id = %i", BusinessInfo[businessid][bOwnerID], BusinessInfo[businessid][bOwner], BusinessInfo[businessid][bID]);
	mysql_tquery(Database, queryBuffer);

	businessReload(businessid);
}

IsBusinessOwner(playerid, businessid)
{
	return (BusinessInfo[businessid][bOwnerID] == PlayerInfo[playerid][pUID]) || (BusinessInfo[businessid][bOwnerID] > 0);
}

bizEnter(playerid)
{
	new id;
	if((id = GetNearbyBusiness(playerid)) >= 0)
	{
	    if(BusinessInfo[id][bLocked])
	    {
			GameTextForPlayer(playerid, "~r~Closed", 5000, 1);
			return 0;
		}

		if(IsBusinessOwner(playerid, id))
		{
		    SendProximityMessage(playerid, 20.0, COLOR_WHITE, "**{C2A2DA} %s has entered their business.", GetRPName(playerid));
		}
		else
		{
			SendProximityMessage(playerid, 20.0, COLOR_WHITE, "**{C2A2DA} %s has entered the business.", GetRPName(playerid));

			switch(BusinessInfo[id][bType])
			{
				case BUSINESS_STORE, BUSINESS_GUNSHOP, BUSINESS_CLOTHES, BUSINESS_RESTAURANT, BUSINESS_BARCLUB, BUSINESS_ELECTRONICS:
					SendClientMessageEx(playerid, COLOR_YELLOW, "Welcome to {FFFFFF}%s's{FFFF00} %s (%i Products left). Type /buy to purchase from this business.", BusinessInfo[id][bOwner], bizInteriors[BusinessInfo[id][bType]][intType], BusinessInfo[id][bProducts]);
				case BUSINESS_AGENCY:
				    SendClientMessageEx(playerid, COLOR_YELLOW, "Welcome to {FFFFFF}%s's{FFFF00} %s. /(ad)vertise to make an advertisement.", BusinessInfo[id][bOwner], bizInteriors[BusinessInfo[id][bType]][intType]);
			}
		}

		SetPlayerInterior(playerid, BusinessInfo[id][bInterior]);
		SetPlayerVirtualWorld(playerid, BusinessInfo[id][bWorld]);
		SetPlayerPos(playerid, BusinessInfo[id][bIntX], BusinessInfo[id][bIntY], BusinessInfo[id][bIntZ]);
		SetCameraBehindPlayer(playerid);
		return 1;
	}
	return 1;
}

bizExit(playerid)
{
	new id;
	if((id = GetInsideBusiness(playerid)) >= 0 && IsPlayerInRangeOfPoint(playerid, 3.0, BusinessInfo[id][bIntX], BusinessInfo[id][bIntY], BusinessInfo[id][bIntZ]))
	{
		SendProximityMessage(playerid, 20.0, COLOR_YELLOW, "**{C2A2DA} %s has exited the business.", GetRPName(playerid));
		SetPlayerPos(playerid, BusinessInfo[id][bPosX], BusinessInfo[id][bPosY], BusinessInfo[id][bPosZ]);
		SetPlayerInterior(playerid, BusinessInfo[id][bOutsideInt]);
		SetPlayerVirtualWorld(playerid, BusinessInfo[id][bOutsideVW]);
		SetCameraBehindPlayer(playerid);
		return 1;
	}
	return 1;
}