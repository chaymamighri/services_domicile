import 'package:flutter/material.dart';
import '../../widgets/custom_appbar.dart';
import 'DashboardHomePage.dart';
import 'PrestatairesPage.dart';
import 'ServicesPage.dart';
import 'BookingsPage.dart';
import 'UsersPage.dart'; // Nouvelle page
import 'package:services_domicile/globals.dart' as globals;

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _currentIndex = 0;

  // Liste des pages
  final List<Widget> _pages = [
    DashboardHomePage(),
    UsersPage(),          // Page utilisateurs
    PrestatairesPage(),
    ServicesPage(),
    ReservationsPage(),
  ];

  void onTabTapped(int index) {
    setState(() {
      _currentIndex = index; // Affiche la page sélectionnée
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        showBack: true,
        title: "Dashboard Admin",
        centerTitle: true,
        username: globals.currentUserName,
        onLogout: () {
          globals.currentUserName = null;
          Navigator.of(context).pushReplacementNamed('/pages/login');
        },
      ),
      body: _pages[_currentIndex],
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
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: onTabTapped,
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.transparent,
          elevation: 0,
          selectedItemColor: Colors.white,
          unselectedItemColor: Colors.white70,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard),
              label: "Dashboard",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person),
              label: "Utilisateurs",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.handshake),
              label: "Prestataires",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.miscellaneous_services),
              label: "Services",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.book_online),
              label: "Réservations",
            ),
          ],
        ),
      ),
    );
  }
}
