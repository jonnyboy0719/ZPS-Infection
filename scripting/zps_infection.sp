/*
	STUFF THAT MAKES THIS WORK
*/
#pragma semicolon 1 
#include <sourcemod>
#include <sdktools>
// Don't have colors include file? get it here: http://forums.alliedmods.net/showthread.php?t=96831 (This version only works on 2007 Engine!!)
#include <colors>

/*
	DEFINES
*/
#define PLUGIN_VERSION "1.2"
#define PLUGIN_NAME "[ZPS] Infection Rate Changer"

// Cvars
new Handle:cvar_setinfection = INVALID_HANDLE,
	Handle:cvar_infectionrate_players = INVALID_HANDLE,
	Handle:InfectionChance = INVALID_HANDLE,
	GrabUsers = 0,
	SetInfectionRate = 0,
	Float:INFECTION_RATIO = 1.5;

/*
	Plugin:myinfo = {}
*/
public Plugin:myinfo = 
{
	name = PLUGIN_NAME,
	author = "JonnyBoy0719",
	description = "Change the infection rate in mid game, or with map configs",
	version = PLUGIN_VERSION,
	url = "http://reperio-studios.net/"
};

/*
	OnPluginStart()
*/
public OnPluginStart()
{
	// What game is this
	decl String:game_name[64];
	GetGameFolderName(game_name, sizeof(game_name));

	if (!StrEqual(game_name, "zps", false))
	{
		SetFailState("Plugin supports Zombie Panic! Source only.");
		return;
	}

	// Cvars
	CreateConVar("sm_infection_version", PLUGIN_VERSION, "Plugin version of Infection Rate Changer", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	cvar_setinfection = CreateConVar("sm_infection_set", "10", "Set infection percentage (higher ratio = easier for carrier to infect someone)", FCVAR_PLUGIN, true, 0.0, true, 100.0);
	cvar_infectionrate_players = CreateConVar("sm_infection_players", "0", "If enabled, it will scale the infection rate with how many players there is on the server.", FCVAR_PLUGIN, true, 0.0, true, 1.0);

	// Events
	HookEvent("player_connect", Event_PlayerConnect, EventHookMode_Pre);
	HookEvent("player_disconnect", Event_PlayerDisconnect, EventHookMode_Pre);

	// Chat Command
	RegConsoleCmd("infectionrate", Command_InfectionRate);
	RegConsoleCmd("infect", Command_InfectionRate);

	// Hooks
	HookConVarChange(cvar_setinfection, action_ConvarChanged);
	HookConVarChange(cvar_infectionrate_players, action_ConvarChanged_player);
}

/*
	Action:Command_InfectionRate
*/
public Action:Command_InfectionRate(client, args)
{
	if (client == 0)
	{
		return Plugin_Handled;
	}

	if (!IsClientInGame(client))
		return Plugin_Handled;
	
	InfectionRate(client);

	return Plugin_Handled;
}

/*
	InfectionRate
*/
stock InfectionRate(client)
{
	decl String:finalOutput[1024];
	finalOutput[0] = 0;
	
	if (cvar_setinfection != INVALID_HANDLE)
	{
		InfectionChance = FindConVar("infected_chance");
		new remaining = GetConVarInt(InfectionChance);

		if(remaining == 10)
			CPrintToChatAll("Infection Rate is currently on: {green}Default{default}");
		else
			CPrintToChatAll("Infection Rate is currently on: {green}%d{default}", remaining);
	}
}

/*
	Action:Event_PlayerConnect
*/
public Action:Event_PlayerConnect(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (GetConVarBool(cvar_infectionrate_players))
	{
		GrabUsers++;
		new Float:result = 10 + GrabUsers * INFECTION_RATIO;
		ServerCommand("sm_infection_set %d", RoundToNearest(result));
	}
}

/*
	Action:Event_PlayerDisconnect
*/
public Action:Event_PlayerDisconnect(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (GetConVarBool(cvar_infectionrate_players))
	{
		GrabUsers--;
		new Float:result = 10 + GrabUsers * INFECTION_RATIO;
		ServerCommand("sm_infection_set %d", RoundToNearest(result));
	}
}

/*
	action_ConvarChanged_player()
*/
public action_ConvarChanged_player(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if (GetConVarBool(cvar_infectionrate_players))
	{
		GrabUsers = 0;
		for (new i = 1; i < MaxClients; i++)
			if (IsClientInGame(i))
				GrabUsers++;
		
		new Float:result = 10 + GrabUsers * INFECTION_RATIO;
		ServerCommand("sm_infection_set %d", RoundToNearest(result));
		PrintToAll("{green}The Carrier{default} has grown stronger...");
	}
	else
	{
		ServerCommand("sm_infection_set %d", SetInfectionRate);
		PrintToAll("{green}The Carrier{default} has weakened...");
	}
}

/*
	action_ConvarChanged()
*/
public action_ConvarChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
	new flags = GetCommandFlags("infected_chance");
	SetCommandFlags("infected_chance", flags & ~FCVAR_CHEAT);
	ServerCommand("infected_chance %d", StringToInt(newValue));
	SetInfectionRate = StringToInt(newValue);
	
	CreateTimer(0.002, Reset_Back, 0);
}

/*
	Action:Reset_Back()
*/
public Action:Reset_Back(Handle:timer, any:client)
{
	new flags = GetCommandFlags("infected_chance");
	// Reset everything back to cheaty mode
	SetCommandFlags("infected_chance", flags|FCVAR_CHEAT);
	return Plugin_Stop;
}

/*
	PrintToAll()
*/
stock PrintToAll(const String:sMessage[])
{
	for (new i = 1; i <= MaxClients; i++)
		if (IsClientInGame(i))
			CPrintToChat(i, sMessage);
}