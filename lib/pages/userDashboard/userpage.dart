import 'package:flutter/material.dart';
import 'package:services_domicile/widgets/custom_appbar.dart';
import 'package:services_domicile/globals.dart' as globals;import 'dart:convert';

class ClientPage extends StatelessWidget {
  const ClientPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
  appBar: CustomAppBar(
    showBack: true,
    title: "bienvenue ✨",
    centerTitle: true,
      username: globals.currentUserName, // nom du user connecté
    onLogout: () {
      // revenir à login sans accéder à globals non définis ici
          globals.currentUserName = null;
      Navigator.of(context).pushReplacementNamed('/pages/login');
    },
  ),
    );
  }
}

