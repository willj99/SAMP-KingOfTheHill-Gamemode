#include                    <a_samp>
#include                    <gl_common>
#include                    <izcmd>
#include                    <streamer>

// --- Configuration & Variables ---
#define MAP_NAME            "Madd Dogg's Mansion" // Tweak this for your own map or theme!
#define GAMEMODE_NAME       "King of the Hill"
#define CROWN_ICON_ID       55  // The slot we are using
#define MYSTERY_BOX_ICON_ID 56
#define ICON_TYPE           0   // Type 0 is the generic map square/dot
#define OBJECTIVE_MODEL     2894        // The Rhyme Book
#define WEATHER             8 
#define TIME_OF_DAY         0

// Colours
#define COLOR_GOLD          0xFFD700AA
#define COLOR_RED           0xFF0000AA
#define COLOR_BLUE          0x0000FFAA
#define COLOR_GREEN         0x00FF00AA
#define COLOR_WHITE         0xFFFFFFFF
#define COLOR_DODGER_BLUE   0x1E90FFAA
#define COLOR_HOT_PINK      0xFF69B4AA
#define COLOR_PURPLE        0x800080AA
#define COLOR_BROWN         0xA52A2AAA
#define COLOR_CYAN          0x00FFFFFF
#define COLOR_TEAL          0x008080AA
#define COLOR_PINK          0xFFC0CBAA

// Pickups
#define PICKUP_KATANA               339
#define PICKUP_SPRAYCAN             365
#define PICKUP_MAC10                352
#define PICKUP_MP5                  353
#define PICKUP_M4                   356
#define PICKUP_SNIPER               358
#define PICKUP_CHAINSAW             341
#define PICKUP_SATCHEL              363
#define PICKUP_SPAS12               351
#define PICKUP_DEAGLE               348
#define PICKUP_NIGHTVISION_GOGGLES  368
#define PICKUP_FLAMETHROWER         361
#define PICKUP_MOLOTOV              344
#define HEALTH_PICKUP               1240
#define ARMOUR_PICKUP               1242

// Soundbank
#define Soundbank_Powerup           1054
#define Soundbank_Penalty           1085
#define Soundbank_Powerup2          1133
#define Soundbank_FireIgnite        1159
#define Soundbank_Explosion         1159

// Crown Variables
new CrownCarrier = INVALID_PLAYER_ID;
new CrownObject;
new Text3D:CrownLabel;
new RoundNumber = 0; // If this hits 4, then end the gamemode.
//new Float:CrownPos[3] = {1244.2, -812.5, 1084.0}; // The initial crown spawn... which has no blip.

// Dialogue for shop...
new DIALOG_SHOP;

// Keep track of the players time with or without the crown.
new CarrierPoints[MAX_PLAYERS];

// How long a player needs to hold the crown to win, and the prize for doing so. 
#define WIN_TIME 120 // How long a player needs to hold the crown to win (in seconds)
#define WIN_PRIZE 50000 // Cash prize, feel free to change or remove this or implement a shop via filterscript

// World and Interior configuration
#define KOTH_INTERIOR 5 // If this koth script is for an interior, set here. 
#define ClassInterior 14

new const VIRTUAL_WORLD = 0;

new KEY_SCOREBOARD = KEY_NO
new Text:LeaderboardBG;
new Text:LeaderboardTitle;
new PlayerText:LeaderboardData[MAX_PLAYERS]; 
new PlayerText:LeaderboardTimeData[MAX_PLAYERS];
new PlayerText:KOTH_UI[MAX_PLAYERS]; // The container for the text
new MysteryBoxPickup = -1; // Initialising at -1 so we can check if it exists before trying to destroy it.
new bool:IsKingDrunk[MAX_PLAYERS]; // One of the mystery box effects
new BoxSpawnTimer; // This is currently set to spawn a mystery box every 30 seconds a crown is held.
//new OOBTimer[MAX_PLAYERS]; // If someone leaves the interior ID they will lose the crown.

// Class Selection Variables 
new Float:ClassSpawn[]          =   {1265.0, -775.0, 1091.0};
new Float:ClassPos[]            =   {258.4893,-41.4008,1002.0234};
new Float:ClassAngle[]          =   {270.0};
new Float:ClassCameraPosition[] =   {256.0815,-43.0475,1004.0234};
new Float:PlayerCameraLookAt[]  =   {258.4893,-41.4008,1002.0234};




new Float:BoxSpawns[][] = {
    {1277.4946,-793.0939,1084.1719}, 
    {1255.2019,-801.0082,1084.178}, 
    {1254.2897,-769.6935,1084.1078}, 
    {1226.4895,-809.8442,1084.1078},  
    {1279.6417,-829.5239,1085.6328},
    {1282.1771,-795.9783,1089.9375}, 
    {1244.2, -812.5, 1084.0}
};

new Float:WeaponSpawns[][] = {
    {1278.9075,-813.9222,1085.6328},
    {1236.5581,-822.9996,1083.1563},
    {1236.2152,-812.0184,1084.0078},
    {1272.9640,-812.9725,1084.0078},
    {1247.0454,-802.8285,1084.0151},
    {1270.6401,-794.8502,1084.1719},
    {1240.1926,-763.2814,1084.0090},
    {1277.3861,-808.3147,1089.9375},
    {1291.0815,-809.5367,1089.9375},
    {1291.8536,-814.0552,1089.9375},
    {1285.8076,-773.8431,1091.9063},
    {1270.2717,-775.7320,1091.9063},
    {1282.3832,-809.3503,1089.9375},
    {1248.7437,-827.9973,1084.0078},
    {1258.9736,-820.6961,1084.0078},
    {1248.5912,-806.3620,1084.0078}
};

// Player Spawn Points 
new Float:PlayerSpawns[][] = {
    {1275.5081,-805.8553,1089.9375}, 
    {1289.5831,-797.2665,1089.9375}, 
    {1278.1370,-817.2461,1085.6328}, 
    {1248.1642,-826.3605,1084.0078}, 
    {1227.2749,-811.8171,1084.0078},
    {1267.8297,-811.8162,1084.0078},
    {1265.3872,-794.4587,1084.0078},
    {1242.0062,-770.0661,1084.0096},
    {1265.9507,-778.5200,1084.0078}
};

// Crown Spawn Points
new Float:CrownSpawns[][] = {
    {1255.1949,-805.7093,1084.0151}, 
    {1234.1421,-807.2415,1084.0078}, 
    {1242.3064,-820.2726,1083.1563}, 
    {1292.0992,-826.2497,1085.6328}, 
    {1251.6196,-812.2668,1084.0078}
};

new WeaponPool[sizeof(WeaponSpawns)]; // This will be populated with the pickups we want to spawn on the map for players to grab and cleared each time KOTH resets.


new const Pickups[] = {
    PICKUP_MOLOTOV,
    PICKUP_FLAMETHROWER,
    PICKUP_M4,
    PICKUP_SNIPER,
    PICKUP_CHAINSAW,
    PICKUP_SATCHEL,
    PICKUP_SPAS12,
    PICKUP_DEAGLE,
    PICKUP_NIGHTVISION_GOGGLES,
    PICKUP_KATANA,
    PICKUP_SPRAYCAN,
    PICKUP_MAC10,
    PICKUP_MP5
}

public OnGameModeInit()
{
    print("Initializing KOTH by wilaim / willj99");
    SetGameModeText(GAMEMODE_NAME);
    InitializeTextDraw();
    
    UsePlayerPedAnims();
    SetWorldTime(TIME_OF_DAY);
    SetWeather(WEATHER);

    for(new i = 0; i <= 311; i++)
    {
        AddPlayerClass(i, ClassSpawn[0], ClassSpawn[1], ClassSpawn[2], 0.0, 0, 0, 0, 0, 0, 0);
    }
    
    ResetKOTHMatch();
    
    DisableInteriorEnterExits();   
    SetTimer("SecondTimer", 1000, true);

    return 1;
}

public OnGameModeExit(){
    return 1;
}

public OnPlayerConnect(playerid)
{
    DrawTextDraws(playerid);
    return 1;
}

public OnPlayerKeyStateChange(playerid, newkeys, oldkeys)
{
    DrawLeaderboard(playerid, newkeys, oldkeys);
    return 1;
}

public OnPlayerSpawn(playerid)
{
    GameTextForPlayer(playerid,"~w~Find and capture the ~g~crown!~n~~w~Hold it for 120 seconds to win.",3000,5);

    new p = random(sizeof(PlayerSpawns));
    SetPlayerInterior(playerid, KOTH_INTERIOR); 
    SetPlayerPos(playerid, PlayerSpawns[p][0], PlayerSpawns[p][1], PlayerSpawns[p][2]);

    // Set Virtual World (keep it 0 unless you use multiple asynchronous matches)
    SetPlayerVirtualWorld(playerid, VIRTUAL_WORLD);

    RemovePlayerAttachedObject(playerid, 0);

    // Show the UI again (in case it hid on death)
    PlayerTextDrawShow(playerid, KOTH_UI[playerid]);

    ResetPlayerWeapons(playerid); // Clear weapons and reassign them.
    GivePlayerWeapon(playerid, 22, 100);  // Colt 45
    GivePlayerWeapon(playerid, 25, 50);   // Shotgun
    GivePlayerWeapon(playerid, 33, 50);   // Country Rifle


    ClearAnimations(playerid, false);

    return 1;
}

public OnPlayerRequestClass(playerid, classid)
{
    // Show the Skin ID on the screen 
    new str[32];
    format(str, sizeof(str), "~y~SKIN ID: ~w~%d", GetPlayerSkin(playerid));
    GameTextForPlayer(playerid, str, 2000, 4);

    // Standard Camera setup
 	SetPlayerInterior(playerid, ClassInterior);
	SetPlayerPos(playerid,ClassPos[0],ClassPos[1],ClassPos[2]);
	SetPlayerFacingAngle(playerid, ClassAngle[0]);
	SetPlayerCameraPos(playerid,ClassCameraPosition[0],ClassCameraPosition[1],ClassCameraPosition[2]);
	SetPlayerCameraLookAt(playerid,PlayerCameraLookAt[0],PlayerCameraLookAt[1],PlayerCameraLookAt[2]);
    
    return 1;
}

public OnDialogResponse(playerid, dialogid, response, listitem, inputtext[])
{
    if(dialogid == DIALOG_SHOP)
    {
        if(!response) return 1; // Player clicked 'Cancel'

        switch(listitem)
        {
            case 0: // Heat-Seeking RPG
            {
                if(GetPlayerMoney(playerid) < 25000) return SendClientMessage(playerid, 0xFF0000FF, "You don't have enough money!");
                
                GivePlayerMoney(playerid, -25000);
                GivePlayerWeapon(playerid, 36, 10); // ID 36 = Heat Seeker
                SendClientMessage(playerid, 0x00FF00FF, "Purchased Heat-Seeking RPG (10 Rounds)");
            }
            case 1: // Standard RPG
            {
                if(GetPlayerMoney(playerid) < 25000) return SendClientMessage(playerid, 0xFF0000FF, "You don't have enough money!");
                
                GivePlayerMoney(playerid, -25000);
                GivePlayerWeapon(playerid, 35, 10); // ID 35 = RPG
                SendClientMessage(playerid, 0x00FF00FF, "Purchased RPG (10 Rounds)");
            }
            case 2: // Minigun
            {
                if(GetPlayerMoney(playerid) < 150000) return SendClientMessage(playerid, 0xFF0000FF, "You don't have enough money!");
                
                GivePlayerMoney(playerid, -150000);
                GivePlayerWeapon(playerid, 38, 500); // ID 38 = Minigun
                SendClientMessage(playerid, 0x00FF00FF, "Purchased Minigun (500 Rounds)");
            }
            case 3: {
                if(GetPlayerMoney(playerid) < 5000) return SendClientMessage(playerid, 0xFF0000FF, "You don't have enough money!");
                
                GivePlayerMoney(playerid, -5000);
                GivePlayerWeapon(playerid, 44, 1); // ID 38 = Minigun
                SendClientMessage(playerid, 0x00FF00FF, "Purchased Nightvision Goggles");
            }
            case 4: {
                if(GetPlayerMoney(playerid) < 5000) return SendClientMessage(playerid, 0xFF0000FF, "You don't have enough money!");
                
                GivePlayerMoney(playerid, -5000);
                GivePlayerWeapon(playerid, 45, 1); // ID 38 = Minigun
                SendClientMessage(playerid, 0x00FF00FF, "Purchased Thermal Vision Goggles");
            }
        }
        return 1;
    }
    return 0;
}

// --- The "Grab" Logic ---
public OnPlayerPickUpPickup(playerid, pickupid)
{

    new name[MAX_PLAYER_NAME], kingName[MAX_PLAYER_NAME], str[144];
    GetPlayerName(playerid, name, sizeof(name));
    if(CrownCarrier != INVALID_PLAYER_ID) { GetPlayerName(CrownCarrier, kingName, sizeof(kingName)); }

    // --- (THE CROWN) ---
    if(pickupid == CrownObject)
    {
        CrownCarrier = playerid;
        DestroyPickup(CrownObject);
        CrownObject = -1; // Reset variable so it doesn't ghost
        Delete3DTextLabel(CrownLabel);
        UpdateCrownBlip(0.0, 0.0, 0.0, false);

        format(str, sizeof(str), "~r~%s ~w~has taken the crown!", name);
        for(new i = 0; i < MAX_PLAYERS; i++) {
            if(IsPlayerConnected(i)) GameTextForPlayer(i, str, 3000, 3);
        }

  

        SetPlayerAttachedObject(playerid, 0, OBJECTIVE_MODEL, 1, -0.12, -0.15, 0.0, 90.0, 0.0, 0.0, 1.0, 1.0, 1.0);
        SetPlayerColor(playerid, 0xFF0000FF); 
        SetPlayerArmour(playerid, 100.0);

        new weapons[] = {24, 25, 29, 30, 34, 38, 16}; 
        GivePlayerWeapon(playerid, weapons[random(sizeof(weapons))], 100);
        
        return 1; 
    }

  
    else if(pickupid == MysteryBoxPickup)
    {
        DestroyPickup(MysteryBoxPickup);
        MysteryBoxPickup = -1; // Reset variable
        

        for(new i = 0; i < MAX_PLAYERS; i++) RemovePlayerMapIcon(i, MYSTERY_BOX_ICON_ID);

        // --- IF HUNTER PICKS IT UP ---
        if(playerid != CrownCarrier && CrownCarrier != INVALID_PLAYER_ID)
        {
            switch(random(8))
            {
                case 0: { // Incinerate King
                    new fireObj = CreatePlayerObject(CrownCarrier, 18685, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0);
                    AttachPlayerObjectToPlayer(CrownCarrier, fireObj, CrownCarrier, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0);
                    SetPlayerHealth(CrownCarrier, 1.0); 
                    SetPlayerArmour(CrownCarrier, 0.0);
                    SetTimerEx("HellfireFinalBlow", 1000, false, "i", CrownCarrier);
                    format(str, sizeof(str), "~r~%s ~w~INCINERATED THE KING!", name);
                    PlaySoundForAllPlayers(Soundbank_Powerup2);
                    PlayerPlaySound(CrownCarrier, Soundbank_FireIgnite, 0.0, 0.0, 2.0);
                }
                case 1: { // Dildo humiliation
                    ResetPlayerWeapons(CrownCarrier);
                    GivePlayerWeapon(CrownCarrier, 10, 1); 
                    SetPlayerSkin(CrownCarrier, 178);
                    format(str, sizeof(str), "~r~%s ~w~WAS CAUGHT ~r~PLAYING WITH HIMSELF!", kingName);
                    PlaySoundForAllPlayers(Soundbank_Powerup2);
                }
                case 2: { // RPG
                    GivePlayerWeapon(playerid, 35, 3);
                    format(str, sizeof(str), "~r~%s ~w~RECEIVED AN RPG!", name);
                    PlaySoundForAllPlayers(Soundbank_Powerup);
                }
                case 3: { // AK47 Gift
                    for(new i = 0; i < MAX_PLAYERS; i++) {
                        if(IsPlayerConnected(i) && i != CrownCarrier) GivePlayerWeapon(i, 30, 90);
                    }
                    format(str, sizeof(str), "~r~%s ~w~GIFTED AKs TO HUNTERS!", name);
                    PlaySoundForAllPlayers(Soundbank_Powerup);
                }
                case 4: { // Drunk King
                    IsKingDrunk[CrownCarrier] = true;
                    SetPlayerDrunkLevel(CrownCarrier, 5000);
                    ApplyAnimation(CrownCarrier, "PED", "WALK_DRUNK", 4.1, 1, 1, 1, 1, 1);
                    format(str, sizeof(str), "~r~%s ~w~INTOXICATED ~r~%s!", name, kingName);
                    SetTimerEx("ResetKingDrunk", 15000, false, "i", CrownCarrier);
                    PlaySoundForAllPlayers(Soundbank_Powerup2);
                }
                case 5: {
                    new fireObj = CreateObject(18685, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0);
                    AttachObjectToPlayer(fireObj, playerid, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0);
                    SetPlayerHealth(playerid, 1.0); // Leave them with a sliver of health
                    SetPlayerArmour(playerid, 0.0);
                    ApplyAnimation(playerid, "FLAME", "FLAME_fire", 4.1, 1, 1, 1, 1, 0);
                    SetTimerEx("HellfireFinalBlow", 1000, false, "ii", playerid, fireObj);

                    // Let everyone know about the backfire lol
                    format(str, sizeof(str), "~r~%s ~w~OPENED A CURSED BOX AND ~r~CAUGHT FIRE!", name);
                    PlaySoundForAllPlayers(Soundbank_Explosion);
                    PlayerPlaySound(playerid, Soundbank_FireIgnite, 0.0, 0.0, 2.0);
                }
                case 6: { // Flamethrower
                    GivePlayerWeapon(playerid, 37, 3);
                    format(str, sizeof(str), "~r~%s ~w~RECEIVED A FLAMETHROWER!", name);
                    PlaySoundForAllPlayers(Soundbank_Powerup);
                }
                case 7: { // Fetch the king to meeeee
                    new Float:kx, Float:ky, Float:kz;
                    GetPlayerPos(playerid, kx, ky, kz);
                    SetPlayerPos(CrownCarrier, kx + 1.0, ky + 1.0, kz); // Bring the king to the player
                    format(str, sizeof(str), "~r~%s ~w~SUMMONED THE KING %s TO HIMSELF!", name, kingName);
                    PlaySoundForAllPlayers(Soundbank_Powerup2);
                }
            }
        }
        // --- IF KING PICKS IT UP ---
        else if(playerid == CrownCarrier)
        {
            switch(random(3))
            {
                case 0: { // Weaken Hunters
                    for(new i = 0; i < MAX_PLAYERS; i++) {
                        if(IsPlayerConnected(i) && i != playerid) {
                            ResetPlayerWeapons(i);
                            GivePlayerWeapon(i, 22, 50);
                        }
                    }
                    format(str, sizeof(str), "~r~%s ~w~WEAKENED THE HUNTERS!", name);
                    PlaySoundForAllPlayers(Soundbank_Powerup2);
                }
                case 1: { // Hellfire Random Hunter
                    new target = INVALID_PLAYER_ID;             
                    new randomTarget = random(MAX_PLAYERS);
                    for(new i = 0; i < MAX_PLAYERS; i++) {
                        new checkId = (randomTarget + i) % MAX_PLAYERS;
                        if(IsPlayerConnected(checkId) && checkId != playerid) {
                            target = checkId;
                            break;
                        }
                    }   

                    if(target != INVALID_PLAYER_ID) {
                        new tName[MAX_PLAYER_NAME]; 
                        GetPlayerName(target, tName, sizeof(tName));

                        new fireObj = CreateObject(18685, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0);
                        AttachObjectToPlayer(fireObj, target, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0);

                        // Drop them to the "burning" state
                        SetPlayerHealth(target, 1.0); 
                        SetPlayerArmour(target, 0.0);

                        ApplyAnimation(target, "FLAME", "FLAME_fire", 4.1, 1, 1, 1, 1, 0);

                        // Pass BOTH the player and the object to the final blow to prevent lingering fire.
                        SetTimerEx("HellfireFinalBlow", 1000, false, "ii", target, fireObj);

                        format(str, sizeof(str), "~r~%s ~w~CAST HELLFIRE ON ~r~%s!", name, tName);
                        PlaySoundForAllPlayers(Soundbank_Powerup2);
                        PlayerPlaySound(target, Soundbank_FireIgnite, 0.0, 0.0, 2.0);
                    }
                }
                case 2: { // Go Dark
                    SetPlayerColor(playerid, 0xFFFFFF00); 
                    format(str, sizeof(str), "~w~THE KING ~r~%s ~w~HAS GONE DARK!", name);
                    SetTimerEx("RestoreKingBlip", 20000, false, "i", playerid);
                    PlaySoundForAllPlayers(Soundbank_Powerup);
                }
            }
        }

        // Send the resulting Mystery Box string as GameText Style 3 to everyone
        for(new i = 0; i < MAX_PLAYERS; i++) {
            if(IsPlayerConnected(i)) GameTextForPlayer(i, str, 6000, 3);
            
        }
       
    }
    
    return 1;
}

// --- The Hunter Penalty (Damage Logic) ---
public OnPlayerGiveDamage(playerid, damagedid, Float:amount, weaponid, bodypart)
{
    // If the person you hit is NOT the carrier AND you aren't the carrier...
    if(damagedid != CrownCarrier && playerid != CrownCarrier)
    {
        new Float:hp;
        GetPlayerHealth(playerid, hp);
        SetPlayerHealth(playerid, hp - (amount / 2)); // Reflect 50% damage back to shooter
        
        GameTextForPlayer(playerid, "~r~PENALTY: ~w~HIT THE WRONG TARGET!", 2000, 3);
        PlayerPlaySound(playerid, 1085, 0.0, 0.0, 0.0); 
        return 0; 
    }
    return 1;
}



// --- The Drop Logic ---
public OnPlayerDeath(playerid, killerid, reason)
{
    if(CrownCarrier == playerid)
    {
        new Float:x, Float:y, Float:z;
        GetPlayerPos(playerid, x, y, z);
        
        RemovePlayerAttachedObject(playerid, 0);
        SetPlayerColor(playerid, GetRandomColor()); // Reset color


        DestroyPickup(CrownObject);
        CrownObject = -1; // Reset variable because of ghosting and id issues
        
        CrownObject = CreatePickup(OBJECTIVE_MODEL, 15, x, y, z, VIRTUAL_WORLD);
        CrownLabel = Create3DTextLabel("CROWN\n{FFFFFF}Come get it!", COLOR_GOLD, x, y, z + 0.5, 20.0, 0);
        UpdateCrownBlip(x, y, z, true);

        CrownCarrier = INVALID_PLAYER_ID;
        SendClientMessageToAll(0xFFFFFF, "The king has dropped the crown!");
    }

    //SendDeathMessage(killerid, playerid, reason); //Hogs up the UI and tbh takes away from the focus of the crown, its not a deathmatch per say lol

    return 1;
}

public OnPlayerDisconnect(playerid, reason)
{
    if(CrownCarrier == playerid)
    {
        new Float:x, Float:y, Float:z;
        GetPlayerPos(playerid, x, y, z);
        
        DestroyPickup(CrownObject);
        CrownObject = -1; // Reset variable because of ghosting and id issues

        new rand = random(sizeof(CrownSpawns));

        // Drop the crown at their last known position
        CrownObject = CreatePickup(OBJECTIVE_MODEL, 1, CrownSpawns[rand][0], CrownSpawns[rand][1], CrownSpawns[rand][2] + 0.2, VIRTUAL_WORLD);
        CrownLabel = Create3DTextLabel("CROWN\n{FFFFFF}Come get it...", COLOR_GOLD, CrownSpawns[rand][0], CrownSpawns[rand][1], CrownSpawns[rand][2] + 0.5, 20.0, 0);
        UpdateCrownBlip(CrownSpawns[rand][0], CrownSpawns[rand][1], CrownSpawns[rand][2], true);     

        // Clear the carrier ID so the script knows it's back on the ground
        CrownCarrier = INVALID_PLAYER_ID;

        // Inform the server why the crown moved
        new name[MAX_PLAYER_NAME], str[128];
        GetPlayerName(playerid, name, sizeof(name));
        format(str, sizeof(str), "The king (%s) has left the server. The crown has been moved to a new location!", name);
        SendClientMessageToAll(COLOR_CYAN, str);
    }

    PlayerTextDrawDestroy(playerid, KOTH_UI[playerid]);
    return 1;
}




forward SecondTimer();
public SecondTimer()
{
    new str[128], kingName[MAX_PLAYER_NAME];

    if(CrownCarrier != INVALID_PLAYER_ID)
    {
        // 1. Increment ONLY the current king's personal time
        CarrierPoints[CrownCarrier]++; 

        // Check for the Win based on the king's individual points
        if(CarrierPoints[CrownCarrier] >= WIN_TIME)
        {
            new winStr[128];
            GetPlayerName(CrownCarrier, kingName, sizeof(kingName));
            format(winStr, sizeof(winStr), "%s held the crown for 2 minutes and earned $%d!", kingName, WIN_PRIZE);
            
            SendClientMessageToAll(0x00FF00FF, winStr);
            GivePlayerMoney(CrownCarrier, WIN_PRIZE);

            ResetKOTHMatch(); 
            return 1;
        }

        if(CrownCarrier != INVALID_PLAYER_ID) {
            BoxSpawnTimer++;
            if(BoxSpawnTimer >= 30) {
                if(MysteryBoxPickup != -1) 
                
                DestroyPickup(MysteryBoxPickup); // Remove old one
                MysteryBoxPickup = -1;

                new rand = random(sizeof(BoxSpawns));
                MysteryBoxPickup = CreatePickup(3016, 1, BoxSpawns[rand][0], BoxSpawns[rand][1], BoxSpawns[rand][2], VIRTUAL_WORLD);

                for (new i = 0; i < MAX_PLAYERS; i++) {
                    if (IsPlayerConnected(i)) {
                        SetPlayerMapIcon(i, MYSTERY_BOX_ICON_ID, BoxSpawns[rand][0], BoxSpawns[rand][1], BoxSpawns[rand][2], 0, 0xFFFF00FF, MAPICON_LOCAL);
                    }
                }

                SendClientMessageToAll(COLOR_CYAN, "A Mystery Box has spawned somewhere in the mansion!");
                BoxSpawnTimer = 0;
            }
        }   
    }

    // 4. Update the UI for everyone
    for(new i = 0; i < MAX_PLAYERS; i++)
    {
        if(!IsPlayerConnected(i)) continue;



        if(CrownCarrier == INVALID_PLAYER_ID) 
        {
            // Show their saved progress even when no one has the crown and show no current king
            format(str, sizeof(str), "King: ~r~None~n~~w~You: ~y~%02d:%02d", CarrierPoints[i] / 60, CarrierPoints[i] % 60);
        }
        else if(CrownCarrier == i) 
        {
            // The King sees their own ticking progress
            format(str, sizeof(str), "~y~YOU ARE KING!~n~~w~%02d:%02d / %02d:%02d", CarrierPoints[i] / 60, CarrierPoints[i] % 60, WIN_TIME / 60, WIN_TIME % 60);
        }
        else 
        {
            // Others see the King's name and their OWN personal progress
            GetPlayerName(CrownCarrier, kingName, sizeof(kingName));

            format(str, sizeof(str), "King: ~r~%s~n~~w~King's Time: %02d:%02d ~n~~w~You: %02d:%02d", 
                kingName, CarrierPoints[CrownCarrier] / 60, CarrierPoints[CrownCarrier] % 60, CarrierPoints[i] / 60, CarrierPoints[i] % 60);

        }
        PlayerTextDrawSetString(i, KOTH_UI[i], str);
    }
    return 1;
}

forward ResetKOTHMatch();
public ResetKOTHMatch()
{


    CreateWeaponPickupsForAll(); 

    DestroyPickup(CrownObject);
    Delete3DTextLabel(CrownLabel);

    CrownObject = -1;

    DestroyPickup(MysteryBoxPickup);

    MysteryBoxPickup = -1;

    new b = random(sizeof(CrownSpawns)); // Pick a random crown location
    CrownObject = CreatePickup(OBJECTIVE_MODEL, 1, CrownSpawns[b][0], CrownSpawns[b][1], CrownSpawns[b][2], VIRTUAL_WORLD);
    CrownLabel = Create3DTextLabel("CROWN\n{FFFFFF}Claim it!", COLOR_GOLD, CrownSpawns[b][0], CrownSpawns[b][1], CrownSpawns[b][2] + 0.5, 20.0, 0);

    UpdateCrownBlip(CrownSpawns[b][0], CrownSpawns[b][1], CrownSpawns[b][2], true);
    // Handle the Players
    for(new i = 0; i < MAX_PLAYERS; i++)
    {
        if(!IsPlayerConnected(i)) continue;

        // Reset everyones timer.
        CarrierPoints[i] = 0;

        // Remove crown object if they were the king
        RemovePlayerAttachedObject(i, 0);
        
        // Randomize their spawn point
        new p = random(sizeof(PlayerSpawns));
        SetPlayerPos(i, PlayerSpawns[p][0], PlayerSpawns[p][1], PlayerSpawns[p][2]);
        SetPlayerInterior(i, KOTH_INTERIOR);

        RemovePlayerMapIcon(i, MYSTERY_BOX_ICON_ID); // Mystery Box Slot

        SetPlayerVirtualWorld(i, 1); 
        SetPlayerVirtualWorld(i, VIRTUAL_WORLD); // Reset their virtual world to prevent ghost pickups and other weirdness
        
        // Let them know
        GameTextForPlayer(i, "~y~NEW ROUND STARTED!", 3000, 3);
    }
    
    CrownCarrier = INVALID_PLAYER_ID; // Clear the carrier last
    
    RoundNumber++;

    if (RoundNumber >= 4) {
        SendClientMessageToAll(COLOR_CYAN, "3 rounds complete. Switching to a new map.");
        SendRconCommand("gmx");
 
        return 1;
    }
    return 1;
}

forward UpdateCrownBlip(Float:x, Float:y, Float:z, bool:show);
public UpdateCrownBlip(Float:x, Float:y, Float:z, bool:show)
{
    for(new i = 0; i < MAX_PLAYERS; i++)
    {
        if(!IsPlayerConnected(i)) continue;
        
        if(show)
        {
            // SetPlayerMapIcon(playerid, iconid, x, y, z, markertype, color, style)
            // Color 0x00FF00FF is solid Green.
            SetPlayerMapIcon(i, CROWN_ICON_ID, x, y, z, ICON_TYPE, 0x00FF00FF, MAPICON_LOCAL);
        }
        else
        {
            RemovePlayerMapIcon(i, CROWN_ICON_ID);
        }
    }
    return 1;
}

forward ResetKingAnim(playerid);
public ResetKingAnim(playerid) { ClearAnimations(playerid); return 1; }

forward ResetKingDrunk(playerid);
public ResetKingDrunk(playerid) { 
    IsKingDrunk[playerid] = false; 
    SetPlayerDrunkLevel(playerid, 0); 
    ClearAnimations(playerid); 
    return 1; 
}

forward RestoreKingBlip(playerid);
public RestoreKingBlip(playerid) { 
    SetPlayerColor(playerid, 0xFF0000FF); // Red for King
    return 1; 
}

forward HellfireFinalBlow(playerid, objectid);
public HellfireFinalBlow(playerid, objectid)
{
    if(IsPlayerConnected(playerid))
    {
        SetPlayerHealth(playerid, 0.0);
        ClearAnimations(playerid);
    }

    if(IsValidObject(objectid)) {
        DestroyObject(objectid);
    }
    return 1;
}


forward PlaySoundForAllPlayers(soundid);
public PlaySoundForAllPlayers(soundid) {
    PlaySoundForAll(soundid, 0.0, 0.0, 1.0);
    return 1;
}

forward CreateWeaponPickupsForAll();
public CreateWeaponPickupsForAll() {

    for(new i = 0; i < sizeof(WeaponPool); i++) {
        if(WeaponPool[i] != -1) {
            DestroyPickup(WeaponPool[i]);
            WeaponPool[i] = -1;
        }
    }

    for(new j = 0; j < sizeof(WeaponSpawns); j++) 
        {
            new pickuporweapon = random(10);

            if (pickuporweapon < 7) {
                new rand = random(sizeof(Pickups) - 2);
                WeaponPool[j] = CreatePickup(
                    Pickups[rand], 
                    3, 
                    WeaponSpawns[j][0], 
                    WeaponSpawns[j][1], 
                    WeaponSpawns[j][2], 
                    VIRTUAL_WORLD
                );
                
            } else {
                new pickupType;
                new rand = random(1);
                if (rand == 0) {pickupType = HEALTH_PICKUP;} else {pickupType = ARMOUR_PICKUP;}
                WeaponPool[j] = CreatePickup(
                    pickupType, 
                    3, 
                    WeaponSpawns[j][0], 
                    WeaponSpawns[j][1], 
                    WeaponSpawns[j][2], 
                    VIRTUAL_WORLD
                );                
            }
        }
    return 1;
}

forward InitializeTextDraw();
public InitializeTextDraw() {
    // Leaderboard draws
    LeaderboardBG = TextDrawCreate(150.0, 120.0, "");
    TextDrawLetterSize(LeaderboardBG, 0.0, 25.0); 
    TextDrawUseBox(LeaderboardBG, 1);
    TextDrawBoxColor(LeaderboardBG, 0x000000DD); 
    TextDrawTextSize(LeaderboardBG, 490.0, 0.0);

  
    LeaderboardTitle = TextDrawCreate(320.0, 100.0, "Leaderboard");
    TextDrawAlignment(LeaderboardTitle, 2);
    TextDrawFont(LeaderboardTitle, 0); 
    TextDrawLetterSize(LeaderboardTitle, 1.6, 3.5);
    TextDrawColor(LeaderboardTitle, 0xFFFFFFFF);
}

forward DrawTextDraws(playerid);
public DrawTextDraws(playerid) {
    
    LeaderboardData[playerid] = CreatePlayerTextDraw(playerid, 160.0, 150.0, " ");
    PlayerTextDrawAlignment(playerid, LeaderboardData[playerid], 1); 
    PlayerTextDrawFont(playerid, LeaderboardData[playerid], 2)

    LeaderboardTimeData[playerid] = CreatePlayerTextDraw(playerid, 450.0, 150.0, " "); 
    PlayerTextDrawAlignment(playerid, LeaderboardTimeData[playerid], 3);
    PlayerTextDrawFont(playerid, LeaderboardTimeData[playerid], 2)

    // Create the TextDraw on the right side of the screen
    KOTH_UI[playerid] = CreatePlayerTextDraw(playerid, 495.0, 120.0, " ");
    PlayerTextDrawLetterSize(playerid, KOTH_UI[playerid], 0.4, 1.6);
    PlayerTextDrawAlignment(playerid, KOTH_UI[playerid], 1);
    PlayerTextDrawColor(playerid, KOTH_UI[playerid], -1);
    PlayerTextDrawSetShadow(playerid, KOTH_UI[playerid], 1);
    PlayerTextDrawSetOutline(playerid, KOTH_UI[playerid], 0);
    PlayerTextDrawBackgroundColor(playerid, KOTH_UI[playerid], 150);
    PlayerTextDrawFont(playerid, KOTH_UI[playerid], 1);
    PlayerTextDrawSetProportional(playerid, KOTH_UI[playerid], 1);
}

forward DrawLeaderboard(playerid, newkeys, oldkeys);
public DrawLeaderboard(playerid, newkeys, oldkeys) {
    if (newkeys & KEY_SCOREBOARD)
    {
        new nameStr[512], timeStr[512], name[MAX_PLAYER_NAME], crownTime;
        
        format(nameStr, sizeof(nameStr), "PLAYER~n~");
        format(timeStr, sizeof(timeStr), "TIME~n~");
        
        for(new i = 0; i < MAX_PLAYERS; i++)
        {
            if(!IsPlayerConnected(i)) continue;
            GetPlayerName(i, name, sizeof(name));
            crownTime = CarrierPoints[i]; 
            
            // Add the name to the Name String
            format(nameStr, sizeof(nameStr), "%s~n~%s", nameStr, name);
            
            // Add the time to the Time String
            format(timeStr, sizeof(timeStr), "%s~n~%02d:%02d", timeStr, crownTime / 60, crownTime % 60);
        }
        
        PlayerTextDrawSetString(playerid, LeaderboardData[playerid], nameStr);
        PlayerTextDrawSetString(playerid, LeaderboardTimeData[playerid], timeStr);
        PlayerTextDrawAlignment(playerid, LeaderboardTimeData[playerid], 2);

        // Show everything
        TextDrawShowForPlayer(playerid, LeaderboardBG);
        TextDrawShowForPlayer(playerid, LeaderboardTitle);
        PlayerTextDrawShow(playerid, LeaderboardData[playerid]);
        PlayerTextDrawShow(playerid, LeaderboardTimeData[playerid]);
    }
    
    if (oldkeys & KEY_SCOREBOARD)
    {
        TextDrawHideForPlayer(playerid, LeaderboardBG);
        TextDrawHideForPlayer(playerid, LeaderboardTitle);
        PlayerTextDrawHide(playerid, LeaderboardData[playerid]);
        PlayerTextDrawHide(playerid, LeaderboardTimeData[playerid]);
    }
}

forward UpdateLeaderboard();
public UpdateLeaderboard()
{
    new string[1024], name[MAX_PLAYER_NAME], crownTime;
    

    format(string, sizeof(string), "Player                                 Time Spent with the Crown~n~");
    for(new i = 0; i < MAX_PLAYERS; i++)
    {
        if(!IsPlayerConnected(i)) continue;
        GetPlayerName(i, name, sizeof(name));
        crownTime = CarrierPoints[i]; 
        
        format(string, sizeof(string), "%s~n~%-20s                                 %02d:%02d", 
            string, name, crownTime / 60, crownTime % 60);
    }

    return 1;
}
// SHOP
CMD:shop(playerid, params[])
{

    ShowPlayerDialog(playerid, DIALOG_SHOP, DIALOG_STYLE_LIST, 
        "{FFD700}The Shop of Kings", 
        "Heat-Seeking RPG (10 rounds) - $25,000\n\
        RPG (10 rounds) - $25,000\n\
        Minigun (500 rounds) - $150,000\n\
        Nightvision Goggles - $5000\n\ 
        Thermal Vision Goggles - $5000", 
        "Buy", "Cancel");
    return 1;
}
CMD:help(playerid, params[]) {
    GameTextForPlayer(playerid, "Capture and hold the 'crown' for 2 minutes to win!~n~~w~Use /shop to buy power-ups.", 10000, 4);
    return 1;
}

stock GetRandomColor()
{
    new r, g, b, color;
    new bool:isBadColor = true;

    while(isBadColor)
    {
        r = random(256);
        g = random(256);
        b = random(256);

        // --- excluding pure reds yellows and greens to avoid confusion on the radar ---
        // Exclude Red (High R, Low G & B)
        if (r > 220 && g < 50 && b < 50) continue;
        
        // Exclude Green (Low R & B, High G)
        if (g > 220 && r < 50 && b < 50) continue;
        
        // Exclude Yellow (High R & G, Low B)
        if (r > 220 && g > 200 && b < 50) continue;

        // If it passed the checks, break the loop
        isBadColor = false;
    }

    color = (r << 24) | (g << 16) | (b << 8) | 0xFF;
    return color;
}