import 'package:bluetooth/utils/color_constants.dart';
import 'package:flutter/material.dart';

import '../data/database_helper.dart';
import '../models/schedule.dart';

var device1;
var epoch;
bool isUploaded = false;
var response;

enum SingingCharacter { D1, D2 }

List<ContainerData> containerDataList = [];

String userName = '';
List<String> receivedUserNames = [];

List<Schedule> schedules = [];

class AllDeviceSchedule extends StatefulWidget {
  final String device;
  AllDeviceSchedule({Key? key, required this.device}) : super(key: key);

  @override
  State<AllDeviceSchedule> createState() => _AllDeviceScheduleState();
}

class _AllDeviceScheduleState extends State<AllDeviceSchedule> {
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

  @override
  void initState() {
    super.initState();
    setState(() {
      getSchedules();
      device1 = widget.device;
      containerDataList = containerDataList;
    });
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
          "Scheduled charts",
          textAlign: TextAlign.start,
          style: TextStyle(
            color: Colors.black,
            fontSize: 25,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.only(top: 20.0),
          child: Column(
            children: [
              Container(
                width: 200,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: Colors.black, width: 1),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 5,
                      ),
                      Text(
                        "${(widget.device.length) > 5 ? widget.device.substring(0, 6) : widget.device} ",
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Icon(
                        isUploaded ? Icons.sync : Icons.sync_disabled,
                        color: isUploaded ? Colors.green : Colors.red,
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets.only(left: 20.0, right: 20.0, top: 10),
                child: Column(
                  children: [
                    //cards
                    schedules.length > 0
                        ? Padding(
                            padding: const EdgeInsets.only(
                                left: 15.0, right: 15, top: 20, bottom: 10),
                            child: Container(
                              height: MediaQuery.of(context).size.height *
                                  0.7, // Adjust height as needed
                              child: ListView.builder(
                                shrinkWrap:
                                    true, // Ensure ListView occupies only the space it needs
                                itemCount: schedules.length,
                                itemBuilder: (context, index) {
                                  final schedule = schedules[index];

                                  return (schedule.status == '1' &&
                                          schedule.device_name == widget.device)
                                      ? ContainerWidget(
                                          day: schedule.day,
                                          schedule: schedule.time,
                                          index: index,
                                          action: schedule.action,
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
                  ],
                ),
              ),
            ],
          ),
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

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 10.0, left: 10, right: 10),
          child: Container(
            width: 300,
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
                      "${schedule}",
                      textAlign: TextAlign.left,
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Flexible(
                    child: Text(
                      "${schedules[index].pin_no}",
                      textAlign: TextAlign.left,
                      style: TextStyle(
                        color: (action == "true") ? Colors.green : Colors.red,
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