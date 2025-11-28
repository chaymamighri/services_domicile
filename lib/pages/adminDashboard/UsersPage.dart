import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:services_domicile/globals.dart';
import 'dart:convert';

class UsersPage extends StatefulWidget {
  const UsersPage({super.key});

  @override
  State<UsersPage> createState() => _UsersPageState();
}

class _UsersPageState extends State<UsersPage> {
  List<dynamic> _users = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    fetchUsers();
  }

  Future<void> fetchUsers() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/get_all_users.php')
      );

      print('Status Code: ${response.statusCode}');
      print('Response Body: ${response.body}'); // Pour debug

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        // Vérifier si la réponse est un objet avec une clé 'users'
        if (data is Map && data.containsKey('users')) {
          setState(() {
            _users = data['users'] as List<dynamic>;
            _isLoading = false;
          });
        } 
        // Ou si c'est directement une liste
        else if (data is List) {
          setState(() {
            _users = data;
            _isLoading = false;
          });
        }
        // Sinon, erreur de format
        else {
          setState(() {
            _errorMessage = 'Format de réponse invalide';
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _errorMessage = 'Erreur serveur : ${response.statusCode}';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Erreur de connexion : $e';
        _isLoading = false;
      });
      print('Exception: $e'); // Pour debug
    }
  }

 Future<void> deleteUser(dynamic id) async {
  // Convertir en int
  final userId = int.tryParse(id.toString()) ?? 0;
  
  if (userId == 0) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('ID utilisateur invalide')),
    );
    return;
  }

  try {
    final response = await http.post(
      Uri.parse('$baseUrl/delete_user.php'),
      headers: {
        'Content-Type': 'application/json', 
      },
      body: json.encode({'id': userId}),  
    );

    if (response.statusCode == 200) {
      final result = json.decode(response.body);
      if (result['success'] == true) {
        if (mounted) { 
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Utilisateur supprimé avec succès')),
          );
          fetchUsers();
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erreur : ${result['message']}')),
          );
        }
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur serveur : ${response.statusCode}')),
        );
      }
    }
  } catch (e) {
    print('Exception: $e'); // Pour debug
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur de connexion : $e')),
      );
    }
  }
}
  

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: fetchUsers,
              child: const Text('Réessayer'),
            ),
          ],
        ),
      );
    }

    if (_users.isEmpty) {
      return const Center(child: Text('Aucun utilisateur trouvé'));
    }

    return RefreshIndicator(
      onRefresh: fetchUsers,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _users.length,
        itemBuilder: (context, index) {
          final user = _users[index];
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 8),
            child: ListTile(
              leading: CircleAvatar(
                child: Text(
                  (user['nom'] ?? 'U')[0].toUpperCase(),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              title: Text(user['nom'] ?? 'Nom inconnu'),
              subtitle: Text(user['email'] ?? 'Email inconnu'),
              trailing: IconButton(
  icon: const Icon(Icons.delete, color: Colors.red),
  onPressed: () {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(  // ← Changé ici
        title: const Text('Confirmer la suppression'),
        content: Text(
          'Voulez-vous supprimer ${user['nom']} ?',
        ),
        actions: [
          TextButton(
            child: const Text('Annuler'),
            onPressed: () => Navigator.pop(dialogContext),  // ← Utiliser dialogContext
          ),
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Supprimer'),
            onPressed: () {
              Navigator.pop(dialogContext);  // ← Utiliser dialogContext
              deleteUser(user['id']);
            },
          ),
        ],
      ),
    );
  },
),
            ),
          );
        },
      ),
    );
  }
}