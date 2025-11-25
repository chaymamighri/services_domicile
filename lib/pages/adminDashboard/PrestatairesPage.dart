import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:typed_data';
import 'package:services_domicile/globals.dart';
import 'package:services_domicile/pages/adminDashboard/AddPrestatairePage.dart';

class PrestatairesPage extends StatefulWidget {
  const PrestatairesPage({super.key});

  @override
  State<PrestatairesPage> createState() => _PrestatairesPageState();
}

class _PrestatairesPageState extends State<PrestatairesPage> {
  List<dynamic> prestataires = [];
  bool _isLoading = true;


  @override
  void initState() {
    super.initState();
    fetchPrestataires();
  }

  // GET ALL PRESTATAIRES
  Future<void> fetchPrestataires() async {
    final String url = "$baseUrl/get_prestataires.php";
    try {
      final response = await http.get(Uri.parse(url));
      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          prestataires = data;
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Erreur de connexion au serveur")),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur : $e")),
      );
    }
  }

  // UPDATE PRESTATAIRE avec image
  Future<void> updatePrestataire({
    required String id,
    required String nom,
    required String email,
    required String telephone,
    required String adresse,
    required String description,
    String? serviceId,
    File? imageFile,
    XFile? webImage,
  }) async {
    final url = "$baseUrl/edit_prestataire.php";
    try {
      var request = http.MultipartRequest("POST", Uri.parse(url));

      // Ajouter les champs
      request.fields['id'] = id;
      request.fields['nom'] = nom;
      request.fields['email'] = email;
      request.fields['telephone'] = telephone;
      request.fields['adresse'] = adresse;
      request.fields['description'] = description;
      
      if (serviceId != null && serviceId.isNotEmpty) {
        request.fields['service_id'] = serviceId;
      }

      // Ajouter l'image si elle existe
      if (kIsWeb && webImage != null) {
        final bytes = await webImage.readAsBytes();
        request.files.add(
          http.MultipartFile.fromBytes(
            "image",
            bytes,
            filename: webImage.name,
          ),
        );
      } else if (imageFile != null) {
        request.files.add(
          await http.MultipartFile.fromPath("image", imageFile.path),
        );
      }

      final response = await request.send();
      final respStr = await response.stream.bytesToString();

      if (!mounted) return;

      final data = json.decode(respStr);
      if (response.statusCode == 200 && data['success'] == true) {
        await fetchPrestataires();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Prestataire modifié avec succès"),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data['message'] ?? "Erreur modification"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Erreur modification: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // DELETE PRESTATAIRE
  Future<void> deletePrestataire(String id) async {
    final url = "$baseUrl/delete_prestataire.php";
    
    // Confirmation avant suppression
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Confirmation"),
        content: const Text("Voulez-vous vraiment supprimer ce prestataire ?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Annuler"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("Supprimer"),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final response = await http.post(
        Uri.parse(url),
        body: {'id': id},
      );
      if (!mounted) return;
      final data = json.decode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        await fetchPrestataires();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Prestataire supprimé avec succès"),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data['message'] ?? "Erreur suppression"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Erreur suppression: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // SHOW EDIT DIALOG 
  void editPrestataireDialog(Map<String, dynamic> prestataire) {
    final nomController = TextEditingController(text: prestataire['nom']);
    final emailController = TextEditingController(text: prestataire['email']);
    final telController = TextEditingController(text: prestataire['telephone']);
    final adresseController = TextEditingController(text: prestataire['adresse']);
    final descController = TextEditingController(text: prestataire['description']);

    File? selectedImage;
    XFile? selectedWebImage;
    final ImagePicker picker = ImagePicker();
    
    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text("Modifier Prestataire"),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nomController,
                      decoration: const InputDecoration(labelText: "Nom"),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: emailController,
                      decoration: const InputDecoration(labelText: "Email"),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: telController,
                      decoration: const InputDecoration(labelText: "Téléphone"),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: adresseController,
                      decoration: const InputDecoration(labelText: "Adresse"),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: descController,
                      decoration: const InputDecoration(labelText: "Description"),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 20),
                    
                    // Section Image
                    Column(
                      children: [
                        const Text(
                          "Image du prestataire",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 10),
                        
                        // Afficher l'image actuelle ou la nouvelle
                        if (kIsWeb && selectedWebImage != null)
                          FutureBuilder<Uint8List>(
                            future: selectedWebImage!.readAsBytes(),
                            builder: (context, snapshot) {
                              if (snapshot.hasData) {
                                return Image.memory(
                                  snapshot.data!,
                                  height: 100,
                                  width: 100,
                                  fit: BoxFit.cover,
                                );
                              }
                              return const CircularProgressIndicator();
                            },
                          )
                        else if (selectedImage != null)
                          Image.file(
                            selectedImage!,
                            height: 100,
                            width: 100,
                            fit: BoxFit.cover,
                          )
                        else if (prestataire['image'] != null && prestataire['image'].toString().isNotEmpty)
                          Image.network(
                            "${baseUrl}/image/${prestataire['image']}",
                            height: 100,
                            width: 100,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                const Icon(Icons.person, size: 100),
                          )
                        else
                          const Icon(Icons.person, size: 100),
                        
                        const SizedBox(height: 10),
                        
                        // Bouton changer image
                        ElevatedButton.icon(
                          onPressed: () async {
                            final XFile? pickedFile = await picker.pickImage(
                              source: ImageSource.gallery,
                              imageQuality: 80,
                            );
                            if (pickedFile != null) {
                              setDialogState(() {
                                if (kIsWeb) {
                                  selectedWebImage = pickedFile;
                                } else {
                                  selectedImage = File(pickedFile.path);
                                }
                              });
                            }
                          },
                          icon: const Icon(Icons.image),
                          label: const Text("Changer l'image"),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Annuler"),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    updatePrestataire(
                      id: prestataire['id'].toString(),
                      nom: nomController.text,
                      email: emailController.text,
                      telephone: telController.text,
                      adresse: adresseController.text,
                      description: descController.text,
                      imageFile: selectedImage,
                      webImage: selectedWebImage,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF058FB6),
                  ),
                  child: const Text("Modifier"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Bouton Add Prestataire
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF058FB6), Color(0xFF38B177)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const AddPrestatairePage(),
                          ),
                        );
                        if (result == true) {
                          fetchPrestataires(); // Rafraîchir la liste
                        }
                      },
                      icon: const Icon(Icons.add),
                      label: const Text("Ajouter Prestataire"),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size.fromHeight(50),
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ),

                // Liste des prestataires
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: prestataires.length,
                    itemBuilder: (context, index) {
                      final p = prestataires[index];
                      String img = p['image'] ?? "";
                      String finalImageUrl = img.startsWith("http")
                          ? img
                          : "$baseUrl/image/$img";

                      return Card(
                        elevation: 5,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                        shadowColor: Colors.grey.withOpacity(0.3),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(12),
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: SizedBox(
                              width: 60,
                              height: 60,
                              child: img.isNotEmpty
                                  ? Image.network(
                                      finalImageUrl,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) =>
                                          const Icon(Icons.person, size: 50, color: Colors.grey),
                                    )
                                  : const Icon(Icons.person, size: 50, color: Colors.grey),
                            ),
                          ),
                          title: Text(
                            p['nom'],
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                p['description'] ?? '',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.black87,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "Email: ${p['email'] ?? ''}",
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Color.fromARGB(255, 112, 146, 163),
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                "Téléphone: ${p['telephone'] ?? ''}",
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Color.fromARGB(255, 122, 205, 126),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                "Adresse: ${p['adresse'] ?? ''}",
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Color.fromARGB(255, 203, 101, 193),
                                ),
                              ),
                            ],
                          ),
                          isThreeLine: true,
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit, color: Colors.blue),
                                onPressed: () => editPrestataireDialog(p),
                                tooltip: "Modifier",
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => deletePrestataire(p['id'].toString()),
                                tooltip: "Supprimer",
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}