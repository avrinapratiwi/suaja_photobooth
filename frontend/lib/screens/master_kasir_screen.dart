import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import '../models/user_model.dart';
import '../services/firebase_service.dart';
import '../widgets/delete_confirmation_dialog.dart';
import '../widgets/notification_bell.dart';

class MasterKasirScreen extends StatefulWidget {
  const MasterKasirScreen({super.key});

  @override
  State<MasterKasirScreen> createState() => _MasterKasirScreenState();
}

class _MasterKasirScreenState extends State<MasterKasirScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  final Set<String> _selectedKasirIds = {};

  void _openKasirDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return KasirFormDialog(
          onSave: (user) async {
            await _firebaseService.addUser(user);
          },
        );
      },
    );
  }

  void _toggleSelection(String id) {
    setState(() {
      if (_selectedKasirIds.contains(id)) {
        _selectedKasirIds.remove(id);
      } else {
        _selectedKasirIds.add(id);
      }
    });
  }

  void _deleteSelected() async {
    final confirmed = await showDeleteConfirmationDialog(
      context: context,
      title: 'Hapus Kasir',
      content: 'Anda yakin ingin menghapus ${_selectedKasirIds.length} kasir terpilih secara permanen?',
    );

    if (confirmed != true) return;

    for (String id in _selectedKasirIds) {
      await _firebaseService.deleteUser(id);
    }
    setState(() {
      _selectedKasirIds.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: Color(0xFF1E293B)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Kelola Kasir',
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
      body: StreamBuilder<List<UserModel>>(
        stream: _firebaseService.kasirsStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final kasirs = snapshot.data ?? [];

          if (kasirs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    LucideIcons.monitorSmartphone,
                    size: 80,
                    color: Color(0xFFCBD5E1),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Belum ada data kasir',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      color: const Color(0xFF64748B),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Silakan tambahkan data kasir terlebih dahulu.',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: const Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ),
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Selection Action Bar
              if (_selectedKasirIds.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(left: 16, right: 16, top: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${_selectedKasirIds.length} dipilih',
                        style: GoogleFonts.poppins(
                          color: const Color(0xFF64748B),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      IconButton(
                        onPressed: _deleteSelected,
                        icon: const Icon(LucideIcons.trash2, color: Colors.red),
                        tooltip: 'Hapus yang dipilih',
                      ),
                    ],
                  ),
                ),
              // Count Header
              Padding(
                padding: const EdgeInsets.only(left: 16, top: 16, right: 16, bottom: 4),
                child: Text(
                  '${kasirs.length} Kasir',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFFAC282C),
                  ),
                ),
              ),
              // List Content
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: kasirs.length,
                  itemBuilder: (context, index) {
                    final kasir = kasirs[index];
                    final isSelected = _selectedKasirIds.contains(kasir.id);
                    final formattedTime = kasir.createdAt != null 
                        ? DateFormat('dd MMM, HH:mm').format(kasir.createdAt!)
                        : 'Waktu tidak diketahui';

                    return GestureDetector(
                      onLongPress: () => _toggleSelection(kasir.id),
                      onTap: () {
                        if (_selectedKasirIds.isNotEmpty) {
                          _toggleSelection(kasir.id);
                        }
                      },
                      child: Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        elevation: isSelected ? 4 : 0,
                        color: isSelected ? const Color(0xFFFEE2E2) : Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: isSelected ? Colors.red : const Color(0xFFE2E8F0),
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                          child: Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: isSelected ? Colors.red.shade100 : const Color(0xFFF1F5F9),
                                child: Icon(
                                  isSelected ? LucideIcons.check : LucideIcons.user, 
                                  color: isSelected ? Colors.red : const Color(0xFF475569)
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Text(
                                  kasir.name,
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF1E293B)
                                  ),
                                ),
                              ),
                              Text(
                                formattedTime,
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: const Color(0xFF94A3B8),
                                ),
                                textAlign: TextAlign.right,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openKasirDialog(),
        backgroundColor: const Color(0xFFAC282C),
        child: const Icon(LucideIcons.plus, color: Colors.white),
      ),
    );
  }
}

class KasirFormDialog extends StatefulWidget {
  final Function(UserModel) onSave;

  const KasirFormDialog({
    super.key,
    required this.onSave,
  });

  @override
  State<KasirFormDialog> createState() => _KasirFormDialogState();
}

class _KasirFormDialogState extends State<KasirFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController(text: 'kasir');
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _nameController.addListener(() {
      final name = _nameController.text.trim().toLowerCase().replaceAll(' ', '');
      _passwordController.text = '${name}kasir';
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _save() {
    if (_formKey.currentState!.validate()) {
      final user = UserModel(
        id: '',
        name: _nameController.text.trim(),
        password: _passwordController.text,
        role: 'kasir',
        createdAt: DateTime.now(),
      );
      widget.onSave(user);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              color: const Color(0xFFF1F5F9), // Light gray background
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Tambah Kasir',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFFAC282C),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(LucideIcons.x, size: 20),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
            // Body
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: 'Nama Kasir',
                      labelStyle: GoogleFonts.poppins(color: const Color(0xFF64748B)),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Color(0xFFAC282C), width: 2),
                      ),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                    ),
                    validator: (value) => value == null || value.isEmpty ? 'Wajib diisi' : null,
                  ),
              const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordController,
                    readOnly: true,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      labelStyle: GoogleFonts.poppins(color: const Color(0xFF64748B)),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Color(0xFFAC282C), width: 2),
                      ),
                      filled: true,
                      fillColor: const Color(0xFFE2E8F0),
                      suffixIcon: IconButton(
                        icon: Icon(_obscurePassword ? LucideIcons.eyeOff : LucideIcons.eye, color: const Color(0xFF94A3B8)),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                    ),
                  ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFAC282C),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    elevation: 0,
                  ),
                  child: Text('Simpan', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                ),
              ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
