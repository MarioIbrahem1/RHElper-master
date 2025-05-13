import 'package:flutter/foundation.dart';

class SignupProvider with ChangeNotifier {
  Map<String, dynamic> userData = {};

  void setUserData(Map<String, dynamic> data) {
    userData.addAll(data);
    notifyListeners();
  }

  void updateValue(String key, dynamic value) {
    userData[key] = value;
    notifyListeners();
  }

  void removeValue(String key) {
    userData.remove(key);
    notifyListeners();
  }

  dynamic getValue(String key) {
    return userData[key];
  }

  bool hasValue(String key) {
    return userData.containsKey(key);
  }

  Map<String, dynamic> getAllData() {
    return Map.from(userData);
  }

  void clear() {
    userData.clear();
    notifyListeners();
  }

  bool isDataComplete() {
    final requiredFields = [
      'firstName',
      'lastName',
      'email',
      'phone',
      'password',
      'confirmPassword',
      'letters',
      'plate_number',
      'car_color',
      'car_model'
    ];

    return requiredFields.every((field) =>
        userData.containsKey(field) &&
        userData[field] != null &&
        userData[field].toString().isNotEmpty);
  }

  void printData() {
    print('Current User Data:');
    userData.forEach((key, value) {
      print('$key: $value');
    });
  }
}
