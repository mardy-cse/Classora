import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ─── Brand palette ────────────────────────────────────────────────────────────
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
class EditStudentScreen extends StatefulWidget {
  final String             docId;
  final Map<String, dynamic> initialData;

  const EditStudentScreen({
    super.key,
    required this.docId,
    required this.initialData,
  });

  @override
  State<EditStudentScreen> createState() => _EditStudentScreenState();
}

class _EditStudentScreenState extends State<EditStudentScreen>
    with SingleTickerProviderStateMixin {
  final _formKey        = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _fatherNameCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _schoolCtrl;
  late final TextEditingController _addressCtrl;

  bool    _saving       = false;
  String? _errorMessage;

  // Batch
  List<Map<String, dynamic>> _batches        = [];
  String?                    _selectedBatchId;
  bool                       _loadingBatches = true;

  late final AnimationController _anim;
  late final Animation<double>   _fade;
  late final Animation<Offset>   _slide;

  @override
  void initState() {
    super.initState();

    // Pre-fill from existing data
    _nameCtrl       = TextEditingController(text: widget.initialData['name']        as String? ?? '');
    _fatherNameCtrl = TextEditingController(text: widget.initialData['father_name'] as String? ?? '');
    _phoneCtrl      = TextEditingController(text: widget.initialData['phone']       as String? ?? '');
    _schoolCtrl     = TextEditingController(text: widget.initialData['school']      as String? ?? '');
    _addressCtrl    = TextEditingController(text: widget.initialData['address']     as String? ?? '');
    _selectedBatchId = widget.initialData['batch_id'] as String?;
    if (_selectedBatchId != null && _selectedBatchId!.isEmpty) {
      _selectedBatchId = null;
    }

    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    )..forward();
    _fade  = CurvedAnimation(parent: _anim, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.10),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _anim, curve: Curves.easeOutCubic));

    _loadBatches();
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

  // ── Load batches ──────────────────────────────────────────────────────────
  Future<void> _loadBatches() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    try {
      final snap = await FirebaseFirestore.instance
          .collection('batches')
          .where('teacher_id', isEqualTo: uid)
          .get()
          .timeout(const Duration(seconds: 15));
      if (!mounted) return;
      setState(() {
        _batches = snap.docs.map((d) => {'id': d.id, ...d.data()}).toList();
        _loadingBatches = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loadingBatches = false);
    }
  }

  // ── Validation ─────────────────────────────────────────────────────────────
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

  // ── Save ───────────────────────────────────────────────────────────────────
  Future<void> _saveChanges() async {
    FocusScope.of(context).unfocus();
    setState(() => _errorMessage = null);
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    try {
      await FirebaseFirestore.instance
          .collection('students')
          .doc(widget.docId)
          .update({
        'name':        _nameCtrl.text.trim(),
        'father_name': _fatherNameCtrl.text.trim(),
        'phone':       _phoneCtrl.text.trim(),
        'school':      _schoolCtrl.text.trim(),
        'address':     _addressCtrl.text.trim(),
        'batch_id':    _selectedBatchId ?? '',
        'updated_at':  FieldValue.serverTimestamp(),
      }).timeout(
        const Duration(seconds: 15),
        onTimeout: () => throw Exception('Request timed out.'),
      );

      if (!mounted) return;
      // Return updated data map to caller
      Navigator.of(context).pop({
        'name':        _nameCtrl.text.trim(),
        'father_name': _fatherNameCtrl.text.trim(),
        'phone':       _phoneCtrl.text.trim(),
        'school':      _schoolCtrl.text.trim(),
        'address':     _addressCtrl.text.trim(),
        'batch_id':    _selectedBatchId ?? '',
      });
    } on FirebaseException catch (e) {
      if (!mounted) return;
      setState(() => _errorMessage = '[${e.code}] ${e.message ?? 'Firebase error'}');
    } catch (e) {
      if (!mounted) return;
      setState(() => _errorMessage = e.toString());
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
            // Background blobs
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

                // ── Form ────────────────────────────────────────────────────
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
                              // ── Student information ──────────────────────
                              const _SectionLabel(label: 'Student Information'),
                              const SizedBox(height: 14),

                              const _FieldLabel(label: 'Full Name', required: true),
                              const SizedBox(height: 8),
                              _InputField(
                                controller: _nameCtrl,
                                hint: 'e.g. Rahim Hossain',
                                icon: Icons.person_outline_rounded,
                                validator: _validateName,
                                textCapitalization: TextCapitalization.words,
                              ),

                              const SizedBox(height: 18),

                              const _FieldLabel(label: "Father's Name"),
                              const SizedBox(height: 8),
                              _InputField(
                                controller: _fatherNameCtrl,
                                hint: 'e.g. Karim Hossain',
                                icon: Icons.people_outline_rounded,
                                textCapitalization: TextCapitalization.words,
                              ),

                              const SizedBox(height: 18),

                              const _FieldLabel(label: 'Phone Number', required: true),
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

                              const _FieldLabel(label: 'School Name'),
                              const SizedBox(height: 8),
                              _InputField(
                                controller: _schoolCtrl,
                                hint: 'e.g. XYZ High School',
                                icon: Icons.school_outlined,
                                textCapitalization: TextCapitalization.words,
                              ),

                              const SizedBox(height: 18),

                              const _FieldLabel(label: 'Address'),
                              const SizedBox(height: 8),
                              _InputField(
                                controller: _addressCtrl,
                                hint: 'e.g. Rajshahi',
                                icon: Icons.location_on_outlined,
                                textCapitalization: TextCapitalization.words,
                              ),

                              const SizedBox(height: 28),

                              // ── Batch assignment ─────────────────────────
                              const _SectionLabel(label: 'Batch Assignment'),
                              const SizedBox(height: 12),
                              _BatchDropdown(
                                batches: _batches,
                                loading: _loadingBatches,
                                selectedId: _selectedBatchId,
                                onChanged: (id) =>
                                    setState(() => _selectedBatchId = id),
                              ),

                              // ── Error ────────────────────────────────────
                              if (_errorMessage != null) ...[
                                const SizedBox(height: 20),
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
                                      const Icon(Icons.error_outline_rounded,
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
                                onTap: _saveChanges,
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
              'Edit Student',
              style: TextStyle(
                color: _kTextDark,
                fontSize: 20,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
              ),
            ),
          ),
          Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [_kPrimary, _kPurple],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: const Icon(Icons.edit_rounded, color: Colors.white, size: 18),
          ),
        ],
      ),
    );
  }
}

// ─── Save button ──────────────────────────────────────────────────────────────
class _SaveButton extends StatelessWidget {
  final bool         saving;
  final VoidCallback onTap;
  const _SaveButton({required this.saving, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
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
                        'Save Changes',
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

// ─── Section label ────────────────────────────────────────────────────────────
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

// ─── Field label ──────────────────────────────────────────────────────────────
class _FieldLabel extends StatelessWidget {
  final String label;
  final bool   required;
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
                style: TextStyle(
                    color: _kError, fontWeight: FontWeight.w700)),
          ],
        ],
      );
}

// ─── Input field ──────────────────────────────────────────────────────────────
class _InputField extends StatelessWidget {
  final TextEditingController       controller;
  final String                      hint;
  final IconData                    icon;
  final TextInputType               keyboardType;
  final String? Function(String?)?  validator;
  final List<TextInputFormatter>?   inputFormatters;
  final TextCapitalization          textCapitalization;

  const _InputField({
    required this.controller,
    required this.hint,
    required this.icon,
    this.keyboardType        = TextInputType.text,
    this.validator,
    this.inputFormatters,
    this.textCapitalization  = TextCapitalization.none,
  });

  @override
  Widget build(BuildContext context) => TextFormField(
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
          hintStyle: TextStyle(
              color: _kTextMuted.withOpacity(0.6), fontSize: 14),
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

// ─── Batch dropdown ───────────────────────────────────────────────────────────
class _BatchDropdown extends StatelessWidget {
  final List<Map<String, dynamic>> batches;
  final bool                       loading;
  final String?                    selectedId;
  final ValueChanged<String?>      onChanged;

  const _BatchDropdown({
    required this.batches,
    required this.loading,
    required this.selectedId,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return Container(
        height: 54,
        decoration: BoxDecoration(
          color: _kCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _kBorder),
        ),
        child: const Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
                strokeWidth: 2, color: _kPrimary),
          ),
        ),
      );
    }

    if (batches.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _kCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _kBorder),
        ),
        child: Row(
          children: [
            Icon(Icons.info_outline_rounded,
                color: _kTextMuted.withOpacity(0.6), size: 18),
            const SizedBox(width: 10),
            const Text(
              'No batches yet — create one first',
              style: TextStyle(color: _kTextMuted, fontSize: 13.5),
            ),
          ],
        ),
      );
    }

    // Ensure selectedId actually exists in loaded batches
    final validId = batches.any((b) => b['id'] == selectedId) ? selectedId : null;

    return Container(
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: validId != null ? _kPrimary : _kBorder,
          width: validId != null ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: validId,
          isExpanded: true,
          hint: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              'No batch assigned',
              style: TextStyle(color: _kTextMuted, fontSize: 14),
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          borderRadius: BorderRadius.circular(14),
          dropdownColor: Colors.white,
          icon: const Icon(Icons.keyboard_arrow_down_rounded,
              color: _kTextMuted),
          items: [
            const DropdownMenuItem<String>(
              value: null,
              child: Text(
                'No batch',
                style: TextStyle(color: _kTextMuted, fontSize: 14),
              ),
            ),
            ...batches.map(
              (b) => DropdownMenuItem<String>(
                value: b['id'] as String,
                child: Text(
                  b['name'] as String? ?? 'Unnamed',
                  style: const TextStyle(
                    color: _kTextDark,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
          onChanged: onChanged,
        ),
      ),
    );
  }
}

// ─── Background blob ──────────────────────────────────────────────────────────
class _Blob extends StatelessWidget {
  final double size;
  final Color  color;
  const _Blob(this.size, this.color);

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      );
}
