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
  // ========== State Variables ==========
  List<Map<String, dynamic>> prestataires = [];
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
    _loadPrestataires();
  }

  // ========== Data Methods ==========
  Future<void> _loadPrestataires() async {
    if (!mounted) return;
    
    setState(() => _isLoading = true);
    await _fetchPrestataires();
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _refreshPrestataires() async {
    if (!mounted) return;
    
    setState(() => _isRefreshing = true);
    await _fetchPrestataires();
    if (mounted) setState(() => _isRefreshing = false);
  }

  Future<void> _fetchPrestataires() async {
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/get_prestataires.php"),
      );

      if (!mounted) return;

      if (response.statusCode != 200) {
        _showErrorSnackbar("Erreur de connexion au serveur");
        return;
      }

      final data = json.decode(response.body);
      setState(() {
        prestataires = List<Map<String, dynamic>>.from(data.map((prestataire) {
          return {
            'id': prestataire['id']?.toString() ?? '',
            'nom': prestataire['nom']?.toString() ?? '',
            'email': prestataire['email']?.toString() ?? '',
            'telephone': prestataire['telephone']?.toString() ?? '',
            'adresse': prestataire['adresse']?.toString() ?? '',
            'description': prestataire['description']?.toString() ?? '',
            'image': prestataire['image']?.toString() ?? '',
            'service_id': prestataire['service_id']?.toString(),
          };
        }));
      });
    } catch (e) {
      if (!mounted) return;
      _showErrorSnackbar("Erreur: $e");
    }
  }

  // ========== Prestataire Operations ==========
  Future<void> _updatePrestataire({
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
    try {
      final request = http.MultipartRequest(
        "POST",
        Uri.parse("$baseUrl/edit_prestataire.php"),
      );

      // Ajouter les champs
      request.fields.addAll({
        'id': id,
        'nom': nom.trim(),
        'email': email.trim(),
        'telephone': telephone.trim(),
        'adresse': adresse.trim(),
        'description': description.trim(),
      });

      if (serviceId != null && serviceId.isNotEmpty) {
        request.fields['service_id'] = serviceId;
      }

      // Ajouter l'image si elle existe
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

      if (!mounted) return;

      final data = json.decode(respStr);
      if (response.statusCode == 200 && data['success'] == true) {
        await _loadPrestataires();
        _showSuccessSnackbar("Prestataire modifié avec succès");
      } else {
        _showErrorSnackbar(data['message'] ?? "Erreur modification");
      }
    } catch (e) {
      if (!mounted) return;
      _showErrorSnackbar("Erreur: $e");
    }
  }

  Future<void> _deletePrestataire(String id) async {
    final confirmed = await _showConfirmationDialog(
      title: "Confirmation",
      content: "Voulez-vous vraiment supprimer ce prestataire ?",
      confirmText: "Supprimer",
      confirmColor: errorColor,
    );

    if (!confirmed) return;

    try {
      final response = await http.post(
        Uri.parse("$baseUrl/delete_prestataire.php"),
        body: {'id': id},
      );

      if (!mounted) return;

      final data = json.decode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        await _loadPrestataires();
        _showSuccessSnackbar("Prestataire supprimé avec succès");
      } else {
        _showErrorSnackbar(data['message'] ?? "Erreur suppression");
      }
    } catch (e) {
      if (!mounted) return;
      _showErrorSnackbar("Erreur: $e");
    }
  }

  void _showEditDialog(Map<String, dynamic> prestataire) {
    final nomController = TextEditingController(text: prestataire['nom']);
    final emailController = TextEditingController(text: prestataire['email']);
    final telController = TextEditingController(text: prestataire['telephone']);
    final adresseController = TextEditingController(text: prestataire['adresse']);
    final descController = TextEditingController(text: prestataire['description']);

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

    Widget _buildImagePreview() {
      if (kIsWeb && selectedWebImage != null) {
        return FutureBuilder<Uint8List>(
          future: selectedWebImage!.readAsBytes(),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              return ClipRRect(
                borderRadius: BorderRadius.circular(imageBorderRadius),
                child: Image.memory(
                  snapshot.data!,
                  height: 100,
                  width: 100,
                  fit: BoxFit.cover,
                ),
              );
            }
            return _buildImagePlaceholder();
          },
        );
      } else if (selectedImage != null) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(imageBorderRadius),
          child: Image.file(
            selectedImage!,
            height: 100,
            width: 100,
            fit: BoxFit.cover,
          ),
        );
      } else if (prestataire['image']?.toString().isNotEmpty == true) {
        final imageUrl = prestataire['image'].toString().startsWith("http")
            ? prestataire['image'].toString()
            : "$baseUrl/image/${prestataire['image']}";
        
        return ClipRRect(
          borderRadius: BorderRadius.circular(imageBorderRadius),
          child: Image.network(
            imageUrl,
            height: 100,
            width: 100,
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
          ),
        );
      } else {
        return _buildImagePlaceholder();
      }
    }

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text(
                "Modifier Prestataire",
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
                      controller: nomController,
                      label: "Nom",
                    ),
                    SizedBox(height: elementSpacing),
                    _buildTextField(
                      controller: emailController,
                      label: "Email",
                      keyboardType: TextInputType.emailAddress,
                    ),
                    SizedBox(height: elementSpacing),
                    _buildTextField(
                      controller: telController,
                      label: "Téléphone",
                      keyboardType: TextInputType.phone,
                    ),
                    SizedBox(height: elementSpacing),
                    _buildTextField(
                      controller: adresseController,
                      label: "Adresse",
                    ),
                    SizedBox(height: elementSpacing),
                    _buildTextField(
                      controller: descController,
                      label: "Description",
                      maxLines: 3,
                    ),
                    SizedBox(height: elementSpacing * 1.5),
                    Column(
                      children: [
                        Text(
                          "Image du prestataire",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: textPrimary,
                          ),
                        ),
                        SizedBox(height: smallSpacing),
                        _buildImagePreview(),
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
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Annuler"),
                  style: TextButton.styleFrom(
                    foregroundColor: textSecondary,
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _updatePrestataire(
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
      height: 100,
      width: 100,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(imageBorderRadius),
        color: Colors.grey[100],
      ),
      child: Center(
        child: Icon(
          Icons.person,
          size: 50,
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

  Widget _buildPrestataireCard(Map<String, dynamic> prestataire) {
    final imageUrl = prestataire['image']?.toString().isNotEmpty == true
        ? (prestataire['image'].toString().startsWith("http")
            ? prestataire['image'].toString()
            : "$baseUrl/image/${prestataire['image']}")
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
          prestataire['nom'],
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
              prestataire['description'],
              style: TextStyle(
                fontSize: 14,
                color: textSecondary,
                height: 1.4,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),
            _buildInfoRow(
              icon: Icons.email,
              text: prestataire['email'],
            ),
            _buildInfoRow(
              icon: Icons.phone,
              text: prestataire['telephone'],
            ),
            _buildInfoRow(
              icon: Icons.location_on,
              text: prestataire['adresse'],
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
                onPressed: () => _showEditDialog(prestataire),
                tooltip: "Modifier",
              ),
              IconButton(
                icon: const Icon(Icons.delete, size: 22),
                color: errorColor,
                onPressed: () => _deletePrestataire(prestataire['id']),
                tooltip: "Supprimer",
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow({required IconData icon, required String text}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 14,
            color: textTertiary,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                color: textTertiary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddPrestataireButton() {
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
            MaterialPageRoute(builder: (context) => const AddPrestatairePage()),
          );
          if (result == true) await _loadPrestataires();
        },
        icon: const Icon(Icons.add, size: 24),
        label: const Text(
          "Ajouter un Prestataire",
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
            Icons.person_outline,
            size: 80,
            color: textTertiary.withOpacity(0.5),
          ),
          const SizedBox(height: elementSpacing),
          Text(
            "Aucun prestataire disponible",
            style: TextStyle(
              fontSize: 18,
              color: textTertiary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: smallSpacing),
          Text(
            "Ajoutez votre premier prestataire",
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
            "Chargement des prestataires...",
            style: TextStyle(
              color: textSecondary,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrestatairesList() {
    return RefreshIndicator(
      onRefresh: _refreshPrestataires,
      backgroundColor: cardBackground,
      color: primaryColor,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(
          horizontal: defaultPadding,
          vertical: defaultPadding,
        ),
        itemCount: prestataires.length,
        separatorBuilder: (context, index) => SizedBox(height: smallSpacing),
        itemBuilder: (context, index) => _buildPrestataireCard(prestataires[index]),
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
          _buildAddPrestataireButton(),
          Expanded(
            child: _isLoading
                ? _buildLoadingState()
                : prestataires.isEmpty
                    ? _buildEmptyState()
                    : _buildPrestatairesList(),
          ),
        ],
      ),
    );
  }
}