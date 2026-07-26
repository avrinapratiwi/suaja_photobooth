import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../models/user_model.dart';
import '../services/firebase_service.dart';

class UpdatePasswordScreen extends StatefulWidget {
  final UserModel user;
  
  const UpdatePasswordScreen({super.key, required this.user});

  @override
  State<UpdatePasswordScreen> createState() => _UpdatePasswordScreenState();
}

class _UpdatePasswordScreenState extends State<UpdatePasswordScreen> {
  int _currentStep = 1;
  final TextEditingController _currentPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  
  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;

  final FirebaseService _firebaseService = FirebaseService();

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _handleNext() {
    if (_currentStep == 1) {
      if (_currentPasswordController.text == widget.user.password) {
        setState(() => _currentStep = 2);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Password saat ini salah.'),
            backgroundColor: Color(0xFFAC282C),
          ),
        );
      }
    } else if (_currentStep == 2) {
      if (_newPasswordController.text.isEmpty || _confirmPasswordController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Password baru tidak boleh kosong.'),
            backgroundColor: Color(0xFFAC282C),
          ),
        );
        return;
      }
      
      if (_newPasswordController.text != _confirmPasswordController.text) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Konfirmasi password tidak cocok.'),
            backgroundColor: Color(0xFFAC282C),
          ),
        );
        return;
      }
      
      _savePassword();
    }
  }

  void _savePassword() async {
    setState(() => _isLoading = true);
    
    // Simulate network delay for progress bar effect
    await Future.delayed(const Duration(milliseconds: 500));
    
    // Attempt update logic
    final bool success = await _firebaseService.updateKasirPassword(widget.user.id, _newPasswordController.text);
    
    setState(() => _isLoading = false);
    
    if (success) {
      _showSuccessToast();
      // Using Future.delayed to wait for the toast progress bar before popping
      Future.delayed(const Duration(milliseconds: 2500), () {
        if (mounted) {
          Navigator.pop(context);
        }
      });
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gagal mengubah password.'),
            backgroundColor: Color(0xFFAC282C),
          ),
        );
      }
    }
  }

  void _showSuccessToast() {
    showDialog(
      context: context,
      barrierColor: Colors.transparent,
      barrierDismissible: false,
      builder: (context) {
        return Align(
          alignment: Alignment.bottomCenter,
          child: Container(
            margin: const EdgeInsets.only(bottom: 24, left: 16, right: 16),
            child: Material(
              color: Colors.transparent,
              child: _ProgressBarToast(),
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
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: Color(0xFF1E293B)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Update Password',
          style: GoogleFonts.poppins(
            color: const Color(0xFF1E293B),
            fontWeight: FontWeight.bold,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: const Color(0xFFE2E8F0), height: 1),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: _currentStep == 1 ? _buildStep1() : _buildStep2(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleNext,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFAC282C),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: _isLoading 
                    ? const SizedBox(
                        height: 20, 
                        width: 20, 
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : Text(
                        'Next',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep1() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'masukkan password sekarang anda',
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: const Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _currentPasswordController,
          obscureText: _obscureCurrent,
          decoration: InputDecoration(
            hintText: 'Password saat ini',
            filled: true,
            fillColor: const Color(0xFFF1F5F9),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFAC282C), width: 2),
            ),
            suffixIcon: IconButton(
              icon: Icon(
                _obscureCurrent ? LucideIcons.eyeOff : LucideIcons.eye,
                color: const Color(0xFF94A3B8),
              ),
              onPressed: () {
                setState(() => _obscureCurrent = !_obscureCurrent);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStep2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'masukkan password baru anda',
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: const Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _newPasswordController,
          obscureText: _obscureNew,
          decoration: InputDecoration(
            hintText: 'Password baru',
            filled: true,
            fillColor: const Color(0xFFF1F5F9),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFAC282C), width: 2),
            ),
            suffixIcon: IconButton(
              icon: Icon(
                _obscureNew ? LucideIcons.eyeOff : LucideIcons.eye,
                color: const Color(0xFF94A3B8),
              ),
              onPressed: () {
                setState(() => _obscureNew = !_obscureNew);
              },
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'konfirmasi password',
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: const Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _confirmPasswordController,
          obscureText: _obscureConfirm,
          decoration: InputDecoration(
            hintText: 'Konfirmasi password',
            filled: true,
            fillColor: const Color(0xFFF1F5F9),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFAC282C), width: 2),
            ),
            suffixIcon: IconButton(
              icon: Icon(
                _obscureConfirm ? LucideIcons.eyeOff : LucideIcons.eye,
                color: const Color(0xFF94A3B8),
              ),
              onPressed: () {
                setState(() => _obscureConfirm = !_obscureConfirm);
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _ProgressBarToast extends StatefulWidget {
  @override
  State<_ProgressBarToast> createState() => _ProgressBarToastState();
}

class _ProgressBarToastState extends State<_ProgressBarToast> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000), // Total 2s before disappear
    )..forward();
    
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        if (mounted) {
          Navigator.of(context).pop();
        }
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                const Icon(LucideIcons.checkCircle, color: Color(0xFF10B981), size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Password berhasil diubah!',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return LinearProgressIndicator(
                value: _controller.value,
                backgroundColor: const Color(0xFF1E293B),
                valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF10B981)),
                minHeight: 4,
              );
            },
          ),
        ],
      ),
    );
  }
}
