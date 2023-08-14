import 'package:flutter/material.dart';
import 'package:shake/shake.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:geolocator/geolocator.dart';
import 'package:women_safety_app/db/db_services.dart';
import 'package:women_safety_app/model/contactsm.dart';
import 'package:women_safety_app/utils/flutter_background_services.dart';
import 'package:background_sms/background_sms.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geocoding/geocoding.dart';
import 'package:telephony/telephony.dart';
import 'package:background_sms/background_sms.dart' as bg_sms;

ShakeDetector? _shakeDetector;

class SafeHome extends StatefulWidget {
  final Position? currentPosition;
  final String? currentAddress;

  SafeHome({this.currentPosition, this.currentAddress});
  @override
  State<SafeHome> createState() => _SafeHomeState();
}

class _SafeHomeState extends State<SafeHome> {
  ShakeDetector? _shakeDetector;

  @override
  void initState() {
    super.initState();

    _shakeDetector = ShakeDetector.autoStart(
      onPhoneShake: () {
        print("Phone shaken!");
        _showShakeSnackBar();
        _sendEmergencyMessage();
        _sendLocationAlert();
      },
    );
  }

  @override
  void dispose() {
    _shakeDetector?.stopListening();
    super.dispose();
  }

  void _showShakeSnackBar() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Phone shaken! Message will be sent.'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _sendEmergencyMessage() async {
    Position? currentPosition = await _getCurrentPosition();
    if (currentPosition != null) {
      String messageBody =
          "Emergency!I am in trouble. My current location: https://www.google.com/maps/search/?api=1&query=${currentPosition.latitude}%2C${currentPosition.longitude}";
      sendMessage(messageBody);
    } else {
      Fluttertoast.showToast(msg: "Unable to get current location.");
    }
  }

  Future<Position?> _getCurrentPosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      Fluttertoast.showToast(msg: "Location services are disabled.");
      return null;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        Fluttertoast.showToast(msg: "Location permissions are denied.");
        return null;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      Fluttertoast.showToast(
          msg: "Location permissions are permanently denied.");
      return null;
    }

    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
      forceAndroidLocationManager: true,
    );

    return position;
  }

  void showModelSafeHome(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height / 1.4,
          child: Padding(
            padding: const EdgeInsets.all(14.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "SEND YOUR CURRENT LOCATION IMMEDIATELY TO YOUR EMERGENCY CONTACTS",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 20),
                ),
                SizedBox(height: 10),
                PrimaryButton(
                  title: "GET LOCATION",
                  onPressed: _getCurrentLocation,
                ),
                SizedBox(height: 10),
                PrimaryButton(
                  title: "SEND ALERT",
                  onPressed: () async {
                    _sendLocationAlert();
                  },
                ),
              ],
            ),
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(30),
              topRight: Radius.circular(30),
            ),
          ),
        );
      },
    );
  }

  void _sendLocationAlert() async {
    String recipients = "";
    List<TContact> contactList = await DatabaseHelper().getContactList();

    Position? currentPosition = await _getCurrentPosition();
    if (currentPosition != null) {
      String messageBody =
          "Emergency! I am in trouble. My current location: https://www.google.com/maps/search/?api=1&query=${_curentPosition!.latitude}%2C${_curentPosition!.longitude}. $_curentAddress";

      if (await _isPermissionGranted()) {
        contactList.forEach((element) {
          _sendSms("${element.number}", messageBody);
        });
      } else {
        Fluttertoast.showToast(msg: "Permission not granted.");
      }
    } else {
      Fluttertoast.showToast(msg: "Unable to get current location.");
    }
  }

  Future<bool> _isPermissionGranted() async {
    return await Permission.sms.status.isGranted;
  }

  Future<void> sendMessage(String messageBody) async {
    List<TContact> contactList = await DatabaseHelper().getContactList();

    if (contactList.isEmpty) {
      Fluttertoast.showToast(
          msg: "No emergency contacts available. Please add contacts.");
    } else {
      for (var i = 0; i < contactList.length; i++) {
        Telephony.backgroundInstance
            .sendSms(to: contactList[i].number, message: messageBody)
            .then((value) {
          Fluttertoast.showToast(msg: "Message sent to ${contactList[i].name}");
        }).catchError((error) {
          Fluttertoast.showToast(
              msg: "Failed to send message to ${contactList[i].name}");
          print("Error sending message: $error");
        });
      }
    }
  }

  void _sendSms(String phoneNumber, String message) async {
    bg_sms.SmsStatus result = await bg_sms.BackgroundSms.sendMessage(
      phoneNumber: phoneNumber,
      message: message,
      simSlot: 1,
    );
    if (result == bg_sms.SmsStatus.sent) {
      print("Sent");
      Fluttertoast.showToast(msg: "Message sent.");
    } else {
      Fluttertoast.showToast(msg: "Failed to send message.");
    }
  }

  Future<bool> _handleLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      Fluttertoast.showToast(
          msg: 'Location services are disabled. Please enable the services');
      return false;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        Fluttertoast.showToast(msg: 'Location permissions are denied');
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      Fluttertoast.showToast(
          msg:
              'Location permissions are permanently denied, we cannot request permissions.');
      return false;
    }
    return true;
  }

  _getCurrentLocation() async {
    final hasPermission = await _handleLocationPermission();
    final Telephony telephony = Telephony.instance;
    await telephony.requestPhoneAndSmsPermissions;

    if (!hasPermission) return;

    await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
      forceAndroidLocationManager: true,
    ).then((Position position) async {
      setState(() {
        _curentPosition = position;
        print(_curentPosition!.latitude);
        _getAddressFromLatLon(); // Fetch the address here
      });
    }).catchError((e) {
      Fluttertoast.showToast(msg: e.toString());
    });
  }

  Position? _curentPosition;
  String? _curentAddress;

  void _getAddressFromLatLon() async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
          _curentPosition!.latitude, _curentPosition!.longitude);

      Placemark place = placemarks[0];
      setState(() {
        _curentAddress =
            "${place.locality},${place.postalCode},${place.street},";
      });
      print(
          "Updated Address: $_curentAddress"); // Add this line to check if the address is being updated
    } catch (e) {
      print("Address Error: $e"); // Print the error for debugging
      Fluttertoast.showToast(msg: e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => showModelSafeHome(context),
      child: Card(
        elevation: 5,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          height: 180,
          width: MediaQuery.of(context).size.width * 0.7,
          decoration: BoxDecoration(),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    ListTile(
                      title: Text("Send Location"),
                      subtitle: Text("Share Location"),
                    ),
                    PrimaryButton(
                      title: "SEND ALERT",
                      onPressed: _sendEmergencyMessage,
                    ),
                  ],
                ),
              ),
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.asset('assets/route.jpg'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class PrimaryButton extends StatelessWidget {
  final String title;
  final Function onPressed;
  final bool loading;

  PrimaryButton({
    required this.title,
    required this.onPressed,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      width: MediaQuery.of(context).size.width * 0.5,
      child: ElevatedButton(
        onPressed: () {
          onPressed();
        },
        child: Text(
          title,
          style: TextStyle(fontSize: 17),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.pink,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
      ),
    );
  }
}
