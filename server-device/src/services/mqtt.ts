import { Watermixer, Alarmclock } from '@gbaranski/types';
import WatermixerDevice from '@/devices/watermixer';
import AlarmclockDevice from '@/devices/alarmclock';
import { convertToFirebaseDevice } from '@/services/firebase';
import { MqttClient } from 'mqtt';

export const onConnection = async (mqttClient: MqttClient, message: Buffer) => {
  const { uid, secret } = JSON.parse(message.toString('UTF-8')) as { uid: string; secret: string };

  try {
    if (!uid || !secret) throw new Error("UID or secret not defined");

    const firebaseDevice = await convertToFirebaseDevice(uid);

    switch (firebaseDevice.type) {
      case 'WATERMIXER':
        new WatermixerDevice(mqttClient, firebaseDevice, {
          ...firebaseDevice,
          data: Watermixer.SAMPLE,
          ip: '8.8.8.8', // to be changed
        });
        break;

      case 'ALARMCLOCK':
        new AlarmclockDevice(mqttClient, firebaseDevice, {
          ...firebaseDevice,
          data: Alarmclock.SAMPLE,
          ip: '8.8.8.8', // to be changed
        });
        break;

      default:
        throw new Error("failed recognizing")
        break;
    }

    console.log(`UID: ${uid} connected`);
  } catch (e) {
    console.log("Should terminate here");
    console.error(`UID: ${uid} failed due to ${e.message}`);
    return;
  }
};