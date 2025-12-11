import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:typed_data';
import 'package:services_domicile/globals.dart';
import 'package:services_domicile/widgets/custom_appbar.dart';

class Addservice extends StatefulWidget {
  const Addservice({super.key});

  @override
  State<Addservice> createState() => _AddserviceState();
}

class _AddserviceState extends State<Addservice> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _titreController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _prixController = TextEditingController();

  File? _imageFile;
  XFile? _webImage;
  bool _isLoading = false;

  final ImagePicker _picker = ImagePicker();

  // Sélection de l'image depuis la galerie
  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (pickedFile != null) {
      setState(() {
        if (kIsWeb) {
          _webImage = pickedFile;
        } else {
          _imageFile = File(pickedFile.path);
        }
      });
    }
  }

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      if (_imageFile == null && _webImage == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Veuillez sélectionner une image"),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      setState(() => _isLoading = true);

      var request = http.MultipartRequest(
        'POST',
        Uri.parse("$baseUrl/add_service.php"),
      );

      request.fields['titre'] = _titreController.text;
      request.fields['description'] = _descriptionController.text;
      request.fields['prix'] = _prixController.text;

      // Ajouter l'image 
      if (kIsWeb && _webImage != null) {
        final bytes = await _webImage!.readAsBytes();
        request.files.add(
          http.MultipartFile.fromBytes(
            'image',
            bytes,
            filename: _webImage!.name,
          ),
        );
      } else if (_imageFile != null) {
       request.files.add( // envoi vers le backend
          await http.MultipartFile.fromPath('image', _imageFile!.path),
        );
      }

      try {
        var response = await request.send();
        var respStr = await response.stream.bytesToString();
        var result = json.decode(respStr);

        if (result['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Service ajouté avec succès !"),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );
          _titreController.clear();
          _descriptionController.clear();
          _prixController.clear();
          setState(() {
            _imageFile = null;
            _webImage = null;
          });
          Navigator.pop(context, true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Erreur : ${result['message']}"),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Erreur serveur: $e"),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: CustomAppBar(
        title: "Ajouter Service",
        showBack: true,
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Center(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 600),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(24.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Titre du formulaire
                        const Text(
                          "Nouveau Service",
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF058FB6),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Remplissez tous les champs requis",
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 30),

                        // Champ Titre
                        _buildTextField(
                          controller: _titreController,
                          label: "Titre du service",
                          icon: Icons.title_outlined,
                          validator: (value) =>
                              value!.isEmpty ? "Le titre est requis" : null,
                        ),
                        const SizedBox(height: 16),

                        // Champ Prix
                        _buildTextField(
                          controller: _prixController,
                          label: "Prix (TND)",
                          icon: Icons.attach_money_outlined,
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value!.isEmpty) return "Le prix est requis";
                            if (double.tryParse(value) == null) {
                              return "Prix invalide";
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Champ Description
                        _buildTextField(
                          controller: _descriptionController,
                          label: "Description",
                          icon: Icons.description_outlined,
                          maxLines: 4,
                          validator: (value) =>
                              value!.isEmpty ? "La description est requise" : null,
                        ),
                        const SizedBox(height: 24),

                        // Section Image
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          child: Column(
                            children: [
                              const Text(
                                "Image du service",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF058FB6),
                                ),
                              ),
                              const SizedBox(height: 16),

                              // Prévisualisation de l'image
                              if (kIsWeb && _webImage != null)
                                FutureBuilder<Uint8List>(
                                  future: _webImage!.readAsBytes(),
                                  builder: (context, snapshot) {
                                    if (snapshot.hasData) {
                                      return Container(
                                        margin: const EdgeInsets.only(bottom: 16),
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(
                                            color: const Color(0xFF058FB6),
                                            width: 2,
                                          ),
                                        ),
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(10),
                                          child: Image.memory(
                                            snapshot.data!,
                                            height: 150,
                                            width: double.infinity,
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                      );
                                    }
                                    return const CircularProgressIndicator();
                                  },
                                )
                              else if (_imageFile != null)
                                Container(
                                  margin: const EdgeInsets.only(bottom: 16),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: const Color(0xFF058FB6),
                                      width: 2,
                                    ),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: Image.file(
                                      _imageFile!,
                                      height: 150,
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                )
                              else
                                Container(
                                  height: 150,
                                  margin: const EdgeInsets.only(bottom: 16),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[200],
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    Icons.image_outlined,
                                    size: 60,
                                    color: Colors.grey[400],
                                  ),
                                ),

                              // Bouton choisir image
                              OutlinedButton.icon(
                                onPressed: _pickImage,
                                icon: const Icon(Icons.photo_library_outlined),
                                label: Text(
                                  _imageFile != null || _webImage != null
                                      ? "Changer l'image"
                                      : "Choisir une image",
                                ),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: const Color(0xFF058FB6),
                                  side: const BorderSide(
                                    color: Color(0xFF058FB6),
                                    width: 2,
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 12,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Bouton Ajouter
                        Container(
                          height: 56,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF058FB6), Color(0xFF38B177)],
                            ),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF058FB6).withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ElevatedButton(
                            onPressed: _submitForm,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              "Ajouter le service",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }

  // Widget pour construire les champs de texte stylisés
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFF058FB6)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF058FB6), width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
        filled: true,
        fillColor: Colors.grey[50],
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
    );
  }

  @override
  void dispose() {
    _titreController.dispose();
    _descriptionController.dispose();
    _prixController.dispose();
    super.dispose();
  }
}