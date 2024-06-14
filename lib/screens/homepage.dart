import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:bluetooth/screens/all_schedules.dart';
import 'package:bluetooth/utils/string_constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:permission_handler/permission_handler.dart';

import '../models/schedule.dart';
import '../utils/color_constants.dart';
import 'bluetooth_device_entry.dart';
import 'dashboard.dart';

List<Schedule> schedules = [];

var response;

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

  void _showSnackBar(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Center(child: Text(text)),
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> _getBondedDevices() async {
    try {
      List<BluetoothDevice> devices =
          await FlutterBluetoothSerial.instance.getBondedDevices();
      setState(() {
        devices = devices
            .where((device) => device.name?.startsWith(deviceName) ?? false)
            .toList();
        bondedDevices = devices;
        if (bondedDevices.length > 0) {
          isDiscovering = false;
        }
        print("Home: Bonded Devices:${bondedDevices.length}");
      });
    } catch (ex) {
      print("Error retrieving bonded devices: $ex");
    }
  }

  bool _isConnected = true;

  Future<void> execute(
    InternetConnectionChecker internetConnectionChecker,
  ) async {
    print('''The statement 'this machine is connected to the Internet' is: ''');
    final bool isConnected = await InternetConnectionChecker().hasConnection;
    print(
      isConnected.toString(),
    );
    print(
      'Current status: ${await InternetConnectionChecker().connectionStatus}',
    );
    final StreamSubscription<InternetConnectionStatus> listener =
        InternetConnectionChecker().onStatusChange.listen(
      (InternetConnectionStatus status) {
        switch (status) {
          case InternetConnectionStatus.connected:
            // ignore: avoid_print
            print('Data connection is available.');
            setState(() {
              _isConnected = true;
            });
            break;
          case InternetConnectionStatus.disconnected:
            // ignore: avoid_print
            print('You are disconnected from the internet.');
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text("You are disconnected from the internet."),
              behavior: SnackBarBehavior.floating,
              duration: Duration(seconds: 2),
            ));
            setState(() {
              _isConnected = false;
            });
            break;
        }
      },
    );
    await Future<void>.delayed(const Duration(minutes: 1));
    await listener.cancel();
  }

  var serviceEnabled;
  Future<void> checkInternet() async {
    await execute(InternetConnectionChecker());

    // Create customized instance which can be registered via dependency injection
    final InternetConnectionChecker customInstance =
        InternetConnectionChecker.createInstance(
      checkTimeout: const Duration(seconds: 1),
      checkInterval: const Duration(seconds: 1),
    );

    // Check internet connection with created instance
    await execute(customInstance);
  }

  @override
  void initState() {
    super.initState();
    checkInternet();
    checkGps();
    // checkLocationPermission();

    FlutterBluetoothSerial.instance.state.then((state) {
      setState(() {
        _getBondedDevices();
        _bluetoothState = state;
        isBluetoothOn = (_bluetoothState == BluetoothState.STATE_ON);
        print('bluetooth state initially is...$_bluetoothState');
      });
    });
  }

  // @override
  // void dispose() {
  //   _streamSubscription?.cancel();
  //   super.dispose();
  // }

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
    setState(() {
      isDiscovering = false;
    });
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        print('Location permissions are denied');
      } else if (permission == LocationPermission.deniedForever) {
        print("Location permissions are permanently denied");
      }
    } else {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        // Location services are disabled, show a message to enable them
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text("Location Services Disabled"),
            content: Text("Please enable location services to continue."),
            actions: [
              TextButton(
                onPressed: () async {
                  bool serviceRequested =
                      await Geolocator.openLocationSettings();
                  Navigator.of(context).pop();
                  if (!serviceRequested) {}
                },
                child: Text("Enable"),
              ),
            ],
          ),
        );
      }
    }
  }

  Future<void> checkLocationPermission() async {
    PermissionStatus status = await Permission.locationAlways.status;
    if (status != PermissionStatus.granted) {
      // Permission not granted, request it
      PermissionStatus permissionStatus =
          await Permission.locationAlways.request();
      if (permissionStatus == PermissionStatus.granted) {
        // Permission granted, check if location services are enabled
        bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
        if (!serviceEnabled) {
          // Location services are disabled, show a message to enable them
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text("Location Services Disabled"),
              content: Text("Please enable location services to continue."),
              actions: [
                TextButton(
                  onPressed: () async {
                    Navigator.of(context).pop(); // Close the dialog
                    // Request to enable location services
                    bool serviceRequested =
                        await Geolocator.openLocationSettings();
                    if (!serviceRequested) {
                      // Unable to open location settings
                      // You can show an error message or handle it accordingly
                    }
                  },
                  child: Text("Enable"),
                ),
              ],
            ),
          );
        } else {
          // Location services are enabled, you can proceed
          // with any necessary actions here
        }
      }
    } else {
      // Location permission already granted, check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        // Location services are disabled, show a message to enable them
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text("Location Services Disabled"),
            content: Text("Please enable location services to continue."),
            actions: [
              TextButton(
                onPressed: () async {
                  Navigator.of(context).pop(); // Close the dialog
                  // Request to enable location services
                  bool serviceRequested =
                      await Geolocator.openLocationSettings();
                  if (!serviceRequested) {
                    // Unable to open location settings
                    // You can show an error message or handle it accordingly
                  }
                },
                child: Text("Enable"),
              ),
            ],
          ),
        );
      } else {
        // Location services are enabled, you can proceed
        // with any necessary actions here
      }
    }
  }

  void _startDiscovery() async {
    if (_bluetoothState != BluetoothState.STATE_ON) {
      return;
    }
    await checkGps();
    // await checkLocationPermission();

    await requestBluetoothConnectPermission();

    var status = await Permission.bluetoothScan.request();
    if (status == PermissionStatus.granted) {
      // await checkLocationPermission();
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

  var connection;

  var nodeStatus;

  Future<void> checkNodeStatus(var device, String address) async {
    Navigator.of(context).push(MaterialPageRoute(
        builder: (context) => Dashboard(
              device: device,
              connection: connection,
              address: address,
            )));
    try {
      var headers = {'macid': address.toString()};
      var request = http.MultipartRequest('POST', Uri.parse(testapiNodeStatus));
      request.fields.addAll({'flags': '{"message":"Fetch node status"}'});
      request.headers.addAll(headers);
      http.StreamedResponse response = await request.send();
      response.statusCode == 404
          ? _showSnackBar(
              "Node is not registered on server, please use another device")
          : null;
      if (response.statusCode == 200) {
        print(await response);
        String responseBody = await response.stream.bytesToString();
        print("Home: Node Status Response: $responseBody");
        setState(() {
          nodeStatus = responseBody;
        });
        device.isBonded && connection != null
            ? Navigator.of(context).push(MaterialPageRoute(
                builder: (context) => Dashboard(
                      device: device,
                      connection: connection,
                      address: address,
                    )))
            : null;
      } else if (response.statusCode == 201) {
        String responseBody = await response.stream.bytesToString();
        print("Home: Node Status Response: $responseBody");
        dynamic jsonData = jsonDecode(responseBody);
        setState(() {
          nodeStatus = jsonData;
          print(nodeStatus);
        });
        device.isBonded && connection != null
            ? Navigator.of(context).push(MaterialPageRoute(
                builder: (context) => Dashboard(
                      device: device,
                      connection: connection,
                      address: address,
                    )))
            : _showSnackBar("Device connection error, please tap again");
      } else {
        _showSnackBar(
            "Node is not registered on server, please use another device");
        setState(() {
          nodeStatus = null;
        });
      }
    } on Exception catch (e) {
      // TODO
      _showSnackBar(
          "Check your internet connection or try again with another device");
    }
  }

  // Future<void> connect(BluetoothDevice device) async {
  //   try {
  //     // checkNodeStatus(device, "FC:B4:67:4E:C1:30");
  //     // await checkNodeStatus(device, "00:00:13:00:3B:E3");
  //     print('Connecting to Bluetooth: ${device.address}');
  //     _showSnackBar("Please wait: ${device.name} is connecting to server");
  //     connection = await BluetoothConnection.toAddress(device.address);
  //     setState(() {
  //       device.isConnected || device.isBonded
  //           ? isConnected = true
  //           : isConnected = false;
  //     });
  //
  //     // Listen for responses after establishing the connection
  //     await connection?.input?.listen((Uint8List data) {
  //       if (data != null) {
  //         setState(() async {
  //           response = utf8.decode(data);
  //           response = jsonDecode(response);
  //           print("Home: MacId ${response}");
  //           if (response != null) {
  //             await checkNodeStatus(device, response['mac_id']);
  //           } else {
  //             _showSnackBar(
  //                 "Node is not registered, please use another device");
  //           }
  //
  //           // await checkNodeStatus(device, "00:00:13:00:3B:E3");
  //         });
  //       }
  //       if (response == null) {
  //         setState(() {
  //           response = utf8.decode(data);
  //         });
  //       } else if (response != null) {
  //         setState(() {
  //           uploadResponse = utf8.decode(data);
  //         });
  //       }
  //
  //       print(
  //           'Home: listenForResponse : response is $response   ${response.toString()}');
  //     });
  //   } catch (e) {
  //     print('Error connecting to Bluetooth: $e');
  //
  //     _showSnackBar("Bluetooth connection error, please try again");
  //   }
  // }

  Future<void> connect(BluetoothDevice device) async {
    bool isFirstResponse = true; // Flag to track the first response

    try {
      print('Connecting to Bluetooth: ${device.address}');
      _showSnackBar("Please wait: ${device.name} is connecting to server");
      connection = await BluetoothConnection.toAddress(device.address);
      setState(() {
        device.isConnected || device.isBonded
            ? isConnected = true
            : isConnected = false;
      });

      await checkNodeStatus(device, response['mac_id']); //testing

      // Listen for responses after establishing the connection
      await connection?.input?.listen((Uint8List data) {
        if (data != null) {
          setState(() async {
            response = utf8.decode(data);
            response = jsonDecode(response);
            print("Home: MacId ${response}");
            if (response != null) {
              // Call checkNodeStatus only if it's the first response
              if (isFirstResponse) {
                await checkNodeStatus(device, response['mac_id']);
                isFirstResponse = false; // Update flag after first call
              }
            } else {
              _showSnackBar(
                  "Node is not registered, please use another device");
            }

            // Handle other response scenarios here
          });
        }
        print(
            'Home: listenForResponse : response is $response   ${response.toString()}');
      });
    } catch (e) {
      print('Error connecting to Bluetooth: $e');
      _showSnackBar("Bluetooth connection error, please try again");
    }
  }

  @override
  Widget build(BuildContext context) {
    print(results);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: primary,
        actions: [
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
                                        onTap: () async {
                                          networkCheck ? checkInternet() : null;
                                          if (networkCheck
                                              ? _isConnected == false
                                              : true) {
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(SnackBar(
                                              content: Text(
                                                  "You are not connected to Internet"),
                                              behavior:
                                                  SnackBarBehavior.floating,
                                              duration: Duration(seconds: 2),
                                            ));
                                          }
                                          connect(device).then((value) {
                                            Future.delayed(Duration(seconds: 5),
                                                () {
                                              if (response == null) {
                                                _showSnackBar(
                                                    "Node is not registered, please use another device");
                                              }
                                            });
                                          });
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
                              if (index < bondedDevices.length) {
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
                                        onTap: () async {
                                          networkCheck ? checkInternet() : null;
                                          if (networkCheck
                                              ? _isConnected == false
                                              : true) {
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(SnackBar(
                                              content: Text(
                                                  "You are not connected to Internet"),
                                              behavior:
                                                  SnackBarBehavior.floating,
                                              duration: Duration(seconds: 2),
                                            ));
                                          }
                                          connect(bondedDevices[index])
                                              .then((value) {
                                            Future.delayed(Duration(seconds: 5),
                                                () {
                                              if (response == null) {
                                                _showSnackBar(
                                                    "Node is not registered, please use another device");
                                              }
                                            });
                                          });
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
