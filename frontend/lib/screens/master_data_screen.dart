import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'master_event_screen.dart';
import 'master_aksesoris_screen.dart';
import 'master_kasir_screen.dart';
import 'master_set_photobooth_screen.dart';
import '../widgets/notification_bell.dart';

class MasterDataScreen extends StatelessWidget {
  const MasterDataScreen({super.key});

  final Color _primaryColor = const Color(0xFFAC282C);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text(
          'Master Data',
          style: GoogleFonts.poppins(
            color: const Color(0xFF1E293B),
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: const [
          NotificationBellWidget(),
          SizedBox(width: 16),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: const Color(0xFFE2E8F0), height: 1),
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isDesktop = constraints.maxWidth >= 600;

          final items = [
            _ItemData(
              icon: LucideIcons.calendar,
              label: 'Schedule Event',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const MasterEventScreen()),
                );
              },
            ),
            _ItemData(
              icon: LucideIcons.package,
              label: 'Kelola Aksesoris',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const MasterAksesorisScreen()),
                );
              },
            ),
            _ItemData(
              icon: LucideIcons.monitorSmartphone,
              label: 'Kelola Kasir',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const MasterKasirScreen()),
                );
              },
            ),
            _ItemData(
              icon: LucideIcons.camera,
              label: 'Set Photobooth',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const MasterSetPhotoboothScreen()),
                );
              },
            ),
          ];

          if (isDesktop) {
            return Padding(
              padding: const EdgeInsets.all(24.0),
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.0,
                children: items.map((item) => _buildGridCard(
                  context, 
                  icon: item.icon, 
                  label: item.label, 
                  onTap: item.onTap
                )).toList(),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.only(top: 16),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return _buildListCard(
                context,
                icon: item.icon,
                label: item.label,
                onTap: item.onTap,
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildListCard(BuildContext context, {required IconData icon, required String label, required VoidCallback onTap}) {
    return Material(
      color: Colors.transparent,
      child: Column(
        children: [
          InkWell(
            onTap: onTap,
            highlightColor: _primaryColor.withValues(alpha: 0.1),
            splashColor: _primaryColor.withValues(alpha: 0.2),
            child: Container(
              color: Colors.transparent,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: _primaryColor.withValues(alpha: 0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(icon, color: _primaryColor, size: 24),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      label,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: _primaryColor,
                      ),
                    ),
                  ),
                  Icon(LucideIcons.chevronRight, color: _primaryColor.withValues(alpha: 0.5)),
                ],
              ),
            ),
          ),
          Container(
            color: Colors.transparent,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Divider(
                height: 1, 
                thickness: 1,
                color: _primaryColor.withValues(alpha: 0.2)
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGridCard(BuildContext context, {required IconData icon, required String label, required VoidCallback onTap}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        highlightColor: _primaryColor.withValues(alpha: 0.1),
        splashColor: _primaryColor.withValues(alpha: 0.2),
        child: Container(
          decoration: BoxDecoration(
            color: _primaryColor.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _primaryColor.withValues(alpha: 0.2)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 48,
                color: _primaryColor,
              ),
              const SizedBox(height: 16),
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: _primaryColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ItemData {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  _ItemData({required this.icon, required this.label, required this.onTap});
}
