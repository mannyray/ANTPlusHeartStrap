using Toybox.Ant;
using Toybox.Time;
using Toybox.System as Sys;

//-----------------------------------------------------------------------------
//-----------------------------------------------------------------------------
class HeartStrapSensor extends Ant.GenericChannel 
{
    //---------------------------------

    static var rgDevType = 120;
    static var rgDevName = "HR";
    // four times a second. Maximum rate as defined in 
    // "ANT+ Device Profile HEART RATE MONITOR" document
    static var rgDevPeriod = 8070; 

    hidden var chanAssign;
    var startTime = 0;

    /*
    Two separate variables for storing incoming HeartData.
    
    The first is for interfacing with users of the HeartStrapSensor
    class where once they copy a specific heartdata via popLatestHeartData() 
    they can no longer access it again meaning they do not have
    to worry if the information is the latest - if there is latest, fresh 
    data then access it via popLatestHeartData() and otherwise get a null.
    
    The second is for internal use mainly to see track if the ant+ heart strap
    is returning the same data as previously. If it is the same data then we keep the
    previousHeartData the same and do not refresh the returnHeartData.
    */
    var returnHeartData = null;
    var previousHeartData = null;

    var searching;
    var deviceCfg;
    
    var idSearch;
    var antid=0;
    var cMsg = 0;

    //-----------------------------------------------------
    function initialize() 
    {
        addMsg("Sensor - " + rgDevName);
        idSearch = 0;
        startTime = System.getTimer();

        // Get the channel
        chanAssign = new Ant.ChannelAssignment(
            Ant.CHANNEL_TYPE_RX_NOT_TX, //!!!0
            Ant.NETWORK_PLUS);
        GenericChannel.initialize(method(:onMessage), chanAssign);

        var iTimeout = (30000 / 2.5 / 1000).toNumber()-1;
        Sys.println("iTimeout: " + iTimeout);

        // Set the configuration
        deviceCfg = new Ant.DeviceConfig( {
            :deviceNumber => idSearch,                 //Wildcard our search
            :deviceType => rgDevType,
            :transmissionType => 0,
            :messagePeriod => rgDevPeriod,
            :radioFrequency => 57,              //Ant+ Frequency
            :searchTimeoutLowPriority => iTimeout,    //Timeout in 25s
            :searchThreshold => 0} );           //Pair to all transmitting sensors
        GenericChannel.setDeviceConfig(deviceCfg);

        searching = true;
        open();
    }

    //-----------------------------------------------------
    function strStatus()
    {
        if (searching) {return("searching");}
        else {return(cMsg+"");}
    }
    
    //-----------------------------------------------------
    function open() 
    {
        // Open the channel
        var fSuccess = GenericChannel.open();
        searching = true;
        addMsg("open=" + fSuccess);
    }

    //-----------------------------------------------------
    function closeSensor() 
    {
        addMsg("closeSensor");
        GenericChannel.close();
    }

    //-----------------------------------------------------
    function popLatestHeartData() as HeartData{
        var tmp = returnHeartData;
        returnHeartData = null;
        return tmp;
    }

    //-----------------------------------------------------
    function onMessage(msg) 
    {
        //addMsg("onMessage");
        // Parse the payload
        var payload = msg.getPayload();

        if( Ant.MSG_ID_BROADCAST_DATA == msg.messageId ) 
        {
            if (searching) 
            {
                searching = false;
                // Update our device configuration primarily to see the device number of the sensor we paired to
                deviceCfg = GenericChannel.getDeviceConfig();
                antid = msg.deviceNumber;
                addMsg("connected: " + antid);
            }
            cMsg = (cMsg + 1) %1000;

            var heartData = new HeartData(payload,previousHeartData);
            if( previousHeartData != null){
                
                // we check for previousHeartData being different from new heartData
                // in case we are being sent repeat data from the ant+ strap
                if(!heartData.isEqualTo(previousHeartData)){
                    previousHeartData = heartData;
                    returnHeartData = heartData;
                    Sys.println(heartData.getDebugString(startTime));
                }
                else{
                    returnHeartData = null;
                    var currentTimeSinceStart = ( (Sys.getTimer()-startTime)/1000.0  ).format("%.2f");
                    Sys.println( currentTimeSinceStart + " -  NO UPDATE" );
                }
            }
            else{
                // only happens at the very beginning upon our first heart beat recording
                previousHeartData = heartData;
                returnHeartData = heartData;
            }
        } 
        else if(Ant.MSG_ID_CHANNEL_RESPONSE_EVENT == msg.messageId) 
        {
            if (Ant.MSG_ID_RF_EVENT == (payload[0] & 0xFF)) 
            {
                if (Ant.MSG_CODE_EVENT_CHANNEL_CLOSED == (payload[1] & 0xFF)) 
                {
                    addMsg("closed");
                    // Channel closed, re-open
                    open();
                } 
                else if( Ant.MSG_CODE_EVENT_RX_FAIL_GO_TO_SEARCH  == (payload[1] & 0xFF) ) 
                {
                    addMsg("go to search");
                    searching = true;
                }
            } 
            else 
            {
                //It is a channel response.
            }
        }
    }

}