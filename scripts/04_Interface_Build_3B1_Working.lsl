///////////////////////////////////////////////////////////////
//
// Max Modular Music Engine
//
// File:
// 04_Interface.lsl
//
// Version:
// 1.01
//
// Build:
// 3B.1
//
// PURPOSE
//
// • Owner interface
// • Playback controls
// • Song browser
// • Volume menu
//
///////////////////////////////////////////////////////////////


//==============================================================
// PLAYBACK API
//==============================================================

integer API_ENGINE_PLAY      = 2100;
integer API_ENGINE_STOP      = 2101;
integer API_ENGINE_PAUSE     = 2102;
integer API_ENGINE_RESUME    = 2103;


//==============================================================
// LIBRARY API
//==============================================================

integer API_DB_REQUEST       = 2000;
integer API_DB_REPLY         = 2001;


//==============================================================
// INTERFACE API
//==============================================================

integer API_IF_STATE         = 3000;
integer API_IF_NOWPLAYING    = 3001;


//==============================================================
// LIBRARY COMMANDS
//==============================================================

string CMD_LIST_SONGS = "LIST_SONGS";
string CMD_SONG_COUNT = "SONG_COUNT";


//==============================================================
// BUTTONS
//==============================================================

// Transport

string BTN_PLAY      = "▶ Play";
string BTN_PAUSE     = "⏸ Pause";
string BTN_CONTINUE  = "▶ Continue";
string BTN_STOP      = "■ Stop";

// Menus

string BTN_SONGS     = "🎵 Songs";
string BTN_VOLUME    = "🔊 Volume";

string BTN_BACK      = "Back";
string BTN_CLOSE     = "Close";

string BTN_NEXT      = "Next ▶";
string BTN_PREV      = "◀ Prev";


//==============================================================
// MENU STATES
//==============================================================

integer MENU_MAIN    = 0;
integer MENU_SONGS   = 1;
integer MENU_VOLUME  = 2;

integer gMenu = MENU_MAIN;


//==============================================================
// DIALOG
//==============================================================

integer gChannel;
integer gListen;


//==============================================================
// PLAYER STATUS
//==============================================================

integer gState = 0;

string gSong   = "No Song";
string gArtist = "";


//==============================================================
// LIBRARY CACHE
//
// Current format:
//
// SongID
// SongTitle
//
// Two entries per song.
//==============================================================

integer SONG_RECORD = 2;

list gLibrary = [];

integer gSongCount = 0;

integer gSongPage  = 0;

integer BUTTONS_PER_PAGE = 9;


//==============================================================
// LIBRARY HELPERS
//==============================================================

integer SongOffset(integer song)
{
    return song * SONG_RECORD;
}

string SongID(integer song)
{
    return llList2String(
        gLibrary,
        SongOffset(song));
}

string SongTitle(integer song)
{
    return llList2String(
        gLibrary,
        SongOffset(song) + 1);
}


//==============================================================
// DIALOG SUPPORT
//==============================================================

OpenDialog(key id)
{
    if(gListen)
        llListenRemove(gListen);

    gChannel =
        -1 - (integer)llFrand(2000000000.0);

    gListen =
        llListen(
            gChannel,
            "",
            id,
            "");
}


//==============================================================
// LIBRARY REQUESTS
//==============================================================

RequestSongList()
{
    llMessageLinked(
        LINK_SET,
        API_DB_REQUEST,
        CMD_LIST_SONGS,
        NULL_KEY);
}

RequestSongCount()
{
    llMessageLinked(
        LINK_SET,
        API_DB_REQUEST,
        CMD_SONG_COUNT,
        NULL_KEY);
}
//==============================================================
// MAIN MENU
//==============================================================

ShowMain(key id)
{
    gMenu = MENU_MAIN;

    OpenDialog(id);

    list buttons =
    [
        BTN_PLAY,
        BTN_PAUSE,
        BTN_CONTINUE,
        BTN_STOP,
        BTN_SONGS,
        BTN_VOLUME,
        BTN_CLOSE
    ];

    string text =
        "══════════════════════\n"
        + "MMME\n"
        + "══════════════════════\n\n"
        + "Now Playing\n\n"
        + gSong;

    if(gArtist != "")
        text += "\n" + gArtist;

    llDialog(
        id,
        text,
        buttons,
        gChannel);
}



//==============================================================
// VOLUME MENU
//==============================================================

ShowVolume(key id)
{
    gMenu = MENU_VOLUME;

    OpenDialog(id);

    list buttons =
    [
        "100%",
        "80%",
        "60%",
        "40%",
        "20%",
        "Mute",
        BTN_BACK
    ];

    llDialog(
        id,
        "Volume Control\n\n(Playback support already built into the Main Engine.)",
        buttons,
        gChannel);
}



//==============================================================
// SONG BROWSER
//==============================================================

ShowSongs(key id)
{
    gMenu = MENU_SONGS;

    OpenDialog(id);

    if(gSongCount == 0)
    {
        RequestSongList();

        llDialog(
            id,
            "Building music library...\n\nPlease try Songs again in a moment.",
            [BTN_BACK],
            gChannel);

        return;
    }

    integer start = gSongPage * BUTTONS_PER_PAGE;
    integer end = start + BUTTONS_PER_PAGE - 1;

    if(end >= gSongCount)
        end = gSongCount - 1;

    list buttons = [];

    integer i;

    for(i = start; i <= end; ++i)
    {
        buttons += [ SongTitle(i) ];
    }

    if(gSongPage > 0)
        buttons += [ BTN_PREV ];

    if(end < (gSongCount - 1))
        buttons += [ BTN_NEXT ];

    buttons += [ BTN_BACK ];

    string text =
        "Songs\n\n"
        + "Showing "
        + (string)(start + 1)
        + " - "
        + (string)(end + 1)
        + " of "
        + (string)gSongCount;

    llDialog(
        id,
        text,
        buttons,
        gChannel);
}
