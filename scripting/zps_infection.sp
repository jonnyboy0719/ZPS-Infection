/*
	STUFF THAT MAKES THIS WORK
*/
#pragma semicolon 1 
#include <sourcemod>
#include <sdktools>

/*
	DEFINES
*/
#define PLUGIN_VERSION "1.0"
#define PLUGIN_NAME "[ZPS] Infection Rate Changer"

// Cvars
new Handle:cvar_setinfection = INVALID_HANDLE;

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

	// Hooks
	HookConVarChange(cvar_setinfection, action_ConvarChanged);
}

/*
	action_ConvarChanged()
*/
public action_ConvarChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
	// Lets uncheat the convars, höhö :V
	if (convar == cvar_setinfection)
	{
		new flags = GetCommandFlags("infected_chance");
		SetCommandFlags("infected_chance", flags & ~FCVAR_CHEAT);
		ServerCommand("infected_chance %d", GetConVarInt(cvar_setinfection));
	}

	CreateTimer(1.0, Reset_Back, 0);
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