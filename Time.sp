// Copyright (C) 2023 Katsute | Licensed under CC BY-NC-SA 4.0

#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

#define TF_RED 2
#define TF_BLU 3

int setup;
int max;

int cp5;
int mode;
int team;

int add;
int set;

ConVar setupCV;
ConVar maxCV;

ConVar cp5CV;
ConVar modeCV;
ConVar teamCV;

ConVar addCV;
ConVar setCV;

public Plugin myinfo = {
    name        = "Round Time",
    author      = "Katsute",
    description = "Set maximum round time, remove bonus round time restrictions, and modify how time changes on captures",
    version     = "1.0",
    url         = "https://github.com/KatsuteTF/Round-Time"
}

public void OnPluginStart(){
    setupCV = CreateConVar("sm_time_setup", "30", "Setup time in seconds, -1 to use default");
    setupCV.AddChangeHook(OnConvarChanged);

    setup = setupCV.IntValue;

    maxCV = CreateConVar("sm_time_max", "600", "Maximum round time in seconds, -1 to use default");
    maxCV.AddChangeHook(OnConvarChanged);

    max = maxCV.IntValue;

    cp5CV = CreateConVar("sm_time_5cp", "0", "If map is a 5 control point map");
    cp5CV.AddChangeHook(OnConvarChanged);

    cp5 = cp5CV.IntValue;

    modeCV = CreateConVar("sm_time_mode", "0", "How to handle time on capture, 0 = default, 1 = add time, 2 = set time");
    modeCV.AddChangeHook(OnConvarChanged);

    mode = modeCV.IntValue;

    teamCV = CreateConVar("sm_time_team", "0", "Which team to add or set time to, 0 = both, 1 = capturing team, 2 = other team");
    teamCV.AddChangeHook(OnConvarChanged);

    team = teamCV.IntValue;

    addCV = CreateConVar("sm_time_add", "60", "Seconds to add on point capture");
    addCV.AddChangeHook(OnConvarChanged);

    add = addCV.IntValue;

    setCV = CreateConVar("sm_time_set", "300", "Seconds to set on point capture");
    setCV.AddChangeHook(OnConvarChanged);

    set = setCV.IntValue;

    RegAdminCmd("sm_addtime", OnAddTime, ADMFLAG_CHANGEMAP, "sm_addtime <seconds> <team?, 0 = all, 1 = RED, 2 = BLU>");
    RegAdminCmd("sm_settime", OnSetTime, ADMFLAG_CHANGEMAP, "sm_settime <seconds> <team?, 0 = all, 1 = RED, 2 = BLU>");

    SetConVarBounds(FindConVar("mp_bonusroundtime"), ConVarBound_Lower, true, 0.0);
    SetConVarBounds(FindConVar("mp_bonusroundtime"), ConVarBound_Upper, false);

    HookEvent("teamplay_round_start", OnStart);

    HookEvent("teamplay_point_captured", OnCaptured);
    HookEvent("teamplay_timer_time_added", OnTimeAdded);
}

public void OnConvarChanged(const ConVar convar, const char[] oldValue, const char[] newValue){
    if(convar == setupCV){
        setup = StringToInt(newValue);
        if(setup != -1)
            SetSetupRoundTime(setup);
    }else if(convar == maxCV){
        max = StringToInt(newValue);
        if(max != -1)
            SetMaxRoundTime(max);
    }else if(convar == cp5CV)
        cp5 = StringToInt(newValue);
    else if(convar == modeCV)
        mode = StringToInt(newValue);
    else if(convar == teamCV)
        team = StringToInt(newValue);
    else if(convar == addCV)
        add = StringToInt(newValue);
    else if(convar == setCV)
        set = StringToInt(newValue);
}

public void OnStart(const Event event, const char[] name, const bool dontBroadcast){
    if(setup != -1)
        SetSetupRoundTime(setup);
    if(max != -1){
        SetMaxRoundTime(max);
        SetTeamRoundTime(TF_RED, max);
        SetTeamRoundTime(TF_BLU, max);
    }
}

public void OnCaptured(const Event event, const char[] name, const bool dontBroadcast){
    int capture = event.GetInt("team");
    int other   = capture == TF_RED ? TF_BLU : TF_RED;

    if(!cp5){
        switch(mode){
            case 1: {
                switch(team){
                    case 0: {
                        AddRoundTime(add);
                    }
                    case 1: {
                        AddTeamRoundTime(capture, add);
                    }
                    case 2: {
                        AddTeamRoundTime(other, add);
                    }
                }
            }
            case 2: {
                switch(team){
                    case 0: {
                        SetRoundTime(set);
                    }
                    case 1: {
                        SetTeamRoundTime(capture, set);
                    }
                    case 2: {
                        SetTeamRoundTime(other, set);
                    }
                }
            }
        }
    }else if(mode == 2)
        CreateTimer(0.1, OnTimeAddedDeferred);
}

public int min(const int x, const int y){
    return x < y ? x : y;
}

public void OnTimeAdded(const Event event, const char[] name, const bool dontBroadcast){
    if(cp5 && mode == 1){
        int remove = min(0, add - event.GetInt("seconds_added"));
        if(remove < 0)
            CreateTimer(0.1, OnTimeAddedDeferred, remove);
    }
}

public Action OnTimeAddedDeferred(const Handle timer, const int time){
    switch(mode){
        case 1: {
            AddRoundTime(time);
        }
        case 2: {
            SetRoundTime(set);
        }
    }
    return Plugin_Handled;
}

public Action OnAddTime(const int client, const int args){
    char map[64];
    GetCurrentMap(map, sizeof(map));
    bool pl = strncmp(map, "pl_", 3) == 0;

    switch(args){
        case 0: {
            ReplyToCommand(client, "[SM] Usage: sm_addtime <seconds> <team?, 0 = all, 1 = RED, 2 = BLU>");
        }
        case 1: {
            char arg1[32];
            GetCmdArg(1, arg1, sizeof(arg1));
            int time = StringToInt(arg1);

            if(pl){
                int ent = -1;
                while((ent = FindEntityByClassname(ent, "team_round_timer")) != -1)
                    AddTeamTime(ent, time);
            }else{
                AddRoundTime(time);
            }
        }
        case 2: {
            char arg1[32];
            GetCmdArg(1, arg1, sizeof(arg1));
            int time = StringToInt(arg1);

            char arg2[32];
            GetCmdArg(2, arg2, sizeof(arg2));
            int tm = StringToInt(arg2);

            if(!pl){
                switch(tm){
                    case 0: {
                        AddRoundTime(time);
                    }
                    case 1: {
                        AddTeamRoundTime(TF_RED, time);
                    }
                    case 2: {
                        AddTeamRoundTime(TF_BLU, time);
                    }
                }
            }
        }
    }
    return Plugin_Handled;
}

public Action OnSetTime(const int client, const int args){
    switch(args){
        case 0: {
            ReplyToCommand(client, "[SM] Usage: sm_settime <seconds> <team?, 0 = all, 1 = RED, 2 = BLU>");
        }
        case 1: {
            char arg1[32];
            GetCmdArg(1, arg1, sizeof(arg1));
            int time = StringToInt(arg1);

            SetRoundTime(time);
        }
        case 2: {
            char arg1[32];
            GetCmdArg(1, arg1, sizeof(arg1));
            int time = StringToInt(arg1);

            char arg2[32];
            GetCmdArg(2, arg2, sizeof(arg2));
            int tm = StringToInt(arg2);

            switch(tm){
                case 0: {
                    SetRoundTime(time);
                }
                case 1: {
                    SetTeamRoundTime(TF_RED, time);
                }
                case 2: {
                    SetTeamRoundTime(TF_BLU, time);
                }
            }
        }
    }
    return Plugin_Handled;
}

//

public void AddTime(const int ent, const int seconds){
    SetVariantInt(seconds);
    AcceptEntityInput(ent, "AddTime");
}

public void AddTeamTime(const int ent, const int seconds){
    char buf[32];
    Format(buf, sizeof(buf), "0 %i", seconds);
    SetVariantString(buf);
    AcceptEntityInput(ent, "AddTeamTime");
}

public void SetTime(const int ent, const int seconds){
    SetVariantInt(seconds);
    AcceptEntityInput(ent, "SetTime");
}

public void SetSetupTime(const int ent, const int seconds){
    SetVariantInt(seconds);
    AcceptEntityInput(ent, "SetSetupTime");
}

public void SetMaxTime(const int ent, const int seconds){
    SetVariantInt(seconds);
    AcceptEntityInput(ent, "SetMaxTime");
}

//

public void AddRoundTime(const int seconds){
    int ent = -1;
    while((ent = FindEntityByClassname(ent, "team_round_timer")) != -1)
        AddTime(ent, seconds);
}

public void SetRoundTime(const int seconds){
    int ent = -1;
    while((ent = FindEntityByClassname(ent, "team_round_timer")) != -1)
        SetTime(ent, seconds);
}

//

public void SetSetupRoundTime(const int seconds){
    int ent = -1;
    while((ent = FindEntityByClassname(ent, "team_round_timer")) != -1)
        SetSetupTime(ent, seconds);
}

public void SetMaxRoundTime(const int seconds){
    int ent = -1;
    while((ent = FindEntityByClassname(ent, "team_round_timer")) != -1)
        SetMaxTime(ent, seconds);
}

//

public void AddTeamRoundTime(const int tm, const int seconds){
    int ent = GetTeamRoundTimer(tm);
    if(ent != -1)
        AddTime(ent, seconds);
}

public void SetTeamRoundTime(const int tm, const int seconds){
    int ent = GetTeamRoundTimer(tm);
    if(ent != -1)
        SetTime(ent, seconds);
}

public int GetTeamRoundTimer(const int tm){
    int ent = -1;
    while((ent = FindEntityByClassname(ent, "team_round_timer")) != -1){
        char name[32];
        GetEntPropString(ent, Prop_Data, "m_iName", name, sizeof(name));

        if(tm == TF_RED && strcmp("zz_red_koth_timer", name) == 0)
            return ent;
        else if(tm == TF_BLU && strcmp("zz_blue_koth_timer", name) == 0)
            return ent;
    }
    return -1;
}