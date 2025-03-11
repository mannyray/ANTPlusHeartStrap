import Toybox.Lang;

module ANTPlusHeartRateSensor {

    // class for parsing and storing data that is communicated 
    // over the ant+ protocol from a heart rate chest strap.
    class HeartData {
        // "All ANT messages have an 8 byte payload" as per document  "ANT+ Device Profile HEART RATE MONITOR"
        // Here we define the indexes of the relevant information ( as defined in the document).
        hidden const PAYLOAD_HEART_RATE_INDEX as Number = 7;
        hidden const PAYLOAD_BEAT_COUNT as Number = 6;
        hidden const PAYLOAD_LATEST_BEAT_INDEX_1 as Number = 4;
        hidden const PAYLOAD_LATEST_BEAT_INDEX_2 as Number = 5;    

        // The heart chest strap has its own clock system where time
        // exists in range from 0 to 64000 and once hitting 64000,
        // resets back to 0. Time measured in milliseconds. 
        hidden const beatEventRollOverTime as Number = 64000;
        
        // current heart rate measured in beat per minutes
        // as computed by the heart strap
        hidden var currentHeartRate as Number = 0;

        // range is integers in between (and includiong) 0 to 255
        // helps differentiate between beat data. Rolls over to 0
        // once past 255.
        hidden var currentBeatCount as Number = 0;
        hidden const beatCountRollOver as Number = 255;

        /*
        Heartbeat event as measured from current heart rate clock epoch time (see definition of beatEventRollOverTime).
        Measured in milliseconds in range from (and including) 0 to beatEventRollOverTime.   
        */
        hidden var latestBeatEvent as Number = 0;
        hidden var previousBeatEvent as Number = 0;

        /*
        Based on pdf titled "ANT+ Device Profile HEART RATE MONITOR" (ANT+ being the maker of this protocol)
        R-R Interval Measurements can be computed based on substracting previousBeatEvent from latestBeatEvent.
        In this code, we call this difference timeDifferenceBeetweenBeats. A heart beat event is therefore
        interpreted as a peak event (R wave) in the electrocardiogram (ECG)
        */
        hidden var timeDifferenceBeetweenBeats as Number = 0;

        /*
        The time, in milliseconds, at which this object was created.
        This helps us have some sort of timing anchor for the heartbeat event
        even though heartBeatEvents are measured in their own timezone of range [0,beatEventRollOverTime]
        in addition to unknown sensor and communication delay.

        Defined by System's getTimer() which has the caveat (according to documentation):
        The returned value typically starts at zero on device boot and will roll over periodically.
        Assuming the timer starts at zero, this will happen ~25 days after a reboot, and every ~50 days thereafter.
        */
        hidden var registerTime as Number = 0;
        

        function initialize(payload as Lang.Array<Lang.Number>, previousHeartData as HeartData){
            // payload is assumed to be an array of length 8
            currentHeartRate = payload[PAYLOAD_HEART_RATE_INDEX];
            currentBeatCount = payload[PAYLOAD_BEAT_COUNT];
            latestBeatEvent = ((payload[PAYLOAD_LATEST_BEAT_INDEX_1] | (payload[PAYLOAD_LATEST_BEAT_INDEX_2] << 8)).toNumber() * 1000) / 1024;

            

            if ( previousHeartData == null or differenceFromPreviousBeat(previousHeartData) != 1){
                // First part of if statement:
                // Assuming this is the first recorded heart beat in our app
                // so setting the previous event to equal the current which 
                // will make the time difference to be 0.
                // Second part of if statement:
                // we are missing heartbeat data and the previousHeartData comes before
                // the actual previous heart beat data. We could do some sort of interpolation
                // here, but instead just default to zero.
                previousBeatEvent = latestBeatEvent;
            }
            else{
                previousBeatEvent = previousHeartData.getLatestBeatEvent(); 
            }

            // the value of latest beat event gets rolled over at 64 seconds ( see beatEventRollOverTime definition )
            // so therefore it is possible for a situation where previousBeatEvent is at 63500 milliseconds
            // while latestBeatEvent is at 100 milliseconds even though latestBeatEvent was the most recent event.
            var rollover = false;
            if (previousBeatEvent > latestBeatEvent){
                latestBeatEvent = latestBeatEvent + beatEventRollOverTime;
                rollover = true;
            }

            timeDifferenceBeetweenBeats = latestBeatEvent - previousBeatEvent;

            if( rollover ){
                // we correct back after a roll over as otherwise our calculation
                // will be adding beatEventRollOverTime every beatEventRollOverTime epoch
                latestBeatEvent = latestBeatEvent - beatEventRollOverTime;
            }

            registerTime = System.getTimer();
        }

        function getRegisterTime() as Number{
            return registerTime;
        }

        function getLatestBeatEvent() as Number {
            return latestBeatEvent;
        }

        function getTimeDifference() as Number {
            return timeDifferenceBeetweenBeats;
        }

        function getCurrentBeatCount() as Number {
            return currentBeatCount;
        }

        function getHeartRate() as Number {
            return currentHeartRate;
        }

        hidden function differenceFromPreviousBeat(firstBeat as HeartData) as Number{
            var previousHeartBeatCount = firstBeat.getCurrentBeatCount();
            if(previousHeartBeatCount <= currentBeatCount){
                // e.g. previousHeartBeatCount = 245 and currentBeatCount is 246
                // meaning that currentBeatCount is directly following previousBeatCount
                return currentBeatCount - previousHeartBeatCount;
            }
            else{
                // there is a rollover situation.
                // e.g previousHeartBeatCount is 255 while currentBeatCount is 0
                return currentBeatCount - previousHeartBeatCount + (beatCountRollOver + 1);
            }
        }

        function isEqualTo(heartData as HeartData) as Boolean{
            /*
            Used to compare two HeartData objects. returns boolean.
            Theoretically possible for two heart beat objects to be representing two 
            separate heart beats while having the same beat count. However,
            this would imply that the beats are over 255 beats apart (due to rollover)
            which brings into question why are we comparing such stale data anyways? We
            could refine the comparison, to on top of checking beat count,
            to also check beat events and time differences but theoretically it is possible 
            for that also to be the same.

            registerTime is not sufficient for comparison as for different times, the heart strap
            might returtn the exact same heart beat data (i.e. same heartbeatcount).
            */
            if(heartData == null){
                return false;
            }

            return heartData.getCurrentBeatCount() == getCurrentBeatCount();
        }
    }
}