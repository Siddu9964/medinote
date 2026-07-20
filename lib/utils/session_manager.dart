import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';

class SessionManager {
  static const String keyUserId = "userId";
  static const String keyUserName = "userName";
  static const String keyUserRole = "userRole";
  static const String keyFullName = "fullName";
  static const String keySpecialization = "specialization";
  static const String keyPhoto = "photo";
  static const String keyExperience = "experienceYears";
  static const String keyQualification = "qualification";
  static const String keyPhoneNumber = "phoneNumber";
  static const String keyAvailableDays = "availableDays";
  static const String keyGender = "gender";
  static const String keyIsLoggedIn = "isLoggedIn";
  static const String keyRememberMe = "rememberMe";
  static const String keySavedUsername = "savedUsername";
  static const String keySavedPassword = "savedPassword";
  static const String keyBranchName = "branchName";
  static const String keySessionCookie = "sessionCookie";

  static Future<void> saveUser(User user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(keyUserId, user.id);
    await prefs.setString(keyUserName, user.username);
    await prefs.setString(keyUserRole, user.role);
    if (user.fullName != null) await prefs.setString(keyFullName, user.fullName!);
    if (user.specialization != null) await prefs.setString(keySpecialization, user.specialization!);
    if (user.photo != null) await prefs.setString(keyPhoto, user.photo!);
    if (user.experienceYears != null) await prefs.setString(keyExperience, user.experienceYears!);
    if (user.qualification != null) await prefs.setString(keyQualification, user.qualification!);
    if (user.phoneNumber != null) await prefs.setString(keyPhoneNumber, user.phoneNumber!);
    if (user.availableDays != null) await prefs.setString(keyAvailableDays, user.availableDays!);
    if (user.gender != null) await prefs.setString(keyGender, user.gender!);
    await prefs.setBool(keyIsLoggedIn, true);
  }

  static Future<void> saveCredentials(String username, String password) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(keyRememberMe, true);
    await prefs.setString(keySavedUsername, username);
    await prefs.setString(keySavedPassword, password);
  }

  static Future<Map<String, String?>> getCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    final rememberMe = prefs.getBool(keyRememberMe) ?? false;
    if (rememberMe) {
      return {
        'username': prefs.getString(keySavedUsername),
        'password': prefs.getString(keySavedPassword),
      };
    }
    return {'username': null, 'password': null};
  }

  static Future<void> clearCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(keyRememberMe, false);
    await prefs.remove(keySavedUsername);
    await prefs.remove(keySavedPassword);
  }

  static Future<void> saveSessionData(String branchName, String? cookie) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(keyBranchName, branchName);
    if (cookie != null) {
      await prefs.setString(keySessionCookie, cookie);
    }
  }

  static Future<String?> getSessionCookie() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(keySessionCookie);
  }

  static Future<String?> getBranchName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(keyBranchName);
  }

  static Future<User?> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.getBool(keyIsLoggedIn) ?? false;
    if (isLoggedIn) {
      return User(
        id: prefs.getString(keyUserId) ?? '',
        username: prefs.getString(keyUserName) ?? '',
        role: prefs.getString(keyUserRole) ?? '',
        fullName: prefs.getString(keyFullName),
        specialization: prefs.getString(keySpecialization),
        photo: prefs.getString(keyPhoto),
        experienceYears: prefs.getString(keyExperience),
        qualification: prefs.getString(keyQualification),
        phoneNumber: prefs.getString(keyPhoneNumber),
        availableDays: prefs.getString(keyAvailableDays),
        gender: prefs.getString(keyGender),
      );
    }
    return null;
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(keyUserId);
    await prefs.remove(keyUserName);
    await prefs.remove(keyUserRole);
    await prefs.remove(keyFullName);
    await prefs.remove(keySpecialization);
    await prefs.remove(keyPhoto);
    await prefs.remove(keyExperience);
    await prefs.remove(keyQualification);
    await prefs.remove(keyPhoneNumber);
    await prefs.remove(keyAvailableDays);
    await prefs.remove(keyGender);
    await prefs.remove(keyBranchName);
    await prefs.remove(keySessionCookie);
    await prefs.setBool(keyIsLoggedIn, false);
  }
}
