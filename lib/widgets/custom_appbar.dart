import 'package:flutter/material.dart';
import 'package:services_domicile/globals.dart' as globals;

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final bool showBack;
  final String? title;
  final bool centerTitle; 
  final String? username; 
  final VoidCallback? onLogout; 

  const CustomAppBar({
    super.key,
    this.showBack = true,
    this.title,required this.centerTitle,
    this.username,
    this.onLogout,
    }
    );

  @override
  Widget build(BuildContext context) {
    return AppBar(
      leading: showBack
          ? IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.pop(context),
            )
          : null,
      title: title != null ? Text(title!) : null,
      centerTitle: centerTitle,
      elevation: 0,
      
      //  === Gradient ===
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color.fromARGB(255, 5, 143, 182),
              Color.fromARGB(255, 56, 177, 119),
              Color.fromARGB(250, 146, 83, 137),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
      ),

       actions: [
        if (username != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Row(
              children: [
                Text(
                  username!,
                  style: const TextStyle(fontSize: 16, color: Colors.white),
                ),
IconButton(
  icon: const Icon(Icons.logout, color: Colors.white),
  onPressed: () {
    if (onLogout != null) {
      onLogout!();
    } else {
      globals.currentUserName = null;
      Navigator.pushReplacementNamed(context, '/login');
    }
  },
),
              ],
            ),
          ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
