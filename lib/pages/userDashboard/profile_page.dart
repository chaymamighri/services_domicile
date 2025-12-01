import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:services_domicile/globals.dart' as globals;



class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Login")),
      body: const Center(
        child: Text("Page Login"),
      ),
    );
  }
}



// PAGE PROFILE SCREEN

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {

  // ==== update profile ====
// ==== update profile ====
Future<bool> updateProfile(String name, String email) async {
  try {
    final response = await http.post(
      Uri.parse('${globals.baseUrl}/update_profile.php'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'id': globals.currentUserId.toString(),
        'name': name,  // Changed from 'nom' to 'name'
        'email': email,
      }),
    );

    print("Status Code: ${response.statusCode}");
    print("Réponse serveur: ${response.body}");

    // Check if response is valid JSON
    final data = json.decode(response.body);
    return data['success'] == true;
  } catch (e) {
    print("Erreur updateProfile: $e");
  
    return false;
  }
}

// ==== update password ====
Future<bool> updatePassword(String oldPassword, String newPassword) async {
  try {
    final response = await http.post(
      Uri.parse('${globals.baseUrl}/update_password.php'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'id': globals.currentUserId.toString(),
        'old_password': oldPassword,
        'new_password': newPassword,
      }),
    );
    
 //   print("Password Update Status: ${response.statusCode}");
   // print("Password Update Response: ${response.body}");
    
    final data = json.decode(response.body);
    return data['success'] == true;
  } catch (e) {
    print("Erreur updatePassword: $e");
    return false;
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Profil"),
        automaticallyImplyLeading: false,
      ),


      body: Padding(
        padding: const EdgeInsets.all(16.0),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
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
                            globals.currentUserName ?? 'Non connecté',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            globals.currentUserEmail ?? 'Email non disponible',
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

            // MODIFIER PROFILE

            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Modifier Profile'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                showDialog(
                  context: context,
                  builder: (context) {
                    final TextEditingController nameController =
                        TextEditingController(text: globals.currentUserName ?? '');
                    final TextEditingController emailController =
                        TextEditingController(text: globals.currentUserEmail ?? '');

                    return AlertDialog(
                      title: const Text("Modifier Profile"),

                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TextField(
                            controller: nameController,
                            decoration: const InputDecoration(labelText: "Nom"),
                          ),
                          const SizedBox(height: 10),
                          TextField(
                            controller: emailController,
                            decoration: const InputDecoration(labelText: "Email"),
                          ),
                        ],
                      ),

                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text("Annuler"),
                        ),

                        ElevatedButton(
                          onPressed: () async {
                            Navigator.pop(context);

                            bool success = await updateProfile(
                              nameController.text,
                              emailController.text,
                            );

                            if (success) {
                              globals.currentUserName = nameController.text;
                              globals.currentUserEmail = emailController.text;

                              setState(() {}); // rafraîchir l'écran

                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text("Profil modifié avec succès")),
                              );
                              
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text("Erreur lors de la modification")),
                              );
                            }
                          },
                          child: const Text("Modifier"),
                        ),
                      ],
                    );
                  },
                );
              },
            ),

            // Modifier mdp
         
            ListTile(
              leading: const Icon(Icons.lock),
              title: const Text("Modifier mot de passe"),
              trailing: const Icon(Icons.arrow_forward_ios),

              onTap: () {
                showDialog(
                  context: context,
                  builder: (context) {
                    final oldPass = TextEditingController();
                    final newPass = TextEditingController();
                    final confirmPass = TextEditingController();

                    return AlertDialog(
                      title: const Text("Modifier mot de passe"),

                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TextField(
                            controller: oldPass,
                            obscureText: true,
                            decoration: const InputDecoration(labelText: "Ancien mot de passe"),
                          ),
                          TextField(
                            controller: newPass,
                            obscureText: true,
                            decoration: const InputDecoration(labelText: "Nouveau mot de passe"),
                          ),
                          TextField(
                            controller: confirmPass,
                            obscureText: true,
                            decoration: const InputDecoration(labelText: "Confirmer mot de passe"),
                          ),
                        ],
                      ),

                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text("Annuler"),
                        ),

                        ElevatedButton(
                          onPressed: () async {
                            if (newPass.text != confirmPass.text) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text("Les mots de passe ne correspondent pas")),
                              );
                              return;
                            }

                            Navigator.pop(context);

                            bool success = await updatePassword(
                              oldPass.text,
                              newPass.text,
                            );

                            if (success) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text("Mot de passe modifié avec succès")),
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text("Erreur : ancien mot de passe incorrect")),
                              );
                            }
                          },
                          child: const Text("Modifier"),
                        ),
                      ],
                    );
                  },
                );
              },
            ),

        // deconnexion

            ListTile(
              leading: const Icon(Icons.exit_to_app),
              title: const Text('Déconnexion'),
              trailing: const Icon(Icons.arrow_forward_ios),

              onTap: () {
                globals.currentUserName = null;
                globals.currentUserEmail = null;

                Navigator.pushReplacementNamed(context, '/pages/login');
                
              },
            ),

          ],
        ),
      ),
    );
  }
}
