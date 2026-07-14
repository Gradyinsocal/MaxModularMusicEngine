///////////////////////////////////////////////////////////////
//
// Max Modular UUID Music Engine
// Version 1.0
// Build 2.1 (Stability Release)
//
// File: 02_MainEngine.lsl
//
// PURPOSE
//  * Own playback only
//  * Receive commands from Interface
//  * Receive songs from Database
//  * Notify Interface
//
// SHALL NOT
//  * Read notecards
//  * Display dialogs
//  * Change textures
//
///////////////////////////////////////////////////////////////

integer API_DB_REQUEST      = 2000;
integer API_DB_REPLY        = 2001;
integer API_DB_READY        = 2002;

integer API_ENGINE_PLAY     = 2100;
integer API_ENGINE_STOP     = 2101;
integer API_ENGINE_PAUSE    = 2102;
integer API_ENGINE_RESUME   = 2103;

integer API_IF_STATE        = 3000;
integer API_IF_NOWPLAYING   = 3001;

integer STATE_STOPPED = 0;
integer STATE_PLAYING = 1;
integer STATE_PAUSED  = 2;

integer gState = STATE_STOPPED;
integer gDatabaseReady = FALSE;
integer gSongLoaded = FALSE;

string gTitle = "";
string gArtist = "";
float  gVolume = 1.0;
float  gClipLength = 10.0;

list    gClips = [];
integer gCurrentClip = 0;

NotifyState()
{
    llMessageLinked(LINK_SET,API_IF_STATE,(string)gState,NULL_KEY);
}

NotifyNowPlaying()
{
    llMessageLinked(LINK_SET,
        API_IF_NOWPLAYING,
        gTitle + "|" + gArtist,
        NULL_KEY);
}

Debug(string s){ llOwnerSay("[MMME] "+s); }

ResetPlayback()
{
    llStopSound();
    llSetTimerEvent(0.0);
    gCurrentClip = 0;
}

LoadSongPacket(string packet)
{
    list p = llParseStringKeepNulls(packet,["|"],[]);
    if(llGetListLength(p) < 6)
    {
        Debug("Invalid song packet.");
        return;
    }

    gTitle  = llList2String(p,2);
    gArtist = llList2String(p,3);
    gVolume = (float)llList2String(p,4);

    gClips = llList2List(p,5,-1);
    gCurrentClip = 0;
    gSongLoaded = TRUE;

    NotifyNowPlaying();

    Debug("Loaded: "+gTitle+" - "+gArtist);
}

PlayCurrentClip()
{
    if(gCurrentClip >= llGetListLength(gClips))
    {
        ResetPlayback();
        gState = STATE_STOPPED;
        NotifyState();
        Debug("Song Finished");
        return;
    }

    llPlaySound(llList2String(gClips,gCurrentClip),gVolume);
    ++gCurrentClip;
    llSetTimerEvent(gClipLength);
}

StartSong()
{
    if(!gDatabaseReady)
    {
        Debug("Database not ready.");
        return;
    }

    if(!gSongLoaded)
    {
        Debug("No song loaded.");
        return;
    }

    // critical stability fix
    gCurrentClip = 0;

    gState = STATE_PLAYING;
    NotifyState();
    PlayCurrentClip();
}

StopSong()
{
    ResetPlayback();
    gState = STATE_STOPPED;
    NotifyState();
}

PauseSong()
{
    if(gState != STATE_PLAYING) return;

    llStopSound();
    llSetTimerEvent(0.0);

    // replay current clip on resume
    if(gCurrentClip > 0)
        --gCurrentClip;

    gState = STATE_PAUSED;
    NotifyState();
}

ResumeSong()
{
    if(gState != STATE_PAUSED) return;

    gState = STATE_PLAYING;
    NotifyState();
    PlayCurrentClip();
}

default
{
    state_entry()
    {
        Debug("Version 1.0 Build 2.1");
        NotifyState();
    }

    timer()
    {
        if(gState == STATE_PLAYING)
            PlayCurrentClip();
    }

    link_message(integer sender, integer num, string str, key id)
    {
        if(num == API_DB_READY)
        {
            gDatabaseReady = TRUE;
            Debug("Database Ready");
            llMessageLinked(LINK_SET,API_DB_REQUEST,"GET_SONG|1",NULL_KEY);
            return;
        }

        if(num == API_DB_REPLY)
        {
            LoadSongPacket(str);
            return;
        }

        if(num == API_ENGINE_PLAY)
        {
            StartSong();
            return;
        }

        if(num == API_ENGINE_STOP)
        {
            StopSong();
            return;
        }

        if(num == API_ENGINE_PAUSE)
        {
            PauseSong();
            return;
        }

        if(num == API_ENGINE_RESUME)
        {
            ResumeSong();
            return;
        }
    }
}
