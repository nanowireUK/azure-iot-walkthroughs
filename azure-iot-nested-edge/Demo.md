## Demo prep

* Open SSH to all three Edges
* Open IoT Hub browser
* Open Visual Studio Code
* Restart the simulated temperature sensor on L4
* Set the twin to false on L3 and restart sensor module
* Check messages coming through
`dotnet run --project /home/phil/Code/Microsoft/azure-iot-samples-csharp/iot-hub/Quickstarts/read-d2c-messages'

## Demo script

* Slide from first screen
    * Introduce setup
    * Networking zones
    * Internet access

* Video feed of set up
    * Show physical device
    * Show data coming through
    > Can we see what is actually running on the devices?

* Console windows screen    
    * Show the modules that are running on the various devices
    > What did you need to do to get them configured to work like this?
    * Show the config.yaml on L4
    > That makes sense on the device side, but how does it look in the IoT Hub?

* Show the IoT Hub
    * Show the three devices
    * Point out connected device count
    * Go into L4 and show the parent relationship
    > You mentioned the deployment manifests. How are the built up for nested edge?

* Show Visual Studio Code
    * Go through the manifests and layers
    * Show the devices in the IoT Hub extension
    > Does this mean we can send data and commands down to the nested edge devices?
    * **Turn on the L3 data feed**
    > So will we see data coming through from both devices now?

* Video feed of set up
    * Show the new L3 data coming through
    * Explain the hops it is making
    > What happens if the network connection is interupted?
    * Unplug L4 to show store and forward
    * Explain what is happening
    * Reconnect and show both data streams resuming

* MQTT Broker
    > So that is the Nested Edge part, how about MQTT Broker?
    * Show the extra layer manifest to get this working
    * Start the sub client and then pub client on custom test topic
    > Do we see that data going through to the IoT Hub?
    * Show that it doesn't and change the pub client to new topic
    * Show the data coming through