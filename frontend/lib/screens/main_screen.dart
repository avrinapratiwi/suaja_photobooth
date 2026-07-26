import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'landing_screen.dart';
import 'kasir_screen.dart';
import 'rekap_screen.dart';
import 'report_screen.dart';
import 'master_data_screen.dart';
import 'profile_screen.dart';
import '../models/event_model.dart';
import 'package:flutter/services.dart';
import 'package:flutter/services.dart';

import '../models/user_model.dart';

final GlobalKey<MainScreenState> mainScreenKey = GlobalKey<MainScreenState>();

class MainScreen extends StatefulWidget {
  final UserModel user;
  MainScreen({Key? key, required this.user}) : super(key: key ?? mainScreenKey);

  @override
  State<MainScreen> createState() => MainScreenState();
}

class MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  final Color _primaryColor = const Color(0xFFAC282C); // Suaja Red
  final GlobalKey<KasirScreenState> _kasirKey = GlobalKey<KasirScreenState>();
  DateTime? _lastBackPressTime;
  EventModel? _activeEvent;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _switchToKasir(EventModel event) {
    setState(() {
      _activeEvent = event;
      _selectedIndex = 1;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Pass the callback to LandingScreen so it can switch tabs instead of pushing a new route
    final List<Widget> pages = [
      LandingScreen(role: widget.user.role, onBukaKasir: _switchToKasir),
      widget.user.role == 'admin' ? const MasterDataScreen() : KasirScreen(key: _kasirKey, role: widget.user.role, user: widget.user, activeEvent: _activeEvent),
      widget.user.role == 'admin' ? const ReportScreen() : const RekapScreen(),
      ProfileScreen(user: widget.user),
    ];

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        // 1. Check Kasir state if we are on Kasir tab
        if (_selectedIndex == 1) {
          final kasirState = _kasirKey.currentState;
          if (kasirState != null) {
            if (kasirState.isSelectionMode) {
              kasirState.cancelSelection();
              return;
            } else if (kasirState.isViewingPOS) {
              kasirState.closePOS();
              return;
            }
          }
        }

        // 2. Not in Beranda -> switch to Beranda
        if (_selectedIndex != 0) {
          setState(() {
            _selectedIndex = 0;
          });
          return;
        }

        // 3. Already in Beranda -> Double back to exit
        final now = DateTime.now();
        if (_lastBackPressTime == null ||
            now.difference(_lastBackPressTime!) > const Duration(seconds: 2)) {
          _lastBackPressTime = now;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(
                'Tekan lagi untuk keluar',
                textAlign: TextAlign.center,
              ),
              backgroundColor: Colors.black.withValues(alpha: 0.7),
              duration: const Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              margin: EdgeInsets.only(
                bottom: MediaQuery.of(context).size.height * 0.4,
                left: 80,
                right: 80,
              ),
            ),
          );
          return;
        }

        SystemNavigator.pop(); // Exit app
      },
      child: Scaffold(
      body: Stack(
        children: [
          IndexedStack(
            index: _selectedIndex,
            children: pages,
          ),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          backgroundColor: Colors.white,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: _primaryColor,
          unselectedItemColor: Colors.grey.shade400,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal, fontSize: 12),
          items: [
            const BottomNavigationBarItem(
              icon: Icon(LucideIcons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(widget.user.role == 'admin' ? LucideIcons.database : LucideIcons.store),
              label: widget.user.role == 'admin' ? 'Master Data' : 'Kasir',
            ),
            BottomNavigationBarItem(
              icon: Icon(widget.user.role == 'admin' ? LucideIcons.fileText : LucideIcons.receipt),
              label: widget.user.role == 'admin' ? 'Laporan' : 'Rekap',
            ),
            BottomNavigationBarItem(
              icon: Icon(widget.user.role == 'admin' ? LucideIcons.settings : LucideIcons.user),
              label: widget.user.role == 'admin' ? 'Setting' : 'Profile',
            ),
          ],
        ),
      ),
    ));
  }
}
