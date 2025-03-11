# ANTPlusHeartStrap

In this repository we provide code for connecting your ANT+ heart strap to your garmin watch.

<center><img src="assets/watch_strap.jpeg" width=75%></center>

## Library usage:

> Note: the code in this repository was tested for Garmin Solar 955 watch and Garmin's Hrm-Pro Plus Heart Rate Sensor, so the manifest.xml in `sample_app` and `ANTPlustHeartRateSensor` directory restricts to that watch specifically. The code here should be usable for most watches, but that is for the user to explicitly test.

The library (or as Garmin calls them monkey barrels) is located in `ANTPlustHeartRateSensor`. To use the library in your project:

1. Build the `ANTPlustHeartRateSensor` project

2. Include the monkey barrel in your own project ( as `sample_app` of this repository does) by following instructions in [https://developer.garmin.com/connect-iq/core-topics/shareable-libraries/](https://developer.garmin.com/connect-iq/core-topics/shareable-libraries/). This will likely involve editing your project's `manifest.xml` to include link to the library:

   ```xml
   <iq:barrels>
           <iq:depends name="ANTPlusHeartRateSensor" version="0.0.0"/>
   </iq:barrels>
   ```
   
   and include ANT related permissions:
   
   ```xml
   <iq:permissions>
        <iq:uses-permission id="Ant"/>
        ...
    </iq:permissions>
   ```

   In addition, you will have to add a `barrels.jungle` file of the format:

   ```bash
   # Do not hand edit this file. To make changes run the
   # "Configure Monkey Barrels" command.
    
   ANTPlusHeartRateSensor = [../ANTPlusHeartRateSensor/monkey.jungle]
   base.barrelPath = $(base.barrelPath);$(ANTPlusHeartRateSensor)
   ```

3. Adding the library code in your app. For more detail look at `sample_app/source/TestAntConnectionApp.mc`:

   Upon starting the app, we create the sensor object:
   
   ```javascript
   function onStart(state) 
   {
      sensor = new ANTPlusHeartRateSensor.HeartStrapSensor(
        ANTPlusHeartRateSensor.WILDCARD_SEARCH
      );
   }
   ```
   
   `ANTPlusHeartRateSensor.WILDCARD_SEARCH` allows us to connect to the first heart strap we find - this is appropriate if you expect to run your watch app just near the one strap and thus don't care to specify. To determine your specific strap id, you can run the app in `sample_app` of this repo's root directory to see the line `4: Connected to 10248` (below) in which case you would replace `ANTPlusHeartRateSensor.WILDCARD_SEARCH` with number `10248` if wanting to connect to the specific strap.
   
   <center><img src="assets/connect.jpeg" width=50%></center>
   
   
4. Upon initializing the app, we create a function that will be regularly called that will pull latest sensor data every 100 milliseconds:

   ```javascript
   timer.start( method(:onTimerTic),100,true);
   ```
   
   The function will look something like:
   ```javascript
   function onTimerTic() //every 100 milliseconds
    {
        if (sensor.searchingForSensor())
        {
            // calls Ui.requestUpdate()
            addMsg("searching...");
        }
        else
        {
            var latestHeartData = sensor.popLatestHeartData();
            if( latestHeartData != null ){
                addMsg(debugString(latestHeartData));
            }
        }
    }
   ```
   where once connected (upon `sensor.searchingForSensor()` evaluating to `false`), we pop the latest heart beat data (if it is available) via `popLatestHeartData()` and do something with it. No information can be available if our sensor is returning the same heart beat event information (due to sensor returning information four times a second which may be more frequent than your heart rate) or we are pinging the sensor via `onTimerTic` more frequently than available information ( in our case every `100 milliseconds` compared to sensor communicating every `246 milliseconds` (`4.06Hz`)). In our case, we just print some debug information via function:
   
   ```javascript
   function debugString(heartData as ANTPlusHeartRateSensor.HeartData) as String{
      ...
   }
   ```
   to understand what data you can extract from the `HeartData` object, go to `ANTPlusHeartRateSensor/HeartData.mc`.

5. Setting up your strap to be ready for connecting to your app (something that had to be done to Garmin's Hrm-Pro Plus Heart Rate Sensor - see [pull request](https://github.com/mannyray/ANTPlusHeartStrap/pull/1) for details) by disconnecting strap from watch:

<center><img src="assets/disconnect.gif" width=75%></center>


6. Building, deploying and running your app. `sample_app`'s directory generates the following experience. We are printing
the current heart beat count, the time (in seconds) from app start, the heart rate according to strap, and the time difference from the previous heart beat event. To understand what data you can extract from the `HeartData` object, go to `ANTPlusHeartRateSensor/HeartData.mc`.
   
   <center><img src="assets/running_app.gif" width=75%></center>

7. Now that you have the basics, you can either build on top of the `sample_app` or import the library to your own code and continue your own adventure!

### Library usage addendum

The above instructions are for a setup where a separate checker that runs every `100 milliseconds` ( as defined in `timer.start( method(:onTimerTic),100,true);`) pops the latest data that has arrived from sensor via `popLatestHeartData()`. However, this may not desirable for the user if they don't want to potentially wait up to `100 milliseconds` after the data has already arrived before calling `popLatestHeartData()`. For this, we create a callback approach so that our sensor code immediately calls our desired function upon recieving fresh data. We would thus replace step (3) above with:

3. Upon starting the app, we create the sensor object:
      
   ```javascript
   function onStart(state) 
   {
      sensor = new ANTPlusHeartRateSensor.HeartStrapSensor();
      sensor.setCallback(method(:callbackFunction),returnEachCommunicationEvent);
   }
   ```
   
   where we define the callback function as
   
   ```javascript
   function callbackFunction(heartData as ANTPlusHeartRateSensor.HeartData or
        ANTPlusHeartRateSensor.HeartStrapError ) as Void{
            
        if(heartData instanceof ANTPlusHeartRateSensor.HeartStrapError){
            addMsg("Obtained Error " + heartData.getErrorCodeString());
            return;
        }
        // addMsg calls Ui.requestUpdate();
        addMsg(debugString(heartData));
    }
   ```
   
   The callback function usage is differentiated by the variable `returnEachCommunicationEvent`
   
   | `returnEachCommunicationEvent` value| Description|
   | ------------- | ------------- |
   |`false` | The sensor code will call `callbackFunction` only when the heart strap returns a new heart beat event. The sensor communicates every `246 milliseconds` and not every communication event returns a new event. When there is no new event, the strap returns the previous heart beat event (e.g. your heart rate occurs at lower frequency than every `246 milliseconds`). By setting `returnEachCommunicationEvent` to `false` we only call the `callBackFunction` when the event is new.<br/><br/> `ANTPlusHeartRateSensor.HeartStrapError` type object will never be returned.<br/><br/> Using this approach, we don't have to call a function `onTimerTic` every `100 milliseconds`, but will call `callbackFunction` only once fresh heart beat data comes in from the heart beat sensor. For a heart rate of 60 beats per minute that means that only one of the four communications (every `246 milliseconds`) will give fresh heart beat data meaning `callBackFunction` is called once a second. Thus we have reduced functions calls from 10 times a second to once a second.|
   |`true` | We now have the sensor code call the `callbackFunction` everytime the strap communicates with the watch - every `246 milliseconds`. This will include new events and repeat events. Furthermore, we can also return `ANTPlusHeartRateSensor.HeartStrapError` type objects as the strap sometimes returns an error (see [garmin forum](https://forums.garmin.com/developer/connect-iq/f/discussion/404209/ant-heart-strap-failing-to-receive-some-packets-in-watch-app#pifragment-1298=2) for details).<br/><br/> The only real use of setting `returnEachCommunicationEvent` to true is if you care to determine the exact time stamps of when the heart strap is communicating which can be determined via `heartData.getRegisterTime()`. <br/><br/>It is up to the user to determine if the `callbackFunction`'s argument is a `HeartStrapError` or `HeartData` object and if the `HeartData` object is different from the previous `HeartData` object.  |
   


# Test app

To toggle between the approaches in `sample_app`, you can fire up the app and choose the following:


| Demo⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀  | Description|
| ------------- | ------------- |
| <center><img src="assets/demo/every_100.gif" width=75%></center>  | Pinging the ANTPlusHeartRateSensor object every `100`ms to see if there is new data saved from the heart strap| 
| <center><img src="assets/demo/callback_new.gif" width=75%></center> | Setting up a call back option with `ANTPlusHeartRateSensor` to only get called with new data  | 
| <center><img src="assets/demo/callback_every.gif" width=75%></center> | Setting up a call back option with `ANTPlusHeartRateSensor` to get called back with every strap communication event (every `246`ms)   |





## Details and reasoning about the code

Please see this repository's [pull request](https://github.com/mannyray/ANTPlusHeartStrap/pull/1) with all of the details.
