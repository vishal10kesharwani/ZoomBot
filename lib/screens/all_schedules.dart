import 'package:bluetooth/screens/all_device_schedule.dart';
import 'package:bluetooth/utils/color_constants.dart';
import 'package:flutter/material.dart';

import '../data/database_helper.dart';
import '../models/schedule.dart';

var device1;
var epoch;
bool isUploaded = false;

enum SingingCharacter { D1, D2 }

String userName = '';
List<String> receivedUserNames = [];
List<Schedule> schedules = [];

class ALlSchedules extends StatefulWidget {
  ALlSchedules({Key? key}) : super(key: key);

  @override
  State<ALlSchedules> createState() => _ALlSchedulesState();
}

class _ALlSchedulesState extends State<ALlSchedules> {
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
    setState(() {
      removeDuplicateSchedules(schedules);
    });
  }

  @override
  void initState() {
    super.initState();
    setState(() {
      getSchedules();
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

                                return Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: ContainerWidget(
                                    day: schedule.day,
                                    schedule: schedule.time,
                                    index: index,
                                    action: schedule.action,
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
  final String day;
  final String schedule;
  final int index;

  final String action;

  const ContainerWidget({
    Key? key,
    required this.day,
    required this.schedule,
    required this.index,
    required this.action,
  }) : super(key: key);

  Future<void> deleteSchedule(int index, BuildContext context) async {
    Services service = Services();
    print(index);
    Schedule schedule = Schedule(
        schedules[index].device_name,
        schedules[index].day,
        schedules[index].time,
        schedules[index].pin_no,
        schedules[index].action,
        schedules[index].is_uploaded,
        "0",
        "null",
        "null",
        schedules[index].created_by,
        "null");

    await service.updateSchedule(schedule, index + 1).then((value) {
      Navigator.pushReplacementNamed(context, '/dashboard');
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text("Schedule deleted successfully"),
        behavior: SnackBarBehavior.floating,
      ));
    });
  }

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
                "${schedules[index].device_name}",
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
              print(schedules[index].device_name);
              Navigator.pushReplacement(context,
                  MaterialPageRoute(builder: (context) {
                return AllDeviceSchedule(device: schedules[index].device_name);
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
