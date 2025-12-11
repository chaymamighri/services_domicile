import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:typed_data';
import 'package:services_domicile/globals.dart';
import 'package:services_domicile/widgets/custom_appbar.dart';

class AddPrestatairePage extends StatefulWidget {
  const AddPrestatairePage({super.key});

  @override
  State<AddPrestatairePage> createState() => _AddPrestatairePageState();
}

class _AddPrestatairePageState extends State<AddPrestatairePage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController nomController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController telController = TextEditingController();
  final TextEditingController adresseController = TextEditingController();
  final TextEditingController descController = TextEditingController();

  bool _isLoading = false;

  File? _image;
  XFile? _webImage;
  final ImagePicker _picker = ImagePicker();

  // Liste des services
  List<Map<String, dynamic>> services = [];
  int? selectedServiceId;
  bool isLoadingServices = true;

  @override
  void initState() {
    super.initState();
    fetchServices();
  }

  // Récupérer la liste des services
 Future<void> fetchServices() async {
  try {
    final response = await http.get(
      Uri.parse("$baseUrl/get_All_services.php"),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['success'] == true) {
        setState(() {
          services = List<Map<String, dynamic>>.from(data['services']).map((service) {
            // conversion de l'id en int
            return {
              ...service,
              'id': int.parse(service['id'].toString()),
            };
          }).toList();
          isLoadingServices = false;
        });
      }
    }
  } catch (e) {
    print("Erreur chargement services: $e");
    setState(() => isLoadingServices = false);
  }
}

  // Choisir une image
  Future<void> pickImage() async {
    final XFile? pickedFile =
        await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (pickedFile != null) {
      setState(() {
        if (kIsWeb) {
          _webImage = pickedFile;
        } else {
          _image = File(pickedFile.path);
        }
      });
    }
  }

  // Ajouter prestataire
  Future<void> addPrestataire() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (selectedServiceId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Veuillez sélectionner un service"),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      var request = http.MultipartRequest(
        "POST",
        Uri.parse("$baseUrl/add_prestataire.php"),
      );
       // pour que le backend puisse le recevoir 
      request.fields['nom'] = nomController.text;
      request.fields['email'] = emailController.text;
      request.fields['telephone'] = telController.text;
      request.fields['adresse'] = adresseController.text;
      request.fields['description'] = descController.text;
      request.fields['service_id'] = selectedServiceId.toString();

      if (kIsWeb && _webImage != null) {
        final bytes = await _webImage!.readAsBytes();
        request.files.add(
          http.MultipartFile.fromBytes(
            "image",
            bytes,
            filename: _webImage!.name,
          ),
        );
      } else if (_image != null) {
        request.files.add(
          await http.MultipartFile.fromPath("image", _image!.path),
        );
      }
       // send request to backend
      final response = await request.send();
      final respStr = await response.stream.bytesToString();
      
      print("Réponse serveur: $respStr"); 

      final data = json.decode(respStr);

      if (response.statusCode == 200 && data['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Prestataire ajouté avec succès"),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data['message'] ?? "Erreur ajout"),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Erreur: $e"),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: CustomAppBar(
        title: "Ajouter Prestataire",
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
                        const Text(
                          "Informations du prestataire",
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

                        // Champ Nom
                        _buildTextField(
                          controller: nomController,
                          label: "Nom complet",
                          icon: Icons.person_outline,
                          validator: (value) =>
                              value!.isEmpty ? "Le nom est requis" : null,
                        ),
                        const SizedBox(height: 16),

                        // Champ Email
                        _buildTextField(
                          controller: emailController,
                          label: "Email",
                          icon: Icons.email_outlined,
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) {
                            if (value!.isEmpty) return "L'email est requis";
                            if (!value.contains('@')) return "Email invalide";
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Champ Téléphone
                        _buildTextField(
                          controller: telController,
                          label: "Téléphone",
                          icon: Icons.phone_outlined,
                          keyboardType: TextInputType.phone,
                          validator: (value) =>
                              value!.isEmpty ? "Le téléphone est requis" : null,
                        ),
                        const SizedBox(height: 16),

                        // Champ Adresse
                        _buildTextField(
                          controller: adresseController,
                          label: "Adresse",
                          icon: Icons.location_on_outlined,
                          validator: (value) =>
                              value!.isEmpty ? "L'adresse est requise" : null,
                        ),
                        const SizedBox(height: 16),

                        // DROPDOWN SERVICE
                        isLoadingServices
                            ? const Center(child: CircularProgressIndicator())
                            : DropdownButtonFormField<int>(
                                value: selectedServiceId,
                                decoration: InputDecoration(
                                  labelText: "Service",
                                  prefixIcon: const Icon(
                                    Icons.work_outline,
                                    color: Color(0xFF058FB6),
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: Colors.grey[300]!),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(
                                      color: Color(0xFF058FB6),
                                      width: 2,
                                    ),
                                  ),
                                  filled: true,
                                  fillColor: Colors.grey[50],
                                ),
                                items: services.map((service) {
                                  return DropdownMenuItem<int>(
                                    value: service['id'],
                                    child: Text(service['titre']),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  setState(() {
                                    selectedServiceId = value;
                                  });
                                },
                                validator: (value) =>
                                    value == null ? "Sélectionnez un service" : null,
                              ),
                        const SizedBox(height: 16),

                        // Champ Description
                        _buildTextField(
                          controller: descController,
                          label: "Description",
                          icon: Icons.description_outlined,
                          maxLines: 4,
                          validator: null,
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
                                "Photo du prestataire",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF058FB6),
                                ),
                              ),
                              const SizedBox(height: 16),
                              
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
                                            width: 150,
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                      );
                                    }
                                    return const CircularProgressIndicator();
                                  },
                                )
                              else if (_image != null)
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
                                      _image!,
                                      height: 150,
                                      width: 150,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                )
                              else
                                Container(
                                  height: 150,
                                  width: 150,
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

                              OutlinedButton.icon(
                                onPressed: pickImage,
                                icon: const Icon(Icons.photo_library_outlined),
                                label: Text(
                                  _image != null || _webImage != null
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
                            onPressed: addPrestataire,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              "Ajouter le prestataire",
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
}