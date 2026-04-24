import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ─── Brand palette (mirrors dashboard) ───────────────────────────────────────
const _kPrimary   = Color(0xFF2563EB);
const _kAccent    = Color(0xFF3B82F6);
const _kPurple    = Color(0xFF7C3AED);
const _kBg        = Color(0xFFF1F5FB);
const _kCard      = Colors.white;
const _kTextDark  = Color(0xFF0F172A);
const _kTextMuted = Color(0xFF64748B);
const _kBorder    = Color(0xFFE2E8F0);
const _kError     = Color(0xFFEF4444);
const _kSuccess   = Color(0xFF10B981);

// ══════════════════════════════════════════════════════════════════════════════
class AddStudentScreen extends StatefulWidget {
  const AddStudentScreen({super.key});

  @override
  State<AddStudentScreen> createState() => _AddStudentScreenState();
}

class _AddStudentScreenState extends State<AddStudentScreen>
    with SingleTickerProviderStateMixin {
  final _formKey        = GlobalKey<FormState>();
  final _nameCtrl       = TextEditingController();
  final _fatherNameCtrl = TextEditingController();
  final _phoneCtrl      = TextEditingController();
  final _schoolCtrl     = TextEditingController();
  final _addressCtrl    = TextEditingController();

  bool    _saving       = false;
  String? _errorMessage;

  // Generated credentials (shown in preview)
  String _generatedEmail    = '';
  String _generatedPassword = '';

  late final AnimationController _anim;
  late final Animation<double>   _fade;
  late final Animation<Offset>   _slide;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 480),
    )..forward();
    _fade  = CurvedAnimation(parent: _anim, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.10),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _anim, curve: Curves.easeOutCubic));

    // Generate default credentials immediately so preview is visible
    _regenerateCredentials('');
    _nameCtrl.addListener(() => _regenerateCredentials(_nameCtrl.text));
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _fatherNameCtrl.dispose();
    _phoneCtrl.dispose();
    _schoolCtrl.dispose();
    _addressCtrl.dispose();
    _anim.dispose();
    super.dispose();
  }

  // ── Credential generation ─────────────────────────────────────────────────
  void _regenerateCredentials(String name) {
    final rng    = Random();
    final suffix = 1000 + rng.nextInt(8999); // 4-digit number
    final slug   = name.trim().isEmpty
        ? 'std'
        : name.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
    final email    = '${slug.isEmpty ? 'std' : slug}$suffix@classora.com';
    final password = (100000 + rng.nextInt(899999)).toString(); // 6-digit
    setState(() {
      _generatedEmail    = email;
      _generatedPassword = password;
    });
  }

  // ── Validation ────────────────────────────────────────────────────────────
  String? _validateName(String? v) {
    if (v == null || v.trim().isEmpty) return 'Student name is required';
    if (v.trim().length < 2) return 'Name must be at least 2 characters';
    return null;
  }

  String? _validatePhone(String? v) {
    if (v == null || v.trim().isEmpty) return 'Phone number is required';
    final digits = v.trim().replaceAll(RegExp(r'\D'), '');
    if (digits.length < 10) return 'Enter a valid phone number';
    return null;
  }

  // ── Save to Firestore ─────────────────────────────────────────────────────
  Future<void> _saveStudent() async {
    FocusScope.of(context).unfocus();
    setState(() => _errorMessage = null);
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;

      await FirebaseFirestore.instance.collection('students').add({
        'name':        _nameCtrl.text.trim(),
        'father_name': _fatherNameCtrl.text.trim(),
        'phone':       _phoneCtrl.text.trim(),
        'school':      _schoolCtrl.text.trim(),
        'address':     _addressCtrl.text.trim(),
        'username':    _generatedEmail,
        'password':    _generatedPassword,
        'batch_id':    '',
        'teacher_id':  uid,
        'status':      'active',
        'created_at':  FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      Navigator.of(context).pop(true); // return true = success
    } on FirebaseException catch (e) {
      if (!mounted) return;
      setState(() => _errorMessage = e.message ?? 'Failed to save student.');
    } catch (_) {
      if (!mounted) return;
      setState(() => _errorMessage = 'Something went wrong. Please try again.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final safeTop    = MediaQuery.of(context).padding.top;
    final safeBottom = MediaQuery.of(context).padding.bottom;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: _kBg,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: _kBg,
        body: Stack(
          children: [
            // Background decorations
            Positioned(
              top: -80, right: -60,
              child: _Blob(220, _kPrimary.withOpacity(0.06)),
            ),
            Positioned(
              bottom: -100, left: -50,
              child: _Blob(260, _kPurple.withOpacity(0.05)),
            ),

            Column(
              children: [
                // ── App bar ─────────────────────────────────────────────────
                _buildAppBar(safeTop),

                // ── Scrollable form ─────────────────────────────────────────
                Expanded(
                  child: FadeTransition(
                    opacity: _fade,
                    child: SlideTransition(
                      position: _slide,
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        padding: EdgeInsets.fromLTRB(24, 24, 24, safeBottom + 32),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Student info section
                              _SectionLabel(label: 'Student Information'),
                              const SizedBox(height: 14),

                              _FieldLabel(label: 'Full Name', required: true),
                              const SizedBox(height: 8),
                              _InputField(
                                controller: _nameCtrl,
                                hint: 'e.g. Rahim Hossain',
                                icon: Icons.person_outline_rounded,
                                validator: _validateName,
                                textCapitalization: TextCapitalization.words,
                              ),

                              const SizedBox(height: 18),

                              _FieldLabel(label: "Father's Name"),
                              const SizedBox(height: 8),
                              _InputField(
                                controller: _fatherNameCtrl,
                                hint: 'e.g. Karim Hossain',
                                icon: Icons.people_outline_rounded,
                                textCapitalization: TextCapitalization.words,
                              ),

                              const SizedBox(height: 18),

                              _FieldLabel(label: 'Phone Number', required: true),
                              const SizedBox(height: 4),
                              Text(
                                'Used for emergency contact with parents',
                                style: TextStyle(
                                  color: _kTextMuted.withOpacity(0.75),
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 8),
                              _InputField(
                                controller: _phoneCtrl,
                                hint: '017XXXXXXXX',
                                icon: Icons.phone_outlined,
                                keyboardType: TextInputType.phone,
                                validator: _validatePhone,
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(
                                      RegExp(r'[\d\+\-\s]')),
                                ],
                              ),

                              const SizedBox(height: 18),

                              _FieldLabel(label: 'School Name'),
                              const SizedBox(height: 8),
                              _InputField(
                                controller: _schoolCtrl,
                                hint: 'e.g. XYZ High School',
                                icon: Icons.school_outlined,
                                textCapitalization: TextCapitalization.words,
                              ),

                              const SizedBox(height: 18),

                              _FieldLabel(label: 'Address'),
                              const SizedBox(height: 8),
                              _InputField(
                                controller: _addressCtrl,
                                hint: 'e.g. Rajshahi',
                                icon: Icons.location_on_outlined,
                                textCapitalization: TextCapitalization.words,
                              ),

                              const SizedBox(height: 28),

                              // ── Credentials preview ──────────────────────
                              _SectionLabel(label: 'Auto-Generated Credentials'),
                              const SizedBox(height: 14),
                              _CredentialsCard(
                                email: _generatedEmail,
                                password: _generatedPassword,
                                onRegenerate: () =>
                                    _regenerateCredentials(_nameCtrl.text),
                              ),

                              // ── Error ────────────────────────────────────
                              if (_errorMessage != null) ...[
                                const SizedBox(height: 16),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: _kError.withOpacity(0.08),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                        color: _kError.withOpacity(0.25)),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(Icons.error_outline_rounded,
                                          color: _kError, size: 18),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          _errorMessage!,
                                          style: const TextStyle(
                                            color: _kError,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],

                              const SizedBox(height: 32),

                              // ── Save button ──────────────────────────────
                              _SaveButton(
                                saving: _saving,
                                onTap: _saveStudent,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── App bar ────────────────────────────────────────────────────────────────
  Widget _buildAppBar(double safeTop) {
    return Container(
      color: _kBg,
      padding: EdgeInsets.fromLTRB(8, safeTop + 8, 20, 12),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.arrow_back_ios_new_rounded,
                size: 20, color: _kTextDark),
          ),
          const Expanded(
            child: Text(
              'Add Student',
              style: TextStyle(
                color: _kTextDark,
                fontSize: 20,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
              ),
            ),
          ),
          // Avatar indicator
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [_kPrimary, _kPurple],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: const Icon(Icons.person_add_rounded,
                color: Colors.white, size: 18),
          ),
        ],
      ),
    );
  }
}

// ─── Credentials preview card ──────────────────────────────────────────────────
class _CredentialsCard extends StatelessWidget {
  final String email;
  final String password;
  final VoidCallback onRegenerate;

  const _CredentialsCard({
    required this.email,
    required this.password,
    required this.onRegenerate,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _kBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.045),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _kSuccess.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.vpn_key_rounded,
                    color: _kSuccess, size: 18),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Login Credentials',
                  style: TextStyle(
                    color: _kTextDark,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              GestureDetector(
                onTap: onRegenerate,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: _kPrimary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.refresh_rounded,
                          color: _kPrimary, size: 14),
                      SizedBox(width: 4),
                      Text(
                        'Regenerate',
                        style: TextStyle(
                          color: _kPrimary,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: _kBorder, height: 1),
          const SizedBox(height: 14),
          _CredRow(
            icon: Icons.alternate_email_rounded,
            label: 'Username (Email)',
            value: email,
          ),
          const SizedBox(height: 12),
          _CredRow(
            icon: Icons.lock_outline_rounded,
            label: 'Password',
            value: password,
          ),
          const SizedBox(height: 12),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF7ED),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFFED7AA)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline_rounded,
                    color: Color(0xFFF97316), size: 14),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Share these credentials with the student to log in.',
                    style: TextStyle(
                      color: const Color(0xFFF97316).withOpacity(0.85),
                      fontSize: 11.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CredRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _CredRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: _kTextMuted),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: _kTextMuted,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: const TextStyle(
                color: _kTextDark,
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ─── Save button ──────────────────────────────────────────────────────────────
class _SaveButton extends StatelessWidget {
  final bool saving;
  final VoidCallback onTap;
  const _SaveButton({required this.saving, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: saving ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        height: 56,
        decoration: BoxDecoration(
          gradient: saving
              ? null
              : const LinearGradient(
                  colors: [_kPrimary, _kAccent],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
          color: saving ? _kBorder : null,
          borderRadius: BorderRadius.circular(16),
          boxShadow: saving
              ? []
              : [
                  BoxShadow(
                    color: _kPrimary.withOpacity(0.35),
                    blurRadius: 14,
                    offset: const Offset(0, 5),
                  ),
                ],
        ),
        child: Center(
          child: saving
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: _kPrimary,
                  ),
                )
              : const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle_outline_rounded,
                        color: Colors.white, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Add Student',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

// ─── Shared small widgets ──────────────────────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Container(
            width: 4,
            height: 18,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [_kPrimary, _kPurple],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            label,
            style: const TextStyle(
              color: _kTextDark,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      );
}

class _FieldLabel extends StatelessWidget {
  final String label;
  final bool required;
  const _FieldLabel({required this.label, this.required = false});

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Text(
            label,
            style: const TextStyle(
              color: _kTextDark,
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (required) ...[
            const SizedBox(width: 3),
            const Text('*',
                style: TextStyle(color: _kError, fontWeight: FontWeight.w700)),
          ],
        ],
      );
}

class _InputField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;
  final List<TextInputFormatter>? inputFormatters;
  final TextCapitalization textCapitalization;

  const _InputField({
    required this.controller,
    required this.hint,
    required this.icon,
    this.keyboardType = TextInputType.text,
    this.validator,
    this.inputFormatters,
    this.textCapitalization = TextCapitalization.none,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      inputFormatters: inputFormatters,
      textCapitalization: textCapitalization,
      style: const TextStyle(
        color: _kTextDark,
        fontSize: 14.5,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: _kTextMuted.withOpacity(0.6), fontSize: 14),
        prefixIcon: Icon(icon, color: _kTextMuted, size: 20),
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _kBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _kBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _kPrimary, width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _kError, width: 1.2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _kError, width: 1.6),
        ),
      ),
    );
  }
}

// ─── Background blob ───────────────────────────────────────────────────────────
class _Blob extends StatelessWidget {
  final double size;
  final Color color;
  const _Blob(this.size, this.color);

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      );
}
