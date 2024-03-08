import 'package:bluetooth/screens/all_device_schedule.dart';
import 'package:bluetooth/utils/color_constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';

import '../data/database_helper.dart';
import '../models/schedule.dart';
import '../utils/string_constants.dart';

var device1;
var epoch;
bool isUploaded = false;

enum SingingCharacter { D1, D2 }

String userName = '';
List<String> receivedUserNames = [];
List<Schedule> schedules = [];
List<BluetoothDevice> bondedDevices = [];

class ALlSchedules extends StatefulWidget {
  ALlSchedules({Key? key}) : super(key: key);

  @override
  State<ALlSchedules> createState() => _ALlSchedulesState();
}

class _ALlSchedulesState extends State<ALlSchedules> {
  List<int?> receivedParameters = [];
  List<int?> paramVal = [];

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

  void getSchedules() async {
    Services service = Services();
    await service.getAllSchedule().then((value) {
      setState(() {
        schedules = value;
        print("Records:$schedules");
      });
    });
    setState(() {
      removeDuplicateSchedules(schedules);
    });
  }

  @override
  void initState() {
    super.initState();
    setState(() {
      // getSchedules();
      _getBondedDevices();
    });
  }

  void removeDuplicateSchedules(List<Schedule> schedules) {
    for (int i = 0; i < schedules.length; i++) {
      for (int j = i + 1; j < schedules.length; j++) {
        if (schedules[i].device_name == schedules[j].device_name) {
          print(
              'Removing index $j with device name ${schedules[j].device_name}');
          setState(() {
            schedules.removeAt(j);
          });
          // Since we removed an element, we need to decrement j to stay at the current index in the next iteration
          j--;
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    SingingCharacter? _character = SingingCharacter.D1;

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 100,
        backgroundColor: primary,
        leading: IconButton(
          padding: const EdgeInsets.only(left: 20.0),
          icon: Icon(Icons.arrow_back_ios),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Text(
          "All Devices",
          style: TextStyle(
            color: Colors.black,
            fontSize: 25,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 20.0, right: 20.0, top: 30),
              child: Column(
                children: [
                  //cards
                  bondedDevices.length > 0
                      ? Padding(
                          padding: const EdgeInsets.only(
                              left: 15.0, right: 15, top: 20, bottom: 10),
                          child: Container(
                            height: MediaQuery.of(context).size.height *
                                0.5, // Adjust height as needed
                            child: ListView.builder(
                              shrinkWrap:
                                  true, // Ensure ListView occupies only the space it needs
                              itemCount: bondedDevices.length,
                              itemBuilder: (context, index) {
                                final schedule = bondedDevices[index];

                                return Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: ContainerWidget(
                                    index: index,
                                  ),
                                );
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
                            child: Text("No Devices Paired"),
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
  final int index;

  const ContainerWidget({
    Key? key,
    required this.index,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: primary, width: 0.5),
      ),
      child: ListTile(
        onTap: () {
          Navigator.push(context, MaterialPageRoute(builder: (context) {
            return AllDeviceSchedule(device: schedules[index].device_name);
          }));
        },
        leading: Icon(Icons.devices),
        title: Row(
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 5.0, right: 10),
              child: Container(width: 1, height: 30, color: Colors.black),
            ),
            Flexible(
              child: Text(
                "${bondedDevices[index].name}",
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
        trailing: IconButton(
            tooltip: ("Active device schedules"),
            onPressed: () {
              print(bondedDevices[index].name);
              Navigator.pushReplacement(context,
                  MaterialPageRoute(builder: (context) {
                return AllDeviceSchedule(device: bondedDevices[index].name!);
              }));
            },
            icon: Icon(
              Icons.edit_calendar,
              color: primary,
            )),
      ),
    );
  }
}
