// TODO Implement this library.
class Schedule {
  var _id;
  var _device_name;
  var _day;
  var _time;
  var _pin_no;
  var _action;
  var _is_uploaded;
  var _status;
  var _created_at;
  var _updated_at;
  var _created_by;
  var _updated_by;

  Schedule(
      this._device_name,
      this._day,
      this._time,
      this._pin_no,
      this._action,
      this._is_uploaded,
      this._status,
      this._created_at,
      this._updated_at,
      this._created_by,
      this._updated_by);

  Schedule.map(dynamic obj) {
    _id = obj['id'];
    _device_name = obj['device_name'];
    _day = obj['day'];
    _time = obj['time'];
    _pin_no = obj['pin_no'];
    _action = obj['action'];
    _is_uploaded = obj['is_uploaded'];
    _status = obj['status'];
    _created_at = obj['created_at'];
    _updated_at = obj['updated_at'];
    _created_by = obj['created_by'];
    _updated_by = obj['updated_by'];
  }

  String get device_name => _device_name;
  String get day => _day;
  String get time => _time;
  String get pin_no => _pin_no;
  String get action => _action;
  String get is_uploaded => _is_uploaded;
  String get status => _status;
  String get created_at => _created_at;
  String get updated_at => _updated_at;
  String get created_by => _created_by;
  String get updated_by => _updated_by;

  Map<String, dynamic> toMap() {
    var map = new Map<String, dynamic>();
    map["device_name"] = _device_name;
    map["day"] = _day;
    map["time"] = _time;
    map["pin_no"] = _pin_no;
    map["action"] = _action;
    map["is_uploaded"] = _is_uploaded;
    map["status"] = _status;
    map["created_at"] = _created_at;
    map["updated_at"] = _updated_at;
    map["created_by"] = _created_by;
    map["updated_by"] = _updated_by;

    return map;
  }
}
