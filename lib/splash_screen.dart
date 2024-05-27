import 'package:flutter/material.dart';
import 'chat_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration(seconds: 5), () {
      Navigator.push(
          context, MaterialPageRoute(builder: (context) => ChatScreen()));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Container(
              width: 150, // Adjust the width as needed
              height: 150, // Adjust the height as needed
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20), // Rounded corners
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 10,
                    offset: Offset(0, 5), // Shadow position
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.asset(
                  'assets/logo.jpeg',
                  fit: BoxFit.cover, // Ensure the image fits the container
                ),
              ),
            ),
            SizedBox(height: 20), // Add some spacing between the logo and text
            Text(
              "Personal ChatBot",
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 30, // Adjust the font size as needed
                color: Colors.black, // Change the text color if needed
              ),
            ),
          ],
        ),
      ),
    );
  }
}
