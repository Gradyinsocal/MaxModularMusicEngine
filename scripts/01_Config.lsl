
///////////////////////////////////////////////////////////////
//
// Max Modular UUID Music Engine
//
// File: 01_Config.lsl
// Version: 0.01
//
// Designed by Max Pitre
// Programming Assistance by OpenAI ChatGPT
//
///////////////////////////////////////////////////////////////

//-------------------------------------------------------------
// DEVELOPMENT
//-------------------------------------------------------------
integer DEV_MODE = TRUE;

//-------------------------------------------------------------
// API MESSAGE NUMBERS
// Keep these synchronized across all modules.
//-------------------------------------------------------------
integer API_DB_REQUEST   = 2000;
integer API_DB_REPLY     = 2001;
integer API_DB_READY     = 2002;

integer API_ENGINE_PLAY  = 2100;
integer API_ENGINE_STOP  = 2101;
integer API_ENGINE_PAUSE = 2102;
integer API_ENGINE_NEXT  = 2103;

//-------------------------------------------------------------
// PLAYBACK DEFAULTS
//-------------------------------------------------------------
float DEFAULT_VOLUME      = 1.0;
float DEFAULT_CLIP_LENGTH = 10.0;

//-------------------------------------------------------------
// DISPLAY
//-------------------------------------------------------------
integer STATUS_FACE = 0;

string TEXTURE_STOP  = "";
string TEXTURE_PLAY  = "";
string TEXTURE_PAUSE = "";

//-------------------------------------------------------------
// DATABASE
//-------------------------------------------------------------
string NOTECARD_PREFIX = "MMME_";
integer ALLOW_DUPLICATES = FALSE;

//-------------------------------------------------------------
// FUTURE OPTIONS
//-------------------------------------------------------------
integer ENABLE_DIAGNOSTICS = TRUE;
integer ENABLE_SEARCH      = TRUE;
integer ENABLE_PLAYLISTS   = TRUE;
integer ENABLE_VISUALIZER  = FALSE;

//-------------------------------------------------------------
// CONFIG PROVIDER
//-------------------------------------------------------------
// Future modules will request values by linked message.
// For now this script simply announces that it is ready.

default
{
    state_entry()
    {
        if (DEV_MODE)
        {
            llOwnerSay("[MMME-CONFIG] Version 0.01");
            llOwnerSay("[MMME-CONFIG] Ready");
        }

        llMessageLinked(
            LINK_SET,
            API_DB_READY,
            "CONFIG_READY",
            NULL_KEY
        );
    }

    link_message(integer sender, integer num, string str, key id)
    {
        // Reserved for future configuration requests.
    }
}
