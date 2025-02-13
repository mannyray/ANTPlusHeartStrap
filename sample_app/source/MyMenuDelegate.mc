using Toybox.System;
using Toybox.WatchUi;
using Toybox.Communications;

class MyMenuDelegate extends WatchUi.Menu2InputDelegate {
    var setupReadyFunction = null;
    function initialize(callback as Method(automaticCallBack as Toybox.Lang.Boolean, everyCommunicationEvent as Toybox.Lang.Boolean) as Void) {
        setupReadyFunction = callback;
        WatchUi.Menu2InputDelegate.initialize();
    }

    function onMenuItem(item) {
        if(item == :one_hundred_ping) {
            setupReadyFunction.invoke(false, false);
        }
        else if( item == :callback_approach){
            setupReadyFunction.invoke(true, false);
        }
        else if( item == :callback_approach_every){
            setupReadyFunction.invoke(true, true);
        }
        else if(item == :exit) {
            WatchUi.popView(WatchUi.SLIDE_RIGHT);
        }
    }
}