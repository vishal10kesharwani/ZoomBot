import 'package:bluetooth/utils/string_constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';

class BluetoothDeviceListEntry extends ListTile {
  final BuildContext context;
  var nodeStatus;

  BluetoothDeviceListEntry({
    super.key,
    required this.context,
    required BluetoothDevice device,
    int? rssi,
    //GestureTapCallback? onTap,
    GestureLongPressCallback? onLongPress,
    onTap,
    bool enabled = true,
  }) : super(
          onTap: onTap,
          onLongPress: onLongPress,
          enabled: enabled,
          leading: const Icon(Icons.devices),
          title: Text(device.name ?? ""),
          subtitle: buildMode == "Test"
              ? Text(device.address.toString())
              : (device.isBonded
                  ? Text("Paired", style: TextStyle(color: Colors.green))
                  : Text("Not paired", style: TextStyle(color: Colors.red))),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              rssi != null
                  ? Container(
                      margin: const EdgeInsets.all(8.0),
                      child: DefaultTextStyle(
                        style: _computeTextStyle(rssi),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            Text(rssi.toString()),
                            const Text('dBm'),
                          ],
                        ),
                      ),
                    )
                  : const SizedBox(width: 0, height: 0),
              device.isConnected
                  ? const Icon(Icons.import_export)
                  : const SizedBox(width: 0, height: 0),
              device.isBonded
                  ? GestureDetector(
                      onTap: () async {
                        print(
                            'BluetoothDeviceListEntry: Tapped on bonded icon for ${device.name}');
                        // handleTap(device);
                        // }
                      },
                      child: Container(
                          padding: const EdgeInsets.all(8.0),
                          decoration: BoxDecoration(
                            color: Colors.grey.withOpacity(0.25),
                            borderRadius: BorderRadius.circular(100),
                          ),
                          child: const Icon(Icons.link)),
                    )
                  : const SizedBox(width: 0, height: 0),
            ],
          ),
        );

  // void handleTap(BluetoothDevice device) async {
  //   print('BluetoothDeviceListEntry: Tapped on bonded icon for ${device.name}');
  //   await checkNodeStatus(device);
  // }

  static TextStyle _computeTextStyle(int rssi) {
    /**/ if (rssi >= -35) {
      return TextStyle(color: Colors.greenAccent[700]);
    } else if (rssi >= -45) {
      return TextStyle(
          color: Color.lerp(
              Colors.greenAccent[700], Colors.lightGreen, -(rssi + 35) / 10));
    } else if (rssi >= -55) {
      return TextStyle(
          color: Color.lerp(
              Colors.lightGreen, Colors.lime[600], -(rssi + 45) / 10));
    } else if (rssi >= -65) {
      return TextStyle(
          color: Color.lerp(Colors.lime[600], Colors.amber, -(rssi + 55) / 10));
    } else if (rssi >= -75) {
      return TextStyle(
          color: Color.lerp(
              Colors.amber, Colors.deepOrangeAccent, -(rssi + 65) / 10));
    } else if (rssi >= -85) {
      return TextStyle(
          color: Color.lerp(
              Colors.deepOrangeAccent, Colors.redAccent, -(rssi + 75) / 10));
    } else {
      /*code symmetry*/
      return const TextStyle(color: Colors.redAccent);
    }
  }
}
