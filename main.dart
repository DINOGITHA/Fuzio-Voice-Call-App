import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';
import 'package:flutter_phone_direct_caller/flutter_phone_direct_caller.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:path_provider/path_provider.dart';
import 'splash_screen.dart'; // Import the splash screen file
import 'dart:io';
import 'package:http/http.dart' as http;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fuzio',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const SplashScreen(), // Set the SplashScreen as the initial route
    );
  }
}

class DialerScreen extends StatefulWidget {
  const DialerScreen({Key? key}) : super(key: key);

  @override
  _DialerScreenState createState() => _DialerScreenState();
}

class _DialerScreenState extends State<DialerScreen> {
  String phoneNumber = '';
  bool isRecording = false;
  Record record = Record();
  String filePath = '';
  late FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
  }

  Future<void> _initializeNotifications() async {
    flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  Future<void> _showNotification(String title, String body) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'record_channel',
      'Recording Notifications',
      channelDescription: 'Notification when the recording stops',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: false,
    );

    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);
    await flutterLocalNotificationsPlugin.show(
      0,
      title,
      body,
      platformChannelSpecifics,
      payload: 'Recording stopped',
    );
  }

  Future<void> _makeCall() async {
    if (phoneNumber.length == 10) {  // Check for 10-digit phone number
      if (await Permission.phone.request().isGranted) {
        await FlutterPhoneDirectCaller.callNumber(phoneNumber);
        await _startRecording();

        Future.delayed(const Duration(seconds: 40), () async {
          if (isRecording) {
            await _stopRecording();
            await _sendRecordingToServer();
          }
        });
      }
    } else {
      _showNotification('Invalid Number', 'Please enter a valid 10-digit phone number');
    }
  }

  Future<void> _startRecording() async {
    if (await Permission.microphone.request().isGranted) {
      Directory appDir = await getApplicationDocumentsDirectory();
      filePath =
          '${appDir.path}/call_recording_${DateTime.now().millisecondsSinceEpoch}.m4a';
      await record.start(path: filePath);
      setState(() {
        isRecording = true;
      });
      print("Recording started at $filePath");
    }
  }

  Future<void> _stopRecording() async {
    await record.stop();
    setState(() {
      isRecording = false;
    });
    print("Recording stopped");
  }

  Future<void> _sendRecordingToServer() async {
    final uri = Uri.parse('https://polar-oasis-65498-0772e687592e.herokuapp.com/');

    var request = http.MultipartRequest('POST', uri)
      ..files.add(await http.MultipartFile.fromPath('file', filePath));

    try {
      var response = await request.send();
      if (response.statusCode == 200) {
        final responseBody = await http.Response.fromStream(response);
        _handleEmotionResponse(responseBody.body);
      } else {
        _showNotification('Error', 'Failed to upload recording.');
      }
    } catch (e) {
      print('Error: $e');
      _showNotification('Error', 'An error occurred while uploading.');
    }
  }

  void _handleEmotionResponse(String responseBody) {
    // Assuming the response contains the detected emotion as plain text
    String detectedEmotion = responseBody.trim();

    switch (detectedEmotion.toLowerCase()) {
      case 'happy':
        _showNotification('Happy', 'All Smiles!');
        break;
      case 'sad':
        _showNotification('Sad', 'Feeling Down');
        break;
      case 'neutral':
        _showNotification('Neutral', 'Calm and Clear');
        break;
      case 'angry':
        _showNotification('Angry', 'Tension Alert');
        break;
      default:
        _showNotification('Unknown Emotion', 'Emotion not recognized.');
    }
  }

  @override
  void dispose() {
    if (isRecording) _stopRecording();
    super.dispose();
  }

  void _onDialButtonPressed(String value) {
    setState(() {
      phoneNumber += value;
    });
  }

  void _onBackspacePressed() {
    if (phoneNumber.isNotEmpty) {
      setState(() {
        phoneNumber = phoneNumber.substring(0, phoneNumber.length - 1);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fuzio'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              readOnly: true,
              decoration: const InputDecoration(
                labelText: 'Phone Number',
                border: OutlineInputBorder(),
              ),
              controller: TextEditingController(text: phoneNumber),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: GridView.count(
                crossAxisCount: 3,
                children: [
                  ...[ '1', '2', '3', '4', '5', '6', '7', '8', '9', '*', '0', '#' ]
                      .map((e) => _buildDialButton(e)),
                ],
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  icon: const Icon(Icons.backspace),
                  onPressed: _onBackspacePressed,
                ),
                ElevatedButton(
                  onPressed: _makeCall,
                  child: const Text('Make Call'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDialButton(String value) {
    return GestureDetector(
      onTap: () => _onDialButtonPressed(value),
      child: Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.blue.shade100,
        ),
        child: Center(
          child: Text(
            value,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}
