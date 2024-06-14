import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:bluetooth/screens/new_schedule.dart';
import 'package:bluetooth/utils/color_constants.dart';
import 'package:bluetooth/utils/string_constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:http/http.dart' as http;
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:intl/intl.dart';

import '../data/database_helper.dart';
import '../models/schedule.dart';

var device1;
var epoch;
bool isUploaded = false;
var response;
var uploadResponse;
var isConnected = true;
var nodeStatus, nodeData;
var isSchedule = true;
var isNodeOnline = true;
bool manual = false;

enum SingingCharacter { D1, D2 }

List<ContainerData> containerDataList = [];

String userName = '';
List<Schedule> uniqueSchedules = [];
List<Schedule> schedules = [];

class Dashboard extends StatefulWidget {
  final BluetoothDevice device;
  dynamic connection;

  var address;
  Dashboard({Key? key, required this.device, this.connection, this.address})
      : super(key: key);

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  BluetoothConnection? connection;

  List<int?> receivedParameters = [];
  List<int?> paramVal = [];
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
            if (_isConnected == false) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text("You are not connected to Internet"),
                behavior: SnackBarBehavior.floating,
                duration: Duration(seconds: 2),
              ));
            }
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

  void getSchedules() async {
    Services service = Services();
    await service.getAllSchedule().then((value) {
      print("Dashboard : ${value}");
      uniqueSchedules.clear();
      setState(() {
        schedules = value;
        print("Records:$schedules");
        removeDuplicateRecords();
      });
    });
    setState(() {});
  }

  void getUniqueSchedules() async {
    setState(() {
      uniqueSchedules = uniqueSchedules;
    });
  }

  void removeDuplicateRecords() {
    for (int i = 0; i < schedules.length; i++) {
      bool isDuplicate = false;
      for (int j = i + 1; j < schedules.length; j++) {
        if (schedules[i].time == schedules[j].time &&
            schedules[i].action == schedules[j].action &&
            schedules[i].day == schedules[j].day) {
          isDuplicate = true;
          break;
        }
      }
      if (!isDuplicate) {
        uniqueSchedules
            .add(schedules[i]); // Add unique schedule to the new list
      }
    }
    setState(() {
      schedules =
          uniqueSchedules; // Update schedules with the new list of unique schedules
    });
  }

  void deleteAllSchedules() async {
    Services service = Services();
    await service.deleteAllSchedule(widget.device.name).then((value) {
      setState(() {
        getSchedules();
        print("Records:$schedules");
      });
    });
    setState(() {});
  }

  @override
  void dispose() {
    connection?.cancel();
    super.dispose();
  }

  Future<void> connect() async {
    try {
      if (connection?.isConnected == false) {
        connection = await BluetoothConnection.toAddress(widget.device.address);
      }
      print("Dashboard: Connection : ${connection?.isConnected}");
      setState(() {
        connection!.isConnected ? isConnected = true : isConnected = false;
      });
      if (connection != null) {
        if (connection!.isConnected) {
          setState(() {
            isConnected = true;
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text("Connected to ${widget.device.name} ..."),
              behavior: SnackBarBehavior.floating,
              duration: Duration(seconds: 1),
            ));
          });
        }
      }
      await connection?.input?.listen((Uint8List data) {
        print('Received raw data: $data');
        if (response == null) {
          setState(() {
            response = utf8.decode(data);
          });
        } else if (response != null) {
          setState(() {
            uploadResponse = utf8.decode(data);
          });
        } else {
          return;
        }
        print(
            'listenForResponse : response is $response   ${uploadResponse.toString()}');
      });
    } catch (e) {
      print('Error connecting to Bluetooth');
    }
  }

  Future<void> sendMessage(String message) async {
    connection?.output.add(Uint8List.fromList(utf8.encode(message + "\r\n")));
  }

  void listenForResponse() {
    connection?.input?.listen((Uint8List data) {
      print('Received raw data: $data');

      if (response == null) {
        setState(() {
          response = utf8.decode(data);
        });
      } else if (response != null) {
        setState(() {
          uploadResponse = utf8.decode(data);
        });
      } else {
        return;
      }

      print(
          'listenForResponse : response is $response   ${uploadResponse.toString()}');

      // Map<String, String> jsonObject = jsonDecode(response);
      // print(
      //     'listenForResponse : jsonObject is ${jsonObject['mac_id'].toString() + " " + widget.device.address.toString()} ');
    });
  }

  Future<void> updateAll() async {
    if (response == uploadResponse) {
      setState(() {
        isUploaded = true;
        Services service = Services();
        service.updateAllSchedule(widget.device.name.toString()).then((_) {
          print("Schedules updated successfully");
        }).catchError((error) {
          print("Error updating schedules: $error");
        });
      });
    }
  }

  Future<void> fetchNodeData() async {
    print("Dashboard: response: $response");
    http.Response response1 = await http.get(
      Uri.parse(testapiUrl),
      headers: {'macid': widget.address.toString()},
      // headers: {'macid': "00:00:13:00:3B:E3"},
    );
    if (response1.statusCode == 200) {
      Map<String, dynamic> data = json.decode(response1.body);
      print('Dashboard: Api Response: ${data}');
      setState(() async {
        nodeData = data;
        if (connection != null &&
            connection!.isConnected &&
            (response != null || uploadResponse != null)) {
          sendMessage(generateJsonString(containerDataList, 6)).then((value) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              margin: EdgeInsets.only(left: 10, right: 10, bottom: 5),
              behavior: SnackBarBehavior.floating,
              content: Center(
                  child: Text(
                "Config Uploded Successfully, please reconnect device by tapping on device name after some seconds.",
                textAlign: TextAlign.center,
              )),
            ));
          });

          // if (uploadResponse != null) {
          //   setState(() {
          //     uploadResponse = jsonDecode(uploadResponse);
          //   });
          //   ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          //     margin: EdgeInsets.only(left: 10, right: 10, bottom: 5),
          //     behavior: SnackBarBehavior.floating,
          //     content: Center(
          //         child: Text(
          //             jsonDecode(uploadResponse['message']).toString())),
          //   ));
          // }
        } else {
          await connectConfig(context);
          print("Bluetooth connection is not established.");
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              margin: EdgeInsets.only(left: 10, right: 10, bottom: 5),
              behavior: SnackBarBehavior.floating,
              content: Center(
                  child: Text("Bluetooth connection is not established."))));
        }
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("Node is not online, please Reconfig node"),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 2),
      ));
      throw Exception('Failed to fetch data: ${response1.statusCode}');
    }
  }

  late StreamController<DateTime> _timeStreamController;
  late Stream<DateTime> _timeStream;
  var apiData;

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
    getSchedules();
    setState(() {
      connection = widget.connection;
    });

    print("Dashboard: Initial Connection: ${widget.connection.isConnected}");
    checkInternet();
    print("Dashboard: Network check: ${networkCheck.toString()}");

    setState(() {
      getSchedules();
      device1 = widget.device;
      widget.device.isConnected ? isConnected = true : isConnected = false;
      containerDataList = containerDataList;
    });
    _timeStreamController = StreamController<DateTime>();
    _timeStream = _timeStreamController.stream;
    // Emit the current time periodically (every second)
    _timeStreamController.addStream(Stream.periodic(Duration(seconds: 1), (_) {
      return DateTime.now();
    }));
    // Dispose the stream controller when the widget is disposed
    _timeStreamController.onCancel = () {
      _timeStreamController.close();
    };
  }

  String time12to24Format(String time) {
    // Split the time string
    List<String> parts = time.split(RegExp(r'[:\s]'));

    // Check if hour and minute are without zero padding
    String hourString = parts[0];
    String minuteString = parts[1];

    // Remove zero padding if present
    if (hourString.startsWith('0')) {
      hourString = hourString.substring(1);
    }
    if (minuteString.startsWith('0')) {
      minuteString = minuteString.substring(1);
    }

    // Parse hour, minute, and meridium
    int h = int.parse(hourString);
    int m = int.parse(minuteString);
    String meridium = parts[2].toLowerCase();

    // Convert to 24-hour format
    if (meridium == "pm" && h != 12) {
      h += 12;
    } else if (meridium == "am" && h == 12) {
      h = 0;
    }

    // Format hour and minute strings with zero padding if needed
    hourString = h.toString().padLeft(2, '0');
    minuteString = m.toString().padLeft(2, '0');

    // Construct the new time string
    String newTime = "$hourString:$minuteString";
    print(newTime);
    return newTime;
  }

  String generateJsonString(
      List<ContainerData?> containerDataList, int mode_key) {
    Map<String, dynamic> scheduler = {};
    Map<String, dynamic> config = {};

    // Get current date and time
    DateTime now = DateTime.now();
    String day1 = DateFormat('EEE').format(now);
    String currentTime = DateFormat('HH:mm').format(now);
    DateTime dateTime = DateFormat('yyyy-MM-dd HH:mm:ss').parse(now.toString());

    // Convert the DateTime object to UTC
    DateTime utcDateTime = dateTime.toLocal();

    // Calculate the epoch value in seconds
    int epochTimeInSeconds =
        (utcDateTime.millisecondsSinceEpoch ~/ 1000) + 19800;
    // epochTimeInSeconds += 19800;

    // Print the epoch time
    print('Epoch time in seconds: $epochTimeInSeconds');

    // Iterate over containerDataList
    getSchedules();
    schedules.forEach((scheduleData) {
      if (scheduleData != null &&
          scheduleData.status != "0" &&
          scheduleData.device_name == widget.device.name) {
        String time24HourFormat = time12to24Format(scheduleData.time);

        // Create keys for both pins
        String keyPin1 = "${scheduleData.day}-${time24HourFormat}-D1";
        String keyPin2 = "${scheduleData.day}-${time24HourFormat}-D2";

        print(keyPin1); // Print the keys for debugging purposes
        print(keyPin2);

        // Calculate epoch value only if the day matches the current day
        if (day1.toUpperCase() == scheduleData.day) {
          int epoch = calculateEpochFromDateAndTime(now, now);
        }

        // Construct value for the keys
        dynamic value = (scheduleData.action == "true") ? "ON" : "OFF";

        // Insert key-value pairs for both pins
        scheduler[keyPin1] = value;
        scheduler[keyPin2] = value;
      }
    });

    // var statusCode;
    // setState(() {
    //   statusCode = nodeStatus['data']['status'];
    //   print(statusCode);
    // });
    // var mode_key = 5;
    // setState(() {
    //   statusCode = nodeData['data']['mode_key'];
    //   print(statusCode);
    // });

    // var statusCode = 3;
    var action;
    if (mode_key == 5) {
      action = "update_schedule";
    } else if (mode_key == 6) {
      action = "update_config_file";
    }

    // Add scheduler and rtc_sync to config map
    config['scheduler'] = scheduler;
    config['rtc_sync'] = epochTimeInSeconds;

    // Construct final JSON object
    Map<String, dynamic> jsonObject = {
      'action': action,
      'config_file': {
        'bootup': mode_key == 5 ? {} : nodeData['data']['bootup'],
        'config': mode_key == 5 ? config : nodeData['data']['config'],
      }
    };

    print(jsonEncode(jsonObject));
    return json.encode(jsonObject);
  }

  String generateManualJsonString(int mode_key) {
    var action;
    if (mode_key == 5) {
      action = "update_schedule";
    } else if (mode_key == 6) {
      action = "update_config_file";
    } else if (mode_key == 7) {
      action = "update_manual";
    }

    Map<String, dynamic> manualJsonObject = {
      'action': action,
      'config_file': {
        'P1': manual ? 'ON' : 'OFF', // Adjust as needed
        'P2': manual ? 'ON' : 'OFF', // Adjust as needed
      }
    };
    print(jsonEncode(manualJsonObject));
    return json.encode(manualJsonObject);
  }

  int calculateEpochFromDateAndTime(
      DateTime currentDate, DateTime currentTime) {
    // Get the current time's hour and minute
    int currentHour = currentTime.hour;
    int currentMinute = currentTime.minute;

    // Create a DateTime object for the current date and time
    DateTime currentDateTime = DateTime(
      currentDate.year,
      currentDate.month,
      currentDate.day,
      currentHour,
      currentMinute,
    );

    // Calculate the difference in milliseconds between the current date and time and the epoch date (January 1, 1970)
    int epochMilliseconds = currentDateTime.millisecondsSinceEpoch;

    // Convert milliseconds to seconds and return the epoch value
    int epochSeconds = epochMilliseconds ~/ 1000;
    return epochSeconds;
  }

  Icon syncIcon = isUploaded
      ? Icon(Icons.sync,
          color: Colors.green) // Change to green color and synced icon
      : const Icon(Icons.sync_disabled, color: Colors.red);

  Future<void> connectAndSendMessage(BuildContext context) async {
    // Maximum number of retries
    const int maxRetries = 2;
    int retryCount = 0;

    while (retryCount < maxRetries) {
      try {
        await connect(); // Attempt connection
        await sendMessage(
            generateJsonString(containerDataList, 5)); // Send message
        if (uploadResponse != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              margin: EdgeInsets.only(left: 10, right: 10, bottom: 5),
              behavior: SnackBarBehavior.floating,
              content: Center(child: Text("Data Uploaded successfully")),
            ),
          );
          updateAll();
        }
        // Update all data
        return; // Exit function if successful
      } catch (error) {
        print('Connection failed. Retrying... Attempt $retryCount');
        retryCount++;
      }
    }

    // Show error message if maximum retries reached
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        margin: EdgeInsets.only(left: 10, right: 10, bottom: 5),
        behavior: SnackBarBehavior.floating,
        content: Center(child: Text("Failed to connect and send data")),
      ),
    );
  }

  Future<void> connectConfig(BuildContext context) async {
    // Maximum number of retries
    const int maxRetries = 2;
    int retryCount = 0;

    while (retryCount < maxRetries) {
      try {
        await connect(); // Attempt connection
        await sendMessage(
            generateJsonString(containerDataList, 6)); // Send message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            margin: EdgeInsets.only(left: 10, right: 10, bottom: 5),
            behavior: SnackBarBehavior.floating,
            content: Center(
                child: Text(
              "Config Uploded Successfully, please reconnect device by tapping on device name after some seconds.",
              textAlign: TextAlign.center,
            )),
          ),
        );
        updateAll(); // Update all data
        return; // Exit function if successful
      } catch (error) {
        print('Connection failed. Retrying... Attempt $retryCount');
        retryCount++;
      }
    }

    // Show error message if maximum retries reached
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        margin: EdgeInsets.only(left: 10, right: 10, bottom: 5),
        behavior: SnackBarBehavior.floating,
        content: Center(child: Text("Failed to connect and send data")),
      ),
    );
  }

  Future<void> connectAndSendManual(BuildContext context) async {
    // Maximum number of retries
    const int maxRetries = 2;
    int retryCount = 0;

    while (retryCount < maxRetries) {
      try {
        await connect(); // Attempt connection
        await sendMessage(generateManualJsonString(7)); // Send message
        if (uploadResponse != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              margin: EdgeInsets.only(left: 10, right: 10, bottom: 5),
              behavior: SnackBarBehavior.floating,
              content: Center(child: Text("Manual Update Success")),
            ),
          );
          updateAll();
        }
        // Update all data
        return; // Exit function if successful
      } catch (error) {
        print('Connection failed. Retrying... Attempt $retryCount');
        retryCount++;
      }
    }

    // Show error message if maximum retries reached
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        margin: EdgeInsets.only(left: 10, right: 10, bottom: 5),
        behavior: SnackBarBehavior.floating,
        content: Center(child: Text("Failed to connect and update manual")),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    SingingCharacter? _character = SingingCharacter.D1;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: primary,
        leading: IconButton(
          padding: const EdgeInsets.only(left: 20.0, top: 10),
          icon: Icon(Icons.arrow_back_ios),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Padding(
          padding: EdgeInsets.only(top: 20.0, bottom: 10),
          child: Text(
            "Scheduled charts",
            textAlign: TextAlign.start,
            style: TextStyle(
              color: Colors.black,
              fontSize: 25,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        actions: [
          StreamBuilder<DateTime>(
            stream: _timeStream,
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                String formattedTime =
                    DateFormat('hh:mm:ss').format(snapshot.data!);
                return Padding(
                  padding:
                      const EdgeInsets.only(right: 20.0, top: 20, bottom: 10),
                  child: Text(
                    "$formattedTime",
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 18,
                    ),
                  ),
                );
              } else {
                return Text(
                    'Loading...'); // Placeholder text while waiting for data
              }
            },
          )
        ],
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 30.0, left: 80, right: 80),
        child: GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => NewSchedule(device: widget.device),
              ),
            ).then((value) {
              setState(() {
                getSchedules();
                // isUploaded = false;
              });
            });
          },
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30),
              color: primary.withOpacity(0.05),
              border: Border.all(color: primary, width: 0.2),
            ),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FloatingActionButton(
                    shape: const CircleBorder(),
                    backgroundColor: primary,
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              NewSchedule(device: widget.device),
                        ),
                      ).then((value) {
                        setState(() {
                          isUploaded = false;
                          getSchedules();
                        });
                      });
                    },
                    child: const Icon(
                      Icons.add,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(
                    width: 10,
                  ),
                  const Text(
                    "Add Schedule",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              child: Container(
                color: primary,
                width: double.infinity,
                child: Padding(
                  padding: const EdgeInsets.only(left: 10.0, right: 10),
                  child: Column(
                    children: [
                      const SizedBox(
                        height: 20,
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(
                              bottom: 10,
                            ),
                            child: Container(
                              padding: EdgeInsets.symmetric(horizontal: 10),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(30),
                                border:
                                    Border.all(color: Colors.black, width: 1),
                              ),
                              height: 40,
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  Icon(
                                    connection!.isConnected
                                        ? Icons.bluetooth_connected
                                        : Icons.bluetooth_disabled,
                                    color: connection!.isConnected
                                        ? Colors.green
                                        : Colors.red,
                                  ),
                                  const SizedBox(
                                    width: 5,
                                  ),
                                  GestureDetector(
                                    onTap: () {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(SnackBar(
                                        content: Text(
                                            "Connecting to ${widget.device.name} ..."),
                                        behavior: SnackBarBehavior.floating,
                                        duration: Duration(seconds: 1),
                                      ));
                                      connect();
                                    },
                                    child: Text(
                                      "${(widget.device.name?.length)! > 5 ? widget.device.name?.substring(0, 6) : widget.device.name} ",
                                      style: const TextStyle(
                                        color: Colors.black,
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  Icon(
                                    isUploaded
                                        ? Icons.sync
                                        : Icons.sync_disabled,
                                    color:
                                        isUploaded ? Colors.green : Colors.red,
                                  ),
                                  buildMode == "Test"
                                      ? const VerticalDivider(
                                          color: Colors.black,
                                        )
                                      : SizedBox(),
                                  buildMode == "Test"
                                      ? IconButton(
                                          onPressed: () {
                                            networkCheck
                                                ? checkInternet()
                                                : null;
                                            // if (isConnected) {
                                            // networkCheck
                                            //     ?
                                            fetchNodeData().then((value) {
                                              if (nodeData['data']
                                                      ['mode_key'] ==
                                                  5) {
                                                sendMessage(generateJsonString(
                                                    containerDataList, 6));
                                              }
                                            });
                                            // : ScaffoldMessenger.of(context)
                                            //     .showSnackBar(const SnackBar(
                                            //     content: Text("Network check if off"),
                                            //     behavior: SnackBarBehavior.floating,
                                            //     duration: Duration(seconds: 2),
                                            //   ));
                                            // } else {
                                            //   ScaffoldMessenger.of(context)
                                            //       .showSnackBar(SnackBar(
                                            //     content:
                                            //         Text("You are not connected to internet"),
                                            //     behavior: SnackBarBehavior.floating,
                                            //     duration: Duration(seconds: 2),
                                            //   ));
                                            // }
                                          },
                                          icon: Icon(Icons.refresh),
                                          style: ButtonStyle(
                                            overlayColor: MaterialStateProperty
                                                .resolveWith<Color?>(
                                              (Set<MaterialState> states) {
                                                if (states.contains(
                                                    MaterialState.pressed)) {
                                                  return Colors.grey.withOpacity(
                                                      0.5); // Color when pressed
                                                }
                                                return null; // Use default color when not pressed
                                              },
                                            ),
                                            foregroundColor:
                                                MaterialStateProperty.all(
                                                    Colors.black),
                                          ),
                                        )
                                      : SizedBox(),
                                  const VerticalDivider(
                                    color: Colors.black,
                                  ),
                                  Transform.scale(
                                    scale: 1.0,
                                    child: Switch(
                                      value: manual,
                                      onChanged: (bool value) async {
                                        setState(() {
                                          manual = value;
                                        });
                                        if (connection != null &&
                                            connection!.isConnected) {
                                          // connect();
                                          sendMessage(
                                                  generateManualJsonString(7))
                                              .then((value) {
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(const SnackBar(
                                              margin: EdgeInsets.only(
                                                  left: 10,
                                                  right: 10,
                                                  bottom: 5),
                                              behavior:
                                                  SnackBarBehavior.floating,
                                              content: Center(
                                                  child: Text(
                                                      "Manual Update Success")),
                                            ));
                                          });
                                          updateAll().then((value) {
                                            setState(() {
                                              isUploaded = true;
                                            });
                                          });
                                          print(
                                              "Dashboard: Manual update success");
                                        } else {
                                          await connectAndSendManual(context);

                                          print(
                                              "Bluetooth connection is not established.");
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(const SnackBar(
                                                  margin: EdgeInsets.only(
                                                      left: 10,
                                                      right: 10,
                                                      bottom: 5),
                                                  behavior:
                                                      SnackBarBehavior.floating,
                                                  content: Center(
                                                      child: Text(
                                                          "Bluetooth connection is not established."))));
                                        }
                                      },
                                      activeColor: Colors.white,
                                      activeTrackColor: Colors.deepOrange,
                                      inactiveThumbColor: Colors.black,
                                      inactiveTrackColor: primary,
                                    ),
                                  ),
                                  SizedBox(width: 5),
                                  manual
                                      ? const Tooltip(
                                          showDuration:
                                              Duration(milliseconds: 200),
                                          message: 'On',
                                          child: Text(
                                            "ON",
                                            style: TextStyle(
                                                color: Colors.green,
                                                fontWeight: FontWeight.bold),
                                          ),
                                        )
                                      : const Tooltip(
                                          message: 'Off',
                                          child: Text(
                                            "OFF",
                                            style: TextStyle(
                                                color: Colors.red,
                                                fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(
                        height: 10,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 20.0, right: 20.0, top: 10),
              child: Column(
                children: [
                  //cards
                  schedules.length > 0
                      ? Padding(
                          padding: const EdgeInsets.only(
                              left: 15.0, right: 15, top: 20, bottom: 10),
                          child: Container(
                            height: MediaQuery.of(context).size.height < 700
                                ? MediaQuery.of(context).size.height * 0.45
                                : MediaQuery.of(context).size.height * 0.5,
                            child: ListView.builder(
                              shrinkWrap:
                                  true, // Ensure ListView occupies only the space it needs
                              itemCount: uniqueSchedules.length,
                              itemBuilder: (context, index) {
                                final schedule = uniqueSchedules[index];

                                return (schedule.status == '1' &&
                                        schedule.device_name ==
                                            widget.device.name)
                                    ? ContainerWidget(
                                        day: schedule.day,
                                        schedule: schedule.time,
                                        index: index,
                                        action: schedule.action,
                                        getSchedules: getUniqueSchedules,
                                      )
                                    : SizedBox();
                              },
                            ),
                          ),
                        )
                      : Padding(
                          padding: const EdgeInsets.only(
                              left: 15.0, right: 15, top: 20, bottom: 10),
                          child: Container(
                            height: MediaQuery.of(context).size.height *
                                0.5, // Adjust height as needed
                            child: Text("No Schedules Created"),
                          ),
                        ),
                  SizedBox(height: 30),
                  Align(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton.icon(
                          onPressed: () {
                            showDialog<String>(
                              context: context,
                              builder: (BuildContext context) => AlertDialog(
                                icon: Icon(
                                  Icons.warning_amber_rounded,
                                  size: 50,
                                ),
                                title: const Text(
                                  'Are you sure you want to delete all schedules?',
                                  style: TextStyle(fontSize: 20),
                                ),
                                content: const Text(
                                  'This action cannot be undone.',
                                  textAlign: TextAlign.center,
                                ),
                                actions: <Widget>[
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, 'Cancel'),
                                    child: const Text('Cancel'),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      deleteAllSchedules();
                                      Navigator.pop(context, 'Confirm');
                                    },
                                    child: const Text('Confirm'),
                                  ),
                                ],
                              ),
                            );
                          },
                          icon: Icon(Icons.delete),
                          label: Text(
                            "Delete Schedule",
                            softWrap: true, // Enable text wrapping
                            textAlign:
                                TextAlign.center, // Center align the text
                          ),
                          style: ButtonStyle(
                            backgroundColor:
                                MaterialStateProperty.all(Colors.red.shade50),
                            foregroundColor:
                                MaterialStateProperty.all(Colors.red),
                            padding: MaterialStateProperty.all(
                                EdgeInsets.all(12)), // Adjust padding as needed
                          ),
                        ),
                        MediaQuery.of(context).size.height < 800
                            ? SizedBox(width: 10)
                            : SizedBox(),
                        ElevatedButton.icon(
                          onPressed: () async {
                            if (connection != null && connection!.isConnected) {
                              // connect();
                              sendMessage(
                                      generateJsonString(containerDataList, 5))
                                  .then((value) {
                                ScaffoldMessenger.of(context)
                                    .showSnackBar(SnackBar(
                                  margin: EdgeInsets.only(
                                      left: 10, right: 10, bottom: 5),
                                  behavior: SnackBarBehavior.floating,
                                  content: Center(
                                      child:
                                          Text("Data Uploaded successfully")),
                                ));
                              });
                              updateAll().then((value) {
                                setState(() {
                                  isUploaded = true;
                                });
                              });
                              print("Parameters sent successfully");
                            } else {
                              await connectAndSendMessage(context);
                              print("Bluetooth connection is not established.");
                              ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      margin: EdgeInsets.only(
                                          left: 10, right: 10, bottom: 5),
                                      behavior: SnackBarBehavior.floating,
                                      content: Center(
                                          child: Text(
                                              "Bluetooth connection is not established."))));
                            }
                          },
                          icon: Icon(Icons.upload),
                          label: Text(
                            "Upload Schedule",
                            softWrap: true, // Enable text wrapping
                            textAlign:
                                TextAlign.center, // Center align the text
                          ),
                          style: ButtonStyle(
                            backgroundColor:
                                MaterialStateProperty.all(Colors.green.shade50),
                            foregroundColor:
                                MaterialStateProperty.all(Colors.green),
                            padding: MaterialStateProperty.all(
                                EdgeInsets.all(12)), // Adjust padding as needed
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 30),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ContainerWidget extends StatelessWidget {
  final String day;
  final String schedule;
  final int index;

  final String action;

  final void Function() getSchedules;

  const ContainerWidget({
    Key? key,
    required this.day,
    required this.schedule,
    required this.index,
    required this.action,
    required void Function() this.getSchedules,
  }) : super(key: key);

  Future<void> deleteSchedule(int index, BuildContext context) async {
    Services service = Services();
    print(index);
    Schedule scheduleToDelete =
        uniqueSchedules[index]; // Get the schedule to delete

// Iterate over the uniqueSchedules list to find and remove/update matching schedules
    for (int i = 0; i < uniqueSchedules.length; i++) {
      if (uniqueSchedules[i].time == scheduleToDelete.time &&
          uniqueSchedules[i].action == scheduleToDelete.action &&
          uniqueSchedules[i].day == scheduleToDelete.day) {
// If the schedule matches, remove it
        uniqueSchedules.removeAt(i);
        i--; // Adjust index as the list size decreases after removing an element
      }
    }

// Now, delete the schedule
    await service
        .updateSchedule(scheduleToDelete, scheduleToDelete.time,
            scheduleToDelete.action, scheduleToDelete.day)
        .then((value) {
// Update the UI
      getSchedules();

// Show a snack bar indicating successful deletion
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text("Schedule deleted successfully"),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 1),
      ));
    });
  }

  void confirm() {
    AlertDialog(
        title: Text("Are you sure?"),
        content: Text("This action cannot be undone."),
        actions: [
          TextButton(
            onPressed: () {},
            child: Text("Cancel"),
          ),
          TextButton(
            onPressed: () {},
            child: Text("Confirm"),
          )
        ]);
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 10.0, left: 10, right: 10),
          child: Container(
            width: MediaQuery.of(context).size.height < 800
                ? 200
                : MediaQuery.of(context).size.height < 900
                    ? 230
                    : 250,
            decoration: BoxDecoration(
              color: primary.withOpacity(0.05),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: primary, width: 0.5),
            ),
            child: Padding(
              padding: const EdgeInsets.all(15.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Text(
                    day,
                    textAlign: TextAlign.left,
                    style: TextStyle(
                      color: (action == "true") ? Colors.green : Colors.red,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 10.0, right: 10),
                    child: Container(width: 1, height: 30, color: Colors.black),
                  ),
                  Flexible(
                    child: Text(
                      "${schedule}",
                      textAlign: TextAlign.left,
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  // Flexible(
                  //   child: Text(
                  //     "${schedules[index].pin_no}",
                  //     textAlign: TextAlign.left,
                  //     style: TextStyle(
                  //       color: (action == "true") ? Colors.green : Colors.red,
                  //       fontSize: 16,
                  //       fontWeight: FontWeight.bold,
                  //     ),
                  //   ),
                  // ),
                ],
              ),
            ),
          ),
        ),
        Spacer(),
        Padding(
          padding: const EdgeInsets.only(right: 20.0),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30),
              color: Colors.red.withOpacity(0.10),
            ),
            child: IconButton(
                onPressed: () => showDialog<String>(
                      context: context,
                      builder: (BuildContext context) => AlertDialog(
                        title: const Text(
                          'Are you sure you want to delete?',
                        ),
                        content: const Text('This action cannot be undone.'),
                        actions: <Widget>[
                          TextButton(
                            onPressed: () => Navigator.pop(context, 'Cancel'),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () {
                              deleteSchedule(index, context);
                              Navigator.pop(context, 'Confirm');
                            },
                            child: const Text('Confirm'),
                          ),
                        ],
                      ),
                    ),
                icon: Icon(
                  Icons.delete,
                  size: 30,
                  color: Colors.red,
                )),
          ),
        ),
      ],
    );
  }
}

class ContainerData {
  final String day;
  final String schedule;
  bool selectedD1; // For D1 selection
  bool selectedD2; // For D2 selection
  bool alarmStatus; // Alarm status: 0 or 1

  ContainerData({
    required this.day,
    required this.schedule,
    this.selectedD1 = false, // Default to false
    this.selectedD2 = false, // Default to false
    this.alarmStatus = false, // Default to false (0)
  });
}
