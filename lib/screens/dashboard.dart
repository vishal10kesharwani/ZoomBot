import 'dart:convert';
import 'dart:typed_data';

import 'package:bluetooth/screens/new_schedule.dart';
import 'package:bluetooth/services/schedule_services.dart';
import 'package:bluetooth/utils/color_constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:intl/intl.dart';

import '../models/schedule.dart';

var device1;
var epoch;

enum SingingCharacter { D1, D2 }

List<ContainerData> containerDataList = [
  ContainerData(
    day: "MON",
    schedule: "10:00 AM",
    selectedD1: false, // Set D1 as selected
    selectedD2: true,
    alarmStatus: true,
  ),
  ContainerData(
    day: "MON",
    schedule: "2:00 PM",
    selectedD1: true, // Set D1 as selected
    selectedD2: false,
    alarmStatus: true,
  ),
  ContainerData(
    day: "TUE",
    schedule: "9:00 AM",
    selectedD1: true, // Set D1 as selected
    selectedD2: false,
    alarmStatus: true,
  ),
  ContainerData(
    day: "TUE",
    schedule: "10:30 AM",
    selectedD1: true, // Set D1 as selected
    selectedD2: false,
    alarmStatus: true,
  ),
  ContainerData(
    day: "TUE",
    schedule: "3:00 PM",
    selectedD1: true, // Set D1 as selected
    selectedD2: false,
    alarmStatus: false,
  ),
  ContainerData(
    day: "TUE",
    schedule: "6:00 PM",
    selectedD1: true, // Set D1 as selected
    selectedD2: false,
    alarmStatus: true,
  ),
  ContainerData(
    day: "WED",
    schedule: "8:00 AM",
    selectedD1: true, // Set D1 as selected
    selectedD2: false,
    alarmStatus: false,
  ),
  ContainerData(
    day: "WED",
    schedule: "11:00 AM",
    selectedD1: true, // Set D1 as selected
    selectedD2: false,
    alarmStatus: true,
  ),
  ContainerData(
    day: "THU",
    schedule: "10:30 AM",
    selectedD1: true, // Set D1 as selected
    selectedD2: false,
    alarmStatus: true,
  ),
  ContainerData(
    day: "FRI",
    schedule: "9:00 AM",
    selectedD1: true, // Set D1 as selected
    selectedD2: false,
    alarmStatus: true,
  ),
  ContainerData(
    day: "SAT",
    schedule: "10:00 AM",
    selectedD1: true, // Set D1 as selected
    selectedD2: false,
    alarmStatus: true,
  ),
  ContainerData(
    day: "SUN",
    schedule: "11:00 AM",
    selectedD1: true, // Set D1 as selected
    selectedD2: false,
    alarmStatus: true,
  ),
];

String userName = '';
List<String> receivedUserNames = [];

List<Schedule> schedules = [];

class Dashboard extends StatefulWidget {
  final BluetoothDevice device;
  Dashboard({Key? key, required this.device}) : super(key: key);

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  BluetoothConnection? connection;

  List<int?> receivedParameters = [];
  List<int?> paramVal = [];

  void getSchedules() async {
    Services service = Services();
    await service.getAllSchedule().then((value) {
      setState(() {
        schedules = value;
        print("Records:$schedules");
      });
    });
    setState(() {});
  }

  void connect() async {
    connection = await BluetoothConnection.toAddress(widget.device.address);
    listenForResponse();
  }

  void sendMessage(String message) {
    connection?.output.add(Uint8List.fromList(utf8.encode(message + "\r\n")));
  }
  // void sendMessage1() {
  //   connection?.output.add(Uint8List.fromList(utf8.encode("!UApoorva,Aman,Chetan")));
  // }

  void requestUserNames() {
    // Send the command to request usernames
    sendMessage('!U*');
    // print('fgfg');
  }

  void listenForResponse() {
    connection?.input?.listen((Uint8List data) {
      print('Received raw data: $data');
      String response = utf8.decode(data);
      print('Login : listenForResponse : response is $response');
      // Check if the response starts with "!U" indicating it contains usernames
      if (response.startsWith('!U')) {
        // Extract the usernames from the response
        List<String> receivedUserNames = response.substring(2).split(',');
        print('Received User Names: $receivedUserNames');
        setState(() {
          print('Received User Names: $receivedUserNames');
        });
      }
    });
  }

  @override
  void initState() {
    super.initState();
    setState(() {
      getSchedules();
      device1 = widget.device;
      containerDataList = containerDataList;
    });
    requestUserNames();
    connect();
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

  String generateJsonString(List<ContainerData?> containerDataList) {
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
    schedules.forEach((scheduleData) {
      if (scheduleData != null) {
        String time24HourFormat = time12to24Format(scheduleData.time);
        String key = "${scheduleData.day}-${time24HourFormat}";

        // Calculate epoch value only if the day matches the current day
        if (day1.toUpperCase() == scheduleData.day) {
          int epoch = calculateEpochFromDateAndTime(now, now);
        }
        // Construct value for the key
        Map<String, dynamic> value = {};
        // Determine which device (D1 or D2) is selected and include alarm status
        if (scheduleData.pin_no == "D1") {
          value['D1'] = (scheduleData.action == "true") ? 1 : 0;
        } else if (scheduleData.pin_no == "D2") {
          value['D2'] = (scheduleData.action == "true") ? 1 : 0;
        }

        // Add key-value pair to scheduler map
        if (scheduler.containsKey(key)) {
          // If key already exists, add value to the list
          scheduler[key]!.add(value);
        } else {
          // If key doesn't exist, create a new list with value
          scheduler[key] = [value];
        }
      }
    });

    // Add scheduler and rtc_sync to config map
    config['scheduler'] = scheduler;
    config['rtc_sync'] = epochTimeInSeconds;

    // Construct final JSON object
    Map<String, dynamic> jsonObject = {
      'bootup': {},
      'config': config,
    };
    print(json.encode(jsonObject));
    // Convert JSON object to string and return
    return json.encode(jsonObject);
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

  @override
  Widget build(BuildContext context) {
    SingingCharacter? _character = SingingCharacter.D1;

    return Scaffold(
      extendBody: true,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          padding: const EdgeInsets.only(left: 20.0, top: 20),
          icon: Icon(Icons.arrow_back_ios),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 30.0, left: 80, right: 80),
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
                                NewSchedule(device: widget.device)));
                  },
                  child: const Icon(
                    Icons.add,
                    color: Colors.white,
                  ),
                ),
                SizedBox(
                  width: 10,
                ),
                Text(
                  "Add Schedule",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                ),
                Text(
                  "*",
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: primary),
                )
              ],
            ),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              // Adjust height as needed
              child: Container(
                color: primary,
                width: double.infinity,
                child: Padding(
                  padding: const EdgeInsets.only(
                    left: 60.0,
                    top: 55,
                  ),
                  child: Column(
                    children: [
                      Align(
                        alignment: Alignment.topLeft,
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
                      SizedBox(
                        height: 20,
                      ),
                      Padding(
                        padding: const EdgeInsets.only(
                          left: 50.0,
                          right: 100.0,
                          bottom: 10,
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(color: Colors.black, width: 1),
                          ),
                          height: 40,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Align(
                                alignment: Alignment.center,
                                child: Text(
                                  "Device 1   ",
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              Icon(
                                Icons.sync_disabled,
                                color: Colors.red,
                              ),
                            ],
                          ),
                        ),
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
                            height: MediaQuery.of(context).size.height *
                                0.5, // Adjust height as needed
                            child: ListView.builder(
                              shrinkWrap:
                                  true, // Ensure ListView occupies only the space it needs
                              itemCount: schedules.length,
                              itemBuilder: (context, index) {
                                final schedule = schedules[index];

                                return schedule.status == '1'
                                    ? ContainerWidget(
                                        day: schedule.day,
                                        schedule: schedule.time,
                                      )
                                    : Text("No Active Schedules Available");
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
                            child: Center(child: Text("No schedules created")),
                          ),
                        ),
                  SizedBox(height: 30),
                  Align(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        ElevatedButton.icon(
                          onPressed: () {},
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
                        ElevatedButton.icon(
                          // onPressed: () {
                          //   print(containerDataList[1].alarmStatus);
                          //   String jsonString =
                          //       generateJsonString(containerDataList);
                          //
                          //   // Send the generated JSON string to the Bluetooth device
                          //   // Replace 'sendJsonToBluetoothDevice' with the actual method to send data via Bluetooth
                          //   print(jsonString);
                          // },
                          onPressed: () async {
                            if (connection != null && connection!.isConnected) {
                              sendMessage(
                                  generateJsonString(containerDataList));
                              ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                      margin: EdgeInsets.only(
                                          left: 10, right: 10, bottom: 5),
                                      behavior: SnackBarBehavior.floating,
                                      content: Center(
                                          child: Text(
                                              "Data write successfully"))));
                              print("Parameters sent successfully");
                            } else {
                              print("Bluetooth connection is not established.");
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

  const ContainerWidget({
    Key? key,
    required this.day,
    required this.schedule,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 10.0, left: 10, right: 10),
          child: Container(
            width: 230,
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
                      color: primary,
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
                      schedule,
                      textAlign: TextAlign.left,
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
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
                onPressed: () {},
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
