import 'package:flutter/material.dart';
import 'Addservice.dart';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:services_domicile/globals.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class ServicesPage extends StatefulWidget {
  const ServicesPage({super.key});

  @override
  State<ServicesPage> createState() => _ServicesPageState();
}

class _ServicesPageState extends State<ServicesPage> {
  List<dynamic> services = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchServices();
  }

  // FETCH SERVICES
  Future<void> fetchServices() async {
    final String url = "$baseUrl/get_All_services.php";
    try {
      final response = await http.get(Uri.parse(url));
      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          setState(() {
            services = (data['services'] as List).map((service) {
              service['id'] = int.parse(service['id'].toString());
              service['prix'] = service['prix'].toString();
              return service;
            }).toList();
            _isLoading = false;
          });
        } else {
          setState(() => _isLoading = false);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(data['message'] ?? "Erreur serveur")),
            );
          }
        }
      } else {
        setState(() => _isLoading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Erreur de connexion au serveur")),
          );
        }
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur : $e")),
      );
    }
  }

  // DELETE SERVICE
  Future<void> deleteService(int id) async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text("Confirmation"),
        content: const Text("Voulez-vous vraiment supprimer ce service ?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text("Annuler"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("Supprimer", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    final url = "$baseUrl/delete_service.php";
    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {'id': id.toString()},
      );
      if (!mounted) return;
      
      final data = json.decode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        await fetchServices();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Service supprimé avec succès"),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(data['message'] ?? "Erreur suppression"),
              backgroundColor: Colors.red,
            ),
          );
        }
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

  // UPDATE SERVICE WITH IMAGE
  Future<void> updateServiceWithImage({
    required String id,
    required String titre,
    required String description,
    required String prix,
    File? imageFile,
    XFile? webImage,
  }) async {
    // Validation
    if (titre.trim().isEmpty || description.trim().isEmpty || prix.trim().isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Veuillez remplir tous les champs"),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    final url = "$baseUrl/edit_service.php";
    try {
      var request = http.MultipartRequest("POST", Uri.parse(url));
      request.fields['id'] = id;
      request.fields['titre'] = titre.trim();
      request.fields['description'] = description.trim();
      request.fields['prix'] = prix.trim();

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
      final data = json.decode(respStr);

      if (!mounted) return;

      if (response.statusCode == 200 && data['success'] == true) {
        await fetchServices();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Service modifié avec succès"),
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

  // EDIT DIALOG
  void editServiceDialog(Map<String, dynamic> service) {
    final titleController = TextEditingController(text: service['titre']);
    final descriptionController = TextEditingController(text: service['description']);
    final priceController = TextEditingController(text: service['prix'].toString());

    File? selectedImage;
    XFile? selectedWebImage;
    final ImagePicker picker = ImagePicker();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (builderContext, setDialogState) {
            return AlertDialog(
              title: const Text("Modifier Service"),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(
                        labelText: "Titre",
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: descriptionController,
                      decoration: const InputDecoration(
                        labelText: "Description",
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: priceController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: "Prix (DT)",
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Column(
                      children: [
                        const Text(
                          "Image du service",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 10),
                        Container(
                          height: 120,
                          width: 120,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: _buildImagePreview(
                              service,
                              selectedImage,
                              selectedWebImage,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
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
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF058FB6),
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text("Annuler"),
                ),
                ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(dialogContext);
                    await updateServiceWithImage(
                      id: service['id'].toString(),
                      titre: titleController.text,
                      description: descriptionController.text,
                      prix: priceController.text,
                      imageFile: selectedImage,
                      webImage: selectedWebImage,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF058FB6),
                    foregroundColor: Colors.white,
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

  // Helper method for image preview
  Widget _buildImagePreview(
    Map<String, dynamic> service,
    File? selectedImage,
    XFile? selectedWebImage,
  ) {
    if (kIsWeb && selectedWebImage != null) {
      return FutureBuilder<Uint8List>(
        future: selectedWebImage.readAsBytes(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return Image.memory(
              snapshot.data!,
              fit: BoxFit.cover,
            );
          }
          return const Center(child: CircularProgressIndicator());
        },
      );
    } else if (selectedImage != null) {
      return Image.file(selectedImage, fit: BoxFit.cover);
    } else if (service['image'] != null &&
        service['image'].toString().isNotEmpty) {
      String img = service['image'].toString();
      String imageUrl = img.startsWith("http") ? img : "$baseUrl/image/$img";
      return Image.network(
        imageUrl,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return const Icon(Icons.miscellaneous_services, size: 60);
        },
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return const Center(child: CircularProgressIndicator());
        },
      );
    } else {
      return const Icon(Icons.miscellaneous_services, size: 60);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Add Service Button
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
                            builder: (context) => const Addservice(),
                          ),
                        );
                        if (result == true) fetchServices();
                      },
                      icon: const Icon(Icons.add),
                      label: const Text("Ajouter Service"),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size.fromHeight(50),
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ),

                // Service List
                Expanded(
                  child: services.isEmpty
                      ? const Center(
                          child: Text(
                            "Aucun service disponible",
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: fetchServices,
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: services.length,
                            itemBuilder: (context, index) {
                              final service = services[index];
                              String img = service['image'] ?? "";
                              String finalImageUrl = img.startsWith("http")
                                  ? img
                                  : "$baseUrl/image/$img";

                              return Card(
                                elevation: 5,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                margin: const EdgeInsets.symmetric(
                                  vertical: 8,
                                  horizontal: 12,
                                ),
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
                                              errorBuilder: (context, error,
                                                  stackTrace) {
                                                return const Icon(
                                                  Icons.miscellaneous_services,
                                                  size: 50,
                                                  color: Colors.grey,
                                                );
                                              },
                                            )
                                          : const Icon(
                                              Icons.miscellaneous_services,
                                              size: 50,
                                              color: Colors.grey,
                                            ),
                                    ),
                                  ),
                                  title: Text(
                                    service['titre'],
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        service['description'],
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: Colors.black87,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        "Prix : ${service['prix']} DT",
                                        style: const TextStyle(
                                          fontSize: 13,
                                          color: Color.fromARGB(255, 125, 124, 124),
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                  isThreeLine: true,
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.edit,
                                            color: Colors.blue),
                                        onPressed: () =>
                                            editServiceDialog(service),
                                        tooltip: "Modifier",
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete,
                                            color: Colors.red),
                                        onPressed: () =>
                                            deleteService(service['id']),
                                        tooltip: "Supprimer",
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                ),
              ],
            ),
    );
  }
}