import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:services_domicile/pages/userDashboard/profile_page.dart';
import 'package:services_domicile/widgets/custom_appbar.dart';
import 'package:services_domicile/globals.dart' as globals;
import 'services_list.dart';
import 'reservation_history.dart';

class ClientPage extends StatefulWidget {
  const ClientPage({super.key});

  @override
  State<ClientPage> createState() => _ClientPageState();
}

class _ClientPageState extends State<ClientPage> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    ServicesListScreen(),
    ReservationHistoryScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        showBack: true,
        title: "Bienvenue",
        centerTitle: true,
        username: globals.currentUserName ?? "Utilisateur",
        onLogout: () {
          globals.currentUserName = null;
          Navigator.of(context).pushReplacementNamed('/pages/login');
        },
      ),
   body: _screens[_currentIndex],

bottomNavigationBar: Container(
  decoration: const BoxDecoration(
    gradient: LinearGradient(
      colors: [
        Color.fromARGB(255, 5, 143, 182),
              Color.fromARGB(255, 56, 177, 119),
              Color.fromARGB(250, 146, 83, 137),
            ],

      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
  ),
  child: Theme(
    data: Theme.of(context).copyWith(
      canvasColor: Colors.transparent, 
    ),
    child: BottomNavigationBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      currentIndex: _currentIndex,
      selectedItemColor: Colors.white,
      unselectedItemColor: Colors.white70,
      onTap: (index) {
        setState(() {
          _currentIndex = index;
        });
      },
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: 'Services',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.history),
          label: 'Réservations',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person),
          label: 'Profil',
        ),
      ],
    ),
  ),
),
);
}
}
