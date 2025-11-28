import 'dart:convert';
import 'package:flutter/material.dart';
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
          Navigator.of(context).pushReplacementNamed('/pages/login'); // Assurez-vous que la route existe
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
      canvasColor: Colors.transparent, // pour que le fond du nav bar soit transparent
    ),
    child: BottomNavigationBar(
      backgroundColor: Colors.transparent, // important pour voir le gradient
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

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.blue[100],
                    child: Icon(Icons.person, size: 30, color: Colors.blue[700]),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          globals.currentUserName ?? 'John Doe',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'john.doe@email.com', // Tu peux récupérer depuis globals
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Paramètres'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.help),
            title: const Text('Aide & Support'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.exit_to_app),
            title: const Text('Déconnexion'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              globals.currentUserName = null;
              Navigator.of(context).pushReplacementNamed('/pages/login');
            },
          ),
        ],
      ),
    );
  }
}
