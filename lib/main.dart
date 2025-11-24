import 'package:flutter/material.dart';

import 'court/screens/courts_list_screen.dart';
import 'court/services/court_service.dart';

void main() {
  const overrideBaseUrl = String.fromEnvironment('COURT_BASE_URL');
  final courtService = CourtService(
    baseUrl: overrideBaseUrl.isEmpty ? null : overrideBaseUrl,
  );
  runApp(MoveBuddyApp(courtService: courtService));
}

class MoveBuddyApp extends StatelessWidget {
  const MoveBuddyApp({super.key, required this.courtService});

  final CourtService courtService;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MoveBuddy',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFCBED98)),
        useMaterial3: true,
      ),
      home: CourtsListScreen(courtService: courtService),
    );
  }
}
