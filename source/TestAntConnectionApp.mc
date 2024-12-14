using Toybox.Application;
using Toybox.WatchUi as Ui;

//-----------------------------------------------------------------------------
//-----------------------------------------------------------------------------
class TestAntConnectionApp extends Application.AppBase 
{
    var timer = new Ui.Timer.Timer();
    var sensor;
    var startTime = 0;

    //-------------------------------------------
    function initialize() 
    {
        AppBase.initialize();
        timer.start( method(:onTimerTic),100,true);
        startTime = System.getTimer();
    }

    //---------------------------------
    function onTimerTic() //every second
    {
        if (sensor.searching)
        {
            addMsg("searching...");
        }
        else
        {
            var latestHeartData = sensor.popLatestHeartData();
            if( latestHeartData != null ){
                addMsg(latestHeartData.getDebugString(startTime));
            }
        }
        Ui.requestUpdate();
    }

    //-------------------------------------------
    function onStart(state) 
    {
        sensor = new HeartStrapSensor();
    }

    //-------------------------------------------
    function onStop(state) 
    {
        //sensor.closeSensor();
        sensor.release();
    }

    //-------------------------------------------
    function getInitialView() 
    {
        return [ new TestAntConnectionView(), new TestAntConnectionDelegate() ];
    }

}
