using Toybox.Ant;
using Toybox.Time;
import Toybox.Lang;
typedef Method as Toybox.Lang.Method;

module ANTPlusHeartRateSensor {

    class HeartStrapSensor extends Ant.GenericChannel 
    {
        //---------------------------------

        hidden const rgDevType as Number = 120; // heart sensor
        // frequency for four times a second. Maximum rate as defined in 
        // "ANT+ Device Profile HEART RATE MONITOR" document
        hidden const rgDevPeriod as Number = 8070; 

        hidden var chanAssign as Ant.ChannelAssignment;

        hidden var startTime as Number  = 0;

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
        hidden var returnHeartData as HeartData = null;
        hidden var previousHeartData as HeartData = null;

        hidden var searching as Boolean;
        hidden var deviceCfg as Ant.DeviceConfig;
        
        hidden var idSearch as Number;
        hidden var antid as Number=0;
        hidden var cMsg as Number = 0;

        hidden var callbackFunction = null;

        //-----------------------------------------------------
        function initialize() 
        {
            idSearch = 0;
            startTime = System.getTimer();

            // Get the channel
            chanAssign = new Ant.ChannelAssignment(
                Ant.CHANNEL_TYPE_RX_NOT_TX, //!!!0
                Ant.NETWORK_PLUS);
            GenericChannel.initialize(method(:onMessage), chanAssign);

            var iTimeout = (30000 / 2.5 / 1000).toNumber()-1;

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
        // Call immediately after initialize constructor to allow for the option
        // for a user define `callback` method to be called immediately when new
        // data is recieved from the heart sensor. In the case the user, does not want 
        // an immediate callback they can then proceed with using popLatestHeartData().
        // If this function is called, then popLatestHeartData will always return null.
        //
        // If you call setCallBack with `null` as argument then immediate callback will 
        // not be used and instead user will have to rely on popLatestHeartData().
        function setCallback(callback as Method(heartData as HeartData) as Void) as Void{
            callbackFunction = callback;

            // to cancel out a potential final call to popLatestHeartData()
            returnHeartData = null;
        }

        //-----------------------------------------------------
        function searchingForSensor() as Boolean{
            return searching;
        }
        
        //-----------------------------------------------------
        function open() as Void 
        {
            // Open the channel
            GenericChannel.open();
            searching = true;
        }

        //-----------------------------------------------------
        function closeSensor() as Void
        {
            GenericChannel.close();
        }

        //-----------------------------------------------------
        function popLatestHeartData() as HeartData{
            if(callbackFunction == null){
                var tmp = returnHeartData;
                returnHeartData = null;
                return tmp;
            }
            else{
                return null;
            }
        }

        //-----------------------------------------------------
        function onMessage(msg as Ant.Message) as Void
        {
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
                }
                cMsg = (cMsg + 1) %1000;

                var heartData = new HeartData(payload,previousHeartData);
                if( previousHeartData != null){
                    
                    // we check for previousHeartData being different from new heartData
                    // in case we are being sent repeat data from the ant+ strap
                    if(!heartData.isEqualTo(previousHeartData)){
                        previousHeartData = heartData;
                        if( callbackFunction == null){
                            returnHeartData = heartData;
                        }
                        else{
                            callbackFunction.invoke(heartData);
                        }
                        
                    }
                    else{
                        returnHeartData = null;
                    }
                }
                else{
                    // only happens at the very beginning upon our first heart beat recording
                    previousHeartData = heartData;
                    if( callbackFunction == null){
                        returnHeartData = heartData;
                    }
                    else{
                        callbackFunction.invoke(heartData);
                    }
                }
            } 
            else if(Ant.MSG_ID_CHANNEL_RESPONSE_EVENT == msg.messageId) 
            {
                if (Ant.MSG_ID_RF_EVENT == (payload[0] & 0xFF)) 
                {
                    if (Ant.MSG_CODE_EVENT_CHANNEL_CLOSED == (payload[1] & 0xFF)) 
                    {
                        // Channel closed, re-open
                        open();
                    } 
                    else if( Ant.MSG_CODE_EVENT_RX_FAIL_GO_TO_SEARCH  == (payload[1] & 0xFF) ) 
                    {
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
}
