import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:weekday_selector/weekday_selector.dart';

import '../data/database_helper.dart';
import '../models/schedule.dart';
import '../utils/color_constants.dart';

int activeStep = 1;
TimeOfDay _selectedTime = TimeOfDay.now();
bool light0 = true;
DateTime? selectedDate = DateTime.now();
int? userid;

class NewSchedule extends StatefulWidget {
  final BluetoothDevice device;
  NewSchedule({Key? key, required this.device}) : super(key: key);
  @override
  State createState() => DynamicList();
}

DateTimeRange dateRange = DateTimeRange(
  start: DateTime(2024, 02, 5),
  end: DateTime(2024, 02, 10),
);

enum SingingCharacter { D1, D2 }

class DynamicList extends State<NewSchedule> {
  Key key = UniqueKey();

  final TextEditingController _task = TextEditingController();
  var _time;
  String? _alarm = light0.toString();

  void _showSnackBar(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: new Text(text),
      behavior: SnackBarBehavior.floating,
    ));
  }

  Future<void> inputTimeSelect() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (BuildContext context, Widget? child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedTime = picked;
        print(_selectedTime);
      });
    }
  }

  var timeMode = true;
  Future<void> _selectTime(BuildContext context) async {
    final bool is24HourFormat = MediaQuery.of(context).alwaysUse24HourFormat;

    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (BuildContext context, Widget? child) {
        return MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(alwaysUse24HourFormat: is24HourFormat),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedTime = picked;
        print(_selectedTime);
      });
    }
  }

  dynamic showTimer() {
    return Container(
        child: Column(
      children: [
        Switch(
            value: timeMode,
            onChanged: (value) {
              setState(() {
                timeMode = !timeMode;
              });
            }),
        if (!timeMode)
          FutureBuilder<void>(
            future: inputTimeSelect(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return CircularProgressIndicator(); // Placeholder until the future completes
              }
              return SizedBox(); // Placeholder for future completion
            },
          ),
        if (timeMode)
          FutureBuilder<void>(
            future: _selectTime(context),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return CircularProgressIndicator(); // Placeholder until the future completes
              }
              return SizedBox(); // Placeholder for future completion
            },
          ),
        // timeMode == true ? ,
      ],
    ));
  }

  @override
  void initState() {
    super.initState();
  }

  int _groupValue = -1;
  printIntAsDay(int day) {
    print(
        'Received integer: $day. Corresponds to day: ${intDayToEnglish(day)}');
  }

  final start = dateRange.start;
  final end = dateRange.end;
  final values = <bool>[false, false, false, false, false, false, false];

  void submit(selectedData) async {
    setState(() {
      _time =
          "${_selectedTime.hourOfPeriod.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')} ${_selectedTime.period.toString().toUpperCase().split('.').last}";

      // for (int i = 0; i < values.length; i++) {
      //   if (values[i]) {
      //     var newSchedule = ContainerData(
      //       day: _getDayOfWeek(i + 1),
      //       schedule: _time!,
      //       selectedD1: _groupValue == 0,
      //       selectedD2: _groupValue == 1,
      //       alarmStatus: light0,
      //     );
      //     print("$i day: ${newSchedule.day}" +
      //         "values[i]: " +
      //         values[i].toString() +
      //         "light0: " +
      //         light0.toString() +
      //         "selectedD1: " +
      //         _groupValue.toString() +
      //         "selectedD2: " +
      //         _groupValue.toString() +
      //         "schedule: " +
      //         _time.toString());
      //
      //     // Add the newSchedule to containerDataList
      //     setState(() {
      //       containerDataList.add(newSchedule);
      //       // WidgetsBinding.instance
      //       //     .addPostFrameCallback((_) {
      //       //   Navigator.pushReplacement(
      //       //       context,
      //       //       MaterialPageRoute(
      //       //           builder: (_) => Dashboard(
      //       //               device: widget.device)));
      //       // });
      //     });
      //   }
      // }
      bool allWeeksFalse = true; // Assume all elements are false initially

      for (bool element in values) {
        if (element == true) {
          allWeeksFalse =
              false; // If any element is true, set allWeeksFalse to false and exit loop
          break;
        }
      }

      if (allWeeksFalse) {
        _showSnackBar("Please select at least one day");
        return; // Exit the function early
      }

      if (selectedData != "D1" && selectedData != "D2" && allWeeksFalse) {
        _showSnackBar("Please select a pin no. (D1 or D2)");
        return; // Exit the function early
      }
      String selectedDevice;
      for (int i = 0; i < values.length; i++) {
        if (values[i]) {
          var newSchedule = Schedule(
              widget.device.name,
              _getDayOfWeek(i),
              _time!,
              selectedDevice = selectedData == "D1" ? "D1" : "D2",
              light0.toString(),
              "false",
              "1",
              "null",
              "null",
              widget.device.name,
              "null");
          print(newSchedule.device_name +
              newSchedule.day +
              newSchedule.time +
              newSchedule.pin_no +
              newSchedule.action +
              newSchedule.is_uploaded +
              newSchedule.status +
              newSchedule.created_at +
              newSchedule.updated_at +
              newSchedule.created_by +
              newSchedule.updated_by);

          Services service = Services();

          // setState(() {
          //   containerDataList.add(newSchedule);
          //   // WidgetsBinding.instance
          //   //     .addPostFrameCallback((_) {
          //   //   Navigator.pushReplacement(
          //   //       context,
          //   //       MaterialPageRoute(
          //   //           builder: (_) => Dashboard(
          //   //               device: widget.device)));
          //   // });
          // });

          var res = service.insertSchedule(newSchedule);
        }
      }
    });
  }

  String intDayToEnglish(int day) {
    if (day % 7 == DateTime.monday % 7) return 'Monday';
    if (day % 7 == DateTime.tuesday % 7) return 'Tueday';
    if (day % 7 == DateTime.wednesday % 7) return 'Wednesday';
    if (day % 7 == DateTime.thursday % 7) return 'Thursday';
    if (day % 7 == DateTime.friday % 7) return 'Friday';
    if (day % 7 == DateTime.saturday % 7) return 'Saturday';
    if (day % 7 == DateTime.sunday % 7) return 'Sunday';
    throw '🐞 This should never have happened: $day';
  }

  bool selectedD1 = true;
  bool selectedD2 = true;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primary,
      // extendBodyBehindAppBar: true,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(50.0),
        child: AppBar(
          forceMaterialTransparency: true,
          backgroundColor: Colors.transparent,
          leadingWidth: 140,
          leading: Padding(
            padding: const EdgeInsets.only(left: 30.0, top: 15),
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white.withOpacity(0.35),
                foregroundColor: Colors.white,
                elevation: 0,
              ),
              onPressed: () {
                Navigator.pop(context);
              },
              icon: Icon(
                // <-- Icon
                Icons.close,
                size: 24.0,
              ),
              label: Text('Back'), // <-- Text
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Align(
              alignment: Alignment.topLeft,
              child: const Padding(
                  padding: EdgeInsets.only(left: 30, top: 30, bottom: 50),
                  child: Text(
                    "Create New Schedule",
                    style: TextStyle(
                        fontSize: 30.0,
                        fontWeight: FontWeight.w500,
                        color: Colors.white),
                  )),
            ),
            Column(
              children: [
                Container(
                  height: MediaQuery.of(context).size.height - 200,
                  width: MediaQuery.of(context).size.width,
                  decoration: BoxDecoration(
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.30),
                        blurRadius: 98.0,
                        offset: Offset(0, -20),
                      ),
                    ],
                    borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(50),
                        topRight: Radius.circular(50)),
                    color: Color(0xFFFBEFE4),
                  ),
                  child: Align(
                    alignment: Alignment.topLeft,
                    child: Padding(
                      padding: EdgeInsets.all(35),
                      child: Column(
                        children: [
                          SizedBox(
                            height: 20,
                          ),
                          const Align(
                            alignment: Alignment.topLeft,
                            child: Text(
                              "Choose Days",
                              style: TextStyle(
                                fontSize: 20.0,
                                fontWeight: FontWeight.w500,
                                color: Colors.black,
                              ),
                            ),
                          ),
                          SizedBox(height: 10),
                          WeekdaySelector(
                            selectedFillColor: Colors.indigo.shade300,
                            onChanged: (v) {
                              printIntAsDay(v);
                              setState(() {
                                values[v % 7] = !values[v % 7]!;
                              });
                            },
                            selectedElevation: 15,
                            elevation: 5,
                            disabledElevation: 0,
                            values: values,
                          ),
                          SizedBox(height: 20),
                          Align(
                            alignment: Alignment.topLeft,
                            child: Text(
                              "Start Time",
                              style: TextStyle(
                                  fontSize: 20.0,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black),
                            ),
                          ),
                          SizedBox(
                            height: 10,
                          ),
                          Align(
                            alignment: Alignment.topLeft,
                            child: Row(
                              children: [
                                IconButton(
                                    onPressed: () => _selectTime(context),
                                    icon: Icon(
                                      Icons.alarm,
                                      color: Colors.black,
                                      size: 40,
                                    )),
                                GestureDetector(
                                  onTap: () => showTimer(),
                                  child: Text(
                                    '${_selectedTime.hourOfPeriod}:${_selectedTime.minute.toString().padLeft(2, '0')} ${_selectedTime.period.toString().split('.').last}',
                                    style: TextStyle(
                                        fontSize: 28.0,
                                        color: primary,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 1),
                                  ),
                                ),
                                SizedBox(height: 20.0),
                                IconButton(
                                    onPressed: () {
                                      timeMode
                                          ? _selectTime(context)
                                          : inputTimeSelect();
                                    },
                                    icon: Icon(
                                      Icons.arrow_drop_down_outlined,
                                      size: 40,
                                      color: primary,
                                    )),
                                Spacer(),
                                Column(
                                  children: [
                                    timeMode
                                        ? Tooltip(
                                            showDuration:
                                                Duration(milliseconds: 200),
                                            message: '12hr',
                                            child: Text(
                                              "12hr",
                                              style: TextStyle(
                                                  color: Colors.green,
                                                  fontWeight: FontWeight.bold),
                                            ),
                                          )
                                        : Tooltip(
                                            message: '24hr',
                                            child: Text(
                                              "24hr",
                                              style: TextStyle(
                                                  color: Colors.green,
                                                  fontWeight: FontWeight.bold),
                                            ),
                                          ),
                                    Transform.scale(
                                      scale: 0.8,
                                      child: Switch(
                                        value: timeMode,
                                        onChanged: (bool value) {
                                          setState(() {
                                            timeMode = value;
                                          });
                                        },
                                        activeColor: Colors.white,
                                        activeTrackColor: primary,
                                        inactiveThumbColor: Colors.black,
                                        inactiveTrackColor: primary,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          SizedBox(
                            height: 20,
                          ),
                          // Row(
                          //   children: <Widget>[
                          //     Expanded(
                          //       flex: 1,
                          //       child: CheckboxListTile(
                          //         title: Text(
                          //           "D1",
                          //           style: TextStyle(
                          //               color: Colors.black,
                          //               fontWeight: FontWeight.bold,
                          //               fontSize: 20),
                          //         ),
                          //         value: selectedD1,
                          //         onChanged: (newValue) {
                          //           setState(() {
                          //             selectedD1 = newValue!;
                          //
                          //             // If both checkboxes are selected, add records for each pin no.
                          //             if (selectedD1 && selectedD2) {
                          //               _groupValue = -1; // Reset radio buttons
                          //               // _addRecordsForBothPins();
                          //             }
                          //           });
                          //         },
                          //         activeColor: primary,
                          //         controlAffinity:
                          //             ListTileControlAffinity.leading,
                          //       ),
                          //     ),
                          //     Expanded(
                          //       flex: 1,
                          //       child: CheckboxListTile(
                          //         title: Text(
                          //           "D2",
                          //           style: TextStyle(
                          //               color: Colors.black,
                          //               fontWeight: FontWeight.bold,
                          //               fontSize: 20),
                          //         ),
                          //         value: selectedD2,
                          //         onChanged: (newValue) {
                          //           setState(() {
                          //             selectedD2 = newValue!;
                          //
                          //             // If both checkboxes are selected, add records for each pin no.
                          //             if (selectedD1 && selectedD2) {
                          //               _groupValue = -1; // Reset radio buttons
                          //               // _addRecordsForBothPins();
                          //             }
                          //           });
                          //         },
                          //         activeColor: primary,
                          //         controlAffinity:
                          //             ListTileControlAffinity.leading,
                          //       ),
                          //     ),
                          //   ],
                          // ),
                          SizedBox(
                            height: 20,
                          ),
                          Row(
                            children: [
                              Transform.scale(
                                scale: 1.2,
                                child: Switch(
                                  value: light0,
                                  onChanged: (bool value) {
                                    setState(() {
                                      light0 = value;
                                    });
                                  },
                                  activeColor: Colors.white,
                                  activeTrackColor: primary,
                                  inactiveThumbColor: Colors.black,
                                  inactiveTrackColor: primary,
                                ),
                              ),
                              SizedBox(width: 10),
                              light0
                                  ? Tooltip(
                                      showDuration: Duration(milliseconds: 200),
                                      message: 'On',
                                      child: Text(
                                        "ON",
                                        style: TextStyle(
                                            color: Colors.green,
                                            fontWeight: FontWeight.bold),
                                      ),
                                    )
                                  : Tooltip(
                                      message: 'Off',
                                      child: Text(
                                        "OFF",
                                        style: TextStyle(
                                            color: Colors.red,
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ),
                              Spacer(),
                              ElevatedButton(
                                onPressed: () {
                                  if (selectedD1 || selectedD2) {
                                    if (selectedD1 && selectedD2) {
                                      submit("D1");
                                      submit("D2");
                                      print("Schedule Added");
                                      _showSnackBar(
                                          "Schedule Added Successfully");
                                      Navigator.pop(context, false);
                                    } else {
                                      submit(selectedD1 ? "D1" : "D2");
                                      print("Schedule Added");
                                      _showSnackBar(
                                          "Schedule Added Successfully");
                                      Navigator.pop(context, false);
                                    }
                                  }
                                },
                                child: Text(
                                  "Save",
                                  style: TextStyle(fontSize: 20),
                                ),
                                style: ButtonStyle(
                                    backgroundColor:
                                        MaterialStateProperty.all(primary),
                                    foregroundColor:
                                        MaterialStateProperty.all(Colors.white),
                                    fixedSize: MaterialStateProperty.all(
                                      Size(130, 60),
                                    ),
                                    shape: MaterialStateProperty.all<
                                            RoundedRectangleBorder>(
                                        RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(18.0),
                                    ))),
                              ),
                            ],
                          )
                        ],
                      ),
                    ),
                  ),
                )
              ],
            )
          ],
        ),
      ),
    );
  }

  String _getDayOfWeek(int index) {
    switch (index) {
      case 1:
        return "Mon";
      case 2:
        return "Tue";
      case 3:
        return "Wed";
      case 4:
        return "Thu";
      case 5:
        return "Fri";
      case 6:
        return "Sat";
      case 7:
        return "Sun";
      default:
        return "";
    }
  }

  void dateSelect(DateTime value) {}

  void onAlarm(bool value) {}

  Future pickDateRange() async {
    DateTimeRange? newDateRange = await showDateRangePicker(
      context: context,
      initialDateRange: dateRange,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    setState(() {
      dateRange = newDateRange ?? dateRange;

      // if (newDateRange == null) return;
      // setState(() => dateRange = newDateRange);
    });
  }
}
