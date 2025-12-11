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
      final response = await http.get(Uri.parse('$baseUrl/get_all_users.php'));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data is Map && data.containsKey('users')) {
          setState(() {
            _users = data['users'] as List<dynamic>;
            _isLoading = false;
          });
        } else if (data is List) {
          setState(() {
            _users = data;
            _isLoading = false;
          });
        } else {
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
    }
  }

  Future<void> deleteUser(dynamic id) async {
    final userId = int.tryParse(id.toString()) ?? 0;

    if (userId == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('ID utilisateur invalide'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
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
              SnackBar(
                content: const Text('Utilisateur supprimé avec succès'),
                backgroundColor: Colors.green,
                behavior: SnackBarBehavior.floating,
              ),
            );
            fetchUsers();
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Erreur : ${result['message']}'),
                backgroundColor: Colors.red,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erreur serveur : ${response.statusCode}'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur de connexion : $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Widget _buildUserAvatar(dynamic user) {
    final String? name = user['nom']?.toString();
    final String initials = name != null && name.isNotEmpty
        ? name[0].toUpperCase()
        : 'U';
    
    final Color avatarColor = _getAvatarColor(user['id']?.hashCode ?? 0);
    
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            avatarColor.withOpacity(0.9),
            avatarColor.withOpacity(0.7),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: avatarColor.withOpacity(0.3),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Center(
        child: Text(
          initials,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
    );
  }

  Color _getAvatarColor(int seed) {
    final colors = [
      const Color.fromARGB(255, 5, 143, 182),   // Bleu
      const Color.fromARGB(255, 56, 177, 119), // Vert
      const Color.fromARGB(250, 146, 83, 137), // Violet
      const Color.fromARGB(255, 255, 152, 0),  // Orange
      const Color.fromARGB(255, 156, 39, 176), // Violet foncé
      const Color.fromARGB(255, 33, 150, 243), // Bleu clair
    ];
    return colors[seed % colors.length];
  }

  Widget _buildUserRole(dynamic user) {
    final String? role = user['role']?.toString();
    if (role == null || role.isEmpty) return const SizedBox();
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _getRoleColor(role),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        role.toUpperCase(),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Color _getRoleColor(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return Colors.red;
      case 'prestataire':
        return Colors.orange;
      case 'client':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  Widget _buildUserStats(dynamic user) {
    return Row(
      children: [
        if (user['phone'] != null)
          Row(
            children: [
              const Icon(Icons.phone, size: 12, color: Colors.grey),
              const SizedBox(width: 4),
              Text(
                user['phone'].toString(),
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        if (user['created_at'] != null) ...[
          const SizedBox(width: 12),
          Row(
            children: [
              const Icon(Icons.calendar_today, size: 12, color: Colors.grey),
              const SizedBox(width: 4),
              Text(
                _formatDate(user['created_at'].toString()),
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ],
      ],
    );
  }

  String _formatDate(String date) {
    try {
      final DateTime parsedDate = DateTime.parse(date);
      return '${parsedDate.day}/${parsedDate.month}/${parsedDate.year}';
    } catch (e) {
      return date;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestion des Utilisateurs'),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  Color.fromARGB(255, 5, 143, 182),   // Bleu
                  Color.fromARGB(255, 56, 177, 119), // Vert
                  Color.fromARGB(250, 146, 83, 137), // Violet
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white),
              onPressed: fetchUsers,
              tooltip: 'Actualiser',
            ),
          ),
        ],
      ),
      body: _isLoading
          ? _buildLoading()
          : _errorMessage != null
              ? _buildError()
              : _users.isEmpty
                  ? _buildEmpty()
                  : _buildUserList(),
    );
  }

  Widget _buildLoading() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  Color.fromARGB(255, 5, 143, 182),
                  Color.fromARGB(255, 56, 177, 119),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
            ),
            child: const CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation(Colors.white),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Chargement des utilisateurs...',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 80,
              color: Colors.red[300],
            ),
            const SizedBox(height: 20),
            Text(
              _errorMessage!,
              style: TextStyle(
                color: Colors.red[600],
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: fetchUsers,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                backgroundColor: const Color.fromARGB(255, 5, 143, 182),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                elevation: 2,
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.refresh, color: Colors.white),
                  SizedBox(width: 8),
                  Text(
                    'Réessayer',
                    style: TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people_outline,
            size: 100,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 20),
          Text(
            'Aucun utilisateur',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Aucun utilisateur n\'a été trouvé dans la base de données.',
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 30),
          ElevatedButton(
            onPressed: fetchUsers,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color.fromARGB(255, 5, 143, 182),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: const Text('Actualiser', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildUserList() {
    return RefreshIndicator(
      onRefresh: fetchUsers,
      backgroundColor: Colors.white,
      color: const Color.fromARGB(255, 5, 143, 182),
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _users.length,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final user = _users[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(15),
              onTap: () {
                // Option: Ajouter un onTap pour voir les détails
              },
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    _buildUserAvatar(user),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  user['nom'] ?? 'Nom inconnu',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              _buildUserRole(user),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            user['email'] ?? 'Email inconnu',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          _buildUserStats(user),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.delete_outline,
                          color: Colors.red,
                          size: 20,
                        ),
                      ),
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (dialogContext) => AlertDialog(
                            title: const Text('Confirmer la suppression'),
                            content: RichText(
                              text: TextSpan(
                                style: const TextStyle(
                                  color: Colors.black87,
                                  fontSize: 15,
                                ),
                                children: [
                                  const TextSpan(
                                    text: 'Voulez-vous vraiment supprimer l\'utilisateur ',
                                  ),
                                  TextSpan(
                                    text: '${user['nom']}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const TextSpan(
                                    text: ' ?\n\nCette action est irréversible.',
                                  ),
                                ],
                              ),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            actions: [
                              TextButton(
                                child: const Text('Annuler'),
                                onPressed: () => Navigator.pop(dialogContext),
                              ),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                child: const Text(
                                  'Supprimer',
                                  style: TextStyle(color: Colors.white),
                                ),
                                onPressed: () {
                                  Navigator.pop(dialogContext);
                                  deleteUser(user['id']);
                                },
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}