import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui; // Necessário para o efeito de Blur
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../auth_service.dart';
import '../database_service.dart';
import 'landing_page.dart';
import 'package:google_fonts/google_fonts.dart'; // <--- IMPORT IMPORTANTE
import 'services/good_behavior_service.dart'; // <--- IMPORT DO NOVO SERVIÇO

class ProfilePageWidget extends StatefulWidget {
  final bool isMainTab;

  const ProfilePageWidget({super.key, this.isMainTab = false});

  @override
  State<ProfilePageWidget> createState() => _ProfilePageWidgetState();
}

class _ProfilePageWidgetState extends State<ProfilePageWidget> {
  final AuthService _auth = AuthService();
  final DatabaseService _dbService = DatabaseService();
  final ImagePicker _picker = ImagePicker();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();

  String? _selectedCountry;
  
  // Lista de Países
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

  bool _isEditing = false;
  bool _notificationsEnabled = false;
  ImageProvider? _avatarImage;
  String? _base64Image;
  
  int _userLevel = 1;
  int _userPoints = 0;
  
  String? _originalUsername; 

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = _auth.currentUser;
    if (user != null) {
      _emailController.text = user.email ?? "";
      final userData = await _dbService.getUserData(user.uid);
      if (userData != null && mounted) {
        setState(() {
          _nameController.text = userData['name'] ?? "";
          
          String userN = userData['username'] ?? "Username";
          _usernameController.text = userN;
          _originalUsername = userN;

          _bioController.text = userData['bio'] ?? "";
          
          String loadedCountry = userData['country'] ?? "";
          if (_countries.contains(loadedCountry)) {
            _selectedCountry = loadedCountry;
          } else if (loadedCountry.isNotEmpty) {
            _countries.add(loadedCountry);
            _countries.sort();
            _selectedCountry = loadedCountry;
          } else {
            _selectedCountry = null;
          }

          _notificationsEnabled = userData['notificationsEnabled'] ?? false;
          _userLevel = userData['level'] ?? 1;
          
          if (userData['points'] != null) {
             _userPoints = (userData['points'] as num).toInt();
          } else {
             _userPoints = 0;
          }

          if (userData['imageBase64'] != null && (userData['imageBase64'] as String).isNotEmpty) {
            _base64Image = userData['imageBase64'];
            _avatarImage = MemoryImage(base64Decode(_base64Image!));
          } else if (user.photoURL != null) {
            _avatarImage = NetworkImage(user.photoURL!);
          }
        });
      }
    }
  }

  Future<void> _pickImage() async {
    if (!_isEditing) return;

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

  Future<void> _saveProfile() async {
    final user = _auth.currentUser;
    if (user != null) {
      final newUsername = _usernameController.text.trim();
      final bio = _bioController.text.trim();
      final name = _nameController.text.trim();

      // --- FILTRO DE BOM COMPORTAMENTO ---
      final validator = GoodBehaviorService();

      if (validator.isOffensive(newUsername)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Username contains inappropriate language."), backgroundColor: Colors.red)
        );
        return;
      }

      if (validator.isOffensive(name)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Name contains inappropriate language."), backgroundColor: Colors.red)
        );
        return;
      }

      if (validator.isOffensive(bio)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Bio contains inappropriate language. Please be respectful."), backgroundColor: Colors.red)
        );
        return;
      }
      // ------------------------------------

      if (newUsername.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Username cannot be empty")));
        return;
      }

      if (newUsername != _originalUsername) {
        bool exists = await _dbService.checkUsernameExists(newUsername);
        if (exists) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Username already taken. Please choose another.")));
          return; 
        }
      }

      if (_selectedCountry == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please select a country")));
        return;
      }

      await _dbService.updateUserData(user.uid, {
        'username': newUsername, 
        'name': name,
        'bio': bio,
        'country': _selectedCountry,
        'notificationsEnabled': _notificationsEnabled,
        'imageBase64': _base64Image ?? "",
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Profile Updated!")));
        setState(() {
          _isEditing = false;
          _originalUsername = newUsername; 
        });
      }
    }
  }

  Future<void> _logout() async {
    await _auth.signOut();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LandingPage()),
        (Route<dynamic> route) => false,
      );
    }
  }

  void _showLevelPopup() {
    print("CLICKED LEVEL");
    int xpPerLevel = 100; 
    int xpInCurrentCycle = _userPoints % xpPerLevel;
    double progress = xpInCurrentCycle / xpPerLevel;
    int xpMissing = xpPerLevel - xpInCurrentCycle;

    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.4),
      builder: (BuildContext context) {
        return BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.all(20),
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                Container(
                  width: 320,
                  padding: const EdgeInsets.all(25),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 15, spreadRadius: 2),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.star_rounded, color: const Color(0xFFFC751D), size: 80),
                      const SizedBox(height: 10),
                      
                      Text(
                        "Level $_userLevel",
                        style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black87),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        "Total XP: $_userPoints",
                        style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                      ),
                      
                      const SizedBox(height: 30),

                      // Barra de Progresso
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: SizedBox(
                          height: 15,
                          child: LinearProgressIndicator(
                            value: progress,
                            backgroundColor: Colors.grey.shade300,
                            valueColor: const AlwaysStoppedAnimation<Color>(const Color(0xFFFC751D)),
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 10),
                      
                      Text(
                        "$xpMissing XP to Level up",
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: const Color(0xFFFC751D)),
                      ),
                    ],
                  ),
                ),

                Positioned(
                  right: 0,
                  top: 0,
                  child: GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      child: const Icon(Icons.close, color: Colors.black54),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Profile", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.normal)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: !widget.isMainTab,
        leading: widget.isMainTab 
            ? null 
            : IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.black), 
                onPressed: () => Navigator.pop(context)
              ),
        actions: [IconButton(icon: const Icon(Icons.logout, color: const Color(0xFFFC751D)), onPressed: _logout)],
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
                      onTap: _isEditing ? _pickImage : () => setState(() => _isEditing = true),
                      child: Stack(
                        children: [
                          CircleAvatar(
                            radius: 45, 
                            backgroundColor: Colors.grey.shade200, 
                            backgroundImage: _avatarImage,
                            child: _avatarImage == null 
                              ? const Icon(Icons.person, size: 50, color: Colors.grey) 
                              : null,
                          ),
                          if (_isEditing)
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(color: const Color(0xFFFC751D), shape: BoxShape.circle),
                                child: const Icon(Icons.camera_alt, color: Colors.white, size: 16),
                              ),
                            )
                        ],
                      ),
                    ),
                    const SizedBox(height: 20), 
                    Text(_isEditing ? "Tap to Change" : "Edit/Change Photo", style: const TextStyle(fontSize: 12, color: Colors.black54)),
                    const SizedBox(height: 0),
                  ],
                ),
                
                // --- COLUNA DO NÍVEL ---
                GestureDetector(
                  onTap: _showLevelPopup, 
                  behavior: HitTestBehavior.translucent, 
                  child: Column(
                    children: [
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          const Icon(Icons.star_rounded, color: const Color(0xFFFC751D), size: 120),
                          Text(
                            "$_userLevel", 
                            style: TextStyle(
                              color: Colors.white, 
                              fontWeight: FontWeight.bold, 
                              fontSize: 40,
                              shadows: [
                                Shadow(offset: const Offset(1.5, 1.5), blurRadius: 3.0, color: Colors.black.withOpacity(0.4)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      const Text("Level/Badges", style: TextStyle(fontSize: 12, color: Colors.black54)),
                      const SizedBox(height: 15),
                    ],
                  ),
                )
              ],
            ),
            
            const SizedBox(height: 40),

            // --- FORMULÁRIO ---
            _buildInfoRow("Username", _usernameController, enabled: _isEditing, showClearIcon: _isEditing),
            _buildInfoRow("Name", _nameController, enabled: _isEditing),
            _buildInfoRow("Bio", _bioController, enabled: _isEditing, showClearIcon: _isEditing),
            _buildInfoRow("Email", _emailController, enabled: false), 
            _buildCountryRow(),

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
                _isEditing 
                ? Switch(value: _notificationsEnabled, activeThumbColor: const Color(0xFFFC751D), onChanged: (val) => setState(() => _notificationsEnabled = val))
                : Icon(
                    Icons.notifications, 
                    color: _notificationsEnabled ? const Color(0xFFFC751D) : Colors.grey
                  )
              ],
            ),

            const SizedBox(height: 40),

            // --- BOTÕES ---
            if (!_isEditing)
               SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () => setState(() => _isEditing = true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFC751D),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text("Edit Profile", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              )
            else
              Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _saveProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFC751D),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text("Save", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 15),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: OutlinedButton(
                      onPressed: () {
                        setState(() => _isEditing = false);
                        _loadUserData(); 
                      },
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: const Color(0xFFFC751D)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text("Cancel", style: TextStyle(color: const Color(0xFFFC751D), fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 20),
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
          // RÓTULO (Esquerda) -> Montserrat (Padrão)
          SizedBox(width: 90, child: Text(label, style: const TextStyle(fontSize: 16, color: Colors.black87))),
          
          Expanded(
            child: TextField(
              controller: controller,
              enabled: enabled,
              textAlign: TextAlign.left,
              decoration: InputDecoration(
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                border: InputBorder.none,
                hintText: label,
                hintStyle: TextStyle(color: Colors.grey.shade300),
                suffixIcon: (enabled && showClearIcon) 
                    ? IconButton(icon: const Icon(Icons.cancel, color: Colors.grey, size: 20), onPressed: () => controller.clear()) 
                    : null,
              ),
              // INPUT DO UTILIZADOR (Direita) -> AR ONE SANS
              style: GoogleFonts.arOneSans(
                fontSize: 16, 
                color: enabled ? Colors.black : Colors.grey.shade600
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCountryRow() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // RÓTULO (Esquerda) -> Montserrat (Padrão)
          SizedBox(
            width: 90, 
            child: Text("Country", style: const TextStyle(fontSize: 16, color: Colors.black87))
          ),
          
          Expanded(
            child: _isEditing
              ? Container(
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedCountry,
                      hint: Text("Select Country", style: GoogleFonts.arOneSans(color: Colors.grey.shade400)),
                      isExpanded: true,
                      icon: const Icon(Icons.arrow_drop_down, color: Colors.grey),
                      items: _countries.map((String country) {
                        return DropdownMenuItem<String>(
                          value: country,
                          // OPÇÃO DO DROPDOWN -> AR ONE SANS
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
                )
              : Container(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                  // VALOR JÁ SELECIONADO (Visualização) -> AR ONE SANS
                  child: Text(
                    _selectedCountry ?? "Not Selected",
                    style: GoogleFonts.arOneSans(fontSize: 16, color: Colors.grey.shade600),
                  ),
                ),
          ),
        ],
      ),
    );
  }
}