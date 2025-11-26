import 'package:flutter/material.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';
import 'package:move_buddy/Event/screens/event_list_page.dart';

void main() {
  runApp(const MoveBuddyApp());
}

class MoveBuddyApp extends StatelessWidget {
  const MoveBuddyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Provider(
      create: (_) {
        CookieRequest request = CookieRequest();
        return request;
      },
      child: MaterialApp(
        title: 'Move Buddy',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF84CC16)),
          useMaterial3: true,
        ),
        home: const EventListPage(), // LANGSUNG KE EVENT LIST
      ),
    );
  }
}