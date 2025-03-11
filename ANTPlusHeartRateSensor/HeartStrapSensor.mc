using Toybox.Ant;
using Toybox.Time;
import Toybox.Lang;
typedef Method as Toybox.Lang.Method;

module ANTPlusHeartRateSensor {


    class HeartStrapError {
        hidden var registerTime as Number = 0;
        hidden var errorCode as Number = 0;
        function initialize(code as Number){
            registerTime = System.getTimer();
            errorCode = code;
        }
        function getErrorCode() as Number{
            return errorCode;
        }
        function getErrorCodeString() as String{
            if(errorCode == Ant.MSG_CODE_EVENT_RX_FAIL){
                return "MSG_CODE_EVENT_RX_FAIL";
            }
            return "unknown";
        }
        function getRegisterTime() as Number{
            return registerTime;
        }
    }


    var WILDCARD_SEARCH = 0;

    class HeartStrapSensor extends Ant.GenericChannel 
    {
        //---------------------------------

        hidden const rgDevType as Number = 120; // heart sensor
        // frequency for four times a second. Maximum rate as defined in 
        // "ANT+ Device Profile HEART RATE MONITOR" document
        hidden const rgDevPeriod as Number = 8070; 

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
        hidden var returnHeartData as HeartData or Null = null;
        hidden var previousHeartData as HeartData or Null= null;

        hidden var searching as Boolean;
        hidden var deviceCfg as Ant.DeviceConfig;
        
        hidden var antid as Number=0;

        hidden var returnEachCommunicationEvent = false;

        hidden var callbackFunction = null;

        //-----------------------------------------------------
        function initialize(id as Toybox.Lang.Number) 
        {
            // Get the channel
            var chanAssign = new Ant.ChannelAssignment(
                Ant.CHANNEL_TYPE_RX_NOT_TX, //!!!0
                Ant.NETWORK_PLUS);
            GenericChannel.initialize(method(:onMessage), chanAssign);

            var iTimeout = (30000 / 2.5 / 1000).toNumber()-1;

            // Set the configuration
            deviceCfg = new Ant.DeviceConfig( {
                :deviceNumber => id,                 
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
        //
        // callEachEvent is a boolean. If true, then we return heart data regardless if it is
        // new or not
        function setCallback(callback as Method(heartData as HeartData or HeartStrapError) as Void, callEachEvent as Toybox.Lang.Boolean) as Void{
            callbackFunction = callback;

            returnEachCommunicationEvent = callEachEvent;

            // to cancel out a potential final call to popLatestHeartData()
            returnHeartData = null;
        }

        //-----------------------------------------------------
        function searchingForSensor() as Boolean{
            return searching;
        }

        //-----------------------------------------------------
        function getDeviceId() as Number{
            return antid;
        }
        
        //-----------------------------------------------------
        function open() as Boolean
        {
            // Open the channel
            GenericChannel.open();
            searching = true;
            return true;
        }

        //-----------------------------------------------------
        function closeSensor() as Void
        {
            GenericChannel.close();
        }

        //-----------------------------------------------------
        function popLatestHeartData() as HeartData or Null{
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

                var heartData = new HeartData(payload,previousHeartData);
                    
                // we check for previousHeartData being different from new heartData
                // in case we are being sent repeat data from the ant+ strap
                if(!heartData.isEqualTo(previousHeartData)){
                    if( callbackFunction != null){
                        callbackFunction.invoke(heartData);
                    }
                    returnHeartData = heartData;
                }
                else{
                    if (returnEachCommunicationEvent and callbackFunction!=null){
                        // the data is stale, but due to returnEachCommunicationEvent,
                        // we pipe it back anyways
                        callbackFunction.invoke(heartData);
                    }
                    returnHeartData = null;
                }
                previousHeartData = heartData;
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
                    else if(Ant.MSG_CODE_EVENT_RX_FAIL  == (payload[1] & 0xFF)){
                        // see https://forums.garmin.com/developer/connect-iq/f/discussion/404209/ant-heart-strap-failing-to-receive-some-packets-in-watch-app#pifragment-1298=2 for details
                        /*
                            This is for cases when the strap is communicating but for some reason returning an error. 
                            We bubble this up to the user of this monkey barrel _if_ caller requested callback for each 
                            strap's communication's event (including errors)
                        */
                        if(!searching){
                            if(returnEachCommunicationEvent and callbackFunction!=null){
                                callbackFunction.invoke(new HeartStrapError(Ant.MSG_CODE_EVENT_RX_FAIL));
                            }
                        }
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
