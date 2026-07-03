# wms2mqtt — Warema WMS to MQTT Gateway

A standalone Docker gateway that connects **Warema WMS (WAREMA Mobile System)** radio-controlled devices to MQTT.

This allows you to:
- Discover and monitor Warema WMS devices (venetian blinds, awnings, roller shutters, motors, etc.)
- Control devices via MQTT commands (open, close, set position, tilt slats)
- Stream real-time position updates and status to any MQTT broker
- Integrate into Home Assistant, Node-RED, Tasmota, or any other MQTT-aware system

**Requirements:**
- Warema WMS Stick (radio transmitter stick) connected via USB — [learn more](https://www.warema.com/en/control-systems/radio-systems/supplementary-components/)
- MQTT broker (e.g., Mosquitto)
- Docker

## About this Gateway

**wms2mqtt** evolved from the Home Assistant Warema addon ecosystem but is now a **standalone, protocol-agnostic gateway**. It exposes Warema devices via MQTT, allowing any home automation platform to consume them.

### Background & Credits

This project builds on:
- **[warema-wms-venetian-blinds](https://www.npmjs.com/package/warema-wms-venetian-blinds)** — The core Node.js library for WMS communication (maintained by `aemm`)
- **[santam85/addon-warema-wms](https://github.com/santam85/addon-warema-wms)** — The original Home Assistant addon that pioneered Warema WMS integration
- Custom enhancements for MQTT v5, extended device type support, and weather deduplication

## Configuration

MQTT_SERVER
: MQTT server url (ie: mqtt://localhost:1883)

MQTT_USER
: Username for MQTT server authentication

MQTT_PASSWORD
: Password for MQTT server authentication

MQTT_VERSION
: MQTT Version for server connect. The default is 4 (v3.1.1) and can be modified to 3 (v3.1) and 5 (v5.0)

MQTT_CLIENTID
: MQTT Client ID. If unset, the default is 'mqttjs_' + random eight-digit number

IGNORED_DEVICES
: A comma-separated list of device ids to exclude from the results of network scanning. Any excluded device will not show up in MQTT, and the integration will ignore any status or position updates coming from it.

FORCE_DEVICES
: A comma-separated list of devices to monitor for status and position updates. The devices included in this list will be added to MQTT even
if the automatic scanning process can't detect them. Their online status will be updated whenever they are in range. You can specify a particular device type for the forced devices
using the format `DEVICE_ID:DEVICE_TYPE` for each device in the list. In case no type is specified, type 25 is assumed (radio-controlled motor). For a list of supported device types check https://www.npmjs.com/package/warema-wms-venetian-blinds.

POLLING_INTERVAL
: Default value: 30000. Time interval in ms between each request to all devices to report their position and state.  

MOVING_INTERVAL
: Default value: 1000. Minimum value: 100, Time interval between each request to a moving device to report position and state.
This applies only to covers being opened or closed, for the duration of the operation or until stopped. Set to 0 to disable.

WMS_CHANNEL, WMS_KEY, WMS_PAN_ID
: Use these parameters to configure the WMS network your devices are connected to. In order to discover the parameters, start the addon with a `PAN_ID` equal to
`FFFF`, and follow the instructions described at the WMS network parameter discovery section ([here](#wms-discovery)).

WMS_SERIAL_PORT
: Default value: `/dev/ttyUSB0`. Device path for the WMS Usb Key.

LOG_LEVEL
: Default value: `info`. Log level, one of `[error, warn, info , http , verbose , debug , silly]` (in increasing order).

### <a name="wms-discovery"></a>WMS Network parameters discovery
In order to control WMS devices, the addon must be configured with the network parameters, which can be discovered through
a brief process. You can initiate this process by starting the add-on with default parameters, or run it standalone with
a command similar to the following:
```shell
docker run -it -e WMS_PAN_ID=FFFF -e WMS_SERIAL_PORT=/dev/ttyUSB0 wms2mqtt 
```

When the `panId` configuration env parameter is set to `"FFFF"`, the stick will enter discovery mode and print out
instructions on the console on how to retrieve your network configuration using a remote.

You will see something resembling the following:
```
--------------------------------------------------------------------------------
Starting getting network parameters...
- Open the battery case of the WMS Handheld transmitter.
- Select the channel using the (+) button.
  Notice: If an unassigned channel is selected, press the (+) button for 5 s.
          As soon as the LED flashes, all channels can be selected by
          pressing the (+) button again
- Press the learn button in the battery case of the WMS Handheld
  transmitter for approx. 5 s. LEDS go green; the transmission LED flashes.
  For several seconds, the WMSHand-held transmitter plus scans the operating 
  range for devices.
- Each time when scanning stops with red LED perform steps:
  1)  When you press the control button (A), you can check WHICH target device
      was just found.
  2) If you can *not* see the output
       "*** Waving and Hello!"
     on the screen after pressing (A) another device than the WMS Stick has
     been found. Press the (C) button to switch to the next receiver.
  3) If you can see the output
       "*** Waving and Hello!"
     on the screen after pressing (A) then the WMS Stick has been found. 
     Press the STOP button to assign the WMS Stick to the channel. After 
     pressing STOP the network parameters are displayed on the screen. 
- Press Ctrl-C to abort.
```
Once the remote is in "learning mode", and you pressed the (A) button to identify devices, you should start seeing messages like:
```
*** Stick scanned by SNR 123456.
*** Stick scanned by SNR 123456.
*** Stick scanned by SNR 123456.
*** *** Waving and Hello! (requested from SNR 123456)
*** *** Waving and Hello! (requested from SNR 123456)
```
Use these logs to make sure you are using the right network channel for the intended devices. 
Once you are happy that (most of) your devices are discovered, by pressing the "stop" button on the remote, you should finally be able to see the network parameters:
```
*** WMS Network parameters successfully detected:
    Channel: 17
    PanId:   1A2B
    Key:     0123456789ABCDEF0123456789ABCDEF
- Write down and remember the network parameters.
- Briefly press the learn button on the back of WMS Handheld transmitter to
  stop the scanning process.
- Press Ctrl-C to stop program.
--------------------------------------------------------------------------------
```
At this point you have all the configuration needed to set up the gateway. Add these configuration parameters as environment variables (see Configuration section above).

You'll need to restart the container with the new configuration to initialize the WMS stick using the correct parameters. 

## Quick Start

### Docker (recommended)

\\\ash
docker run -d \
  -e MQTT_SERVER="mqtt://mosquitto:1883" \
  -e MQTT_USER="mqtt_user" \
  -e MQTT_PASSWORD="secret" \
  -e WMS_CHANNEL=17 \
  -e WMS_PAN_ID=1A2B \
  -e WMS_KEY=0123456789ABCDEF0123456789ABCDEF \
  -e WMS_SERIAL_PORT=/dev/ttyUSB0 \
  --device /dev/ttyUSB0 \
  --name wms2mqtt \
  marc-berg/wms2mqtt:latest
\\\

### Docker Compose

\\\yaml
services:
  wms2mqtt:
    image: marc-berg/wms2mqtt:latest
    environment:
      MQTT_SERVER: mqtt://mosquitto:1883
      MQTT_USER: mqtt_user
      MQTT_PASSWORD: secret
      WMS_CHANNEL: 17
      WMS_PAN_ID: 1A2B
      WMS_KEY: 0123456789ABCDEF0123456789ABCDEF
      WMS_SERIAL_PORT: /dev/ttyUSB0
    devices:
      - /dev/ttyUSB0:/dev/ttyUSB0
\\\

## Supported Device Types

The gateway discovers and controls the following Warema WMS device types:

| Type | Device |
|------|--------|
| 02 | WMS Stick / Software |
| 06 | Weather Station |
| 07 | Remote Control (+) |
| 09 | Web Control Pro |
| 20 | Plug Receiver |
| 21 | Actuator UP |
| 24 | Smart Socket |
| 25 | Radio Motor |
| 28 | LED |
| 2A | LAMAXA L50/60 |
| 2E | Actuator 230V UP |
| 63 | Web Control / Weather Station Pro |

For full API and feature documentation, see the upstream [warema-wms-venetian-blinds](https://www.npmjs.com/package/warema-wms-venetian-blinds) package.

## License

MIT

## Related Projects

- **[warema-wms-venetian-blinds](https://www.npmjs.com/package/warema-wms-venetian-blinds)** (npm) — Core WMS communication library
- **[santam85/addon-warema-wms](https://github.com/santam85/addon-warema-wms)**
- **[giannello/addon-warema-bridge](https://github.com/giannello/addon-warema-bridge)**
