import 'dart:math';

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

// ─── Options ──────────────────────────────────────────────────────────────────
const _kClassOptions = [
  'Class 6', 'Class 7', 'Class 8', 'Class 9', 'Class 10',
  'SSC', 'HSC', 'Degree', 'Masters', 'Other',
];

const _kSubjectOptions = [
  'Science', 'Commerce', 'Arts / Humanities',
  'Mathematics', 'English', 'Bangla', 'Physics',
  'Chemistry', 'Biology', 'ICT', 'General',
];

const _kStatusOptions = ['Upcoming', 'Active', 'Inactive'];

const _kDayOptions = ['Sat', 'Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri'];

// ══════════════════════════════════════════════════════════════════════════════
class CreateBatchScreen extends StatefulWidget {
  const CreateBatchScreen({super.key});

  @override
  State<CreateBatchScreen> createState() => _CreateBatchScreenState();
}

class _CreateBatchScreenState extends State<CreateBatchScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  // Required
  final _batchNameCtrl = TextEditingController();
  String? _selectedClass;
  final _sessionCtrl = TextEditingController();

  // Optional academic
  String? _selectedSubject;

  // System generated
  late String _batchCode;

  // Management
  DateTime? _startDate;
  DateTime? _endDate;
  final _maxStudentsCtrl = TextEditingController(text: '30');
  String _status = 'Upcoming';

  // Advanced
  final _descriptionCtrl = TextEditingController();
  final Set<String> _selectedDays = {};
  final _classTimeCtrl = TextEditingController();

  bool    _saving       = false;
  String? _errorMessage;

  late final AnimationController _anim;
  late final Animation<double>   _fade;
  late final Animation<Offset>   _slide;

  @override
  void initState() {
    super.initState();
    _batchCode = _generateBatchCode();

    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 480),
    )..forward();
    _fade  = CurvedAnimation(parent: _anim, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.10),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _anim, curve: Curves.easeOutCubic));
  }

  @override
  void dispose() {
    _batchNameCtrl.dispose();
    _sessionCtrl.dispose();
    _maxStudentsCtrl.dispose();
    _descriptionCtrl.dispose();
    _classTimeCtrl.dispose();
    _anim.dispose();
    super.dispose();
  }

  // ── Batch code generator ─────────────────────────────────────────────────
  String _generateBatchCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final rng = Random();
    final suffix =
        List.generate(5, (_) => chars[rng.nextInt(chars.length)]).join();
    return 'BCH-$suffix';
  }

  // ── Date picker ───────────────────────────────────────────────────────────
  Future<void> _pickDate({required bool isStart}) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart ? (_startDate ?? now) : (_endDate ?? now),
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: _kPrimary),
        ),
        child: child!,
      ),
    );
    if (picked == null) return;
    setState(() {
      if (isStart) {
        _startDate = picked;
      } else {
        _endDate = picked;
      }
    });
  }

  // ── Validation ────────────────────────────────────────────────────────────
  String? _validateRequired(String? v, String field) {
    if (v == null || v.trim().isEmpty) return '$field is required';
    return null;
  }

  String? _validateMaxStudents(String? v) {
    if (v == null || v.trim().isEmpty) return null;
    final n = int.tryParse(v.trim());
    if (n == null || n < 1) return 'Enter a valid number';
    if (n > 1000) return 'Max limit is 1000 students';
    return null;
  }

  // ── Save to Firestore ─────────────────────────────────────────────────────
  Future<void> _saveBatch() async {
    FocusScope.of(context).unfocus();
    setState(() => _errorMessage = null);
    if (!_formKey.currentState!.validate()) return;
    if (_selectedClass == null) {
      setState(() => _errorMessage = 'Please select a Class / Level');
      return;
    }

    setState(() => _saving = true);
    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;

      await FirebaseFirestore.instance.collection('batches').add({
        // Required
        'name':         _batchNameCtrl.text.trim(),
        'class_level':  _selectedClass,
        'session':      _sessionCtrl.text.trim(),
        // Optional academic
        'subject':      _selectedSubject ?? '',
        // System
        'batch_code':   _batchCode,
        'teacher_id':   uid,
        'status':       _status,
        'created_at':   FieldValue.serverTimestamp(),
        // Management
        'start_date':   _startDate != null
            ? Timestamp.fromDate(_startDate!)
            : null,
        'end_date':     _endDate != null
            ? Timestamp.fromDate(_endDate!)
            : null,
        'max_students': int.tryParse(_maxStudentsCtrl.text.trim()) ?? 30,
        // Advanced
        'description':  _descriptionCtrl.text.trim(),
        'schedule_days': _selectedDays.toList(),
        'class_time':   _classTimeCtrl.text.trim(),
      }).timeout(
        const Duration(seconds: 15),
        onTimeout: () => throw Exception('Request timed out. Check your internet connection.'),
      );

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on FirebaseException catch (e) {
      if (!mounted) return;
      setState(() => _errorMessage = '[${e.code}] ${e.message ?? 'Firebase error'}');
    } on PlatformException catch (e) {
      if (!mounted) return;
      setState(() => _errorMessage = '[Platform] ${e.message ?? e.code}');
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
            Positioned(
              top: -80, right: -60,
              child: _Blob(220, _kPurple.withOpacity(0.06)),
            ),
            Positioned(
              bottom: -100, left: -50,
              child: _Blob(260, _kPrimary.withOpacity(0.05)),
            ),
            Column(
              children: [
                _buildAppBar(safeTop),
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
                              // ── Batch Code Preview ───────────────────────
                              _BatchCodeCard(
                                code: _batchCode,
                                onRegenerate: () =>
                                    setState(() => _batchCode = _generateBatchCode()),
                              ),

                              const SizedBox(height: 24),

                              // ── Basic Info ───────────────────────────────
                              _SectionLabel(label: 'Basic Information'),
                              const SizedBox(height: 14),

                              _FieldLabel(label: 'Batch Name', required: true),
                              const SizedBox(height: 8),
                              _InputField(
                                controller: _batchNameCtrl,
                                hint: 'e.g. SSC 2026 Science / Class 10 Morning',
                                icon: Icons.class_rounded,
                                textCapitalization: TextCapitalization.words,
                                validator: (v) =>
                                    _validateRequired(v, 'Batch name'),
                              ),

                              const SizedBox(height: 18),

                              _FieldLabel(label: 'Class / Level', required: true),
                              const SizedBox(height: 8),
                              _DropdownField<String>(
                                value: _selectedClass,
                                hint: 'Select class or level',
                                icon: Icons.school_rounded,
                                items: _kClassOptions,
                                onChanged: (v) =>
                                    setState(() => _selectedClass = v),
                              ),

                              const SizedBox(height: 18),

                              _FieldLabel(label: 'Session / Year', required: true),
                              const SizedBox(height: 8),
                              _InputField(
                                controller: _sessionCtrl,
                                hint: 'e.g. 2026 or 2025–2026',
                                icon: Icons.calendar_today_rounded,
                                keyboardType: TextInputType.text,
                                validator: (v) =>
                                    _validateRequired(v, 'Session'),
                              ),

                              const SizedBox(height: 24),

                              // ── Academic Info ────────────────────────────
                              _SectionLabel(label: 'Academic Info'),
                              const SizedBox(height: 14),

                              _FieldLabel(label: 'Subject / Group'),
                              const SizedBox(height: 8),
                              _DropdownField<String>(
                                value: _selectedSubject,
                                hint: 'Select subject or group (optional)',
                                icon: Icons.menu_book_rounded,
                                items: _kSubjectOptions,
                                onChanged: (v) =>
                                    setState(() => _selectedSubject = v),
                              ),

                              const SizedBox(height: 24),

                              // ── Management ───────────────────────────────
                              _SectionLabel(label: 'Management'),
                              const SizedBox(height: 14),

                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        _FieldLabel(label: 'Start Date'),
                                        const SizedBox(height: 8),
                                        _DatePickerField(
                                          date: _startDate,
                                          hint: 'Pick date',
                                          onTap: () =>
                                              _pickDate(isStart: true),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        _FieldLabel(label: 'End Date'),
                                        const SizedBox(height: 8),
                                        _DatePickerField(
                                          date: _endDate,
                                          hint: 'Optional',
                                          onTap: () =>
                                              _pickDate(isStart: false),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 18),

                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        _FieldLabel(label: 'Max Students'),
                                        const SizedBox(height: 8),
                                        _InputField(
                                          controller: _maxStudentsCtrl,
                                          hint: '30',
                                          icon: Icons.people_rounded,
                                          keyboardType: TextInputType.number,
                                          inputFormatters: [
                                            FilteringTextInputFormatter
                                                .digitsOnly
                                          ],
                                          validator: _validateMaxStudents,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        _FieldLabel(label: 'Status'),
                                        const SizedBox(height: 8),
                                        _DropdownField<String>(
                                          value: _status,
                                          hint: 'Status',
                                          icon: Icons.toggle_on_rounded,
                                          items: _kStatusOptions,
                                          onChanged: (v) => setState(
                                              () => _status = v ?? 'Upcoming'),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 24),

                              // ── Advanced ─────────────────────────────────
                              _SectionLabel(label: 'Advanced (Optional)'),
                              const SizedBox(height: 14),

                              _FieldLabel(label: 'Batch Description'),
                              const SizedBox(height: 8),
                              _InputField(
                                controller: _descriptionCtrl,
                                hint: 'Short info about this batch...',
                                icon: Icons.notes_rounded,
                                maxLines: 3,
                                textCapitalization: TextCapitalization.sentences,
                              ),

                              const SizedBox(height: 18),

                              _FieldLabel(label: 'Class Schedule / Days'),
                              const SizedBox(height: 10),
                              _DaySelector(
                                selectedDays: _selectedDays,
                                onToggle: (day) => setState(() {
                                  if (_selectedDays.contains(day)) {
                                    _selectedDays.remove(day);
                                  } else {
                                    _selectedDays.add(day);
                                  }
                                }),
                              ),

                              const SizedBox(height: 18),

                              _FieldLabel(label: 'Class Time'),
                              const SizedBox(height: 8),
                              _InputField(
                                controller: _classTimeCtrl,
                                hint: 'e.g. 8:00 AM – 10:00 AM',
                                icon: Icons.access_time_rounded,
                              ),

                              // ── Error ────────────────────────────────────
                              if (_errorMessage != null) ...[
                                const SizedBox(height: 16),
                                _ErrorBanner(message: _errorMessage!),
                              ],

                              const SizedBox(height: 32),

                              // ── Save button ──────────────────────────────
                              _SaveButton(
                                saving: _saving,
                                onTap: _saveBatch,
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
              'Create Batch',
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
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [_kPrimary, _kPurple],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: const Icon(Icons.group_add_rounded,
                color: Colors.white, size: 18),
          ),
        ],
      ),
    );
  }
}

// ─── Batch code preview card ──────────────────────────────────────────────────
class _BatchCodeCard extends StatelessWidget {
  final String code;
  final VoidCallback onRegenerate;
  const _BatchCodeCard({required this.code, required this.onRegenerate});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2563EB), Color(0xFF7C3AED)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2563EB).withOpacity(0.30),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.qr_code_rounded,
                color: Colors.white, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Batch Code (Auto-Generated)',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.75),
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  code,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: onRegenerate,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.18),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.refresh_rounded,
                  color: Colors.white, size: 18),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Day selector ──────────────────────────────────────────────────────────────
class _DaySelector extends StatelessWidget {
  final Set<String> selectedDays;
  final void Function(String) onToggle;
  const _DaySelector({required this.selectedDays, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _kDayOptions.map((day) {
        final selected = selectedDays.contains(day);
        return GestureDetector(
          onTap: () => onToggle(day),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: selected ? _kPrimary : _kCard,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: selected ? _kPrimary : _kBorder,
                width: selected ? 1.5 : 1.0,
              ),
              boxShadow: selected
                  ? [
                      BoxShadow(
                        color: _kPrimary.withOpacity(0.25),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      )
                    ]
                  : [],
            ),
            child: Text(
              day,
              style: TextStyle(
                color: selected ? Colors.white : _kTextMuted,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ─── Date picker field ────────────────────────────────────────────────────────
class _DatePickerField extends StatelessWidget {
  final DateTime? date;
  final String hint;
  final VoidCallback onTap;
  const _DatePickerField(
      {required this.date, required this.hint, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final label = date == null
        ? hint
        : '${date!.day.toString().padLeft(2, '0')}/'
            '${date!.month.toString().padLeft(2, '0')}/'
            '${date!.year}';
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: _kCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _kBorder),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_month_rounded,
                color: _kTextMuted, size: 18),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: date == null ? _kTextMuted.withOpacity(0.6) : _kTextDark,
                fontSize: 13.5,
                fontWeight: date == null ? FontWeight.w400 : FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Dropdown field ────────────────────────────────────────────────────────────
class _DropdownField<T> extends StatelessWidget {
  final T? value;
  final String hint;
  final IconData icon;
  final List<T> items;
  final void Function(T?) onChanged;
  const _DropdownField({
    required this.value,
    required this.hint,
    required this.icon,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _kBorder),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isExpanded: true,
          hint: Row(
            children: [
              Icon(icon, color: _kTextMuted, size: 18),
              const SizedBox(width: 10),
              Text(
                hint,
                style: TextStyle(
                    color: _kTextMuted.withOpacity(0.6), fontSize: 14),
              ),
            ],
          ),
          icon: const Icon(Icons.keyboard_arrow_down_rounded,
              color: _kTextMuted, size: 20),
          style: const TextStyle(
              color: _kTextDark, fontSize: 14.5, fontWeight: FontWeight.w500),
          dropdownColor: Colors.white,
          borderRadius: BorderRadius.circular(12),
          items: items
              .map((item) => DropdownMenuItem<T>(
                    value: item,
                    child: Row(
                      children: [
                        Icon(icon, color: _kPrimary, size: 16),
                        const SizedBox(width: 10),
                        Text(
                          item.toString(),
                          style: const TextStyle(
                            color: _kTextDark,
                            fontSize: 14.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ))
              .toList(),
          onChanged: onChanged,
        ),
      ),
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
                  colors: [_kPrimary, _kPurple],
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
                      'Create Batch',
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

// ─── Error banner ─────────────────────────────────────────────────────────────
class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: _kError.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _kError.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: _kError, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: _kError,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
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
  final int maxLines;

  const _InputField({
    required this.controller,
    required this.hint,
    required this.icon,
    this.keyboardType = TextInputType.text,
    this.validator,
    this.inputFormatters,
    this.textCapitalization = TextCapitalization.none,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      inputFormatters: inputFormatters,
      textCapitalization: textCapitalization,
      maxLines: maxLines,
      style: const TextStyle(
        color: _kTextDark,
        fontSize: 14.5,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle:
            TextStyle(color: _kTextMuted.withOpacity(0.6), fontSize: 14),
        prefixIcon: maxLines == 1
            ? Icon(icon, color: _kTextMuted, size: 20)
            : Padding(
                padding: const EdgeInsets.only(left: 14, top: 14, right: 10),
                child: Icon(icon, color: _kTextMuted, size: 20),
              ),
        prefixIconConstraints: maxLines > 1
            ? const BoxConstraints(minWidth: 0, minHeight: 0)
            : null,
        alignLabelWithHint: maxLines > 1,
        filled: true,
        fillColor: Colors.white,
        contentPadding: EdgeInsets.symmetric(
          horizontal: 16,
          vertical: maxLines > 1 ? 14 : 15,
        ),
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
