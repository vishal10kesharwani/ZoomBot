import 'dart:async';

import 'package:bluetooth/screens/all_schedules.dart';
import 'package:bluetooth/utils/string_constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

import '../utils/color_constants.dart';
import 'bluetooth_device_entry.dart';
import 'dashboard.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<BluetoothDevice> bondedDevices = [];

  BluetoothState _bluetoothState = BluetoothState.UNKNOWN;
  bool isBluetoothOn = true;
  final FlutterBluetoothSerial _bluetooth = FlutterBluetoothSerial.instance;
  StreamSubscription<BluetoothDiscoveryResult>? _streamSubscription;
  List<BluetoothDiscoveryResult> results =
      List<BluetoothDiscoveryResult>.empty(growable: true);
  bool isDiscovering = false;

  final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();

  Future<void> _getBondedDevices() async {
    try {
      List<BluetoothDevice> devices =
          await FlutterBluetoothSerial.instance.getBondedDevices();
      setState(() {
        devices = devices
            .where((device) => device.name?.startsWith(deviceName) ?? false)
            .toList();
        bondedDevices = devices;
        print("Home: Bonded Devices:${bondedDevices.length}");
      });
    } catch (ex) {
      print("Error retrieving bonded devices: $ex");
    }
  }

  @override
  void initState() {
    super.initState();
    FlutterBluetoothSerial.instance.state.then((state) {
      setState(() {
        _getBondedDevices();
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

  Future<void> checkGps() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        print('Location permissions are denied');
      } else if (permission == LocationPermission.deniedForever) {
        print("Location permissions are permanently denied");
      } else {}
    } else {}
  }

  void _startDiscovery() async {
    if (_bluetoothState != BluetoothState.STATE_ON) {
      return;
    }
    checkGps();

    await requestBluetoothConnectPermission();

    var status = await Permission.bluetoothScan.request();
    if (status == PermissionStatus.granted) {
      setState(() {
        isDiscovering = true;
      });
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
    } else {
      showDialog(
        context: context,
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
        backgroundColor: primary,
        actions: [
          IconButton(onPressed: () {}, icon: Icon(Icons.search)),
          Padding(
            padding: const EdgeInsets.only(right: 10.0),
            child: IconButton(
              tooltip: 'All device schedules',
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) {
                  return ALlSchedules();
                }));
              },
              icon: Icon(Icons.devices_other),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.all(30),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: <Widget>[
                  Expanded(
                    child: Text(
                      'Bluetooth',
                      style: TextStyle(
                        color: ColorConstants.silverMetallic,
                        fontSize: 18,
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
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 30.0, right: 30),
              child: Divider(),
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
                        "Discovered Devices",
                        style: TextStyle(
                            fontSize: 20,
                            color: ColorConstants.silverMetallicDark),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    Padding(
                      padding:
                          const EdgeInsets.only(left: 30.0, right: 30, top: 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: <Widget>[
                          Expanded(
                            child: Text(
                              'Scan devices',
                              style: TextStyle(
                                color: ColorConstants.silverMetallic,
                                fontSize: 18,
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.grey.withOpacity(0.25),
                              borderRadius: BorderRadius.circular(100),
                            ),
                            child: isDiscovering
                                ? Transform.scale(
                                    scale: 0.5,
                                    child: CircularProgressIndicator())
                                : IconButton(
                                    tooltip: "Scan",
                                    onPressed: () {
                                      _startDiscovery();
                                    },
                                    icon: Icon(Icons.sync),
                                  ),
                          ),
                        ],
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
                                            ?.startsWith(deviceName) ??
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
                            if (filteredDevices.isEmpty == false) {
                              if (index < filteredDevices.length) {
                                BluetoothDiscoveryResult result =
                                    filteredDevices[index];

                                // BluetoothDiscoveryResult result = results[index];
                                final device = result.device;
                                final address = device.address;

                                return Padding(
                                  padding: const EdgeInsets.only(
                                      left: 30, right: 30, bottom: 10),
                                  child: Card(
                                    shadowColor: Colors.black,
                                    elevation: 3,
                                    child: BluetoothDeviceListEntry(
                                        context: context,
                                        device: device,
                                        rssi: result.rssi,
                                        onTap: () {
                                          device.isBonded
                                              ? Navigator.of(context).push(
                                                  MaterialPageRoute(
                                                      builder: (context) =>
                                                          Dashboard(
                                                            device: device,
                                                          )))
                                              : null;
                                        },
                                        onLongPress: () async {
                                          try {
                                            bool bonded = false;
                                            if (device.isBonded) {
                                              print(
                                                  'Unbonding from ${device.name}...');
                                              await FlutterBluetoothSerial
                                                  .instance
                                                  .removeDeviceBondWithAddress(
                                                      address);
                                              print(
                                                  'Unpaired from ${device.name} has succed');
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(SnackBar(
                                                      content: Center(
                                                          child: Text(
                                                              "Device Un-Paired Successfully"))));
                                            } else {
                                              print(
                                                  'Pairing with ${device.name}...');
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(SnackBar(
                                                      content: Center(
                                                          child: Text(
                                                              "Pairing with ${device.name}..."))));
                                              bonded =
                                                  (await FlutterBluetoothSerial
                                                          .instance
                                                          .bondDeviceAtAddress(
                                                              address)) ??
                                                      false;
                                              print(
                                                  'Pairing with ${device.name} has ${bonded ? 'succed' : 'failed'}.');
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(SnackBar(
                                                content: Center(
                                                    child: Text(
                                                        "Device Paired Successfully")),
                                                behavior:
                                                    SnackBarBehavior.floating,
                                              ));
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
                                              context: context,
                                              builder: (BuildContext context) {
                                                return AlertDialog(
                                                  title: const Text(
                                                      'Error occurred while pairing'),
                                                  content: Text(ex.toString()),
                                                  actions: <Widget>[
                                                    TextButton(
                                                      child:
                                                          const Text("Close"),
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
                            } else {
                              if (index < filteredDevices.length) {
                                BluetoothDiscoveryResult result =
                                    BluetoothDiscoveryResult(
                                  device: bondedDevices[index],
                                  rssi: 0, // Set your desired RSSI value
                                );

                                return Padding(
                                  padding: const EdgeInsets.only(
                                      left: 30, right: 30, bottom: 10),
                                  child: Card(
                                    shadowColor: Colors.black,
                                    elevation: 3,
                                    child: BluetoothDeviceListEntry(
                                        context: context,
                                        device: bondedDevices[index],
                                        rssi: 0,
                                        onTap: () {
                                          bondedDevices[index].isBonded
                                              ? Navigator.of(context).push(
                                                  MaterialPageRoute(
                                                      builder: (context) =>
                                                          Dashboard(
                                                            device:
                                                                bondedDevices[
                                                                    index],
                                                          )))
                                              : null;
                                        },
                                        onLongPress: () async {
                                          try {
                                            bool bonded = false;
                                            if (bondedDevices[index].isBonded) {
                                              print(
                                                  'Unbonding from ${bondedDevices[index].name}...');
                                              await FlutterBluetoothSerial
                                                  .instance
                                                  .removeDeviceBondWithAddress(
                                                      bondedDevices[index]
                                                          .address);
                                              print(
                                                  'Unpaired from ${bondedDevices[index].name} has succed');
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(SnackBar(
                                                      content: Center(
                                                          child: Text(
                                                              "Device Un-Paired Successfully"))));
                                            } else {
                                              print(
                                                  'Pairing with ${bondedDevices[index].name}...');
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(SnackBar(
                                                      content: Center(
                                                          child: Text(
                                                              "Pairing with ${bondedDevices[index].name}..."))));
                                              bonded =
                                                  (await FlutterBluetoothSerial
                                                          .instance
                                                          .bondDeviceAtAddress(
                                                              bondedDevices[
                                                                      index]
                                                                  .address)) ??
                                                      false;
                                              print(
                                                  'Pairing with ${bondedDevices[index].name} has ${bonded ? 'succed' : 'failed'}.');
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(SnackBar(
                                                content: Center(
                                                    child: Text(
                                                        "Device Paired Successfully")),
                                                behavior:
                                                    SnackBarBehavior.floating,
                                              ));
                                            }
                                            setState(() {
                                              results[results.indexOf(result)] =
                                                  BluetoothDiscoveryResult(
                                                      device: BluetoothDevice(
                                                        name:
                                                            bondedDevices[index]
                                                                    .name ??
                                                                '',
                                                        address:
                                                            bondedDevices[index]
                                                                .address,
                                                        type:
                                                            bondedDevices[index]
                                                                .type,
                                                        bondState: bonded
                                                            ? BluetoothBondState
                                                                .bonded
                                                            : BluetoothBondState
                                                                .none,
                                                      ),
                                                      rssi: 0);
                                            });
                                          } catch (ex) {
                                            showDialog(
                                              context: context,
                                              builder: (BuildContext context) {
                                                return AlertDialog(
                                                  title: const Text(
                                                      'Error occurred while pairing'),
                                                  content: Text(ex.toString()),
                                                  actions: <Widget>[
                                                    TextButton(
                                                      child:
                                                          const Text("Close"),
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
                            }
                          }),
                    ),
                    SizedBox(
                      height: 20,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 30),
                      child: Text(
                        "Long press on a device card to pair, and long press on the link to unpair.",
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
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
