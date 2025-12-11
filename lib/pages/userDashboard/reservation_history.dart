import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:services_domicile/globals.dart';
import 'package:services_domicile/globals.dart' as globals; // contient baseUrl et currentUserId

// Enum pour les statuts de réservation
enum ReservationStatus { pending, confirmed, rejected }

ReservationStatus parseStatus(String statut) {
  switch (statut) {
    case 'en_attente':
      return ReservationStatus.pending;
    case 'confirmée':
      return ReservationStatus.confirmed;
    case 'rejetée':
      return ReservationStatus.rejected;
    default:
      return ReservationStatus.pending;
  }
}

// Badge pour le statut
class StatusBadge extends StatelessWidget {
  final ReservationStatus status;
  const StatusBadge({Key? key, required this.status}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final Map<ReservationStatus, Map<String, dynamic>> statusInfo = {
      ReservationStatus.pending: {'color': Colors.orange, 'text': 'En attente'},
      ReservationStatus.confirmed: {'color': Colors.blue, 'text': 'Confirmée'},
      ReservationStatus.rejected: {'color': Colors.red, 'text': 'Refusée'},
    };
    final color = statusInfo[status]!['color'] as Color;
    final text = statusInfo[status]!['text'] as String;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12),
      ),
    );
  }
}

// Carte de réservation
class ReservationCard extends StatelessWidget {
  final Map<String, dynamic> reservation;
  const ReservationCard({Key? key, required this.reservation}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final status = parseStatus(reservation['statut']);
    final date = DateTime.parse("${reservation['date_reservation']} ${reservation['heure_reservation']}");

    return Card(
      margin: EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: EdgeInsets.all(16),
        child:Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            reservation['service_nom'] ?? "Service",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ),
        StatusBadge(status: status),
      ],
    ),
    SizedBox(height: 8),
    Text(
      'Prestataire: ${reservation['prestataire_nom'] ?? "Inconnu"}\n'
      'Numéro: ${reservation['prestataire_telephone'] ?? "N/A"}',
      style: TextStyle(color: Colors.grey[600]),
    ),
    SizedBox(height: 8),
    Row(
      children: [
        Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
        SizedBox(width: 4),
        Text('${date.day}/${date.month}/${date.year}',
            style: TextStyle(color: Colors.grey[600])),
        SizedBox(width: 16),
        Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
        SizedBox(width: 4),
        Text('${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}',// si 1 chiffre on ajoute 0 devant
            style: TextStyle(color: Colors.grey[600])),
      ],
    ),
  ],
),

      ),
    );
  }
}

// Écran historique des réservations
class ReservationHistoryScreen extends StatefulWidget {
  const ReservationHistoryScreen({Key? key}) : super(key: key);

  @override
  _ReservationHistoryScreenState createState() => _ReservationHistoryScreenState();
}

class _ReservationHistoryScreenState extends State<ReservationHistoryScreen> {
  List<Map<String, dynamic>> reservations = [];
  String selectedFilter = 'Toutes';
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchReservations();
  }

  Future<void> fetchReservations() async {
    try {
      final uri = Uri.parse('$baseUrl/get_user_reservations.php').replace(
        queryParameters: {'user_id': globals.currentUserId.toString()},
      );

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['success'] == true) {
          setState(() {
            reservations = List<Map<String, dynamic>>.from(data['reservations']);
            isLoading = false;
          });
        } else {
          setState(() => isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erreur lors de la récupération des réservations')),
          );
        }
      } else {
        setState(() => isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur serveur ${response.statusCode}')),
        );
      }
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e')),
      );
    }
  }
// return list des reservation filtrer par status

  List<Map<String, dynamic>> get filteredReservations {
    if (selectedFilter == 'Toutes') return reservations;
    switch (selectedFilter) {
      case 'En attente':
        return reservations.where((r) => r['statut'] == 'en_attente').toList();
      case 'Confirmée':
        return reservations.where((r) => r['statut'] == 'confirmée').toList();
      case 'Rejetée':
        return reservations.where((r) => r['statut'] == 'rejetée').toList();
      default:
        return reservations;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Historique des réservations'),
      automaticallyImplyLeading: false,
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildFilterChips(),
                Expanded(
                  child: filteredReservations.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          padding: EdgeInsets.all(16),
                          itemCount: filteredReservations.length,
                          itemBuilder: (context, index) {
                            final reservation = filteredReservations[index];
                            return ReservationCard(reservation: reservation);
                          },
                        ),
                ),
              ],
            ),
    );
  }

// les icon de filtrage par status (---filter chip--)

  Widget _buildFilterChips() {
    final filters = ['Toutes', 'En attente', 'Confirmée', 'Rejetée'];
    return Container(
      padding: EdgeInsets.all(16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: filters.map((filter) {
            return Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: FilterChip(
                label: Text(filter),
                selected: selectedFilter == filter,
                onSelected: (_) {
                  setState(() => selectedFilter = filter);
                },
              ),
            );
          }).toList(),// convert le map en list puisque row
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history, size: 80, color: Colors.grey[300]),
          SizedBox(height: 16),
          Text('Aucune réservation', style: TextStyle(fontSize: 18, color: Colors.grey[600])),
          SizedBox(height: 8),
          Text('Vos réservations apparaîtront ici', style: TextStyle(color: Colors.grey[500])),
        ],
      ),
    );
  }
}
