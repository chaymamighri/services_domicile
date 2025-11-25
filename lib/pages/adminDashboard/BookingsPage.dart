import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:services_domicile/globals.dart';

class ReservationsPage extends StatefulWidget {
  const ReservationsPage({super.key});

  @override
  State<ReservationsPage> createState() => _ReservationsPageState();
}

class _ReservationsPageState extends State<ReservationsPage> {
  List<Map<String, dynamic>> reservations = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchReservations();
  }

  // FETCH RESERVATIONS

  Future<void> fetchReservations() async {
    setState(() => _isLoading = true);
    try {
      final response = await http.get(Uri.parse("$baseUrl/get_all_reservations.php"));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> rawList = data['reservations'] ?? [];
        final List<Map<String, dynamic>> listMapped = rawList.map<Map<String, dynamic>>((res) {
          return {
            ...Map<String, dynamic>.from(res),
            'id': int.parse(res['id'].toString()),
            'statut': res['statut'].toString().toLowerCase(),
          };
        }).toList();

        setState(() {
          reservations = listMapped;
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
        _showSnackBar("Erreur serveur", Colors.red);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnackBar("Erreur : $e", Colors.red);
    }
  }

  // UPDATE STATUS reservation

  Future<void> updateReservationStatus(int id, String status) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/update_reservation_status.php"),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'id': id, 'statut': status}),
      );

      final data = json.decode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        await fetchReservations();
        _showSnackBar("Réservation ${status.toUpperCase()} avec succès", Colors.green);
      } else {
        _showSnackBar(data['message'] ?? "Erreur mise à jour", Colors.orange);
      }
    } catch (e) {
      _showSnackBar("Erreur : $e", Colors.red);
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color backgroundColor;
    Color textColor;
    String statusText;

    switch (status) {
      case 'confirmée':
        backgroundColor = Colors.green.withOpacity(0.15);
        textColor = Colors.green;
        statusText = 'CONFIRMÉE';
        break;
      case 'rejetee':
      case 'rejetée':
        backgroundColor = Colors.red.withOpacity(0.15);
        textColor = Colors.red;
        statusText = 'REJETÉE';
        break;
      case 'en_attente':
        backgroundColor = Colors.orange.withOpacity(0.15);
        textColor = Colors.orange;
        statusText = 'EN ATTENTE';
        break;
      default:
        backgroundColor = const Color(0xFF56390F).withOpacity(0.15);
        textColor = const Color(0xFF56390F);
        statusText = status.toUpperCase();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: textColor.withOpacity(0.3)),
      ),
      child: Text(
        statusText,
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildActionButtons(Map<String, dynamic> reservation) {
    final isPending = reservation['statut'] == 'en_attente';
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Bouton confirmer
          IconButton(
            icon: Icon(
              Icons.check_circle,
              color: isPending ? Colors.green : Colors.grey.shade400,
              size: 28,
            ),
            onPressed: isPending
                ? () => updateReservationStatus(reservation['id'], 'confirmée')
                : null,
            tooltip: 'Confirmer',
          ),
          // Bouton rejeter
          IconButton(
            icon: Icon(
              Icons.cancel,
              color: isPending ? Colors.red : Colors.grey.shade400,
              size: 28,
            ),
            onPressed: isPending
                ? () => updateReservationStatus(reservation['id'], 'rejetée')
                : null,
            tooltip: 'Rejeter',//pop-up text
          ),
        ],
      ),
    );
  }

   Widget _buildInfoRow({required IconData icon, required String text}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            icon,
            size: 16,
            color: Colors.grey.shade600,
          ),

          const SizedBox(width: 8),
          
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: Colors.grey.shade700,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReservationCard(Map<String, dynamic> reservation) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 8,
      shadowColor: Colors.black.withOpacity(0.1),
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white,
              Colors.grey.shade50,
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // En-tête avec titre et statut
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      reservation['service_titre'] ?? "Service inconnu",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Color(0xFF2D3748),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  _buildStatusChip(reservation['statut']),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Informations de la réservation

              _buildInfoRow(
                icon: Icons.person_outline,
                text: "Prestataire: ${reservation['prestataire_nom'] ?? 'Inconnu'}",
              ),
              
              _buildInfoRow(
                icon: Icons.people_outline,
                text: "Utilisateur: ${reservation['user_nom'] ?? 'Inconnu'}",
              ),
              
              _buildInfoRow(
                icon: Icons.calendar_today_outlined,
                text: "Date: ${reservation['date_reservation']}",
              ),
              
              _buildInfoRow(
                icon: Icons.access_time_outlined,
                text: "Heure: ${reservation['heure_reservation']}",
              ),
              
              const SizedBox(height: 12),
              
              // Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "ID: #${reservation['id']}",
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 12,
                    ),
                  ),
                  _buildActionButtons(reservation),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }


  Widget _buildCounterItem({required int count, required String label, required Color color}) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Text(
            count.toString(),
            style: TextStyle(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 12,
          ),
        ),
      ],
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
    body: Container(
  decoration: const BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      
      colors: [
        Color(0xFF058FB6),
        Color(0xFF38B177),
      ],
    ),
  ),
  child: Column(
    children: [
      // En-tête avec titre
     Container(
  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
  width: double.infinity,
  child: Row(
    children: [
      // Placeholder à gauche pour équilibrer le refresh
      const SizedBox(width: 48), // même largeur que l'IconButton

      // Texte centré
      Expanded(
        child: Center(
          child: const Text(
            'Réservations',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 22,
              color: Colors.white,
            ),
          ),
        ),
      ),

      // Icône refresh à droite
      IconButton(
        icon: const Icon(
          Icons.refresh,
          color: Colors.white,
          size: 28,
        ),
        onPressed: fetchReservations,
        tooltip: "Actualiser",
      ),
    ],
  ),
),

      // En-tête avec compteur
      Container(
        padding: const EdgeInsets.all(16),
        child: Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 4,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildCounterItem(
                  count: reservations.length,
                  label: 'Total',
                  color: const Color(0xFF4F6EF5),
                ),
                _buildCounterItem(
                  count: reservations.where((r) => r['statut'] == 'en_attente').length,
                  label: 'En attente',
                  color: Colors.orange,
                ),
                _buildCounterItem(
                  count: reservations.where((r) => r['statut'] == 'confirmée').length,
                  label: 'Confirmées',
                  color: Colors.green,
                ),
                _buildCounterItem(
                 count: reservations.where((r) => r['statut'] == 'rejetée' || r['statut'] == 'rejetee').length,
                 label: 'Rejetées',
                 color: Colors.red,
                ),
              ],
            ),
          ),
        ),
      ),
      
      // Liste des réservations
      Expanded(
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          child: _isLoading
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4F6EF5)),
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Chargement des réservations...',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                )
              : reservations.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.event_note_outlined,
                            size: 64,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            "Aucune réservation",
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "Les nouvelles réservations apparaîtront ici",
                            style: TextStyle(
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: fetchReservations,
                      color: const Color(0xFF4F6EF5),
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: reservations.length,
                        itemBuilder: (context, index) {
                          return _buildReservationCard(reservations[index]);
                        },
                      ),
                    ),
        ),
      ),
    ],
  ),
),
    );
  }
}
