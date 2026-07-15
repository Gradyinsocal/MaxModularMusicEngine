
///////////////////////////////////////////////////////////////
//
// MMME - Max Modular Music Engine
//
// File: 02_MainEngine.lsl
// Version: 1.01
// Build: 3B.3 Seamless Playback Preview
//
// PURPOSE
//
// • Play UUID sound clips consecutively
// • Preload upcoming sound UUIDs
// • Queue the next clip before the current clip ends
// • Preserve Play, Pause, Continue, and Stop
// • Ignore non-song Library replies
//
// IMPORTANT
//
// QUEUE_LEAD_TIME assumes clips are approximately 10 seconds.
// If your edited clips are consistently shorter or longer,
// adjust QUEUE_LEAD_TIME after in-world testing.
//
///////////////////////////////////////////////////////////////


//==============================================================
// LIBRARY API
//==============================================================

integer API_DB_REQUEST = 2000;
integer API_DB_REPLY   = 2001;
integer API_DB_READY   = 2002;


//==============================================================
// PLAYBACK API
//==============================================================

integer API_ENGINE_PLAY   = 2100;
integer API_ENGINE_STOP   = 2101;
integer API_ENGINE_PAUSE  = 2102;
integer API_ENGINE_RESUME = 2103;


//==============================================================
// INTERFACE API
//==============================================================

integer API_IF_STATE      = 3000;
integer API_IF_NOWPLAYING = 3001;


//==============================================================
// PLAYER STATES
//==============================================================

integer STATE_STOPPED = 0;
integer STATE_PLAYING = 1;
integer STATE_PAUSED  = 2;


//==============================================================
// PLAYBACK TIMING
//==============================================================

// Nominal duration of each uploaded clip.
float CLIP_LENGTH = 10.0;

// Queue the next clip this many seconds after the current
// clip begins. This gives the viewer time to receive the
// upcoming sound before the transition.
float QUEUE_LEAD_TIME = 8.75;

// After the final clip is queued, wait this long before
// reporting that the song has finished.
float FINAL_WAIT_TIME = 11.25;


//==============================================================
// ENGINE STATUS
//==============================================================

integer DEBUG = TRUE;

integer gState = STATE_STOPPED;
integer gDatabaseReady = FALSE;
integer gSongLoaded = FALSE;


//==============================================================
// SONG DATA
//==============================================================

string gTitle = "";
string gArtist = "";

float gVolume = 1.0;

list gClips = [];


//==============================================================
// PLAYBACK POSITION
//==============================================================

// Clip that began the current playback run.
integer gRunStartClip = 0;

// Next clip that has not yet been queued.
integer gNextClipToQueue = 0;

// TRUE after the first queue timer has fired.
integer gQueueStarted = FALSE;

// TRUE when every clip has already been submitted.
integer gWaitingForFinish = FALSE;

// Used to estimate which clip was playing when Pause is pressed.
float gRunStartTime = 0.0;


//==============================================================
// DEBUG
//==============================================================

Debug(string text)
{
    if(DEBUG)
        llOwnerSay("[MMME-PLAY] " + text);
}


//==============================================================
// INTERFACE NOTIFICATIONS
//==============================================================

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


//==============================================================
// UUID VALIDATION
//==============================================================

integer IsValidSoundUUID(string value)
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


//==============================================================
// SOUND QUEUE CONTROL
//==============================================================

FlushSoundQueue()
{
    // Disabling queueing before stopping prevents an already
    // queued clip from starting after Pause or Stop.
    llSetSoundQueueing(FALSE);
    llStopSound();
    llSetTimerEvent(0.0);
    llSetSoundQueueing(TRUE);
}


//==============================================================
// LIBRARY PACKET
//==============================================================

LoadSongPacket(string packet)
{
    // API_DB_REPLY also carries SONG_LIST, SONG_COUNT and
    // LIBRARY_INFO. Only SONG packets belong in this engine.
    if(llSubStringIndex(packet, "SONG|") != 0)
        return;

    list fields =
        llParseStringKeepNulls(
            packet,
            ["|"],
            []);

    if(llGetListLength(fields) < 6)
    {
        Debug("Invalid SONG packet.");
        return;
    }

    gTitle =
        llStringTrim(
            llList2String(fields, 2),
            STRING_TRIM);

    gArtist =
        llStringTrim(
            llList2String(fields, 3),
            STRING_TRIM);

    gVolume =
        (float)llStringTrim(
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

        if(IsValidSoundUUID(clip))
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
        gClips = [];
        gSongLoaded = FALSE;

        Debug(
            "No valid sound UUIDs found for "
            + gTitle
            + ".");

        return;
    }

    FlushSoundQueue();

    gClips = cleanClips;
    gSongLoaded = TRUE;

    gRunStartClip = 0;
    gNextClipToQueue = 0;
    gQueueStarted = FALSE;
    gWaitingForFinish = FALSE;

    NotifyNowPlaying();

    Debug(
        "Loaded "
        + gTitle
        + " with "
        + (string)llGetListLength(gClips)
        + " clip(s).");
}


//==============================================================
// PRELOAD
//==============================================================

PreloadClip(integer clipIndex)
{
    if(clipIndex < 0)
        return;

    if(clipIndex >= llGetListLength(gClips))
        return;

    string clipUUID =
        llList2String(
            gClips,
            clipIndex);

    if(IsValidSoundUUID(clipUUID))
        llPreloadSound(clipUUID);
}


//==============================================================
// BEGIN OR RESUME PLAYBACK
//==============================================================

BeginPlaybackAt(integer clipIndex)
{
    integer count = llGetListLength(gClips);

    if(clipIndex < 0)
        clipIndex = 0;

    if(clipIndex >= count)
        clipIndex = count - 1;

    FlushSoundQueue();

    gRunStartClip = clipIndex;
    gNextClipToQueue = clipIndex + 1;
    gQueueStarted = FALSE;
    gWaitingForFinish = FALSE;

    llResetTime();
    gRunStartTime = llGetTime();

    string firstUUID =
        llList2String(
            gClips,
            clipIndex);

    llPlaySound(firstUUID, gVolume);

    if(gNextClipToQueue < count)
    {
        llSetTimerEvent(QUEUE_LEAD_TIME);
        PreloadClip(gNextClipToQueue);
    }
    else
    {
        gWaitingForFinish = TRUE;
        llSetTimerEvent(CLIP_LENGTH);
    }
}


//==============================================================
// TRANSPORT CONTROLS
//==============================================================

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

    gState = STATE_PLAYING;
    NotifyState();

    BeginPlaybackAt(0);
}

StopSong()
{
    FlushSoundQueue();

    gRunStartClip = 0;
    gNextClipToQueue = 0;
    gQueueStarted = FALSE;
    gWaitingForFinish = FALSE;

    gState = STATE_STOPPED;
    NotifyState();
}

integer EstimatePlayingClip()
{
    float elapsed = llGetTime() - gRunStartTime;

    if(elapsed < 0.0)
        elapsed = 0.0;

    integer offset =
        (integer)(elapsed / CLIP_LENGTH);

    integer clipIndex =
        gRunStartClip + offset;

    integer lastClip =
        llGetListLength(gClips) - 1;

    if(clipIndex > lastClip)
        clipIndex = lastClip;

    if(clipIndex < 0)
        clipIndex = 0;

    return clipIndex;
}

PauseSong()
{
    if(gState != STATE_PLAYING)
        return;

    integer pausedClip = EstimatePlayingClip();

    FlushSoundQueue();

    gRunStartClip = pausedClip;
    gNextClipToQueue = pausedClip + 1;
    gQueueStarted = FALSE;
    gWaitingForFinish = FALSE;

    gState = STATE_PAUSED;
    NotifyState();

    Debug(
        "Paused at clip "
        + (string)(pausedClip + 1)
        + ".");
}

ResumeSong()
{
    if(gState != STATE_PAUSED)
        return;

    gState = STATE_PLAYING;
    NotifyState();

    // As before, Continue restarts the clip that was active
    // when Pause was pressed.
    BeginPlaybackAt(gRunStartClip);
}


//==============================================================
// QUEUE TIMER
//==============================================================

HandleQueueTimer()
{
    integer count = llGetListLength(gClips);

    if(gWaitingForFinish)
    {
        llSetTimerEvent(0.0);

        gWaitingForFinish = FALSE;
        gState = STATE_STOPPED;
        NotifyState();

        Debug("Song finished.");
        return;
    }

    if(gNextClipToQueue >= count)
    {
        gWaitingForFinish = TRUE;
        llSetTimerEvent(FINAL_WAIT_TIME);
        return;
    }

    string clipUUID =
        llList2String(
            gClips,
            gNextClipToQueue);

    if(IsValidSoundUUID(clipUUID))
    {
        // Because sound queueing is enabled, this attached
        // sound waits for the current attached sound to finish.
        llPlaySound(clipUUID, gVolume);
    }
    else
    {
        Debug(
            "Skipped invalid queued clip "
            + (string)(gNextClipToQueue + 1)
            + ".");
    }

    ++gNextClipToQueue;
    gQueueStarted = TRUE;

    if(gNextClipToQueue < count)
    {
        // Subsequent queue calls occur one nominal clip length
        // apart. Each call happens approximately QUEUE_LEAD_TIME
        // into the clip currently being heard.
        llSetTimerEvent(CLIP_LENGTH);
        PreloadClip(gNextClipToQueue);
    }
    else
    {
        gWaitingForFinish = TRUE;
        llSetTimerEvent(FINAL_WAIT_TIME);
    }
}


//==============================================================
// DEFAULT STATE
//==============================================================

default
{
    state_entry()
    {
        llSetSoundQueueing(TRUE);

        Debug(
            "Version 1.01 Build 3B.3 "
            + "Seamless Playback Preview");

        NotifyState();
    }

    timer()
    {
        if(gState == STATE_PLAYING)
            HandleQueueTimer();
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
