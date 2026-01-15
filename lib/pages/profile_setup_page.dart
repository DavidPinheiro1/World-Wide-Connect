import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart'; // <--- IMPORT FONTE
import '../database_service.dart';
import 'services/good_behavior_service.dart'; // <--- IMPORT FILTRO
import 'main_screen.dart'; 

class ProfileSetupPage extends StatefulWidget {
  final String? name;
  final String? email;

  const ProfileSetupPage({super.key, this.name, this.email});

  @override
  State<ProfileSetupPage> createState() => _ProfileSetupPageState();
}

class _ProfileSetupPageState extends State<ProfileSetupPage> {
  final DatabaseService _dbService = DatabaseService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final ImagePicker _picker = ImagePicker();

  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  bool _isLoading = false;
  bool _notificationsEnabled = true;
  ImageProvider? _avatarImage;
  String? _base64Image;

  String? _selectedCountry; 
  
  final List<String> _countries = [
    "Afghanistan", "Albania", "Algeria", "Andorra", "Angola", "Antigua and Barbuda", "Argentina", "Armenia", "Australia", "Austria", "Azerbaijan",
    "Bahamas", "Bahrain", "Bangladesh", "Barbados", "Belarus", "Belgium", "Belize", "Benin", "Bhutan", "Bolivia", "Bosnia and Herzegovina", "Botswana", "Brazil", "Brunei", "Bulgaria", "Burkina Faso", "Burundi",
    "Cabo Verde", "Cambodia", "Cameroon", "Canada", "Central African Republic", "Chad", "Chile", "China", "Colombia", "Comoros", "Congo (Congo-Brazzaville)", "Costa Rica", "Croatia", "Cuba", "Cyprus", "Czechia (Czech Republic)",
    "Democratic Republic of the Congo", "Denmark", "Djibouti", "Dominica", "Dominican Republic",
    "East Timor (Timor-Leste)", "Ecuador", "Egypt", "El Salvador", "Equatorial Guinea", "Eritrea", "Estonia", "Eswatini", "Ethiopia",
    "Fiji", "Finland", "France",
    "Gabon", "Gambia", "Georgia", "Germany", "Ghana", "Greece", "Grenada", "Guatemala", "Guinea", "Guinea-Bissau", "Guyana",
    "Haiti", "Honduras", "Hungary",
    "Iceland", "India", "Indonesia", "Iran", "Iraq", "Ireland", "Israel", "Italy", "Ivory Coast",
    "Jamaica", "Japan", "Jordan",
    "Kazakhstan", "Kenya", "Kiribati", "Kuwait", "Kyrgyzstan",
    "Laos", "Latvia", "Lebanon", "Lesotho", "Liberia", "Libya", "Liechtenstein", "Lithuania", "Luxembourg",
    "Madagascar", "Malawi", "Malaysia", "Maldives", "Mali", "Malta", "Marshall Islands", "Mauritania", "Mauritius", "Mexico", "Micronesia", "Moldova", "Monaco", "Mongolia", "Montenegro", "Morocco", "Mozambique", "Myanmar (formerly Burma)",
    "Namibia", "Nauru", "Nepal", "Netherlands", "New Zealand", "Nicaragua", "Niger", "Nigeria", "North Korea", "North Macedonia", "Norway",
    "Oman",
    "Pakistan", "Palau", "Palestine State", "Panama", "Papua New Guinea", "Paraguay", "Peru", "Philippines", "Poland", "Portugal",
    "Qatar",
    "Romania", "Russia", "Rwanda",
    "Saint Kitts and Nevis", "Saint Lucia", "Saint Vincent and the Grenadines", "Samoa", "San Marino", "Sao Tome and Principe", "Saudi Arabia", "Senegal", "Serbia", "Seychelles", "Sierra Leone", "Singapore", "Slovakia", "Slovenia", "Solomon Islands", "Somalia", "South Africa", "South Korea", "South Sudan", "Spain", "Sri Lanka", "Sudan", "Suriname", "Sweden", "Switzerland", "Syria",
    "Tajikistan", "Tanzania", "Thailand", "Togo", "Tonga", "Trinidad and Tobago", "Tunisia", "Turkey", "Turkmenistan", "Tuvalu",
    "Uganda", "Ukraine", "United Arab Emirates", "United Kingdom", "United States", "Uruguay", "Uzbekistan",
    "Vanuatu", "Vatican City", "Venezuela", "Vietnam",
    "Yemen",
    "Zambia", "Zimbabwe"
  ].toList()..sort();

  @override
  void initState() {
    super.initState();
    _preFillData();
  }

  void _preFillData() {
    if (widget.name != null && widget.name!.isNotEmpty) {
      _nameController.text = widget.name!;
    }
    
    if (widget.email != null && widget.email!.isNotEmpty) {
      _emailController.text = widget.email!;
      if (widget.email!.contains('@')) {
        _usernameController.text = widget.email!.split('@')[0];
      }
    }

    final user = _auth.currentUser;
    if (user != null) {
      if (_emailController.text.isEmpty) {
        _emailController.text = user.email ?? "";
      }
      if (_usernameController.text.isEmpty && user.email != null) {
        _usernameController.text = user.email!.split('@')[0];
      }
    }
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      final bytes = await File(image.path).readAsBytes();
      final base64String = base64Encode(bytes);
      setState(() {
        _avatarImage = MemoryImage(bytes);
        _base64Image = base64String;
      });
    }
  }

  Future<void> _completeSetup() async {
    final name = _nameController.text.trim();
    final username = _usernameController.text.trim();
    final bio = _bioController.text.trim();

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Name is required")));
      return;
    }

    if (_selectedCountry == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please select a country")));
      return;
    }

    // --- NOVO: FILTRO DE BOM COMPORTAMENTO ---
    final validator = GoodBehaviorService();

    if (validator.isOffensive(name) || validator.isOffensive(username)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Name or Username contains inappropriate language."),
          backgroundColor: Colors.red,
        )
      );
      return;
    }

    if (validator.isOffensive(bio)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Bio contains inappropriate language."),
          backgroundColor: Colors.red,
        )
      );
      return;
    }
    // ------------------------------------------

    setState(() => _isLoading = true);

    try {
      final user = _auth.currentUser;
      if (user != null) {
        await _dbService.updateUserData(user.uid, {
          'username': username,
          'name': name,
          'bio': bio,
          'country': _selectedCountry, 
          'notificationsEnabled': _notificationsEnabled,
          'email': _emailController.text.trim(), 
          'level': 1, 
          'points': 0,
          'imageBase64': _base64Image ?? "",
          
          // --- FLAG DE PERFIL COMPLETO ---
          'isProfileComplete': true, 
          // -------------------------------
        });

        if (mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const MainScreen()),
            (route) => false,
          );
        }
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        // Título -> Montserrat (Padrão)
        title: const Text("Setup Profile", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false, 
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 10),
        child: Column(
          children: [
            // --- HEADER ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Column(
                  children: [
                    GestureDetector(
                      onTap: _pickImage,
                      child: CircleAvatar(
                        radius: 45, 
                        backgroundColor: Colors.grey.shade200,
                        backgroundImage: _avatarImage,
                        child: _avatarImage == null 
                          ? const Icon(Icons.person, size: 50, color: Colors.grey) 
                          : null,
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Texto estático -> Montserrat
                    const Text("Edit/Change Photo", style: TextStyle(fontSize: 12, color: Colors.black54))
                  ],
                ),
                Column(
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        const Icon(Icons.star_rounded, color: const Color(0xFFFC751D), size: 105),
                        Text(
                          "1", 
                          style: TextStyle(
                            color: Colors.white, 
                            fontWeight: FontWeight.bold, 
                            fontSize: 36, 
                            shadows: [
                              Shadow(offset: const Offset(1.5, 1.5), blurRadius: 3.0, color: Colors.black.withOpacity(0.4)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5), 
                    const Text("Level/Badges", style: TextStyle(fontSize: 12, color: Colors.black54))
                  ],
                )
              ],
            ),
            
            const SizedBox(height: 40),

            // --- FORMULÁRIO ---
            _buildInfoRow("Username", _usernameController),
            _buildInfoRow("Name", _nameController),
            _buildInfoRow("Bio", _bioController, showClearIcon: true),
            _buildInfoRow("Email", _emailController, enabled: false),
            
            _buildCountryDropdown(), 

            const SizedBox(height: 20),

            // --- NOTIFICAÇÕES ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Notifications", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                    Text("Receive Topic Notifications", style: TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
                Switch(
                  value: _notificationsEnabled, 
                  activeThumbColor: const Color(0xFFFC751D), 
                  onChanged: (val) => setState(() => _notificationsEnabled = val)
                )
              ],
            ),

            const SizedBox(height: 40),

            // --- BOTÃO SAVE ---
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _completeSetup,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFC751D),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isLoading 
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text("Save", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
            
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, TextEditingController controller, {bool enabled = true, bool showClearIcon = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // RÓTULO -> Montserrat
          SizedBox(
            width: 90, 
            child: Text(label, style: const TextStyle(fontSize: 16, color: Colors.black87))
          ),
          
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade100, 
                borderRadius: BorderRadius.circular(12), 
              ),
              child: TextField(
                controller: controller,
                enabled: enabled,
                textAlign: TextAlign.left,
                textAlignVertical: TextAlignVertical.center, 
                
                // INPUT DO UTILIZADOR -> AR ONE SANS
                style: GoogleFonts.arOneSans(
                  fontSize: 16, 
                  color: enabled ? Colors.black : Colors.grey.shade600
                ),

                decoration: InputDecoration(
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12), 
                  border: InputBorder.none,
                  hintText: enabled ? "Enter $label" : label,
                  
                  // PLACEHOLDER -> AR ONE SANS
                  hintStyle: GoogleFonts.arOneSans(color: Colors.grey.shade400),
                  
                  suffixIcon: (enabled && showClearIcon) 
                      ? IconButton(
                          icon: const Icon(Icons.cancel, color: Colors.grey, size: 20), 
                          onPressed: () => controller.clear(),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ) 
                      : null,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCountryDropdown() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // RÓTULO -> Montserrat
          const SizedBox(
            width: 90, 
            child: Text("Country", style: TextStyle(fontSize: 16, color: Colors.black87))
          ),
          
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade100, 
                borderRadius: BorderRadius.circular(12), 
              ),
              padding: const EdgeInsets.symmetric(horizontal: 15),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedCountry,
                  // PLACEHOLDER DROPDOWN -> AR ONE SANS
                  hint: Text("Select Country", style: GoogleFonts.arOneSans(color: Colors.grey.shade400, fontSize: 16)),
                  icon: const Icon(Icons.arrow_drop_down, color: Colors.grey),
                  isExpanded: true,
                  // ESTILO DO ITEM SELECIONADO -> AR ONE SANS
                  style: GoogleFonts.arOneSans(fontSize: 16, color: Colors.black),
                  dropdownColor: Colors.white,
                  items: _countries.map((String country) {
                    return DropdownMenuItem<String>(
                      value: country,
                      // ITEM DA LISTA -> AR ONE SANS
                      child: Text(country, style: GoogleFonts.arOneSans()),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedCountry = newValue;
                    });
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}