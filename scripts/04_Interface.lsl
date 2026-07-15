
///////////////////////////////////////////////////////////////
//
// MMME - Max Modular Music Engine
//
// File: 04_Interface.lsl
// Version: 1.01
// Build: 3B.2 Stability Fix
//
///////////////////////////////////////////////////////////////

integer API_ENGINE_PLAY   = 2100;
integer API_ENGINE_STOP   = 2101;
integer API_ENGINE_PAUSE  = 2102;
integer API_ENGINE_RESUME = 2103;

integer API_DB_REQUEST = 2000;
integer API_DB_REPLY   = 2001;

integer API_IF_STATE      = 3000;
integer API_IF_NOWPLAYING = 3001;

string CMD_LIST_SONGS = "LIST_SONGS";
string CMD_SONG_COUNT = "SONG_COUNT";

integer STATE_STOPPED = 0;
integer STATE_PLAYING = 1;
integer STATE_PAUSED  = 2;

string BTN_PLAY     = "▶ Play";
string BTN_PAUSE    = "⏸ Pause";
string BTN_CONTINUE = "▶ Continue";
string BTN_STOP     = "■ Stop";
string BTN_SONGS    = "🎵 Songs";
string BTN_VOLUME   = "🔊 Volume";
string BTN_BACK     = "Back";
string BTN_CLOSE    = "Close";
string BTN_NEXT     = "Next ▶";
string BTN_PREV     = "◀ Prev";

integer MENU_MAIN   = 0;
integer MENU_SONGS  = 1;
integer MENU_VOLUME = 2;

integer gMenu = MENU_MAIN;

integer gChannel = 0;
integer gListen = 0;

integer gState = STATE_STOPPED;

string gSong = "No Song";
string gArtist = "";

integer SONG_RECORD = 2;
integer BUTTONS_PER_PAGE = 9;

list gLibrary = [];

integer gSongCount = 0;
integer gSongPage = 0;

key gActiveUser = NULL_KEY;
integer gRefreshMainOnState = FALSE;

integer SongOffset(integer song)
{
    return song * SONG_RECORD;
}

string SongID(integer song)
{
    return llList2String(gLibrary, SongOffset(song));
}

string SongTitle(integer song)
{
    return llList2String(gLibrary, SongOffset(song) + 1);
}

OpenDialog(key id)
{
    if(gListen)
        llListenRemove(gListen);

    gActiveUser = id;
    gChannel = -1 - (integer)llFrand(2000000000.0);
    gListen = llListen(gChannel, "", id, "");
}

CloseDialog()
{
    if(gListen)
    {
        llListenRemove(gListen);
        gListen = 0;
    }

    gActiveUser = NULL_KEY;
    gRefreshMainOnState = FALSE;
}

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

ShowMain(key id)
{
    gMenu = MENU_MAIN;
    OpenDialog(id);

    list buttons = [];

    if(gState == STATE_PLAYING)
        buttons += [BTN_PAUSE, BTN_STOP];
    else if(gState == STATE_PAUSED)
        buttons += [BTN_CONTINUE, BTN_STOP];
    else
        buttons += [BTN_PLAY];

    buttons += [BTN_SONGS, BTN_VOLUME, BTN_CLOSE];

    string stateText = "Stopped";

    if(gState == STATE_PLAYING)
        stateText = "Playing";
    else if(gState == STATE_PAUSED)
        stateText = "Paused";

    string text =
        "MMME\n\n"
        + "Status: "
        + stateText
        + "\n\n"
        + "Now Playing\n"
        + gSong;

    if(gArtist != "")
        text += "\n" + gArtist;

    llDialog(id, text, buttons, gChannel);
}

ShowVolume(key id)
{
    gMenu = MENU_VOLUME;
    OpenDialog(id);

    llDialog(
        id,
        "Volume Control\n\nVolume connection comes in a later build.",
        ["100%", "80%", "60%", "40%", "20%", "Mute", BTN_BACK],
        gChannel);
}

ShowSongs(key id)
{
    gMenu = MENU_SONGS;
    OpenDialog(id);

    if(gSongCount == 0)
    {
        RequestSongList();
        RequestSongCount();

        llDialog(
            id,
            "Building music library...\n\nOpen Songs again in a moment.",
            [BTN_BACK],
            gChannel);

        return;
    }

    integer maxPage = (gSongCount - 1) / BUTTONS_PER_PAGE;

    if(gSongPage < 0)
        gSongPage = 0;

    if(gSongPage > maxPage)
        gSongPage = maxPage;

    integer start = gSongPage * BUTTONS_PER_PAGE;
    integer end = start + BUTTONS_PER_PAGE - 1;

    if(end >= gSongCount)
        end = gSongCount - 1;

    list buttons = [];
    integer i;

    for(i = start; i <= end; ++i)
        buttons += [SongTitle(i)];

    if(gSongPage > 0)
        buttons += [BTN_PREV];

    if(gSongPage < maxPage)
        buttons += [BTN_NEXT];

    buttons += [BTN_BACK];

    llDialog(
        id,
        "Songs\n\nShowing "
        + (string)(start + 1)
        + " - "
        + (string)(end + 1)
        + " of "
        + (string)gSongCount,
        buttons,
        gChannel);
}

SendTransportCommand(integer command, key id)
{
    gActiveUser = id;
    gRefreshMainOnState = TRUE;

    llMessageLinked(
        LINK_SET,
        command,
        "",
        id);
}

HandleMainMenu(key id, string msg)
{
    if(msg == BTN_PLAY)
    {
        SendTransportCommand(API_ENGINE_PLAY, id);
        return;
    }

    if(msg == BTN_PAUSE)
    {
        SendTransportCommand(API_ENGINE_PAUSE, id);
        return;
    }

    if(msg == BTN_CONTINUE)
    {
        SendTransportCommand(API_ENGINE_RESUME, id);
        return;
    }

    if(msg == BTN_STOP)
    {
        SendTransportCommand(API_ENGINE_STOP, id);
        return;
    }

    if(msg == BTN_SONGS)
    {
        ShowSongs(id);
        return;
    }

    if(msg == BTN_VOLUME)
    {
        ShowVolume(id);
        return;
    }

    if(msg == BTN_CLOSE)
    {
        CloseDialog();
        return;
    }
}

HandleVolumeMenu(key id, string msg)
{
    if(msg == BTN_BACK)
    {
        ShowMain(id);
        return;
    }

    llOwnerSay("[MMME-IF] Volume selected: " + msg);
    ShowVolume(id);
}

HandleSongMenu(key id, string msg)
{
    if(msg == BTN_BACK)
    {
        ShowMain(id);
        return;
    }

    if(msg == BTN_NEXT)
    {
        ++gSongPage;
        ShowSongs(id);
        return;
    }

    if(msg == BTN_PREV)
    {
        if(gSongPage > 0)
            --gSongPage;

        ShowSongs(id);
        return;
    }

    integer start = gSongPage * BUTTONS_PER_PAGE;
    integer end = start + BUTTONS_PER_PAGE - 1;

    if(end >= gSongCount)
        end = gSongCount - 1;

    integer i;

    for(i = start; i <= end; ++i)
    {
        if(msg == SongTitle(i))
        {
            llOwnerSay(
                "[MMME-IF] Selected Song "
                + SongID(i)
                + ": "
                + SongTitle(i));

            ShowMain(id);
            return;
        }
    }

    ShowSongs(id);
}

HandleListen(key id, string msg)
{
    if(gMenu == MENU_MAIN)
        HandleMainMenu(id, msg);
    else if(gMenu == MENU_SONGS)
        HandleSongMenu(id, msg);
    else if(gMenu == MENU_VOLUME)
        HandleVolumeMenu(id, msg);
}

CacheSongList(string message)
{
    gLibrary = [];
    gSongCount = 0;
    gSongPage = 0;

    list records = llParseStringKeepNulls(message, ["|"], []);
    integer i;

    for(i = 1; i < llGetListLength(records); ++i)
    {
        list fields =
            llParseStringKeepNulls(
                llList2String(records, i),
                ["="],
                []);

        if(llGetListLength(fields) >= 2)
        {
            string songID = llList2String(fields, 0);
            string title = llList2String(fields, 1);

            if(songID != "" && title != "")
            {
                gLibrary += [songID, title];
                ++gSongCount;
            }
        }
    }
}

HandleLinkMessage(integer num, string message)
{
    if(num == API_IF_STATE)
    {
        gState = (integer)message;

        if(gRefreshMainOnState && gActiveUser != NULL_KEY)
        {
            gRefreshMainOnState = FALSE;
            ShowMain(gActiveUser);
        }

        return;
    }

    if(num == API_IF_NOWPLAYING)
    {
        list p = llParseStringKeepNulls(message, ["|"], []);

        if(llGetListLength(p) >= 2)
        {
            gSong = llList2String(p, 0);
            gArtist = llList2String(p, 1);
        }

        return;
    }

    if(num == API_DB_REPLY)
    {
        if(llSubStringIndex(message, "SONG_LIST|") == 0)
        {
            CacheSongList(message);
            return;
        }

        if(llSubStringIndex(message, "SONG_COUNT|") == 0)
        {
            integer reportedCount =
                (integer)llGetSubString(message, 11, -1);

            if(gSongCount == 0)
                gSongCount = reportedCount;

            return;
        }
    }
}

default
{
    state_entry()
    {
        RequestSongList();
        RequestSongCount();
    }

    touch_start(integer total)
    {
        key id = llDetectedKey(0);

        if(id == llGetOwner())
            ShowMain(id);
    }

    listen(
        integer channel,
        string name,
        key id,
        string message)
    {
        HandleListen(id, message);
    }

    link_message(
        integer sender,
        integer num,
        string message,
        key id)
    {
        HandleLinkMessage(num, message);
    }

    changed(integer change)
    {
        if(change & CHANGED_INVENTORY)
        {
            gLibrary = [];
            gSongCount = 0;
            gSongPage = 0;

            RequestSongList();
            RequestSongCount();
        }
    }

    on_rez(integer start)
    {
        llResetScript();
    }
}
