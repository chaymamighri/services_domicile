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

  // Fonction pour afficher la boîte de dialogue de réinitialisation
  void _showResetPasswordDialog() {
    showDialog(
      context: context,
      builder: (context) => PasswordResetDialog(),
    );
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
                      hintStyle: const TextStyle(color: Colors.white70),
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
                      hintStyle: const TextStyle(color: Colors.white70),
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
                          globals.currentUserId = int.tryParse(data['id'].toString());
                          globals.currentUserName = data['nom'].toString();
                          globals.currentUserEmail = data['email'].toString();

                          print("ID utilisateur: ${globals.currentUserId}");
                          print("Nom utilisateur: ${globals.currentUserName}");
                          print("Email utilisateur: ${globals.currentUserEmail}");

                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Connexion réussie !"),
                              backgroundColor: Colors.green,
                            ),
                          );

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
                      "Pas encore de compte ? S'inscrire",
                      style: TextStyle(color: Colors.white70),
                    ),
                  ),

                  const SizedBox(height: 20),

                  TextButton(
                    onPressed: _showResetPasswordDialog,
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

// Boîte de dialogue pour la réinitialisation de mot de passe
class PasswordResetDialog extends StatefulWidget {
  const PasswordResetDialog({super.key});

  @override
  State<PasswordResetDialog> createState() => _PasswordResetDialogState();
}

class _PasswordResetDialogState extends State<PasswordResetDialog> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  
  String _step = 'email'; // 'email' -> 'verify' -> 'new_password'
  bool _isLoading = false;
  String _message = '';
  bool _isSuccess = false;

  Future<void> _verifyIdentity() async {
    if (_emailController.text.isEmpty) {
      setState(() {
        _message = 'Veuillez entrer votre email';
        _isSuccess = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _message = '';
    });

    try {
      var url = Uri.parse("${globals.baseUrl}verify_identity.php");
      var response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          "email": _emailController.text,
        }),
      );

      var data = json.decode(response.body);
      
      if (data['success'] == true) {
        setState(() {
          _step = 'new_password';
          _message = 'Vérification réussie. Entrez votre nouveau mot de passe.';
          _isSuccess = true;
        });
      } else {
        setState(() {
          _message = data['message'] ?? 'Email non trouvé';
          _isSuccess = false;
        });
      }
    } catch (e) {
      setState(() {
        _message = 'Erreur de connexion au serveur';
        _isSuccess = false;
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _resetPassword() async {
    if (_newPasswordController.text.isEmpty || _confirmPasswordController.text.isEmpty) {
      setState(() {
        _message = 'Veuillez remplir tous les champs';
        _isSuccess = false;
      });
      return;
    }

    if (_newPasswordController.text != _confirmPasswordController.text) {
      setState(() {
        _message = 'Les mots de passe ne correspondent pas';
        _isSuccess = false;
      });
      return;
    }

    if (_newPasswordController.text.length < 6) {
      setState(() {
        _message = 'Le mot de passe doit contenir au moins 6 caractères';
        _isSuccess = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _message = '';
    });

    try {
      var url = Uri.parse("${globals.baseUrl}reset_password.php");
      var response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          "email": _emailController.text,
          "new_password": _newPasswordController.text,
        }),
      );

      var data = json.decode(response.body);
      
      if (data['success'] == true) {
        setState(() {
          _message = 'Mot de passe réinitialisé avec succès !';
          _isSuccess = true;
        });
        
        // Fermer la boîte de dialogue après 2 secondes
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) {
          Navigator.pop(context);
        }
      } else {
        setState(() {
          _message = data['message'] ?? 'Erreur lors de la réinitialisation';
          _isSuccess = false;
        });
      }
    } catch (e) {
      setState(() {
        _message = 'Erreur de connexion au serveur';
        _isSuccess = false;
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Widget _buildEmailStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'Réinitialiser votre mot de passe',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 15),
        const Text(
          'Entrez votre email pour vérifier votre identité',
          style: TextStyle(color: Colors.grey),
        ),
        const SizedBox(height: 20),
        
        TextField(
          controller: _emailController,
          decoration: InputDecoration(
            labelText: 'Email',
            prefixIcon: const Icon(Icons.email),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
        const SizedBox(height: 20),
        
        if (_message.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _isSuccess ? Colors.green[50] : Colors.red[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: _isSuccess ? Colors.green : Colors.red,
                width: 1,
              ),
            ),
            child: Text(
              _message,
              style: TextStyle(
                color: _isSuccess ? Colors.green[800] : Colors.red[800],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildPasswordStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'Nouveau mot de passe',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 15),
        Text(
          'Pour ${_emailController.text}',
          style: const TextStyle(color: Colors.grey, fontSize: 14),
        ),
        const SizedBox(height: 5),
        const Text(
          'Entrez votre nouveau mot de passe',
          style: TextStyle(color: Colors.grey, fontSize: 14),
        ),
        const SizedBox(height: 20),
        
        TextField(
          controller: _newPasswordController,
          obscureText: true,
          decoration: InputDecoration(
            labelText: 'Nouveau mot de passe',
            prefixIcon: const Icon(Icons.lock),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
        const SizedBox(height: 15),
        
        TextField(
          controller: _confirmPasswordController,
          obscureText: true,
          decoration: InputDecoration(
            labelText: 'Confirmer le mot de passe',
            prefixIcon: const Icon(Icons.lock),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
        const SizedBox(height: 20),
        
        if (_message.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _isSuccess ? Colors.green[50] : Colors.red[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: _isSuccess ? Colors.green : Colors.red,
                width: 1,
              ),
            ),
            child: Text(
              _message,
              style: TextStyle(
                color: _isSuccess ? Colors.green[800] : Colors.red[800],
              ),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Étape actuelle
              _step == 'email' ? _buildEmailStep() : _buildPasswordStep(),
              
              const SizedBox(height: 20),
              
              // Boutons
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Annuler'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : ElevatedButton(
                          onPressed: _step == 'email' ? _verifyIdentity : _resetPassword,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color.fromARGB(255, 5, 143, 182),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: Text(
                            _step == 'email' ? 'Vérifier' : 'Réinitialiser',
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                  ),
                ],
              ),
              
              if (_step == 'new_password')
                TextButton(
                  onPressed: () {
                    setState(() {
                      _step = 'email';
                      _message = '';
                    });
                  },
                  child: const Text('Retour à la vérification'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}