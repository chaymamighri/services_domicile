import 'package:flutter/material.dart';


class Home extends StatelessWidget {
  const Home({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
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
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo
              Image.asset(
                'images/logo.png',
                width: 250, // réduit pour un meilleur rendu
                height: 200,
              ),
              const SizedBox(height: 30), // espace réduit entre logo et titre

              // Titre
              const Text(
                'AlloMaison',
                style: TextStyle(
                  fontSize: 36,
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w800,
                  color: Color.fromARGB(255, 250, 249, 253),
                  letterSpacing: 1.5,
                  shadows: [
                    Shadow(
                      offset: Offset(3, 3),
                      blurRadius: 10,
                      color: Color.fromARGB(66, 5, 5, 5),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10), // petit espace avant le slogan

              // Slogan
              const Text(
                'Tous vos services à domicile en un clic !',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 40), // espace avant le bouton

              // Bouton Explorer
              ElevatedButton(
                key: const Key('exploreButton'),
                onPressed: () {
                  Navigator.pushNamed(context, '/pages/login');
                  
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF00C6FF),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 40, vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  elevation: 8,
                ),
                child: const Text(
                  'Explorer',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
