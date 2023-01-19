/*
*	Saferoom Door Closed Announce
*	Copyright (C) 2022 kahdeg
*
*	This program is free software: you can redistribute it and/or modify
*	it under the terms of the GNU General Public License as published by
*	the Free Software Foundation, either version 3 of the License, or
*	(at your option) any later version.
*
*	This program is distributed in the hope that it will be useful,
*	but WITHOUT ANY WARRANTY; without even the implied warranty of
*	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
*	GNU General Public License for more details.
*
*	You should have received a copy of the GNU General Public License
*	along with this program.  If not, see <https://www.gnu.org/licenses/>.
*/

#define PLUGIN_VERSION		"1.27"

/*=======================================================================================
	Plugin Info:

*	Name	:	[L4D2] Saferoom Door Close Announce
*	Author	:	kahdeg
*	Descrp	:	Announce who closed the safe door.
*	Link	:	
*	Plugins	:	

========================================================================================
	Change Log:

1.0 (30-Aug-2013)
	- Initial creation.

======================================================================================*/

#pragma newdecls required
#pragma semicolon 1

#include <sourcemod>
#include <sdkhooks>
#include <sdktools>
#include <left4dhooks>

#define CVAR_FLAGS				FCVAR_NOTIFY

ConVar g_hCvarAllow;
bool g_bCvarAllow;

// ====================================================================================================
//					PLUGIN INFO / START
// ====================================================================================================
public Plugin myinfo =
{
	name = "[L4D2] Saferoom Door Close Announce",
	author = "kahdeg",
	description = "Announce who closed the safe door.",
	version = PLUGIN_VERSION,
	url = ""
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	EngineVersion test = GetEngineVersion();
	if( test != Engine_Left4Dead2 )
	{
		strcopy(error, err_max, "Plugin only supports Left 4 Dead 2.");
		return APLRes_SilentFailure;
	}

	return APLRes_Success;
}

public void OnAllPluginsLoaded()
{
	ConVar version = FindConVar("left4dhooks_version");
	if( version != null )
	{
		char sVer[8];
		version.GetString(sVer, sizeof(sVer));

		float ver = StringToFloat(sVer);
		if( ver >= 1.101 )
		{
			return;
		}
	}

	SetFailState("\n==========\nThis plugin requires \"Left 4 DHooks Direct\" version 1.01 or newer. Please update:\nhttps://forums.alliedmods.net/showthread.php?t=321696\n==========");
}

// ==================================================
// 					PLUGIN START
// ==================================================
public void OnPluginStart()
{
	g_hCvarAllow =		CreateConVar(	"l4d2_safedoor_announce_enable",			"1",			"0=Plugin off, 1=Plugin on.", CVAR_FLAGS);

	CreateConVar(						"l4d2_safedoor_announce_version",		PLUGIN_VERSION,	"Saferoom Door Spam Protection plugin version",	FCVAR_NOTIFY|FCVAR_DONTRECORD);
	AutoExecConfig(true, "l4d2_safedoor_announce");

	g_hCvarAllow.AddChangeHook(ConVarChanged_Allow);
}

// ====================================================================================================
//					CVARS
// ====================================================================================================
public void OnConfigsExecuted()
{
	IsAllowed();
}

void ConVarChanged_Allow(Handle convar, const char[] oldValue, const char[] newValue)
{
	IsAllowed();
}

void IsAllowed()
{
	bool bAllow = GetConVarBool(g_hCvarAllow);
	
	if( g_bCvarAllow == false && bAllow == true  )
	{
		g_bCvarAllow = true;
		HookEvents(true);
	}
	else if( g_bCvarAllow == true && bAllow == false )
	{
		g_bCvarAllow = false;
		HookEvents(false);
	}
}

void HookEvents(bool hook)
{
	if( hook )
	{
		HookEvent("door_close",			Event_DoorClose);
	}
	else
	{
		UnhookEvent("door_close",		Event_DoorClose);
	}
}

void Event_DoorClose(Event event, const char[] name, bool dontBroadcast)
{
	if( event.GetBool("checkpoint") )
	{
		int client = GetClientOfUserId(event.GetInt("userid"));
		if( client )
		{
			for( int i = 1; i <= MaxClients; i++ )
			{
				if( IsClientInGame(i) && !IsFakeClient(i) )
				{
					CPrintToChat(i, "{orange}%N {white}closed the door", i, client);
				}
			}
		}
	}
}

void CPrintToChat(int client, char[] message, any ...)
{
	static char buffer[256];
	VFormat(buffer, sizeof(buffer), message, 3);

	ReplaceString(buffer, sizeof(buffer), "{default}",		"\x01");
	ReplaceString(buffer, sizeof(buffer), "{white}",		"\x01");
	ReplaceString(buffer, sizeof(buffer), "{cyan}",			"\x03");
	ReplaceString(buffer, sizeof(buffer), "{lightgreen}",	"\x03");
	ReplaceString(buffer, sizeof(buffer), "{orange}",		"\x04");
	ReplaceString(buffer, sizeof(buffer), "{green}",		"\x04"); // Actually orange in L4D2, but replicating colors.inc behaviour
	ReplaceString(buffer, sizeof(buffer), "{olive}",		"\x05");
	PrintToChat(client, buffer);
}