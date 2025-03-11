using Toybox.Application;
using Toybox.WatchUi as Ui;
import Toybox.Lang;

//-----------------------------------------------------------------------------
//-----------------------------------------------------------------------------
class TestAntConnectionApp extends Application.AppBase 
{
    var searchTimer = new Ui.Timer.Timer();
    var pingTimer = new Ui.Timer.Timer();
    var sensor;
    var startTime = 0;

    var previousBeatNumber = null;

    var isAutomaticCallBackEnabled = false;
    var forCallBackreturnEachCommunicationEvent = false;
    var menuBeingDecidedOn = true;

    //-------------------------------------------
    function initialize() 
    {
        AppBase.initialize();
    }

    function setup(automaticCallBack as Boolean, everyCommunicationEvent as Boolean){
        isAutomaticCallBackEnabled = automaticCallBack;
        forCallBackreturnEachCommunicationEvent = everyCommunicationEvent;

        sensor = new ANTPlusHeartRateSensor.HeartStrapSensor(ANTPlusHeartRateSensor.WILDCARD_SEARCH);
        if(isAutomaticCallBackEnabled){
            sensor.setCallback(method(:callbackFunction),forCallBackreturnEachCommunicationEvent);
        }
        searchTimer.start( method(:onSearchTimerTic),100,true);

        if(isAutomaticCallBackEnabled == false){
            pingTimer.start( method(:sensorPingTimer),100,true);
        }
        startTime = System.getTimer();
    }
    
    function callbackFunction(heartData as ANTPlusHeartRateSensor.HeartData or
        ANTPlusHeartRateSensor.HeartStrapError ) as Void{
            
        if(heartData instanceof ANTPlusHeartRateSensor.HeartStrapError){
            addMsg("Obtained Error " + heartData.getErrorCodeString());
            return;
        }
        // addMsg calls Ui.requestUpdate();
        addMsg(debugString(heartData));
    }
    

    function debugString(heartData as ANTPlusHeartRateSensor.HeartData) as String{
        var referenceTimeDifference = ( (heartData.getRegisterTime()-startTime)/1000.0  ).format("%.2f");// in seconds
        var hrv = heartData.getTimeDifference();
        var beatCount = heartData.getCurrentBeatCount();
        var heartRate = heartData.getHeartRate();
        var message = beatCount+"-"+referenceTimeDifference+"-"+heartRate+"-"+hrv;
        if(previousBeatNumber!=null){
            if(previousBeatNumber == beatCount){
                //data is repeat from previous call
                message = "repeat info";
            }
        }
        previousBeatNumber = beatCount;
        return message;

    }

    function sensorPingTimer(){
        if (!sensor.searchingForSensor())
        {
            var latestHeartData = sensor.popLatestHeartData();
            if( latestHeartData != null ){
                addMsg(debugString(latestHeartData));
            }
            else{
                addMsg("no new info");
            }
        }
    }

    //---------------------------------
    function onSearchTimerTic() //every 100 milliseconds
    {
        if (sensor.searchingForSensor())
        {
            // calls Ui.requestUpdate()
            addMsg("searching...");
        }
        else{
            addMsg("Connected to "+sensor.getDeviceId());
            searchTimer.stop();
        }
    }

    //-------------------------------------------
    function onStart(state) 
    {
        
    }

    //-------------------------------------------
    function onStop(state) 
    {
        sensor.closeSensor();
    }

    //-------------------------------------------
    function getInitialView() 
    {
        return [ new TestAntConnectionView(method(:setup)), new TestAntConnectionDelegate() ];
    }

}
