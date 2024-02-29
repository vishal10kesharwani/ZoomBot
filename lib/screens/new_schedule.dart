import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:weekday_selector/weekday_selector.dart';

import '../models/schedule.dart';
import '../services/schedule_services.dart';
import '../utils/color_constants.dart';
import 'dashboard.dart';

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

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );

    if (picked != null) {
      setState(() {
        _selectedTime = picked;
        print(_selectedTime);
      });
    }
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

  void submit() async {
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
      bool allWeeksFalse = !values.any((element) => element == true);
      if (allWeeksFalse) {
        _showSnackBar("Please select at least one day");
        return; // Exit the function early
      }
      if (_groupValue == -1) {
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
              selectedDevice = _groupValue == 0 ? "D1" : "D2",
              light0.toString(),
              "true",
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
          if (res != null) {
            print("Schedule Added");
            _showSnackBar("Schedule Added Successfully");
            Navigator.pop(context);
            Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                    builder: (context) => Dashboard(device: widget.device)));
          }
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
                          Align(
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
                                Text(
                                  '${_selectedTime.hourOfPeriod} : ${_selectedTime.minute.toString().padLeft(2, '0')} ${_selectedTime.period.toString().split('.').last}',
                                  style: TextStyle(
                                      fontSize: 28.0,
                                      color: primary,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1),
                                ),
                                SizedBox(height: 20.0),
                                IconButton(
                                    onPressed: () => _selectTime(context),
                                    icon: Icon(
                                      Icons.arrow_drop_down_outlined,
                                      size: 40,
                                      color: primary,
                                    ))
                              ],
                            ),
                          ),
                          SizedBox(
                            height: 20,
                          ),
                          Row(
                            children: <Widget>[
                              Expanded(
                                flex: 1,
                                child: RadioListTile(
                                  value: 0,
                                  groupValue: _groupValue,
                                  title: Text("D1"),
                                  onChanged: (newValue) =>
                                      setState(() => _groupValue = newValue!),
                                  activeColor: Colors.red,
                                  selected: false,
                                ),
                              ),
                              Expanded(
                                flex: 1,
                                child: RadioListTile(
                                  value: 1,
                                  groupValue: _groupValue,
                                  title: Text("D2"),
                                  onChanged: (newValue) =>
                                      setState(() => _groupValue = newValue!),
                                  activeColor: Colors.red,
                                  selected: false,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(
                            height: 20,
                          ),
                          Row(
                            children: [
                              Switch(
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
                              Spacer(),
                              ElevatedButton(
                                onPressed: () {
                                  submit();
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
