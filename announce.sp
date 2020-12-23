#pragma semicolon 1

#define PLUGIN_AUTHOR "JustCrypticsuxj"
#define PLUGIN_VERSION "1.0.0"

#include <sourcemod>
#include <sdktools>
#include <cstrike>

#pragma newdecls required

public Plugin myinfo = 
{
	name = "Announce",
	author = PLUGIN_AUTHOR,
	description = "A way to annouce messages in chat with intervals, links can also be set in different colors...",
	version = PLUGIN_VERSION,
	url = ""
};


char[] getColor(char[] text, char[] color) 
{
	char colored_text[256];
	
	if (StrEqual(color, "gray", false)) 
	{
		Format(colored_text, sizeof(colored_text), " \x01%s", text);
	}
	else if (StrEqual(color, "red", false)) 
	{
		Format(colored_text, sizeof(colored_text), " \x02%s", text);
	}
	else if (StrEqual(color, "magenda", false)) 
	{
		Format(colored_text, sizeof(colored_text), " \x03%s", text);
	}
	else if (StrEqual(color, "limegreen", false)) 
	{
		Format(colored_text, sizeof(colored_text), " \x04%s", text);
	}
	else if (StrEqual(color, "darkgreen", false)) 
	{
		Format(colored_text, sizeof(colored_text), " \x05%s", text);
	}
	else if (StrEqual(color, "grassgreen", false)) 
	{
		Format(colored_text, sizeof(colored_text), " \x06%s", text);
	}
	else if (StrEqual(color, "darkred", false)) 
	{
		Format(colored_text, sizeof(colored_text), " \x07%s", text);
	}
	else if (StrEqual(color, "darkyellow", false)) 
	{
		Format(colored_text, sizeof(colored_text), " \x09%s", text);
	}
	else if (StrEqual(color, "darkblue", false)) 
	{
		Format(colored_text, sizeof(colored_text), " \x0C%s", text);
	}
	else if (StrEqual(color, "golden", false)) 
	{
		Format(colored_text, sizeof(colored_text), " \x10%s", text);
	}

	return colored_text;
}

void generateKeys(ArrayList &allMessages, ArrayList &allIntervals) 
{	
	// Use dataset as stack, store all timers then pop the top in order to start the next timer when current is done
	// When list is empty reset state of dataset in order to start over, do this none stop
	// ---------------------------------------------------------------------------------------------------------------
	// Could also just start every timer once and continuesly loop them with the timer flag TIMER_REPEAT
	
	char basePath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, basePath, sizeof(basePath), "configs/messages.txt");
	
	KeyValues kv = new KeyValues("Messages");
	if(!kv.ImportFromFile(basePath))
	{
		SetFailState("Could not parse key values...");
		return;
	}

	if(!kv.JumpToKey("Arguments")) 
	{
		SetFailState("Could not find arguments section...");
		return;
	}
	
	if(!kv.GotoFirstSubKey()) 
	{
		SetFailState("Could not find section subkey...");
		return;
	}
	
	char key_section[128];
	
	char subkey_message[512];		
	char subkey_link[256];
	char subkey_color[128];
	
	int subkey_interval;
	 
	do 
	{
		kv.GetSectionName(key_section, sizeof(key_section));
		
		kv.GetString("message", subkey_message, sizeof(subkey_message));
		kv.GetString("link", subkey_link, sizeof(subkey_link));
		kv.GetString("color", subkey_color, sizeof(subkey_color));
		subkey_interval = kv.GetNum("interval");
	
		Format(subkey_message, sizeof(subkey_message), "%s %s", subkey_message, getColor(subkey_link, subkey_color));
		
		allMessages.PushString(subkey_message);
		allIntervals.Push(subkey_interval);
	} while (kv.GotoNextKey());
	
	delete kv;
}

void setTimer(ArrayList &allMessages, ArrayList &allIntervals, int messageIndex, int newIndex) 
{	
	if(messageIndex > allIntervals.Length - 1) 
	{
		messageIndex = 0;
	}	
	
	bool isdone;
	newIndex = 0;
	
	while(!isdone)
	{
		if(newIndex == messageIndex) 
		{
			char tempString[768];
			DataPack message = new DataPack();
			CreateDataTimer(float(allIntervals.Get(messageIndex)), broadcastTimerMessage, message);
			
			allMessages.GetString(messageIndex, tempString, sizeof(tempString));
			WritePackString(message, tempString);	
			
			isdone = true;
		}
		
		newIndex++;
	}
	messageIndex++;
	
	DataPack oldData = new DataPack();		
		
	CreateDataTimer(float(allIntervals.Get(messageIndex - 1)), awaitBroadcastTimerMessage, oldData);

	WritePackCell(oldData, allMessages);
	WritePackCell(oldData, allIntervals);
	WritePackCell(oldData, messageIndex);
	WritePackCell(oldData, newIndex);
}

public Action broadcastTimerMessage(Handle timer, DataPack messageData) 
{
	char message[768];
	messageData.Reset();
	
	ReadPackString(messageData, message, sizeof(message));
	PrintToChatAll("%s", message);
}

public Action awaitBroadcastTimerMessage(Handle timer, DataPack oldData) 
{
	oldData.Reset();
	
	ArrayList allMessages = ReadPackCell(oldData);
	ArrayList allIntervals = ReadPackCell(oldData);
	
	int messageIndex = ReadPackCell(oldData);
	int newIndex = ReadPackCell(oldData);
	
	setTimer(allMessages, allIntervals, messageIndex, newIndex);
}

public void OnPluginStart()
{	
	RegConsoleCmd("sm_discord", command_discord, "Discord server with link in chat...");
	RegConsoleCmd("sm_apply", command_apply_admin, "Apply for administrator form link...");
	
	ArrayList allMessages = new ArrayList(ByteCountToCells(512));
	ArrayList allIntervals = new ArrayList();
	
	generateKeys(allMessages, allIntervals);

	int messageIndex = 0;
	int newIndex = 0;
	
	setTimer(allMessages, allIntervals, messageIndex, newIndex);
}

public Action command_discord(int client, int args) 
{		
	PrintToChat(client, "Our discord - \x0Chttps://www.discord.io/peakcs");
	return Plugin_Handled;
}

public Action command_apply_admin(int client, int args) 
{	
	PrintToChat(client, "Want to apply for server admin? \x03https://bit.ly/3arjxFs");
	return Plugin_Handled;
}