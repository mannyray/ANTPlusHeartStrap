# ANTPlusHeartStrap

In this repository we provide code for connecting your ANT+ heart strap to your garmin watch.

![](https://private-user-images.githubusercontent.com/7882414/395820577-2cdd25d2-b58a-46e6-8b7c-6f0ac7d65f98.jpeg?jwt=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJnaXRodWIuY29tIiwiYXVkIjoicmF3LmdpdGh1YnVzZXJjb250ZW50LmNvbSIsImtleSI6ImtleTUiLCJleHAiOjE3MzQzODA0NDAsIm5iZiI6MTczNDM4MDE0MCwicGF0aCI6Ii83ODgyNDE0LzM5NTgyMDU3Ny0yY2RkMjVkMi1iNThhLTQ2ZTYtOGI3Yy02ZjBhYzdkNjVmOTguanBlZz9YLUFtei1BbGdvcml0aG09QVdTNC1ITUFDLVNIQTI1NiZYLUFtei1DcmVkZW50aWFsPUFLSUFWQ09EWUxTQTUzUFFLNFpBJTJGMjAyNDEyMTYlMkZ1cy1lYXN0LTElMkZzMyUyRmF3czRfcmVxdWVzdCZYLUFtei1EYXRlPTIwMjQxMjE2VDIwMTU0MFomWC1BbXotRXhwaXJlcz0zMDAmWC1BbXotU2lnbmF0dXJlPTM3YzlmMmJhZjJlNzRjYzdhZGNiZGJkMThkOTQzYjhjMTgwYjliNjM0ZTNjOTg0ODM4ZTgwMjJlZjdlOTM4YzEmWC1BbXotU2lnbmVkSGVhZGVycz1ob3N0In0.eDS6phbJPSJw_SM1m9kkn3rWYDJmUpNE3aRQ7HjS1q0)

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

   In addition, you will have to add a `barrels.jungle` file of the format:

   ```
   # Do not hand edit this file. To make changes run the
   # "Configure Monkey Barrels" command.
    
   ANTPlusHeartRateSensor = [../ANTPlusHeartRateSensor/monkey.jungle]
   base.barrelPath = $(base.barrelPath);$(ANTPlusHeartRateSensor)
   ```

3. Adding the library code in your app. For more detail look at `sample_app/source/TestAntConnectionApp.mc`:

   Upon starting the app, we create the sensor object:
   
   ```
   function onStart(state) 
   {
      sensor = new ANTPlusHeartRateSensor.HeartStrapSensor();
   }
   ```
   
   Upon initializing the app, we create a function that will be regularly called that will pull latest sensor data every 100 milliseconds:

   ```
   timer.start( method(:onTimerTic),100,true);
   ```
   
   The function will look something like:
   ```
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
   ```
   where once connected (upon `sensor.searchingForSensor()` evaluating to `false`), we pop the latest heart beat data (if it is available) via `popLatestHeartData()` and do something with it. No information can be available if our sensor is returning the same heart beat event information (due to sensor returning information four times a second which may be more frequent than your heart rate) or we are pinging the sensor via `onTimerTic` more frequently than available information ( in our case every `100 milliseconds` compared to sensor communicating every `250 milliseconds`).   In our case, we just print some debug information via function:
   
   ```
   function debugString(heartData as ANTPlusHeartRateSensor.HeartData) as String{
      ...
   }
   ```
   to understand what data you can extract from the `HeartData` object, go to `ANTPlusHeartRateSensor/HeartData.mc`.

4. Setting up your strap to be ready for connecting to your app (something that had to be done to Garmin's Hrm-Pro Plus Heart Rate Sensor - see [pull request](https://github.com/mannyray/ANTPlusHeartStrap/pull/1) for details) by disconnecting strap from watch:

   ![](https://private-user-images.githubusercontent.com/7882414/395821089-fd22fead-be99-44ca-ba0f-f38e3cef6d8a.gif?jwt=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJnaXRodWIuY29tIiwiYXVkIjoicmF3LmdpdGh1YnVzZXJjb250ZW50LmNvbSIsImtleSI6ImtleTUiLCJleHAiOjE3MzQzODQwODUsIm5iZiI6MTczNDM4Mzc4NSwicGF0aCI6Ii83ODgyNDE0LzM5NTgyMTA4OS1mZDIyZmVhZC1iZTk5LTQ0Y2EtYmEwZi1mMzhlM2NlZjZkOGEuZ2lmP1gtQW16LUFsZ29yaXRobT1BV1M0LUhNQUMtU0hBMjU2JlgtQW16LUNyZWRlbnRpYWw9QUtJQVZDT0RZTFNBNTNQUUs0WkElMkYyMDI0MTIxNiUyRnVzLWVhc3QtMSUyRnMzJTJGYXdzNF9yZXF1ZXN0JlgtQW16LURhdGU9MjAyNDEyMTZUMjExNjI1WiZYLUFtei1FeHBpcmVzPTMwMCZYLUFtei1TaWduYXR1cmU9Y2U3MWUzYWNkMWUxZDc5OTc3ODk1Y2E0MDdlZjFjZmJkOGViMjVmM2NhZGZhNTdjOTU3ZTZmNzFhMzg0YjZmYiZYLUFtei1TaWduZWRIZWFkZXJzPWhvc3QifQ.OKzVmpy5pC2w_KlZsS2bHqJ736jNFaG9ftmO9BWs2TU)
   

5. Building, deploying and running your app. `sample_app`'s directory generates the following experience. We are printing
the current heart beat count, the time (in seconds) from app start, the heart rate according to strap, and the time difference from the previous heart beat event. To understand what data you can extract from the `HeartData` object, go to `ANTPlusHeartRateSensor/HeartData.mc`.

   ![](https://private-user-images.githubusercontent.com/7882414/395820816-62d0f419-5eea-40f2-94ec-a613c9d9a891.gif?jwt=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJnaXRodWIuY29tIiwiYXVkIjoicmF3LmdpdGh1YnVzZXJjb250ZW50LmNvbSIsImtleSI6ImtleTUiLCJleHAiOjE3MzQzODE4MDksIm5iZiI6MTczNDM4MTUwOSwicGF0aCI6Ii83ODgyNDE0LzM5NTgyMDgxNi02MmQwZjQxOS01ZWVhLTQwZjItOTRlYy1hNjEzYzlkOWE4OTEuZ2lmP1gtQW16LUFsZ29yaXRobT1BV1M0LUhNQUMtU0hBMjU2JlgtQW16LUNyZWRlbnRpYWw9QUtJQVZDT0RZTFNBNTNQUUs0WkElMkYyMDI0MTIxNiUyRnVzLWVhc3QtMSUyRnMzJTJGYXdzNF9yZXF1ZXN0JlgtQW16LURhdGU9MjAyNDEyMTZUMjAzODI5WiZYLUFtei1FeHBpcmVzPTMwMCZYLUFtei1TaWduYXR1cmU9YzFhNDQ5YjgyYTcyMGQ3NGU4YzljNzRmYWNkZGNkNzhkMzE0ZmRlNDIxMjMyOTk2MWMyYzEwY2JlYzY0NGI2ZiZYLUFtei1TaWduZWRIZWFkZXJzPWhvc3QifQ.JEm71M03bR4vLqXMo7q6Dwy33Yg8Z-w35AnaC3vUrG8)

6. Now that you have the basics, you can either build on top of the `sample_app` or import the library to your own code and continue your own adventure!

## Details and reasoning about the code

Please see this repository's [pull request](https://github.com/mannyray/ANTPlusHeartStrap/pull/1) with all of the details.
