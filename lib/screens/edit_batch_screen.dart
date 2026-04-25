import 'package:cloud_firestore/cloud_firestore.dart';
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
class EditBatchScreen extends StatefulWidget {
  final String docId;
  final Map<String, dynamic> initialData;

  const EditBatchScreen({
    super.key,
    required this.docId,
    required this.initialData,
  });

  @override
  State<EditBatchScreen> createState() => _EditBatchScreenState();
}

class _EditBatchScreenState extends State<EditBatchScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _batchNameCtrl;
  late final TextEditingController _sessionCtrl;
  late final TextEditingController _maxStudentsCtrl;
  late final TextEditingController _descriptionCtrl;
  late final TextEditingController _classTimeCtrl;

  String? _selectedClass;
  String? _selectedSubject;
  String  _status = 'Upcoming';
  DateTime? _startDate;
  DateTime? _endDate;
  final Set<String> _selectedDays = {};

  bool    _saving       = false;
  String? _errorMessage;

  late final AnimationController _anim;
  late final Animation<double>   _fade;
  late final Animation<Offset>   _slide;

  @override
  void initState() {
    super.initState();
    final d = widget.initialData;

    _batchNameCtrl    = TextEditingController(text: d['name']        as String? ?? '');
    _sessionCtrl      = TextEditingController(text: d['session']     as String? ?? '');
    _maxStudentsCtrl  = TextEditingController(
        text: (d['max_students'] as num?)?.toInt().toString() ?? '30');
    _descriptionCtrl  = TextEditingController(text: d['description'] as String? ?? '');
    _classTimeCtrl    = TextEditingController(text: d['class_time']  as String? ?? '');

    _selectedClass    = _kClassOptions.contains(d['class_level'])   ? d['class_level']  as String? : null;
    _selectedSubject  = _kSubjectOptions.contains(d['subject'])     ? d['subject']      as String? : null;
    _status           = _kStatusOptions.contains(d['status'])       ? d['status']       as String  : 'Upcoming';

    final startTs = d['start_date'] as Timestamp?;
    final endTs   = d['end_date']   as Timestamp?;
    _startDate = startTs?.toDate();
    _endDate   = endTs?.toDate();

    final days = (d['schedule_days'] as List?)?.cast<String>() ?? [];
    _selectedDays.addAll(days);

    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    )..forward();
    _fade  = CurvedAnimation(parent: _anim, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.08),
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
    setState(() => isStart ? _startDate = picked : _endDate = picked);
  }

  String? _validateRequired(String? v, String field) {
    if (v == null || v.trim().isEmpty) return '$field is required';
    return null;
  }

  String? _validateMaxStudents(String? v) {
    if (v == null || v.trim().isEmpty) return null;
    final n = int.tryParse(v.trim());
    if (n == null || n < 1) return 'Enter a valid number';
    if (n > 1000) return 'Max limit is 1000';
    return null;
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    setState(() => _errorMessage = null);
    if (!_formKey.currentState!.validate()) return;
    if (_selectedClass == null) {
      setState(() => _errorMessage = 'Please select a Class / Level');
      return;
    }

    setState(() => _saving = true);
    try {
      await FirebaseFirestore.instance
          .collection('batches')
          .doc(widget.docId)
          .update({
        'name':          _batchNameCtrl.text.trim(),
        'class_level':   _selectedClass,
        'session':       _sessionCtrl.text.trim(),
        'subject':       _selectedSubject ?? '',
        'status':        _status,
        'start_date':    _startDate != null ? Timestamp.fromDate(_startDate!) : null,
        'end_date':      _endDate   != null ? Timestamp.fromDate(_endDate!)   : null,
        'max_students':  int.tryParse(_maxStudentsCtrl.text.trim()) ?? 30,
        'description':   _descriptionCtrl.text.trim(),
        'schedule_days': _selectedDays.toList(),
        'class_time':    _classTimeCtrl.text.trim(),
        'updated_at':    FieldValue.serverTimestamp(),
      }).timeout(const Duration(seconds: 15));

      if (!mounted) return;
      Navigator.of(context).pop(true);
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
        body: Column(
          children: [
            // ── App Bar ────────────────────────────────────────────────────
            Container(
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
                      'Edit Batch',
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
                    child: const Icon(Icons.edit_rounded,
                        color: Colors.white, size: 18),
                  ),
                ],
              ),
            ),

            // ── Form ───────────────────────────────────────────────────────
            Expanded(
              child: FadeTransition(
                opacity: _fade,
                child: SlideTransition(
                  position: _slide,
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: EdgeInsets.fromLTRB(24, 8, 24, safeBottom + 32),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Batch code (read-only display)
                          _BatchCodeBadge(
                              code: widget.initialData['batch_code']
                                      as String? ?? '—'),
                          const SizedBox(height: 24),

                          // ── Basic Info ─────────────────────────────────
                          _SectionLabel(label: 'Basic Information'),
                          const SizedBox(height: 14),

                          _FieldLabel(label: 'Batch Name', required: true),
                          const SizedBox(height: 8),
                          _InputField(
                            controller: _batchNameCtrl,
                            hint: 'e.g. SSC 2026 Science',
                            icon: Icons.class_rounded,
                            textCapitalization: TextCapitalization.words,
                            validator: (v) => _validateRequired(v, 'Batch name'),
                          ),
                          const SizedBox(height: 18),

                          _FieldLabel(label: 'Class / Level', required: true),
                          const SizedBox(height: 8),
                          _DropdownField<String>(
                            value: _selectedClass,
                            hint: 'Select class or level',
                            icon: Icons.school_rounded,
                            items: _kClassOptions,
                            onChanged: (v) => setState(() => _selectedClass = v),
                          ),
                          const SizedBox(height: 18),

                          _FieldLabel(label: 'Session / Year', required: true),
                          const SizedBox(height: 8),
                          _InputField(
                            controller: _sessionCtrl,
                            hint: 'e.g. 2026 or 2025–2026',
                            icon: Icons.calendar_today_rounded,
                            validator: (v) => _validateRequired(v, 'Session'),
                          ),
                          const SizedBox(height: 24),

                          // ── Academic Info ──────────────────────────────
                          _SectionLabel(label: 'Academic Info'),
                          const SizedBox(height: 14),

                          _FieldLabel(label: 'Subject / Group'),
                          const SizedBox(height: 8),
                          _DropdownField<String>(
                            value: _selectedSubject,
                            hint: 'Select subject (optional)',
                            icon: Icons.menu_book_rounded,
                            items: _kSubjectOptions,
                            onChanged: (v) =>
                                setState(() => _selectedSubject = v),
                          ),
                          const SizedBox(height: 24),

                          // ── Management ─────────────────────────────────
                          _SectionLabel(label: 'Management'),
                          const SizedBox(height: 14),

                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _FieldLabel(label: 'Start Date'),
                                    const SizedBox(height: 8),
                                    _DatePickerField(
                                      date: _startDate,
                                      hint: 'Pick date',
                                      onTap: () => _pickDate(isStart: true),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _FieldLabel(label: 'End Date'),
                                    const SizedBox(height: 8),
                                    _DatePickerField(
                                      date: _endDate,
                                      hint: 'Optional',
                                      onTap: () => _pickDate(isStart: false),
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
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _FieldLabel(label: 'Max Students'),
                                    const SizedBox(height: 8),
                                    _InputField(
                                      controller: _maxStudentsCtrl,
                                      hint: '30',
                                      icon: Icons.people_rounded,
                                      keyboardType: TextInputType.number,
                                      inputFormatters: [
                                        FilteringTextInputFormatter.digitsOnly,
                                      ],
                                      validator: _validateMaxStudents,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
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

                          // ── Advanced ───────────────────────────────────
                          _SectionLabel(label: 'Advanced'),
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

                          if (_errorMessage != null) ...[
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: _kError.withOpacity(0.07),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                    color: _kError.withOpacity(0.25)),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.error_outline_rounded,
                                      color: _kError, size: 18),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      _errorMessage!,
                                      style: const TextStyle(
                                          color: _kError, fontSize: 13),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],

                          const SizedBox(height: 32),

                          // ── Save button ────────────────────────────────
                          GestureDetector(
                            onTap: _saving ? null : _save,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: double.infinity,
                              height: 54,
                              decoration: BoxDecoration(
                                gradient: _saving
                                    ? null
                                    : const LinearGradient(
                                        colors: [_kPrimary, _kAccent],
                                        begin: Alignment.centerLeft,
                                        end: Alignment.centerRight,
                                      ),
                                color: _saving ? _kBorder : null,
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: _saving
                                    ? []
                                    : [
                                        BoxShadow(
                                          color: _kPrimary.withOpacity(0.30),
                                          blurRadius: 14,
                                          offset: const Offset(0, 5),
                                        ),
                                      ],
                              ),
                              child: Center(
                                child: _saving
                                    ? const SizedBox(
                                        width: 22,
                                        height: 22,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.5,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                  _kPrimary),
                                        ),
                                      )
                                    : const Text(
                                        'Save Changes',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 15.5,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: 0.3,
                                        ),
                                      ),
                              ),
                            ),
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
      ),
    );
  }
}

// ─── Batch code badge (read-only) ─────────────────────────────────────────────
class _BatchCodeBadge extends StatelessWidget {
  final String code;
  const _BatchCodeBadge({required this.code});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
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
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Batch Code',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.75),
                  fontSize: 11.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 3),
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
        ],
      ),
    );
  }
}

// ─── Shared form widgets ──────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        color: _kTextDark,
        fontSize: 14,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.2,
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String label;
  final bool required;
  const _FieldLabel({required this.label, this.required = false});

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        text: label,
        style: const TextStyle(
          color: _kTextMuted,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
        children: required
            ? [
                const TextSpan(
                  text: ' *',
                  style: TextStyle(color: _kError),
                )
              ]
            : [],
      ),
    );
  }
}

class _InputField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final TextCapitalization textCapitalization;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final String? Function(String?)? validator;
  final int maxLines;

  const _InputField({
    required this.controller,
    required this.hint,
    required this.icon,
    this.textCapitalization = TextCapitalization.none,
    this.keyboardType,
    this.inputFormatters,
    this.validator,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      textCapitalization: textCapitalization,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: validator,
      maxLines: maxLines,
      style: const TextStyle(
        color: _kTextDark,
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          color: _kTextMuted.withOpacity(0.55),
          fontSize: 13.5,
        ),
        prefixIcon: Icon(icon, color: _kTextMuted, size: 19),
        filled: true,
        fillColor: _kCard,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
          borderSide: const BorderSide(color: _kPrimary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _kError),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _kError, width: 1.5),
        ),
      ),
    );
  }
}

class _DropdownField<T> extends StatelessWidget {
  final T? value;
  final String hint;
  final IconData icon;
  final List<T> items;
  final ValueChanged<T?> onChanged;

  const _DropdownField({
    required this.value,
    required this.hint,
    required this.icon,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      value: value,
      hint: Text(hint,
          style: TextStyle(
              color: _kTextMuted.withOpacity(0.55), fontSize: 13.5)),
      icon: const Icon(Icons.keyboard_arrow_down_rounded, color: _kTextMuted),
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: _kTextMuted, size: 19),
        filled: true,
        fillColor: _kCard,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
          borderSide: const BorderSide(color: _kPrimary, width: 1.5),
        ),
      ),
      items: items
          .map((e) => DropdownMenuItem<T>(
                value: e,
                child: Text('$e',
                    style: const TextStyle(
                        color: _kTextDark,
                        fontSize: 14,
                        fontWeight: FontWeight.w500)),
              ))
          .toList(),
      onChanged: onChanged,
    );
  }
}

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
                color:
                    date == null ? _kTextMuted.withOpacity(0.6) : _kTextDark,
                fontSize: 13.5,
                fontWeight:
                    date == null ? FontWeight.w400 : FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

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
