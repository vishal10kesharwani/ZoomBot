import 'dart:async';

import 'package:bluetooth/screens/all_schedules.dart';
import 'package:bluetooth/utils/string_constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:permission_handler/permission_handler.dart';

import '../utils/color_constants.dart';
import 'bluetooth_device_entry.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  BluetoothState _bluetoothState = BluetoothState.UNKNOWN;
  bool isBluetoothOn = true;
  final FlutterBluetoothSerial _bluetooth = FlutterBluetoothSerial.instance;
  StreamSubscription<BluetoothDiscoveryResult>? _streamSubscription;
  List<BluetoothDiscoveryResult> results =
      List<BluetoothDiscoveryResult>.empty(growable: true);
  bool isDiscovering = false;

  final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    FlutterBluetoothSerial.instance.state.then((state) {
      setState(() {
        _bluetoothState = state;
        isBluetoothOn = (_bluetoothState == BluetoothState.STATE_ON);
        print('bluetooth state initially is...$_bluetoothState');
      });
    });
  }

  @override
  void dispose() {
    _streamSubscription?.cancel();
    super.dispose();
  }

  Future<void> _toggleBluetooth() async {
    if (isBluetoothOn) {
      await FlutterBluetoothSerial.instance.requestEnable();
      FlutterBluetoothSerial.instance.state.then((state) {
        setState(() {
          _bluetoothState = state;
          isBluetoothOn = (_bluetoothState == BluetoothState.STATE_ON);
        });
      });
    } else {
      await FlutterBluetoothSerial.instance.requestDisable();
      FlutterBluetoothSerial.instance.state.then((state) {
        setState(() {
          _bluetoothState = state;
          isBluetoothOn = (_bluetoothState == BluetoothState.STATE_OFF);
        });
      });
    }
  }

  Future<void> requestBluetoothConnectPermission() async {
    var bluetoothConnectPermissionStatus =
        await Permission.bluetoothConnect.request();
    if (bluetoothConnectPermissionStatus != PermissionStatus.granted) {
      print('Bluetooth Connect permission not granted.');
    }
  }

  void _startDiscovery() async {
    if (_bluetoothState != BluetoothState.STATE_ON) {
      return;
    }

    await requestBluetoothConnectPermission();

    var status = await Permission.bluetoothScan.request();
    if (status == PermissionStatus.granted) {
      if (_streamSubscription == null) {
        _streamSubscription =
            FlutterBluetoothSerial.instance.startDiscovery().listen((r) {
          WidgetsBinding.instance!.addPostFrameCallback((_) {
            setState(() {
              final existingIndex = results.indexWhere(
                (element) => element.device.address == r.device.address,
              );
              print("Home: Start Discovery: $existingIndex");

              if (existingIndex >= 0) {
                results[existingIndex] = r;
              } else {
                results.add(r);
              }
            });
          });
        });

        _streamSubscription!.onDone(() {
          setState(() {
            isDiscovering = false;
          });
        });
      }
    } else {
      showDialog(
        context: scaffoldKey.currentContext!,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Permission Denied'),
            content: const Text(
                'Location permission is required for Bluetooth discovery.'),
            actions: <Widget>[
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('OK'),
              ),
            ],
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    print(results);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: ColorConstants.whiteColor,
        actions: [
          IconButton(onPressed: () {}, icon: Icon(Icons.search)),
          IconButton(
            onPressed: () {},
            icon: Icon(Icons.notifications_active_outlined),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.all(15),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: <Widget>[
                  Expanded(
                    child: Text(
                      'Bluetooth Switch',
                      style: TextStyle(
                        color: ColorConstants.silverMetallic,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Switch(
                    value: isBluetoothOn,
                    onChanged: (value) {
                      setState(() {
                        isBluetoothOn = value;
                      });
                      _toggleBluetooth();
                    },
                    activeColor: Colors.red, // Set the color when switch is on
                    inactiveThumbColor: Colors.grey,
                  ),
                  // ElevatedButton(
                  //   style: ElevatedButton.styleFrom(
                  //     shape: RoundedRectangleBorder(
                  //       borderRadius: BorderRadius.circular(20.0),
                  //     ),
                  //   ),
                  //   onPressed: _toggleBluetooth,
                  //   child: Text(
                  //     _bluetoothState == BluetoothState.STATE_OFF
                  //         ? 'OFF'
                  //         : 'ON',
                  //     style: const TextStyle(color: Colors.white),
                  //   ),
                  // ),
                ],
              ),
            ),
            const SizedBox(
              height: 10,
            ),
            Stack(
              children: <Widget>[
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    const SizedBox(
                      height: 10,
                    ),
                    Padding(
                      padding: EdgeInsets.only(top: 10),
                      child: Text(
                        " Discovered Devices",
                        style: TextStyle(
                            fontSize: 20,
                            color: ColorConstants.silverMetallicDark),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(
                      height: 30,
                    ),
                    //   discovered devices list
                    SingleChildScrollView(
                      child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: results.length,
                          itemBuilder: (BuildContext context, index) {
                            List<BluetoothDiscoveryResult> filteredDevices =
                                results
                                    .where((result) =>
                                        result.device.name
                                            ?.contains(deviceName) ??
                                        false)
                                    .toList();

                            filteredDevices.sort(
                              (a, b) => (a.device.name ?? "")
                                  .compareTo(b.device.name ?? " "),
                            );
                            // Filtering devices with a non-null name
                            List<BluetoothDiscoveryResult> nonNullNameDevices =
                                results
                                    .where(
                                        (result) => result.device.name != null)
                                    .toList();

                            // Sort the devices with a non-null name to appear at the top
                            nonNullNameDevices.sort(
                              (a, b) => (a.device.name ?? "")
                                  .compareTo(b.device.name ?? " "),
                            );
                            if (index < filteredDevices.length) {
                              BluetoothDiscoveryResult result =
                                  filteredDevices[index];

                              // BluetoothDiscoveryResult result = results[index];
                              final device = result.device;
                              final address = device.address;

                              return Padding(
                                padding:
                                    const EdgeInsets.only(left: 30, right: 30),
                                child: Card(
                                  shadowColor: Colors.black,
                                  elevation: 3,
                                  child: BluetoothDeviceListEntry(
                                      context: context,
                                      device: device,
                                      rssi: result.rssi,
                                      // onTap: () {
                                      //   Navigator.of(context)
                                      //       .pop(result.device);
                                      // },
                                      onLongPress: () async {
                                        try {
                                          bool bonded = false;
                                          if (device.isBonded) {
                                            print(
                                                'Unbonding from ${device.address}...');
                                            await FlutterBluetoothSerial
                                                .instance
                                                .removeDeviceBondWithAddress(
                                                    address);
                                            print(
                                                'Unpaired from ${device.address} has succed');
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(SnackBar(
                                                    content: Center(
                                                        child: Text(
                                                            "Device Un-Paired Successfully"))));
                                          } else {
                                            print(
                                                'Pairing with ${device.address}...');
                                            bonded =
                                                (await FlutterBluetoothSerial
                                                        .instance
                                                        .bondDeviceAtAddress(
                                                            address)) ??
                                                    false;
                                            print(
                                                'Pairing with ${device.address} has ${bonded ? 'succed' : 'failed'}.');
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(SnackBar(
                                                    content: Center(
                                                        child: Text(
                                                            "Device Paired Successfully"))));
                                          }
                                          setState(() {
                                            results[results.indexOf(result)] =
                                                BluetoothDiscoveryResult(
                                                    device: BluetoothDevice(
                                                      name: device.name ?? '',
                                                      address: address,
                                                      type: device.type,
                                                      bondState: bonded
                                                          ? BluetoothBondState
                                                              .bonded
                                                          : BluetoothBondState
                                                              .none,
                                                    ),
                                                    rssi: result.rssi);
                                          });
                                        } catch (ex) {
                                          showDialog(
                                            context:
                                                scaffoldKey.currentContext!,
                                            builder: (BuildContext context) {
                                              return AlertDialog(
                                                title: const Text(
                                                    'Error occurred while bonding'),
                                                content: Text(ex.toString()),
                                                actions: <Widget>[
                                                  TextButton(
                                                    child: const Text("Close"),
                                                    onPressed: () {
                                                      Navigator.of(context)
                                                          .pop();
                                                    },
                                                  ),
                                                ],
                                              );
                                            },
                                          );
                                        }
                                      }),
                                ),
                              );
                            }
                          }),
                    )
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
      drawer: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Drawer(
          child: ListView(
            children: <Widget>[
              UserAccountsDrawerHeader(
                decoration: BoxDecoration(color: primary),
                currentAccountPicture: SizedBox(),
                accountName: SizedBox(),
                accountEmail: SizedBox(),
              ),
              const SizedBox(
                height: 20,
              ),
              ListTile(
                leading: Icon(
                  Icons.devices,
                  color: ColorConstants.silverMetallicDark,
                ),
                title: Text(
                  'Scan devices',
                  style: TextStyle(
                      color: ColorConstants.silverMetallic,
                      fontSize: 18,
                      fontWeight: FontWeight.bold),
                ),
                onTap: isDiscovering ? null : _startDiscovery,
              ),
              ListTile(
                leading: Icon(
                  Icons.schedule_sharp,
                  color: ColorConstants.silverMetallicDark,
                ),
                title: Text(
                  'Active device schedules',
                  style: TextStyle(
                      color: ColorConstants.silverMetallic,
                      fontSize: 18,
                      fontWeight: FontWeight.bold),
                ),
                onTap: () {
                  Navigator.pop(context);

                  Navigator.push(context, MaterialPageRoute(builder: (context) {
                    return ALlSchedules();
                  }));
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// @override
// Widget build(BuildContext context) {
//   return Scaffold(
//     backgroundColor: primaryColor,
//     appBar: AppBar(
//       backgroundColor: primaryColor,
//       actions: [
//         IconButton(onPressed: () {}, icon: Icon(Icons.search)),
//         IconButton(
//           onPressed: () {},
//           icon: Icon(Icons.notifications_active_outlined),
//         ),
//       ],
//     ),
//     body: Padding(
//       padding: const EdgeInsets.all(30.0),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Padding(
//             padding: const EdgeInsets.only(bottom: 20.0),
//             child: Row(
//               children: [
//                 Expanded(
//                   child: Text(
//                     'Bluetooth Switch',
//                     style: TextStyle(
//                       color: Colors.black,
//                       fontSize: 16,
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                 ),
//                 const SizedBox(height: 20),
//                 Switch(
//                   value: true,
//                   onChanged: (value) {
//                     setState(() {
//                       isBluetoothOn = value;
//                     });
//                     _toggleBluetooth();
//                   },
//                   activeColor: Colors.red, // Set the color when switch is on
//                   inactiveThumbColor: Colors.grey,
//                 ),
//               ],
//             ),
//           ),
//           Text(
//             "All Devices",
//             style: TextStyle(fontSize: 25, fontWeight: FontWeight.w500),
//           ),
//           SizedBox(height: 20),
//           Expanded(
//             child: ListView.builder(
//               itemCount: devices.length,
//               itemBuilder: (context, index) {
//                 // Get device details
//                 final device = devices[index];
//
//                 // Check if the device name contains "Device"
//                 if (device['name'].contains(deviceName)) {
//                   return GestureDetector(
//                     onTap: () {
//                       print('Card tapped: ${device['name']}');
//                       Navigator.push(
//                           context,
//                           MaterialPageRoute(
//                               builder: (context) => Dashboard()));
//                     },
//                     child: Card(
//                       color: Colors.white, // Set background color to white
//                       shadowColor: Colors.grey.withOpacity(0.25),
//                       elevation: 3,
//                       child: ListTile(
//                         leading: CircleAvatar(
//                           backgroundImage: NetworkImage(device['image']),
//                         ),
//                         title: Text(
//                           device['name'],
//                           style: TextStyle(fontWeight: FontWeight.w500),
//                         ),
//                         subtitle: Row(
//                           children: [
//                             Container(
//                               width: 8,
//                               height: 8,
//                               decoration: BoxDecoration(
//                                 shape: BoxShape.circle,
//                                 color: device['status'] == 'Online'
//                                     ? Colors.green
//                                     : Colors.red,
//                               ),
//                               margin: EdgeInsets.only(right: 8),
//                             ),
//                             Text(
//                               device['status'],
//                               style: TextStyle(
//                                 color: device['status'] == 'Online'
//                                     ? Colors.green
//                                     : Colors.red,
//                               ),
//                             ),
//                           ],
//                         ),
//                         trailing: device['status'] == 'Online'
//                             ? Icon(Icons.bluetooth)
//                             : Icon(Icons.bluetooth_disabled),
//                       ),
//                     ),
//                   );
//                 } else {
//                   // If the device name doesn't contain "Device", return an empty container
//                   return Container();
//                 }
//               },
//             ),
//           ),
//         ],
//       ),
//     ),
//   );
// }
