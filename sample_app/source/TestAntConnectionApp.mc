using Toybox.Application;
using Toybox.WatchUi as Ui;
import Toybox.Lang;

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

    function debugString(heartData as ANTPlusHeartRateSensor.HeartData) as String{
        var referenceTimeDifference = ( (heartData.getRegisterTime()-startTime)/1000.0  ).format("%.2f");// in seconds
        return heartData.getCurrentBeatCount()+"-"+referenceTimeDifference+"-"+heartData.getHeartRate()+"-"+heartData.getTimeDifference();
    }

    //---------------------------------
    function onTimerTic() //every 100 milliseconds
    {
        if (sensor.searchingForSensor())
        {
            addMsg("searching...");
        }
        else
        {
            var latestHeartData = sensor.popLatestHeartData();
            if( latestHeartData != null ){
                addMsg(debugString(latestHeartData));
            }
        }
        Ui.requestUpdate();
    }

    //-------------------------------------------
    function onStart(state) 
    {
        sensor = new ANTPlusHeartRateSensor.HeartStrapSensor();
    }

    //-------------------------------------------
    function onStop(state) 
    {
        sensor.closeSensor();
    }

    //-------------------------------------------
    function getInitialView() 
    {
        return [ new TestAntConnectionView(), new TestAntConnectionDelegate() ];
    }

}
