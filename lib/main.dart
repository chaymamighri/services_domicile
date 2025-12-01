import 'package:flutter/material.dart';
import 'package:services_domicile/pages/adminDashboard/UsersPage.dart';
import 'package:services_domicile/pages/adminDashboard/adminpage.dart';
import 'package:services_domicile/pages/userDashboard/userpage.dart';
import 'pages/login.dart';
import 'pages/home.dart';
import 'pages/signup.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'AlloMaison',
      initialRoute: '/',
      routes: {
        '/': (context) => const Home(),
        '/pages/login': (context) => const Login(),
        '/pages/signup': (context) => const SignUp(),
        '/pages/home': (context) => const Home(),
        '/pages/userPage': (context) => const ClientPage(),
       '/pages/adminPage': (context) => const AdminDashboard(),
    
    },
    );
  }
}
