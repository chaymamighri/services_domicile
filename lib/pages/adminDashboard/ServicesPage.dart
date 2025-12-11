import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:services_domicile/globals.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import 'Addservice.dart';

class ServicesPage extends StatefulWidget {
  const ServicesPage({super.key});

  @override
  State<ServicesPage> createState() => _ServicesPageState();
}

class _ServicesPageState extends State<ServicesPage> {
  // ========== State Variables ==========
  List<Map<String, dynamic>> services = [];
  bool _isLoading = true;
  bool _isRefreshing = false;

  // ========== Color Constants ==========
  static const Color primaryColor = Color(0xFF058FB6);
  static const Color secondaryColor = Color(0xFF38B177);
  static const Color errorColor = Color(0xFFD32F2F);
  static const Color successColor = Color(0xFF388E3C);
  static const Color warningColor = Color(0xFFF57C00);
  static const Color cardBackground = Colors.white;
  static const Color textPrimary = Color(0xFF333333);
  static const Color textSecondary = Color(0xFF666666);
  static const Color textTertiary = Color(0xFF999999);

  // ========== Spacing Constants ==========
  static const double cardBorderRadius = 16.0;
  static const double imageBorderRadius = 12.0;
  static const double defaultPadding = 16.0;
  static const double elementSpacing = 12.0;
  static const double smallSpacing = 8.0;

  // ========== Lifecycle Methods ==========
  @override
  void initState() {
    super.initState();
    _loadServices();
  }

  // ========== Data Methods ==========
  Future<void> _loadServices() async {
    if (!mounted) return;

    setState(() => _isLoading = true);
    await _fetchServices();
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _refreshServices() async {
    if (!mounted) return;

    setState(() => _isRefreshing = true);
    await _fetchServices();
    if (mounted) setState(() => _isRefreshing = false);
  }

  Future<void> _fetchServices() async {
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/get_All_services.php"),
      );

      if (!mounted) return;

      if (response.statusCode != 200) {
        _showErrorSnackbar("Erreur de connexion au serveur");
        return;
      }

      final data = json.decode(response.body);
      
      if (data['success'] == true) {
        setState(() {
          services = List<Map<String, dynamic>>.from(
            (data['services'] as List).map((service) {
              return {
                'id': int.parse(service['id'].toString()),
                'titre': service['titre']?.toString() ?? '',
                'description': service['description']?.toString() ?? '',
                'prix': service['prix']?.toString() ?? '0',
                'image': service['image']?.toString() ?? '',
              };
            }),
          );
        });
      } else {
        _showErrorSnackbar(data['message'] ?? "Erreur serveur");
      }
    } catch (e) {
      if (!mounted) return;
      _showErrorSnackbar("Erreur: $e");
    }
  }

  // ========== Service Operations ==========
  Future<void> _deleteService(int id) async {
    final confirmed = await _showConfirmationDialog(
      title: "Confirmation",
      content: "Voulez-vous vraiment supprimer ce service ?",
      confirmText: "Supprimer",
      confirmColor: errorColor,
    );

    if (!confirmed) return;

    try {
      final response = await http.post(
        Uri.parse("$baseUrl/delete_service.php"),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {'id': id.toString()},
      );

      if (!mounted) return;

      final data = json.decode(response.body);
      
      if (response.statusCode == 200 && data['success'] == true) {
        await _loadServices();
        _showSuccessSnackbar("Service supprimé avec succès");
      } else {
        _showErrorSnackbar(data['message'] ?? "Erreur lors de la suppression");
      }
    } catch (e) {
      if (!mounted) return;
      _showErrorSnackbar("Erreur: $e");
    }
  }

  Future<void> _updateService({
    required String id,
    required String titre,
    required String description,
    required String prix,
    File? imageFile,
    XFile? webImage,
  }) async {
    // Validation
    if (titre.trim().isEmpty || 
        description.trim().isEmpty || 
        prix.trim().isEmpty) {
      _showWarningSnackbar("Veuillez remplir tous les champs");
      return;
    }

    try {
      final request = http.MultipartRequest(
        "POST",
        Uri.parse("$baseUrl/edit_service.php"),
      );

      request.fields.addAll({
        'id': id,
        'titre': titre.trim(),
        'description': description.trim(),
        'prix': prix.trim(),
      });

      if (kIsWeb && webImage != null) {
        final bytes = await webImage.readAsBytes();
        request.files.add(http.MultipartFile.fromBytes(
          "image",
          bytes,
          filename: webImage.name,
        ));
      } else if (imageFile != null) {
        request.files.add(await http.MultipartFile.fromPath(
          "image",
          imageFile.path,
        ));
      }

      final response = await request.send();
      final respStr = await response.stream.bytesToString();
      final data = json.decode(respStr);

      if (!mounted) return;

      if (response.statusCode == 200 && data['success'] == true) {
        await _loadServices();
        _showSuccessSnackbar("Service modifié avec succès");
      } else {
        _showErrorSnackbar(data['message'] ?? "Erreur modification");
      }
    } catch (e) {
      if (!mounted) return;
      _showErrorSnackbar("Erreur: $e");
    }
  }

  void _showEditDialog(Map<String, dynamic> service) {
    final titleController = TextEditingController(text: service['titre']);
    final descriptionController = TextEditingController(text: service['description']);
    final priceController = TextEditingController(text: service['prix']);

    File? selectedImage;
    XFile? selectedWebImage;

    Future<void> _pickImage(StateSetter setDialogState) async {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
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
    }

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (builderContext, setDialogState) {
            Widget _buildImagePreview() {
              if (kIsWeb && selectedWebImage != null) {
                return FutureBuilder<Uint8List>(
                  future: selectedWebImage!.readAsBytes(),
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      return Image.memory(
                        snapshot.data!,
                        fit: BoxFit.cover,
                      );
                    }
                    return _buildImagePlaceholder();
                  },
                );
              } else if (selectedImage != null) {
                return Image.file(selectedImage!, fit: BoxFit.cover);
              } else if (service['image']?.toString().isNotEmpty == true) {
                final imagePath = service['image'].toString();
                final imageUrl = imagePath.startsWith("http")
                    ? imagePath
                    : "$baseUrl/image/$imagePath";
                
                return Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Center(
                      child: CircularProgressIndicator(
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                                loadingProgress.expectedTotalBytes!
                            : null,
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return _buildImagePlaceholder();
                  },
                );
              } else {
                return _buildImagePlaceholder();
              }
            }

            return AlertDialog(
              title: const Text(
                "Modifier Service",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildTextField(
                      controller: titleController,
                      label: "Titre",
                    ),
                    SizedBox(height: elementSpacing),
                    _buildTextField(
                      controller: descriptionController,
                      label: "Description",
                      maxLines: 3,
                    ),
                    SizedBox(height: elementSpacing),
                    _buildTextField(
                      controller: priceController,
                      label: "Prix (DT)",
                      keyboardType: TextInputType.number,
                    ),
                    SizedBox(height: elementSpacing * 1.5),
                    Column(
                      children: [
                        Text(
                          "Image du service",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: textPrimary,
                          ),
                        ),
                        SizedBox(height: smallSpacing),
                        Container(
                          height: 140,
                          width: 140,
                          decoration: BoxDecoration(
                            border: Border.all(color: textTertiary.withOpacity(0.3)),
                            borderRadius: BorderRadius.circular(imageBorderRadius),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(imageBorderRadius),
                            child: _buildImagePreview(),
                          ),
                        ),
                        SizedBox(height: smallSpacing),
                        ElevatedButton.icon(
                          onPressed: () => _pickImage(setDialogState),
                          icon: const Icon(Icons.photo_library, size: 20),
                          label: const Text("Changer l'image"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
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
                  style: TextButton.styleFrom(
                    foregroundColor: textSecondary,
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                    _updateService(
                      id: service['id'].toString(),
                      titre: titleController.text,
                      description: descriptionController.text,
                      prix: priceController.text,
                      imageFile: selectedImage,
                      webImage: selectedWebImage,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
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

  // ========== UI Helper Methods ==========
  Widget _buildImagePlaceholder() {
    return Container(
      color: Colors.grey[100],
      child: const Center(
        child: Icon(
          Icons.miscellaneous_services,
          size: 60,
          color: textTertiary,
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
          borderSide: BorderSide(color: textTertiary.withOpacity(0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
          borderSide: const BorderSide(color: primaryColor),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 14,
        ),
      ),
    );
  }

  Widget _buildServiceCard(Map<String, dynamic> service) {
    final imageUrl = service['image']?.toString().isNotEmpty == true
        ? (service['image'].toString().startsWith("http")
            ? service['image'].toString()
            : "$baseUrl/image/${service['image']}")
        : null;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(cardBorderRadius),
      ),
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        contentPadding: const EdgeInsets.all(defaultPadding),
        leading: Container(
          width: 70,
          height: 70,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(imageBorderRadius),
            color: Colors.grey[100],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(imageBorderRadius),
            child: imageUrl != null
                ? Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return _buildImagePlaceholder();
                    },
                  )
                : _buildImagePlaceholder(),
          ),
        ),
        title: Text(
          service['titre'],
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: textPrimary,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              service['description'],
              style: TextStyle(
                fontSize: 14,
                color: textSecondary,
                height: 1.4,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),
            Text(
              "${service['prix']} DT",
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: primaryColor,
              ),
            ),
          ],
        ),
        trailing: SizedBox(
          width: 90,
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.edit, size: 22),
                color: primaryColor,
                onPressed: () => _showEditDialog(service),
                tooltip: "Modifier",
              ),
              IconButton(
                icon: const Icon(Icons.delete, size: 22),
                color: errorColor,
                onPressed: () => _deleteService(service['id']),
                tooltip: "Supprimer",
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAddServiceButton() {
    return Container(
      margin: const EdgeInsets.all(defaultPadding),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [primaryColor, secondaryColor],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(cardBorderRadius),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton.icon(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const Addservice()),
          );
          if (result == true) await _loadServices();
        },
        icon: const Icon(Icons.add, size: 24),
        label: const Text(
          "Ajouter un Service",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        style: ElevatedButton.styleFrom(
          minimumSize: const Size.fromHeight(56),
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(cardBorderRadius),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.miscellaneous_services_outlined,
            size: 80,
            color: textTertiary.withOpacity(0.5),
          ),
          const SizedBox(height: elementSpacing),
          Text(
            "Aucun service disponible",
            style: TextStyle(
              fontSize: 18,
              color: textTertiary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: smallSpacing),
          Text(
            "Ajoutez votre premier service",
            style: TextStyle(
              fontSize: 14,
              color: textTertiary.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
            strokeWidth: 3,
          ),
          const SizedBox(height: elementSpacing),
          Text(
            "Chargement des services...",
            style: TextStyle(
              color: textSecondary,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceList() {
    return RefreshIndicator(
      onRefresh: _refreshServices,
      backgroundColor: cardBackground,
      color: primaryColor,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(
          horizontal: defaultPadding,
          vertical: defaultPadding,
        ),
        itemCount: services.length,
        separatorBuilder: (context, index) => 
            SizedBox(height: smallSpacing),
        itemBuilder: (context, index) => 
            _buildServiceCard(services[index]),
      ),
    );
  }

  // ========== Utility Methods ==========
  Future<bool> _showConfirmationDialog({
    required String title,
    required String content,
    required String confirmText,
    required Color confirmColor,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: textPrimary,
          ),
        ),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Annuler"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: confirmColor,
            ),
            child: Text(
              confirmText,
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
    
    return result ?? false;
  }

  void _showSnackbar({
    required String message,
    required Color backgroundColor,
    Color textColor = Colors.white,
  }) {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: TextStyle(color: textColor),
        ),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showErrorSnackbar(String message) =>
      _showSnackbar(message: message, backgroundColor: errorColor);

  void _showSuccessSnackbar(String message) =>
      _showSnackbar(message: message, backgroundColor: successColor);

  void _showWarningSnackbar(String message) =>
      _showSnackbar(message: message, backgroundColor: warningColor);

  // ========== Build Method ==========
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          _buildAddServiceButton(),
          Expanded(
            child: _isLoading
                ? _buildLoadingState()
                : services.isEmpty
                    ? _buildEmptyState()
                    : _buildServiceList(),
          ),
        ],
      ),
    );
  }
}