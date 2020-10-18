import 'package:houseflow/models/device.dart';
import 'package:houseflow/models/devices/relay.dart';
import 'package:flutter/material.dart';
import 'package:houseflow/screens/devices/deviceCard.dart';
import 'package:houseflow/services/firebase.dart';
import 'package:houseflow/shared/device_actions.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:houseflow/services/mqtt.dart';
import 'package:houseflow/utils/misc.dart';
import 'package:houseflow/shared/constants.dart';
import 'dart:async';

const tenMinutesInMillis = 1000 * 10 * 60;

class Watermixer extends StatefulWidget {
  final FirebaseDevice firebaseDevice;

  Watermixer({@required this.firebaseDevice});

  @override
  _WatermixerState createState() => _WatermixerState();
}

class _WatermixerState extends State<Watermixer> {
  Timer _countdownTimer;
  String lastSignalString = "";

  void startCounting(int lastSignalTimestamp) {
    final callback = (Timer timer) {
      if (!this.mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        lastSignalString =
            durationToString(getEpochDiffDuration(lastSignalTimestamp));
      });
    };

    _countdownTimer = Timer.periodic(Duration(seconds: 1), callback);
    callback(_countdownTimer);
  }

  @override
  void dispose() {
    _countdownTimer.cancel();
    _countdownTimer = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final RelayData data = RelayData.fromJson(widget.firebaseDevice.data);
    startCounting(data.lastSignalTimestamp);

    final startMixing = () async {
      print("MQTT CONN STAT: ${MqttService.mqttClient.connectionStatus}");
      final String uid = widget.firebaseDevice.uid;
      final DeviceTopic topic = RelayData.getSendSignalTopic(uid);

      bool hasCompleted = false;
      final Future req = MqttService.sendMessage(
          topic: topic, qos: MqttQos.atMostOnce, data: null);

      req.whenComplete(() {
        hasCompleted = true;
        const snackbar = SnackBar(
          content: Text("Success mixing water!"),
          duration: Duration(milliseconds: 500),
        );
        Scaffold.of(context).showSnackBar(snackbar);
        final RelayData newDeviceData = RelayData(
            lastSignalTimestamp:
                DateTime.now().millisecondsSinceEpoch + tenMinutesInMillis);
        FirebaseService.updateFirebaseDeviceData(uid, newDeviceData.toJson());
      });
      Future.delayed(Duration(seconds: 2), () {
        if (!hasCompleted) {
          const snackbar = SnackBar(content: Text("No response from device!"));
          Scaffold.of(context).showSnackBar(snackbar);
        }
      });
    };

    final DeviceAction startMixAction = DeviceAction(
        onSubmit: startMixing,
        actionText: "Start mixing",
        icon: Icon(
          MdiIcons.showerHead,
          color: ACTION_ICON_COLOR,
          size: ACTION_ICON_SIZE,
        ));

    return DeviceCard(children: [
      SizedBox(
        height: 5,
      ),
      Text("Watermixer", style: TextStyle(fontSize: 24)),
      Divider(
        indent: 20,
        endIndent: 20,
        thickness: 1,
      ),
      Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
        Column(children: [
          Text(
            "Mixing state",
            style: TextStyle(
                fontWeight: FontWeight.w300,
                fontSize: 14,
                color: Colors.black.withOpacity(0.6)),
          ),
          Text(
              data.lastSignalTimestamp > DateTime.now().millisecondsSinceEpoch
                  ? "Mixing!"
                  : "Idle",
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.w300)),
        ]),
        Column(children: [
          Text(
            "Mixing time",
            style: TextStyle(
                fontWeight: FontWeight.w300,
                fontSize: 14,
                color: Colors.black.withOpacity(0.6)),
          ),
          Text(lastSignalString,
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.w300)),
        ]),
      ]),
      DeviceActions(deviceActions: [startMixAction]),
    ]);
  }
}
