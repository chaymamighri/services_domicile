import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:services_domicile/globals.dart';
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:services_domicile/pages/userDashboard/userpage.dart';

class ServicesListScreen extends StatefulWidget {
  final String? currentUserName;

  const ServicesListScreen({Key? key, this.currentUserName}) : super(key: key);

  @override
  _ServicesListScreenState createState() => _ServicesListScreenState();
}

class _ServicesListScreenState extends State<ServicesListScreen> {

  bool _isLoading = true;
  String _selectedCategory = 'Tous';

  final TextEditingController _searchController = TextEditingController();

  List<Map<String, dynamic>> services = [];
  List<Map<String, dynamic>> filteredServices = [];

  @override
  void initState() {
    super.initState();
    _fetchServices();
    _searchController.addListener(_filterServices);
  }

  @override
  void dispose() {
    _searchController.removeListener(_filterServices);
    _searchController.dispose();
    super.dispose();
  }

  // --------------FETCH SERVICES -----------------
  Future<void> _fetchServices() async {
  if (!mounted) return;

  setState(() => _isLoading = true);

  try {
    final response = await http.get(Uri.parse("$baseUrl/get_all_services_with_prestataire.php"));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);

      if (data['success'] == true) {
        List<dynamic> raw = data['services'];

        setState(() {
          services = raw.map<Map<String, dynamic>>((s) {
            return {
              'id': int.tryParse(s['id']?.toString() ?? '0') ?? 0,
              'titre': s['titre']?.toString() ?? 'Titre non disponible',
              'description': s['description']?.toString() ?? 'Description non disponible',
              'prix': s['prix']?.toString() ?? '0',
              'image': s['image']?.toString(),
              'prestataires': s['prestataires'] != null
                  ? List<Map<String, dynamic>>.from(s['prestataires'])
                  : [],
            };
          }).toList();

          filteredServices = List.from(services);
          _isLoading = false;
        });
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } else {
      if (mounted) setState(() => _isLoading = false);
    }
  } catch (e) {
    if (mounted) setState(() => _isLoading = false);
  }
}

  // --------------FILTRAGE -----------------
  void _filterServices() {
    if (!mounted) return;

    final query = _searchController.text.toLowerCase();
    setState(() {
      filteredServices = services.where((service) {
        final titre = service['titre']?.toString().toLowerCase() ?? '';
        final description = service['description']?.toString().toLowerCase() ?? '';

        final matchesSearch = titre.contains(query) || description.contains(query);
        final matchesCategory = _selectedCategory == 'Tous' ||
            titre.contains(_selectedCategory.toLowerCase()) ;

        return matchesSearch && matchesCategory;
      }).toList();
    });
  }

  // ------------- RÉSERVATION ----------------
  Future<void> _faireReservation(Map<String, dynamic> service) async {
  final prestataires = service['prestataires'] as List<dynamic>? ?? [];
  if (prestataires.isEmpty) {
    _showSnackBar("Aucun prestataire disponible pour ce service", Colors.red);
    return;
  }

  // Pour l'instant on prend le premier prestataire (ou créer un choix dans l'UI)
  final prestataire = prestataires[0];

  final confirm = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text("Confirmer la réservation"),
      content: Text("Voulez-vous réserver le service \"${service['titre']}\" avec ${prestataire['nom']} ?"),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Annuler")),
        ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text("Confirmer")),
      ],
    ),
  );

  if (confirm == true) {
    final reservationData = {
      'prestataire_id': prestataire['id'],
      'service_nom': service['titre'],
      'date_reservation': DateFormat('yyyy-MM-dd').format(DateTime.now()),
      'heure_reservation': DateFormat('HH:mm').format(DateTime.now()),
    };
    await _confirmerReservation(reservationData);
  }
}


  Future<void> _confirmerReservation(Map<String, dynamic> reservationData) async {
  // Vérifier que l'utilisateur est connecté
  if (currentUserId == null) {
    _showSnackBar("Veuillez vous connecter pour effectuer une réservation", Colors.red);
    return;
  }
  final String url = "$baseUrl/create_reservation.php";
  try {
    final response = await http.post(Uri.parse(url), body: {
      'user_id': currentUserId!.toString(), // Utiliser ! pour confirmer qu'il n'est pas null
      'prestataire_id': reservationData['prestataire_id'].toString(),
      'date_reservation': reservationData['date_reservation'],
      'heure_reservation': reservationData['heure_reservation'],
      'service_nom': reservationData['service_nom'],
    });

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          _showSnackBar("Réservation créée avec succès!", Colors.green);
          if (mounted) {Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => ClientPage()),
      );
      }
        } else {
          _showSnackBar(data['message'] ?? "Erreur lors de la réservation", Colors.red);
        }
      } else {
        _showSnackBar("Erreur de connexion au serveur: ${response.statusCode}", Colors.red);
      }
    } catch (e) {
      _showSnackBar("Erreur : $e", Colors.red);
    }
  }

  void _showSnackBar(String message, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color, duration: const Duration(seconds: 3)),
    );
  }

  // -------- BUILD ---------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          _buildSearchBar(),
          _buildCategoryFilter(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredServices.isEmpty
                    ? _buildEmptyState()
                    : _buildServicesList(),
          ),
        ],
      ),
       // button refresh
   floatingActionButton: Container(
      width: 56,
      height: 56,
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
            color: Colors.black.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        type: MaterialType.circle,
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(28),
          onTap: _fetchServices,
          child: const Center(
            child: Icon(
              Icons.refresh,
              color: Colors.white,
              size: 28,
            ),
          ),
        ),
      ),
    ),
  );
}

  Widget _buildSearchBar() => Padding(
        padding: const EdgeInsets.all(12),
        child: TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: "Rechercher un service...",
            prefixIcon: const Icon(Icons.search),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      );

   // widget de filtrage 
      Widget _buildCategoryFilter() {
      final List<Map<String, dynamic>> categories = [
      {"name": "Tous", "icon": Icons.apps},
      {"name": "Plomberie", "icon": Icons.plumbing},
      {"name": "Électricité", "icon": Icons.bolt},
      {"name": "Ménage", "icon": Icons.cleaning_services},
      {"name": "Jardinage", "icon": Icons.yard},
      {"name": "Design D'intérieur", "icon": Icons.format_paint},
      {"name": "Babysitting", "icon": Icons.child_care},
    ];

    return SizedBox(
      height: 70,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        itemBuilder: (context, i) {
          final c = categories[i];
          final isSelected = _selectedCategory == c["name"];
          return GestureDetector(
            onTap: () {
              if (mounted) {
                setState(() {
                  _selectedCategory = c["name"]!;
                  _filterServices();
                });
              }
            },
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 7, vertical: 10),
              padding: const EdgeInsets.symmetric(horizontal: 18),
              decoration: BoxDecoration(
                color: isSelected ? Colors.blue : Colors.grey[200],
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Icon(c["icon"], color: isSelected ? Colors.white : Colors.black),
                  const SizedBox(width: 6),
                  Text(c["name"]!, style: TextStyle(color: isSelected ? Colors.white : Colors.black)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text("Aucun service trouvé", style: TextStyle(fontSize: 18, color: Colors.grey[600])),
            const SizedBox(height: 8),
            Text("Essayez de modifier vos critères de recherche", style: TextStyle(color: Colors.grey[500])),
          ],
        ),
      );

  Widget _buildServicesList() => ListView.builder(
        itemCount: filteredServices.length,
        itemBuilder: (context, index) => _buildServiceCard(filteredServices[index]),
      );

  Widget _buildServiceCard(Map<String, dynamic> service) => Card(
        margin: const EdgeInsets.all(10),
        elevation: 3,
        child: ListTile(
          leading: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: service["image"] != null && service["image"].toString().isNotEmpty
                ? Image.network(
                    "$baseUrl${service['image']}",
                    width: 60,
                    height: 60,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      width: 60,
                      height: 60,
                      color: Colors.grey[300],
                      child: const Icon(Icons.home_repair_service),
                    ),
                  )
                : Container(
                    width: 60,
                    height: 60,
                    color: Colors.grey[300],
                    child: const Icon(Icons.home_repair_service),
                  ),
          ),
          title: Text(service['titre']?.toString() ?? 'Titre non disponible', style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text("${service['prix']} DT"),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          onTap: () => _showServiceDetails(service),
        ),
      );

  void _showServiceDetails(Map<String, dynamic> service) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => ServiceDetailsModal(
        service: service,
        onReservation: _faireReservation,
      ),
    );
  }
}

// ---------- MODAL DETAILS ---------------
class ServiceDetailsModal extends StatelessWidget {

  final Map<String, dynamic> service;
  final Function(Map<String, dynamic>) onReservation;

  const ServiceDetailsModal({
    Key? key,
    required this.service,
    required this.onReservation,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(service['titre']?.toString() ?? 'Titre non disponible', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Text(service['description']?.toString() ?? 'Description non disponible', style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 15),
            Text("Prix: ${service['prix']} DT", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green)),
            const SizedBox(height: 25),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  onReservation(service);
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, padding: const EdgeInsets.symmetric(vertical: 16)),
                child: const Text("Réserver ce service", style: TextStyle(fontSize: 16, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
