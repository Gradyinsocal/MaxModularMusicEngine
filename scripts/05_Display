
///////////////////////////////////////////////////////////////
//
// Max Modular UUID Music Engine
//
// File:
// 05_Display.lsl
//
// Version:
// 1.0
//
// Status:
// Production Display Engine
//
// Designed by Max Pitre
// Programming Assistance by OpenAI ChatGPT
//
// PURPOSE
//
// • Drive the proven low-land-impact 16-character display
// • Use three linked mesh panels
// • Show song title and artist
// • Scroll long text automatically
// • React to Playing / Paused / Stopped states
// • Run a short startup sequence
//
// SHALL NOT
//
// • Play sounds
// • Read song notecards
// • Open user menus
// • Control playback
//
///////////////////////////////////////////////////////////////


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
// FONT ATLAS
//
// Replace this UUID with the exact new 1024 × 1024 atlas
// you uploaded after the successful calibration test.
//==============================================================

string FONT_ATLAS_UUID =
    "c8b7efcf-a787-dea9-4adf-1bb04b2b6647";

integer ATLAS_COLUMNS = 16;
integer ATLAS_ROWS    = 8;


//==============================================================
// DISPLAY HARDWARE
//==============================================================

integer DISPLAY_LENGTH = 16;

string PANEL_1_NAME = "TEST CHARACTER PANEL 1";
string PANEL_2_NAME = "TEST CHARACTER PANEL 2";
string PANEL_3_NAME = "TEST CHARACTER PANEL 3";

list PANEL_1_FACES = [1,0,2,7,6,5,4,3];
list PANEL_2_FACES = [4,3,2,1,0];
list PANEL_3_FACES = [0,2,1];


//==============================================================
// ATLAS CHARACTER ORDER
//
// Exact order used by the corrected 16 × 8 production atlas.
//==============================================================

list ATLAS_CHARACTERS =
[
    " ","A","B","C","D","E","F","G",
    "H","I","J","K","L","M","N","O",

    "P","Q","R","S","T","U","V","W",
    "X","Y","Z","0","1","2","3","4",

    "5","6","7","8","9","a","b","c",
    "d","e","f","g","h","i","j",

    "k","l","m","n","o","p","q","r",
    "s","t","u","v","w","x","y","z",

    ".",",","!","?","-","_","/","\\",
    ":",";","'","\"","(",")","+","=",

    "<",">","[","]","{","}","@","#",
    "$","%","&","*","^","~","|","`",

    " "," "," "," "," "," "," "," ",
    " "," "," "," "," "," "," "," ",

    " "," "," "," "," "," "," "," ",
    " "," "," "," "," "," "," "," "
];


//==============================================================
// DISPLAY MODES
//==============================================================

integer MODE_STARTUP = 0;
integer MODE_TITLE   = 1;
integer MODE_ARTIST  = 2;
integer MODE_STATUS  = 3;


//==============================================================
// TIMING
//==============================================================

float SCROLL_INTERVAL       = 0.40;
float STATIC_PAGE_INTERVAL  = 4.00;
float STARTUP_PAGE_INTERVAL = 1.25;
float STATUS_HOLD_TIME      = 1.50;


//==============================================================
// RUNTIME STATE
//==============================================================

list gCharacterLinks = [];
list gCharacterFaces = [];

integer gState = STATE_STOPPED;

string gTitle  = "";
string gArtist = "";

integer gMode = MODE_STARTUP;

integer gScrollPosition = 0;
integer gNeedsScrolling = FALSE;

integer gStartupStep = 0;

float gNextPageTime = 0.0;
float gStatusUntil  = 0.0;

integer gReady = FALSE;


//==============================================================
// DEBUG
//==============================================================

integer DEBUG = TRUE;

Debug(string message)
{
    if(DEBUG)
    {
        llOwnerSay(
            "[MMME-DISPLAY] "
            + message);
    }
}


//==============================================================
// PANEL DISCOVERY
//==============================================================

integer FindLinkByName(string primName)
{
    integer count = llGetNumberOfPrims();
    integer link;

    for(link = 1; link <= count; ++link)
    {
        if(llGetLinkName(link) == primName)
            return link;
    }

    return 0;
}


BuildCharacterMap()
{
    integer panel1 =
        FindLinkByName(PANEL_1_NAME);

    integer panel2 =
        FindLinkByName(PANEL_2_NAME);

    integer panel3 =
        FindLinkByName(PANEL_3_NAME);

    gCharacterLinks = [];
    gCharacterFaces = [];

    integer index;

    for(
        index = 0;
        index < llGetListLength(PANEL_1_FACES);
        ++index)
    {
        gCharacterLinks += [panel1];
        gCharacterFaces +=
        [
            llList2Integer(
                PANEL_1_FACES,
                index)
        ];
    }

    for(
        index = 0;
        index < llGetListLength(PANEL_2_FACES);
        ++index)
    {
        gCharacterLinks += [panel2];
        gCharacterFaces +=
        [
            llList2Integer(
                PANEL_2_FACES,
                index)
        ];
    }

    for(
        index = 0;
        index < llGetListLength(PANEL_3_FACES);
        ++index)
    {
        gCharacterLinks += [panel3];
        gCharacterFaces +=
        [
            llList2Integer(
                PANEL_3_FACES,
                index)
        ];
    }

    gReady =
        panel1
        && panel2
        && panel3
        && llGetListLength(gCharacterLinks) == DISPLAY_LENGTH;

    if(gReady)
        Debug("Display hardware ready.");
    else
        Debug("One or more display panels are missing.");
}


//==============================================================
// CHARACTER HELPERS
//==============================================================

integer CharacterIndex(string character)
{
    integer index =
        llListFindList(
            ATLAS_CHARACTERS,
            [character]);

    if(index >= 0)
        return index;

    return 0;
}


string CharacterAt(
    string text,
    integer index)
{
    if(index < 0)
        return " ";

    if(index >= llStringLength(text))
        return " ";

    return
        llGetSubString(
            text,
            index,
            index);
}


string PadRight(
    string text,
    integer width)
{
    while(llStringLength(text) < width)
        text += " ";

    return
        llGetSubString(
            text,
            0,
            width - 1);
}


string CenterText(
    string text,
    integer width)
{
    integer length =
        llStringLength(text);

    if(length >= width)
    {
        return
            llGetSubString(
                text,
                0,
                width - 1);
    }

    integer leftPadding =
        (width - length) / 2;

    string result = "";

    integer index;

    for(index = 0; index < leftPadding; ++index)
        result += " ";

    result += text;

    return PadRight(result, width);
}


//==============================================================
// CHARACTER RENDERING
//==============================================================

SetCharacter(
    integer position,
    string character)
{
    if(!gReady)
        return;

    if(
        position < 0
        || position >= DISPLAY_LENGTH)
    {
        return;
    }

    integer link =
        llList2Integer(
            gCharacterLinks,
            position);

    integer face =
        llList2Integer(
            gCharacterFaces,
            position);

    integer cell =
        CharacterIndex(character);

    integer column =
        cell % ATLAS_COLUMNS;

    integer row =
        cell / ATLAS_COLUMNS;

    float repeatX =
        1.0 / (float)ATLAS_COLUMNS;

    float repeatY =
        1.0 / (float)ATLAS_ROWS;

    float offsetX =
        -0.5
        + ((float)column + 0.5)
        * repeatX;

    float offsetY =
        0.5
        - ((float)row + 0.5)
        * repeatY;

    llSetLinkPrimitiveParamsFast(
        link,
        [
            PRIM_TEXTURE,
            face,
            FONT_ATLAS_UUID,
            <repeatX, repeatY, 0.0>,
            <offsetX, offsetY, 0.0>,
            0.0
        ]);
}


RenderText(string text)
{
    text =
        PadRight(
            text,
            DISPLAY_LENGTH);

    integer index;

    for(
        index = 0;
        index < DISPLAY_LENGTH;
        ++index)
    {
        SetCharacter(
            index,
            CharacterAt(
                text,
                index));
    }
}


//==============================================================
// SCROLLING
//==============================================================

RenderScrollingText(string text)
{
    integer length =
        llStringLength(text);

    if(length <= DISPLAY_LENGTH)
    {
        gNeedsScrolling = FALSE;
        gScrollPosition = 0;

        RenderText(
            CenterText(
                text,
                DISPLAY_LENGTH));

        return;
    }

    gNeedsScrolling = TRUE;

    string scrollText =
        text
        + "    "
        + text;

    integer scrollLength =
        llStringLength(scrollText);

    string window = "";

    integer index;

    for(
        index = 0;
        index < DISPLAY_LENGTH;
        ++index)
    {
        integer sourceIndex =
            (gScrollPosition + index)
            % scrollLength;

        window +=
            CharacterAt(
                scrollText,
                sourceIndex);
    }

    RenderText(window);
}


//==============================================================
// STATUS TEXT
//==============================================================

string StateText()
{
    if(gState == STATE_PLAYING)
        return "PLAYING";

    if(gState == STATE_PAUSED)
        return "PAUSED";

    return "STOPPED";
}


//==============================================================
// DISPLAY MODE CONTROL
//==============================================================

ShowStatus()
{
    gMode = MODE_STATUS;
    gNeedsScrolling = FALSE;
    gScrollPosition = 0;

    RenderText(
        CenterText(
            StateText(),
            DISPLAY_LENGTH));

    gStatusUntil =
        llGetTime()
        + STATUS_HOLD_TIME;
}


ShowTitle()
{
    gMode = MODE_TITLE;
    gScrollPosition = 0;

    string text = gTitle;

    if(text == "")
        text = "MMME READY";

    RenderScrollingText(text);

    gNextPageTime =
        llGetTime()
        + STATIC_PAGE_INTERVAL;
}


ShowArtist()
{
    gMode = MODE_ARTIST;
    gScrollPosition = 0;

    string text = gArtist;

    if(text == "")
        text = StateText();

    RenderScrollingText(text);

    gNextPageTime =
        llGetTime()
        + STATIC_PAGE_INTERVAL;
}


//==============================================================
// STARTUP SEQUENCE
//==============================================================

AdvanceStartup()
{
    gMode = MODE_STARTUP;
    gNeedsScrolling = FALSE;
    gScrollPosition = 0;

    if(gStartupStep == 0)
    {
        RenderText(
            CenterText(
                "MAX MODULAR",
                DISPLAY_LENGTH));
    }
    else if(gStartupStep == 1)
    {
        RenderText(
            CenterText(
                "MUSIC ENGINE",
                DISPLAY_LENGTH));
    }
    else if(gStartupStep == 2)
    {
        RenderText(
            CenterText(
                "VERSION 1.0",
                DISPLAY_LENGTH));
    }
    else
    {
        ShowTitle();
        return;
    }

    ++gStartupStep;

    gNextPageTime =
        llGetTime()
        + STARTUP_PAGE_INTERVAL;
}


//==============================================================
// MASTER TIMER
//==============================================================

UpdateTimer()
{
    llSetTimerEvent(
        SCROLL_INTERVAL);
}


//==============================================================
// ENGINE MESSAGE HANDLERS
//==============================================================

HandleNowPlaying(string message)
{
    list fields =
        llParseStringKeepNulls(
            message,
            ["|"],
            []);

    if(llGetListLength(fields) >= 2)
    {
        gTitle =
            llList2String(
                fields,
                0);

        gArtist =
            llList2String(
                fields,
                1);

        ShowTitle();
    }
}


HandleState(string message)
{
    integer newState =
        (integer)message;

    if(newState == gState)
        return;

    gState = newState;

    ShowStatus();
}


//==============================================================
// TIMER LOGIC
//==============================================================

HandleTimer()
{
    float now =
        llGetTime();

    if(gMode == MODE_STARTUP)
    {
        if(now >= gNextPageTime)
            AdvanceStartup();

        return;
    }

    if(gMode == MODE_STATUS)
    {
        if(now >= gStatusUntil)
            ShowTitle();

        return;
    }

    if(gNeedsScrolling)
    {
        ++gScrollPosition;

        if(gMode == MODE_TITLE)
            RenderScrollingText(gTitle);
        else if(gMode == MODE_ARTIST)
            RenderScrollingText(gArtist);

        return;
    }

    if(now >= gNextPageTime)
    {
        if(
            gMode == MODE_TITLE
            && gArtist != "")
        {
            ShowArtist();
        }
        else
        {
            ShowTitle();
        }
    }
}


//==============================================================
// DEFAULT STATE
//==============================================================

default
{
    state_entry()
    {
        llResetTime();

        BuildCharacterMap();

        if(
            FONT_ATLAS_UUID
            == "00000000-0000-0000-0000-000000000000")
        {
            Debug(
                "Paste the corrected atlas UUID into "
                + "FONT_ATLAS_UUID before testing.");
        }

        gStartupStep = 0;
        gNextPageTime = 0.0;

        AdvanceStartup();
        UpdateTimer();
    }


    timer()
    {
        HandleTimer();
    }


    link_message(
        integer sender,
        integer number,
        string message,
        key id)
    {
        if(number == API_IF_NOWPLAYING)
        {
            HandleNowPlaying(message);
            return;
        }

        if(number == API_IF_STATE)
        {
            HandleState(message);
            return;
        }
    }


    changed(integer change)
    {
        if(change & CHANGED_LINK)
        {
            BuildCharacterMap();
            ShowTitle();
        }
    }


    on_rez(integer start)
    {
        llResetScript();
    }
}
