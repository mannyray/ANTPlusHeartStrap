using Toybox.WatchUi as Ui;
using Toybox.System as Sys;
using Toybox.Graphics as Gfx;

//-----------------------------------------------------------------------------
//-----------------------------------------------------------------------------
var rgmsg = [""];
var cMsg = 0;

//-----------------------------------------------------
function addMsg(str)
{
    cMsg = (cMsg + 1) % 100;
    str = cMsg + ": " + str;
    Sys.println(str);
    rgmsg.add(str);
    if (rgmsg.size() > 7)
    {
        rgmsg.remove(rgmsg[0]);
    }
    Ui.requestUpdate();
}

//-----------------------------------------------------------------------------
//-----------------------------------------------------------------------------
class TestAntConnectionView extends Ui.View 
{
    var counter = 0;
    var setupReadyFunction = null;

    //-----------------------------------------------------
    function initialize(callback as Method(automaticCallBack as Toybox.Lang.Boolean, everyCommunicationEvent as Toybox.Lang.Boolean) as Void) 
    {
        setupReadyFunction = callback;
        View.initialize();
    }

    function onShow(){
        if(counter == 0){
            var menu = new Ui.Menu();
            var delegate;
            menu.setTitle("Menu");
            menu.addItem("100ms ping", :one_hundred_ping);
            menu.addItem("callback every event", :callback_approach);
            menu.addItem("callback only new event", :callback_approach_every);
            menu.addItem("Exit", :exit);
            delegate = new MyMenuDelegate(setupReadyFunction);
            Ui.pushView(menu, delegate, WatchUi.SLIDE_RIGHT);
            counter++;
        }
    }

    //-----------------------------------------------------
    function onUpdate(dc) 
    {
        dc.setColor(Gfx.COLOR_WHITE,Gfx.COLOR_BLACK);
        dc.clear();
        
        var fnt = Gfx.FONT_XTINY;
        var cyLine = dc.getFontHeight(fnt);
        var y = dc.getHeight() - cyLine*3;
        
        for (var i = rgmsg.size()-1; i >= 0; i--)
        {
            dc.drawText(dc.getWidth()/2, y, fnt, rgmsg[i], Gfx.TEXT_JUSTIFY_CENTER);
            y -= cyLine;
        }
    }

}
