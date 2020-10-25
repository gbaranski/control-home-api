import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:houseflow/models/device.dart';
import 'package:houseflow/models/user.dart';
import 'package:houseflow/services/auth.dart';
import 'package:houseflow/services/firebase.dart';
import 'package:houseflow/shared/device_icon.dart';
import 'package:houseflow/utils/misc.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class Settings extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<AuthService>(builder: (context, authModel, child) {
      return ListView.builder(
          itemCount: AuthService.firebaseUser.devices.length,
          itemBuilder: (context, index) {
            final FirebaseUserDevice firebaseUserDevice =
                AuthService.firebaseUser.devices[index];

            return StreamBuilder(
                stream: FirebaseService.getFirebaseDeviceSnapshot(
                    firebaseUserDevice.uid),
                builder: (BuildContext context,
                    AsyncSnapshot<DocumentSnapshot> snapshot) {
                  if (snapshot.hasError) return Text("Error occured");
                  if (snapshot.connectionState == ConnectionState.waiting)
                    return Container();
                  final Map<String, dynamic> data = snapshot.data.data();
                  final FirebaseDevice firebaseDevice =
                      FirebaseDevice.fromMap(data);

                  final subscribe = () {
                    final SnackBar snackBar = SnackBar(
                        content: Text(
                            "Success subscribing to ${firebaseDevice.uid}"));
                    FirebaseService.subscribeTopic(firebaseDevice.uid)
                        .then((_) {
                      Scaffold.of(context).showSnackBar(snackBar);
                    });
                  };

                  final unsubscribe = () {
                    final SnackBar snackBar = SnackBar(
                        content: Text(
                            "Success unsubscribing to ${firebaseDevice.uid}"));
                    FirebaseService.unsubscribeTopic(firebaseDevice.uid)
                        .then((_) {
                      Scaffold.of(context).showSnackBar(snackBar);
                    });
                  };

                  return ExpansionTile(
                    leading: DeviceIcon(firebaseDevice.type),
                    title: Text(upperFirstCharacter(firebaseDevice.type)),
                    children: [
                      const Text(
                        "Notifications",
                        style: const TextStyle(fontSize: 18),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          OutlineButton(
                            child: const Text("Subscribe"),
                            onPressed: subscribe,
                          ),
                          OutlineButton(
                            child: const Text("Unsubscribe"),
                            onPressed: unsubscribe,
                          )
                        ],
                      )
                    ],
                  );
                });
          });
    });
  }
}
