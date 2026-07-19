
///////////////////////////////////////////////////////////////
//
// Max Modular UUID Music Engine
//
// File:
// 04_Interface.lsl
//
// Version:
// 4.4 — Polished Hardware Dialogs
//
// Status:
// Production Branch
//
// Designed by Max Pitre
// Programming Assistance by OpenAI ChatGPT
//
// PURPOSE
//
// • Owner/guest dialog interface
// • State-aware transport controls
// • Browse and select songs
// • Next / Previous track control
// • Session volume control
// • Persistent guest-access setting
// • Persistent Interface debug setting
//
// SHALL NOT
//
// • Read song notecards
// • Play sounds directly
// • Change display textures
// • Control future 3D panel lights
//
///////////////////////////////////////////////////////////////


//==============================================================
// REVISION HISTORY
//==============================================================
//
// 4.0
// - Complete Interface rewrite
// - Preserves working Build 3C behavior
// - Adds clean persistent Settings architecture
// - Adds owner-only About menu
// - Keeps Browse, Volume, transport, and paging
//


//==============================================================
// LIBRARY API
//==============================================================

integer API_DB_REQUEST = 2000;
integer API_DB_REPLY   = 2001;
integer API_DB_READY   = 2002;


//==============================================================
// ENGINE API
//==============================================================

integer API_ENGINE_PLAY      = 2100;
integer API_ENGINE_STOP      = 2101;
integer API_ENGINE_PAUSE     = 2102;
integer API_ENGINE_RESUME    = 2103;
integer API_ENGINE_PLAY_SONG = 2104;
integer API_ENGINE_VOLUME    = 2105;
integer API_ENGINE_NEXT      = 2106;
integer API_ENGINE_PREV      = 2107;


//==============================================================
// INTERFACE API
//==============================================================

integer API_IF_STATE      = 3000;
integer API_IF_NOWPLAYING = 3001;
integer API_IF_OPEN_BROWSE = 3002;
integer API_IF_OPEN_VOLUME = 3003;
integer API_IF_GUEST_STATE = 3004;
integer API_PANEL_POWER = 3100;


//==============================================================
// ENGINE STATES
//==============================================================

integer STATE_STOPPED = 0;
integer STATE_PLAYING = 1;
integer STATE_PAUSED  = 2;


//==============================================================
// MENU STATES
//==============================================================

integer MENU_MAIN     = 0;
integer MENU_BROWSE   = 1;
integer MENU_VOLUME   = 2;
integer MENU_SETTINGS = 3;
integer MENU_ABOUT    = 4;


//==============================================================
// LIBRARY COMMANDS
//==============================================================

string CMD_LIST_SONGS = "LIST_SONGS";
string CMD_SONG_COUNT = "SONG_COUNT";


//==============================================================
// MAIN BUTTONS
//==============================================================

string BTN_PLAY     = "▶ Play";
string BTN_PAUSE    = "⏸ Pause";
string BTN_CONTINUE = "▶ Continue";
string BTN_STOP     = "■ Stop";

string BTN_PREV_TRACK = "⏮ Prev";
string BTN_NEXT_TRACK = "⏭ Next";

string BTN_BROWSE   = "📖 Browse";
string BTN_VOLUME   = "🔊 Volume";
string BTN_SETTINGS = "⚙ Settings";

string BTN_BACK  = "Back";
string BTN_CLOSE = "Close";


//==============================================================
// BROWSE BUTTONS
//==============================================================

string BTN_PREV_PAGE = "◀ Prev";
string BTN_NEXT_PAGE = "Next ▶";


//==============================================================
// SETTINGS BUTTONS
//==============================================================

string BTN_GUESTS_ON  = "Guests: On";
string BTN_GUESTS_OFF = "Guests: Off";

string BTN_DEBUG_ON  = "Debug: On";
string BTN_DEBUG_OFF = "Debug: Off";

string BTN_ABOUT = "About";


//==============================================================
// PERSISTENT SETTINGS KEYS
//==============================================================

string LSD_GUEST_ACCESS = "MMME_IF_GUEST_ACCESS";
string LSD_DEBUG_MODE   = "MMME_IF_DEBUG_MODE";


//==============================================================
// DIALOG STATE
//==============================================================

integer gMenu = MENU_MAIN;

integer gChannel = 0;
integer gListen  = 0;

key gActiveUser = NULL_KEY;

integer gDialogOpen = FALSE;


//==============================================================
// TRANSPORT REFRESH STATE
//
// -1 means no state transition is being awaited.
//==============================================================

integer gExpectedState = -1;


//==============================================================
// PLAYER STATUS
//==============================================================

integer gState = STATE_STOPPED;

string gSong   = "No Song";
string gArtist = "";

string gVolumeLabel = "100%";


//==============================================================
// SETTINGS STATE
//==============================================================

integer gAllowGuests   = FALSE;
integer gInterfaceDebug = FALSE;


//==============================================================
// LIBRARY CACHE
//
// Two entries per song:
//
// Song ID
// Song Title
//==============================================================

integer SONG_RECORD = 2;

integer SONGS_PER_PAGE = 9;

list gLibrary = [];

integer gSongCount = 0;
integer gSongPage  = 0;


//==============================================================
// DEBUG
//==============================================================

InterfaceDebug(string message)
{
    if(gInterfaceDebug)
    {
        llOwnerSay(
            "[MMME-IF] "
            + message);
    }
}


//==============================================================
// SETTINGS STORAGE
//==============================================================

LoadSettings()
{
    string guestValue =
        llLinksetDataRead(
            LSD_GUEST_ACCESS);

    string debugValue =
        llLinksetDataRead(
            LSD_DEBUG_MODE);

    gAllowGuests =
        (guestValue == "1");

    gInterfaceDebug =
        (debugValue == "1");
}


SaveGuestAccess()
{
    llLinksetDataWrite(
        LSD_GUEST_ACCESS,
        (string)gAllowGuests);
}


SaveDebugMode()
{
    llLinksetDataWrite(
        LSD_DEBUG_MODE,
        (string)gInterfaceDebug);
}


//==============================================================
// GUEST STATE BROADCAST
//==============================================================

BroadcastGuestState()
{
    llMessageLinked(
        LINK_SET,
        API_IF_GUEST_STATE,
        (string)gAllowGuests,
        NULL_KEY);
}


//==============================================================
// AUTHORIZATION
//==============================================================

integer IsAuthorized(key id)
{
    if(id == llGetOwner())
        return TRUE;

    if(gAllowGuests)
        return TRUE;

    return FALSE;
}


//==============================================================
// LIBRARY HELPERS
//==============================================================

integer SongOffset(integer songIndex)
{
    return songIndex * SONG_RECORD;
}


string SongID(integer songIndex)
{
    return llList2String(
        gLibrary,
        SongOffset(songIndex));
}


string SongTitle(integer songIndex)
{
    return llList2String(
        gLibrary,
        SongOffset(songIndex) + 1);
}


string ShortDisplayTitle(string title)
{
    integer limit = 38;

    if(llStringLength(title) <= limit)
        return title;

    return
        llGetSubString(
            title,
            0,
            limit - 4)
        + "...";
}


//==============================================================
// DIALOG LISTENER
//==============================================================

OpenDialog(key id)
{
    if(gListen)
        llListenRemove(gListen);

    gActiveUser = id;
    gDialogOpen = TRUE;

    gChannel =
        -1
        - (integer)llFrand(
            2000000000.0);

    gListen =
        llListen(
            gChannel,
            "",
            id,
            "");

    // Gives the viewer a moment to remove the dialog whose
    // button was just clicked before displaying its replacement.
    llSleep(0.15);
}


CloseDialog()
{
    if(gListen)
    {
        llListenRemove(gListen);
        gListen = 0;
    }

    gActiveUser = NULL_KEY;
    gDialogOpen = FALSE;
    gExpectedState = -1;
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
// TRANSPORT COMMAND
//==============================================================

SendTransportCommand(
    integer command,
    string message,
    integer expectedState,
    key id)
{
    gActiveUser = id;
    gExpectedState = expectedState;

    llMessageLinked(
        LINK_SET,
        command,
        message,
        id);
}


//==============================================================
// MAIN MENU
//==============================================================

ShowMain(key id)
{
    gMenu = MENU_MAIN;

    OpenDialog(id);

    list buttons = [];

    if(gState == STATE_PLAYING)
    {
        buttons +=
        [
            BTN_PAUSE,
            BTN_STOP,
            BTN_PREV_TRACK,
            BTN_NEXT_TRACK
        ];
    }
    else if(gState == STATE_PAUSED)
    {
        buttons +=
        [
            BTN_CONTINUE,
            BTN_STOP,
            BTN_PREV_TRACK,
            BTN_NEXT_TRACK
        ];
    }
    else
    {
        buttons +=
        [
            BTN_PLAY
        ];
    }

    buttons +=
    [
        BTN_BROWSE,
        BTN_VOLUME
    ];

    if(id == llGetOwner())
    {
        buttons +=
        [
            BTN_SETTINGS
        ];
    }

    buttons +=
    [
        BTN_CLOSE
    ];

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
    {
        text +=
            "\n"
            + gArtist;
    }

    llDialog(
        id,
        text,
        buttons,
        gChannel);
}


//==============================================================
// BROWSE MENU
//==============================================================

ShowBrowse(key id)
{
    gMenu = MENU_BROWSE;

    OpenDialog(id);

    if(gSongCount == 0)
    {
        RequestSongList();
        RequestSongCount();

        llDialog(
            id,
            "Building music library...\n\n"
            + "Open Browse again in a moment.",
            [BTN_BACK],
            gChannel);

        return;
    }

    integer maxPage =
        (gSongCount - 1)
        / SONGS_PER_PAGE;

    if(gSongPage < 0)
        gSongPage = 0;

    if(gSongPage > maxPage)
        gSongPage = maxPage;

    integer start =
        gSongPage
        * SONGS_PER_PAGE;

    integer end =
        start
        + SONGS_PER_PAGE
        - 1;

    if(end >= gSongCount)
        end = gSongCount - 1;

    list buttons = [];

    string text =
        "Browse\n\n";

    integer songIndex;
    integer localNumber = 1;

    for(
        songIndex = start;
        songIndex <= end;
        ++songIndex)
    {
        text +=
            (string)localNumber
            + ". "
            + ShortDisplayTitle(
                SongTitle(songIndex))
            + "\n";

        buttons +=
        [
            (string)localNumber
        ];

        ++localNumber;
    }

    text +=
        "\nShowing "
        + (string)(start + 1)
        + " - "
        + (string)(end + 1)
        + " of "
        + (string)gSongCount;

    if(gSongPage > 0)
    {
        buttons +=
        [
            BTN_PREV_PAGE
        ];
    }

    if(gSongPage < maxPage)
    {
        buttons +=
        [
            BTN_NEXT_PAGE
        ];
    }

    buttons +=
    [
        BTN_BACK
    ];

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

    llDialog(
        id,
        "Volume Control\n\n"
        + "Current setting: "
        + gVolumeLabel,
        [
            "100%",
            "80%",
            "60%",
            "40%",
            "20%",
            "Mute",
            BTN_BACK
        ],
        gChannel);
}


//==============================================================
// SETTINGS MENU
//==============================================================

ShowSettings(key id)
{
    if(id != llGetOwner())
    {
        ShowMain(id);
        return;
    }

    gMenu = MENU_SETTINGS;

    OpenDialog(id);

    string guestButton =
        BTN_GUESTS_OFF;

    string debugButton =
        BTN_DEBUG_OFF;

    string accessText =
        "Owner Only";

    if(gAllowGuests)
    {
        guestButton =
            BTN_GUESTS_ON;

        accessText =
            "Owner + Guests";
    }

    if(gInterfaceDebug)
    {
        debugButton =
            BTN_DEBUG_ON;
    }

    string text =
        "MMME Settings\n\n"
        + "Access: "
        + accessText
        + "\n\n"
        + "Guest access allows playback, "
        + "Browse, and Volume.\n"
        + "Settings remain owner-only.";

    llDialog(
        id,
        text,
        [
            guestButton,
            debugButton,
            BTN_ABOUT,
            BTN_BACK
        ],
        gChannel);
}


//==============================================================
// ABOUT MENU
//==============================================================

ShowAbout(key id)
{
    if(id != llGetOwner())
    {
        ShowMain(id);
        return;
    }

    gMenu = MENU_ABOUT;

    OpenDialog(id);

    llDialog(
        id,
        "MMME\n"
        + "Max Modular UUID Music Engine\n\n"
        + "Interface Version 4.0\n\n"
        + "Designed by Max Pitre\n"
        + "Programming Assistance by OpenAI ChatGPT",
        [
            BTN_BACK
        ],
        gChannel);
}


//==============================================================
// MAIN MENU HANDLER
//==============================================================

HandleMainMenu(
    key id,
    string message)
{
    if(message == BTN_PLAY)
    {
        SendTransportCommand(
            API_ENGINE_PLAY,
            "",
            STATE_PLAYING,
            id);

        return;
    }

    if(message == BTN_PAUSE)
    {
        SendTransportCommand(
            API_ENGINE_PAUSE,
            "",
            STATE_PAUSED,
            id);

        return;
    }

    if(message == BTN_CONTINUE)
    {
        SendTransportCommand(
            API_ENGINE_RESUME,
            "",
            STATE_PLAYING,
            id);

        return;
    }

    if(message == BTN_STOP)
    {
        SendTransportCommand(
            API_ENGINE_STOP,
            "",
            STATE_STOPPED,
            id);

        return;
    }

    if(message == BTN_PREV_TRACK)
    {
        SendTransportCommand(
            API_ENGINE_PREV,
            "",
            STATE_PLAYING,
            id);

        return;
    }

    if(message == BTN_NEXT_TRACK)
    {
        SendTransportCommand(
            API_ENGINE_NEXT,
            "",
            STATE_PLAYING,
            id);

        return;
    }

    if(message == BTN_BROWSE)
    {
        ShowBrowse(id);
        return;
    }

    if(message == BTN_VOLUME)
    {
        ShowVolume(id);
        return;
    }

    if(message == BTN_SETTINGS)
    {
        ShowSettings(id);
        return;
    }

    if(message == BTN_CLOSE)
    {
        CloseDialog();
        return;
    }

    ShowMain(id);
}


//==============================================================
// BROWSE HANDLER
//==============================================================

HandleBrowseMenu(
    key id,
    string message)
{
    if(message == BTN_BACK)
    {
        ShowMain(id);
        return;
    }

    if(message == BTN_NEXT_PAGE)
    {
        ++gSongPage;
        ShowBrowse(id);
        return;
    }

    if(message == BTN_PREV_PAGE)
    {
        if(gSongPage > 0)
            --gSongPage;

        ShowBrowse(id);
        return;
    }

    integer selection =
        (integer)message;

    if(
        selection >= 1
        && selection <= SONGS_PER_PAGE)
    {
        integer songIndex =
            (gSongPage * SONGS_PER_PAGE)
            + selection
            - 1;

        if(
            songIndex >= 0
            && songIndex < gSongCount)
        {
            SendTransportCommand(
                API_ENGINE_PLAY_SONG,
                SongID(songIndex),
                STATE_PLAYING,
                id);

            return;
        }
    }

    ShowBrowse(id);
}


//==============================================================
// VOLUME HANDLER
//==============================================================

HandleVolumeMenu(
    key id,
    string message)
{
    if(message == BTN_BACK)
    {
        ShowMain(id);
        return;
    }

    float volume = -1.0;

    if(message == "100%")
        volume = 1.0;
    else if(message == "80%")
        volume = 0.8;
    else if(message == "60%")
        volume = 0.6;
    else if(message == "40%")
        volume = 0.4;
    else if(message == "20%")
        volume = 0.2;
    else if(message == "Mute")
        volume = 0.0;

    if(volume >= 0.0)
    {
        gVolumeLabel = message;

        llMessageLinked(
            LINK_SET,
            API_ENGINE_VOLUME,
            (string)volume,
            id);
    }

    ShowVolume(id);
}


//==============================================================
// SETTINGS HANDLER
//==============================================================

HandleSettingsMenu(
    key id,
    string message)
{
    if(id != llGetOwner())
    {
        ShowMain(id);
        return;
    }

    if(message == BTN_BACK)
    {
        ShowMain(id);
        return;
    }

    if(message == BTN_ABOUT)
    {
        ShowAbout(id);
        return;
    }

    if(
        message == BTN_GUESTS_ON
        || message == BTN_GUESTS_OFF)
    {
        gAllowGuests =
            !gAllowGuests;

        SaveGuestAccess();
        BroadcastGuestState();

        InterfaceDebug(
            "Guest access changed to "
            + (string)gAllowGuests);

        ShowSettings(id);
        return;
    }

    if(
        message == BTN_DEBUG_ON
        || message == BTN_DEBUG_OFF)
    {
        gInterfaceDebug =
            !gInterfaceDebug;

        SaveDebugMode();

        InterfaceDebug(
            "Interface debug changed to "
            + (string)gInterfaceDebug);

        ShowSettings(id);
        return;
    }

    ShowSettings(id);
}


//==============================================================
// ABOUT HANDLER
//==============================================================

HandleAboutMenu(
    key id,
    string message)
{
    if(message == BTN_BACK)
    {
        ShowSettings(id);
        return;
    }

    ShowAbout(id);
}


//==============================================================
// LISTEN DISPATCHER
//==============================================================

HandleListen(
    key id,
    string message)
{
    if(!IsAuthorized(id))
        return;

    if(gMenu == MENU_MAIN)
    {
        HandleMainMenu(
            id,
            message);

        return;
    }

    if(gMenu == MENU_BROWSE)
    {
        HandleBrowseMenu(
            id,
            message);

        return;
    }

    if(gMenu == MENU_VOLUME)
    {
        HandleVolumeMenu(
            id,
            message);

        return;
    }

    if(gMenu == MENU_SETTINGS)
    {
        HandleSettingsMenu(
            id,
            message);

        return;
    }

    if(gMenu == MENU_ABOUT)
    {
        HandleAboutMenu(
            id,
            message);

        return;
    }
}


//==============================================================
// LIBRARY CACHE
//==============================================================

CacheSongList(string message)
{
    gLibrary = [];
    gSongCount = 0;
    gSongPage = 0;

    list records =
        llParseStringKeepNulls(
            message,
            ["|"],
            []);

    integer index;

    for(
        index = 1;
        index < llGetListLength(records);
        ++index)
    {
        list fields =
            llParseStringKeepNulls(
                llList2String(
                    records,
                    index),
                ["="],
                []);

        if(llGetListLength(fields) >= 2)
        {
            string songID =
                llList2String(
                    fields,
                    0);

            string title =
                llList2String(
                    fields,
                    1);

            if(
                songID != ""
                && title != "")
            {
                gLibrary +=
                [
                    songID,
                    title
                ];

                ++gSongCount;
            }
        }
    }

    InterfaceDebug(
        "Cached "
        + (string)gSongCount
        + " songs.");
}


//==============================================================
// LINKED MESSAGE HANDLER
//==============================================================

HandleLinkMessage(
    integer number,
    string message,
    key messageUser)
{
    if(number == API_IF_OPEN_BROWSE)
    {
        if(IsAuthorized(messageUser))
        {
            CloseDialog();
            ShowBrowse(messageUser);
        }
        return;
    }

    if(number == API_IF_OPEN_VOLUME)
    {
        if(IsAuthorized(messageUser))
        {
            CloseDialog();
            ShowVolume(messageUser);
        }
        return;
    }

    if(number == API_PANEL_POWER)
    {
        if((integer)message == FALSE)
            CloseDialog();

        return;
    }

    if(number == API_DB_READY)
    {
        RequestSongList();
        RequestSongCount();
        return;
    }

    if(number == API_IF_STATE)
    {
        gState =
            (integer)message;

        if(gExpectedState >= 0)
        {
            if(gState == gExpectedState)
            {
                key user =
                    gActiveUser;

                gExpectedState = -1;

                if(user)
                    ShowMain(user);
            }
        }

        return;
    }

    if(number == API_IF_NOWPLAYING)
    {
        list fields =
            llParseStringKeepNulls(
                message,
                ["|"],
                []);

        if(llGetListLength(fields) >= 2)
        {
            gSong =
                llList2String(
                    fields,
                    0);

            gArtist =
                llList2String(
                    fields,
                    1);
        }

        return;
    }

    if(number == API_DB_REPLY)
    {
        if(
            llSubStringIndex(
                message,
                "SONG_LIST|") == 0)
        {
            CacheSongList(
                message);

            return;
        }

        if(
            llSubStringIndex(
                message,
                "SONG_COUNT|") == 0)
        {
            // The Browse count is intentionally derived
            // from the actual cached song list.
            return;
        }
    }
}


//==============================================================
// PHYSICAL CONTROL TOUCH FILTER
//==============================================================

integer IsPhysicalControl(string primName)
{
    if(primName == "POWER")  return TRUE;
    if(primName == "PREV")   return TRUE;
    if(primName == "PLAY")   return TRUE;
    if(primName == "PAUSE")  return TRUE;
    if(primName == "STOP")   return TRUE;
    if(primName == "NEXT")   return TRUE;
    if(primName == "BROWSE") return TRUE;
    if(primName == "VOLUME") return TRUE;

    return FALSE;
}


//==============================================================
// DEFAULT STATE
//==============================================================

default
{
    state_entry()
    {
        LoadSettings();
        BroadcastGuestState();

        RequestSongList();
        RequestSongCount();
    }


    touch_start(integer total)
    {
        key id =
            llDetectedKey(0);

        integer touchedLink =
            llDetectedLinkNumber(0);

        string touchedName =
            llGetLinkName(touchedLink);

        // Physical controls are handled exclusively by
        // 06_ControlPanel. This prevents two dialogs from
        // opening from a single button press.
        if(IsPhysicalControl(touchedName))
            return;

        if(IsAuthorized(id))
            ShowMain(id);
    }


    listen(
        integer channel,
        string name,
        key id,
        string message)
    {
        gDialogOpen = FALSE;

        HandleListen(
            id,
            message);
    }


    link_message(
        integer sender,
        integer number,
        string message,
        key id)
    {
        HandleLinkMessage(
            number,
            message,
            id);
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
