// login page
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'adminDashboard/adminpage.dart';
import 'userDashboard/userpage.dart';
import 'package:services_domicile/globals.dart' as globals;

class Login extends StatefulWidget {
  const Login({super.key});


  @override
  State<Login> createState() => _LoginPageState();
}

class _LoginPageState extends State<Login> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  String messageErreur = '';

  void login() async {
 var url = Uri.parse("${globals.baseUrl}login.php");

  try {
    var response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        "email": _emailController.text,
        "password": _passwordController.text,
      }),
    );

    var data = json.decode(response.body);

    if (data['success'] == true) {
      String role = data['role'];
      
   globals.currentUserId = int.tryParse(data['id'].toString());
   globals.currentUserName = data['nom'].toString();
   globals.currentUserEmail = data['email'].toString();

 print("ID utilisateur récupéré : ${globals.currentUserId}"); // <- test ici
  print("Nom utilisateur : ${globals.currentUserName}");
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Connexion réussie !")),
      );

      //  Redirection selon le role
      if (role == "admin") {
        Navigator.push(
            // ignore: use_build_context_synchronously
            context, MaterialPageRoute(builder: (context) => AdminDashboard()));
      } else if (role == "user") {
        Navigator.push(
            // ignore: use_build_context_synchronously
            context, MaterialPageRoute(builder: (context) => ClientPage()));
      }  else {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(data['message'] ?? "Identifiants incorrects")),
      );
}}
  } catch (e) {
    // ignore: use_build_context_synchronously
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Serveur indisponible")),
    );
  }
}

@override
Widget build(BuildContext context) {
  return Scaffold(
  body: Stack(
    children: [

      // 1. Gradient en arrière-plan

      Container(
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
      ),

      // 2. Contenu principal
      
      Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'images/logo.png',
                width: 200,
                height: 150,
              ),
              const SizedBox(height: 20),
              const Text(
                'AlloMaison',
                style: TextStyle(
                  fontSize: 32,
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  shadows: [
                    Shadow(
                      offset: Offset(2, 2),
                      blurRadius: 8,
                      color: Colors.black26,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),

              const Text(
                'Connectez-vous pour continuer',
                style: TextStyle(fontSize: 16, color: Colors.white70),
              ),
              const SizedBox(height: 30),

              TextField(
                controller: _emailController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Email',
                  hintStyle: TextStyle(color: Colors.white70),
                  filled: true,
                  fillColor: Colors.white24,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide.none,
                  ),
                  prefixIcon: const Icon(Icons.email, color: Colors.white),
                ),
              ),
              const SizedBox(height: 20),

              TextField(
                controller: _passwordController,
                obscureText: true,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Mot de passe',
                  hintStyle: TextStyle(color: Colors.white70),
                  filled: true,
                  fillColor: Colors.white24,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide.none,
                  ),
                  prefixIcon: const Icon(Icons.lock, color: Colors.white),
                ),
              ),
              const SizedBox(height: 30),

            ElevatedButton(
  onPressed: () async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Veuillez remplir tous les champs"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    var url = Uri.parse("${globals.baseUrl}login.php");

    try {
      var response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          "email": email,
          "password": password,
        }),
      );

      var data = json.decode(response.body);

      if (data['success'] == true) {
        // Récupération et conservation de l'ID et nom utilisateur
       globals.currentUserId = int.tryParse(data['id'].toString());
       globals.currentUserName = data['nom'].toString();
       globals.currentUserEmail =data['email'].toString();


        // Debug console
        print("ID utilisateur: ${globals.currentUserId}");
        print("Nom utilisateur: ${globals.currentUserName}");
       print("Nom utilisateur: ${globals.currentUserEmail}");


        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Connexion réussie !"),
            backgroundColor: Colors.green,
          ),
        );

        // Redirection selon rôle
        String role = data['role'];
if (role == "admin") {
  Navigator.pushReplacementNamed(context, '/pages/adminPage');
} else {
  Navigator.pushReplacementNamed(context, '/pages/userPage');
}
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data['message'] ?? "Identifiants incorrects"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Serveur indisponible"),
          backgroundColor: Colors.red,
        ),
      );
      print("Erreur login: $e");
    }
  },
  style: ElevatedButton.styleFrom(
    backgroundColor: Colors.white,
    foregroundColor: const Color(0xFF00C6FF),
    padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(30),
    ),
    elevation: 8,
  ),
  child: const Text(
    'Se connecter',
    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
  ),
),

              const SizedBox(height: 20),

              GestureDetector(
                onTap: () {
                  Navigator.pushNamed(context, '/pages/signup');
                },
                child: const Text(
                  "Pas encore de compte ? S’inscrire",
                  style: TextStyle(color: Colors.white70),
                ),
              ),

              const SizedBox(height: 20),

              TextButton(
                onPressed: () {},
                child: const Text('Mot de passe oublié ?',
                    style: TextStyle(color: Colors.white70)),
              ),

              if (messageErreur.isNotEmpty)
                Text(
                  messageErreur,
                  style: const TextStyle(
                      color: Colors.redAccent, fontWeight: FontWeight.bold),
                ),
            ],
          ),
        ),
      ),

      // 3. Flèche en dernier pour rester visible
      Positioned(
        top: 40,
        left: 10,
        child: InkWell(
          onTap: () => Navigator.pop(context),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: Colors.white24,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.arrow_back, color: Colors.white, size: 28),
          ),
        ),
      ),
    ],
  ),
);
}
}
