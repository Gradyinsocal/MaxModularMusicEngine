///////////////////////////////////////////////////////////////
//
// Max Modular UUID Music Engine
// Version 1.0
// Build 2.1 (Stability Release)
//
// File: 02_MainEngine.lsl
//
// PURPOSE
///////////////////////////////////////////////////////////////
//
// MMME - Max Modular Music Engine
//
// File: 02_MainEngine.lsl
// Version: 1.01
// Build: 3B.2 Stability Fix
//
///////////////////////////////////////////////////////////////

integer API_DB_REQUEST = 2000;
integer API_DB_REPLY   = 2001;
integer API_DB_READY   = 2002;

integer API_ENGINE_PLAY   = 2100;
integer API_ENGINE_STOP   = 2101;
integer API_ENGINE_PAUSE  = 2102;
integer API_ENGINE_RESUME = 2103;

integer API_IF_STATE      = 3000;
integer API_IF_NOWPLAYING = 3001;

integer STATE_STOPPED = 0;
integer STATE_PLAYING = 1;
integer STATE_PAUSED  = 2;

integer DEBUG = TRUE;

integer gState = STATE_STOPPED;
integer gDatabaseReady = FALSE;
integer gSongLoaded = FALSE;

string gTitle = "";
string gArtist = "";

float gVolume = 1.0;
float gClipLength = 10.0;

list gClips = [];
integer gCurrentClip = 0;

Debug(string text)
{
    if(DEBUG)
        llOwnerSay("[MMME-PLAY] " + text);
}

NotifyState()
{
    llMessageLinked(
        LINK_SET,
        API_IF_STATE,
        (string)gState,
        NULL_KEY);
}

NotifyNowPlaying()
{
    llMessageLinked(
        LINK_SET,
        API_IF_NOWPLAYING,
        gTitle + "|" + gArtist,
        NULL_KEY);
}

ResetPlayback()
{
    llStopSound();
    llSetTimerEvent(0.0);
    gCurrentClip = 0;
}

integer IsValidAssetUUID(string value)
{
    value = llStringTrim(value, STRING_TRIM);

    if(value == "")
        return FALSE;

    if(llStringLength(value) != 36)
        return FALSE;

    if((key)value == NULL_KEY)
        return FALSE;

    return TRUE;
}

LoadSongPacket(string packet)
{
    // The shared reply channel also carries SONG_LIST,
    // SONG_COUNT and LIBRARY_INFO. Only SONG packets belong here.
    if(llSubStringIndex(packet, "SONG|") != 0)
        return;

    list fields = llParseStringKeepNulls(packet, ["|"], []);

    if(llGetListLength(fields) < 6)
    {
        Debug("Invalid SONG packet.");
        return;
    }

    gTitle  = llStringTrim(llList2String(fields, 2), STRING_TRIM);
    gArtist = llStringTrim(llList2String(fields, 3), STRING_TRIM);
    gVolume = (float)llStringTrim(
        llList2String(fields, 4),
        STRING_TRIM);

    list cleanClips = [];
    integer i;

    for(i = 5; i < llGetListLength(fields); ++i)
    {
        string clip =
            llStringTrim(
                llList2String(fields, i),
                STRING_TRIM);

        if(IsValidAssetUUID(clip))
        {
            cleanClips += [clip];
        }
        else
        {
            Debug(
                "Skipped invalid clip entry in "
                + gTitle
                + ": "
                + clip);
        }
    }

    if(llGetListLength(cleanClips) == 0)
    {
        gSongLoaded = FALSE;
        gClips = [];
        Debug("No valid sound UUIDs found for " + gTitle + ".");
        return;
    }

    gClips = cleanClips;
    gCurrentClip = 0;
    gSongLoaded = TRUE;

    NotifyNowPlaying();

    Debug(
        "Loaded "
        + gTitle
        + " with "
        + (string)llGetListLength(gClips)
        + " clip(s).");
}

PlayCurrentClip()
{
    if(gCurrentClip >= llGetListLength(gClips))
    {
        ResetPlayback();
        gState = STATE_STOPPED;
        NotifyState();
        Debug("Song finished.");
        return;
    }

    string clipUUID = llList2String(gClips, gCurrentClip);

    if(!IsValidAssetUUID(clipUUID))
    {
        Debug("Skipped invalid clip at position " + (string)(gCurrentClip + 1) + ".");
        ++gCurrentClip;
        PlayCurrentClip();
        return;
    }

    llPlaySound((key)clipUUID, gVolume);

    ++gCurrentClip;
    llSetTimerEvent(gClipLength);
}

StartSong()
{
    if(!gDatabaseReady)
    {
        Debug("Library is not ready.");
        return;
    }

    if(!gSongLoaded)
    {
        Debug("No valid song is loaded.");
        return;
    }

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
    if(gState != STATE_PLAYING)
        return;

    llStopSound();
    llSetTimerEvent(0.0);

    if(gCurrentClip > 0)
        --gCurrentClip;

    gState = STATE_PAUSED;
    NotifyState();
}

ResumeSong()
{
    if(gState != STATE_PAUSED)
        return;

    gState = STATE_PLAYING;
    NotifyState();
    PlayCurrentClip();
}

default
{
    state_entry()
    {
        Debug("Version 1.01 Build 3B.2");
        NotifyState();
    }

    timer()
    {
        if(gState == STATE_PLAYING)
            PlayCurrentClip();
    }

    link_message(
        integer sender,
        integer num,
        string message,
        key id)
    {
        if(num == API_DB_READY)
        {
            gDatabaseReady = TRUE;
            Debug("Library ready.");

            llMessageLinked(
                LINK_SET,
                API_DB_REQUEST,
                "GET_SONG|1",
                NULL_KEY);

            return;
        }

        if(num == API_DB_REPLY)
        {
            LoadSongPacket(message);
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

    on_rez(integer start)
    {
        llResetScript();
    }
}

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
