
///////////////////////////////////////////////////////////////
//
// Max Modular UUID Music Engine
//
// Version 1.0 - Build 3A
//
// File: 04_Interface.lsl
//
// Build 3A
// - Owner dialog framework
// - Play / Stop
// - Volume menu
// - Ready for song pages
//
///////////////////////////////////////////////////////////////

integer API_ENGINE_PLAY  = 2100;
integer API_ENGINE_STOP  = 2101;

integer API_IF_STATE      = 3000;
integer API_IF_NOWPLAYING = 3001;

integer CHAN;
integer gListen=0;

string MAIN_MENU="MAIN";
string VOL_MENU="VOL";

string gSong="No Song";
string gArtist="";
integer gState=0;

ShowMain(key id)
{
    if(gListen) llListenRemove(gListen);
    CHAN = -1 - (integer)llFrand(2000000000.0);
    gListen = llListen(CHAN,"",id,"");

    list b=["▶ Play","■ Stop","🎵 Songs","🔊 Volume","Close"];
    llDialog(id,
        "Max Modular UUID Music Engine\n\n"
        +"Song: "+gSong+"\n"
        +"Artist: "+gArtist,
        b,CHAN);
}

ShowVolume(key id)
{
    if(gListen) llListenRemove(gListen);
    CHAN = -1 - (integer)llFrand(2000000000.0);
    gListen = llListen(CHAN,"",id,"");

    list b=["100%","80%","60%","40%","20%","Mute","Back"];
    llDialog(id,"Volume",b,CHAN);
}

default
{
    state_entry()
    {
        llSetText("■ STOPPED",<0.2,1.0,0.2>,1.0);
    }

    touch_start(integer n)
    {
        key id=llDetectedKey(0);
        if(id!=llGetOwner()) return;
        ShowMain(id);
    }

    listen(integer c,string name,key id,string msg)
    {
        if(msg=="▶ Play")
            llMessageLinked(LINK_SET,API_ENGINE_PLAY,"",id);

        else if(msg=="■ Stop")
            llMessageLinked(LINK_SET,API_ENGINE_STOP,"",id);

        else if(msg=="🔊 Volume")
        {
            ShowVolume(id);
            return;
        }
        else if(msg=="Back")
        {
            ShowMain(id);
            return;
        }
        else if(msg=="🎵 Songs")
        {
            llOwnerSay("[MMME-IF] Song browser coming in Build 3B.");
            ShowMain(id);
            return;
        }
        else if(msg=="Close")
        {
            if(gListen) llListenRemove(gListen);
            gListen=0;
            return;
        }
        else
        {
            llOwnerSay("[MMME-IF] Volume selection: "+msg+" (engine hook in next build)");
            ShowMain(id);
            return;
        }

        ShowMain(id);
    }

    link_message(integer s,integer num,string str,key id)
    {
        if(num==API_IF_STATE)
        {
            gState=(integer)str;
            if(gState==0)
                llSetText("■ STOPPED",<0.2,1.0,0.2>,1.0);
            else if(gState==1)
                llSetText("▶ "+gSong+"\n"+gArtist,<0.2,1.0,0.2>,1.0);
            else
                llSetText("❚❚ "+gSong,<1.0,1.0,0.2>,1.0);
        }
        else if(num==API_IF_NOWPLAYING)
        {
            list p=llParseStringKeepNulls(str,["|"],[]);
            if(llGetListLength(p)>=2)
            {
                gSong=llList2String(p,0);
                gArtist=llList2String(p,1);
            }
            if(gState==1)
                llSetText("▶ "+gSong+"\n"+gArtist,<0.2,1.0,0.2>,1.0);
        }
    }
}
