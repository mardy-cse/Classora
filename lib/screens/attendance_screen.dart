import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// ─── Brand palette ────────────────────────────────────────────────────────────
const _kPrimary   = Color(0xFF2563EB);
const _kPurple    = Color(0xFF7C3AED);
const _kBg        = Color(0xFFF1F5FB);
const _kCard      = Colors.white;
const _kTextDark  = Color(0xFF0F172A);
const _kTextMuted = Color(0xFF64748B);
const _kBorder    = Color(0xFFE2E8F0);
const _kSuccess   = Color(0xFF10B981);
const _kWarning   = Color(0xFFF59E0B);
const _kError     = Color(0xFFEF4444);

// ─── Status constants ─────────────────────────────────────────────────────────
enum AttStatus { present, absent, late }

extension AttStatusExt on AttStatus {
  String get label => switch (this) {
        AttStatus.present => 'Present',
        AttStatus.absent  => 'Absent',
        AttStatus.late    => 'Late',
      };

  String get value => switch (this) {
        AttStatus.present => 'present',
        AttStatus.absent  => 'absent',
        AttStatus.late    => 'late',
      };

  Color get color => switch (this) {
        AttStatus.present => _kSuccess,
        AttStatus.absent  => _kError,
        AttStatus.late    => _kWarning,
      };

  IconData get icon => switch (this) {
        AttStatus.present => Icons.check_circle_rounded,
        AttStatus.absent  => Icons.cancel_rounded,
        AttStatus.late    => Icons.watch_later_rounded,
      };

  static AttStatus fromString(String? v) => switch (v) {
        'present' => AttStatus.present,
        'late'    => AttStatus.late,
        _         => AttStatus.absent,
      };
}

// ─── Firestore doc ID helper ──────────────────────────────────────────────────
String _docId(String batchId, DateTime date) =>
    '${batchId}_${DateFormat('yyyy-MM-dd').format(date)}';

// ══════════════════════════════════════════════════════════════════════════════
class AttendanceScreen extends StatefulWidget {
  final String batchId;
  final String batchName;
  final DateTime? initialDate;

  const AttendanceScreen({
    super.key,
    required this.batchId,
    required this.batchName,
    this.initialDate,
  });

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen>
    with SingleTickerProviderStateMixin {
  late DateTime _selectedDate;
  late final AnimationController _anim;
  late final Animation<double> _fade;

  // studentId → status
  final Map<String, AttStatus> _records = {};

  // studentId → name
  List<Map<String, String>> _students = [];

  bool _loadingStudents = true;
  bool _saving          = false;
  String? _errorMessage;

  final _uid = FirebaseAuth.instance.currentUser!.uid;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate ?? DateTime.now();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    )..forward();
    _fade = CurvedAnimation(parent: _anim, curve: Curves.easeOut);
    _loadStudents();
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  // ── Load enrolled students ────────────────────────────────────────────────
  Future<void> _loadStudents() async {
    setState(() { _loadingStudents = true; _errorMessage = null; });
    try {
      final snap = await FirebaseFirestore.instance
          .collection('students')
          .where('teacher_id', isEqualTo: _uid)
          .where('batch_id', isEqualTo: widget.batchId)
          .get();
      final students = snap.docs
          .map((d) => {
                'id': d.id,
                'name': (d.data()['name'] as String? ?? '-'),
                'phone': (d.data()['phone'] as String? ?? ''),
              })
          .toList()
        ..sort((a, b) => a['name']!.compareTo(b['name']!));
      if (!mounted) return;
      setState(() {
        _students = students;
        _loadingStudents = false;
      });
      await _loadAttendanceForDate();
    } catch (e) {
      if (!mounted) return;
      setState(() { _errorMessage = e.toString(); _loadingStudents = false; });
    }
  }

  // ── Load saved attendance for selected date ───────────────────────────────
  Future<void> _loadAttendanceForDate() async {
    setState(() { _errorMessage = null; });
    try {
      final doc = await FirebaseFirestore.instance
          .collection('attendance')
          .doc(_docId(widget.batchId, _selectedDate))
          .get();

      final saved = <String, AttStatus>{};
      if (doc.exists) {
        final recs = (doc.data()?['records'] as Map?)?.cast<String, String>() ?? {};
        for (final e in recs.entries) {
          saved[e.key] = AttStatusExt.fromString(e.value);
        }
      }

      // Default unrecorded students to absent
      final merged = <String, AttStatus>{};
      for (final s in _students) {
        merged[s['id']!] = saved[s['id']!] ?? AttStatus.absent;
      }

      if (!mounted) return;
      setState(() => _records
        ..clear()
        ..addAll(merged));
    } catch (e) {
      if (!mounted) return;
      setState(() => _errorMessage = e.toString());
    }
  }

  // ── Pick date ─────────────────────────────────────────────────────────────
  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: _kPrimary,
            onPrimary: Colors.white,
            surface: Colors.white,
            onSurface: _kTextDark,
          ),
        ),
        child: child!,
      ),
    );
    if (picked == null || !mounted) return;
    setState(() => _selectedDate = picked);
    await _loadAttendanceForDate();
  }

  // ── Mark all ─────────────────────────────────────────────────────────────
  void _markAll(AttStatus status) {
    setState(() {
      for (final id in _records.keys) {
        _records[id] = status;
      }
    });
  }

  // ── Save attendance ───────────────────────────────────────────────────────
  Future<void> _saveAttendance() async {
    if (_students.isEmpty) return;
    setState(() { _saving = true; _errorMessage = null; });
    try {
      final recordsMap = <String, String>{};
      for (final e in _records.entries) {
        recordsMap[e.key] = e.value.value;
      }
      await FirebaseFirestore.instance
          .collection('attendance')
          .doc(_docId(widget.batchId, _selectedDate))
          .set({
        'batch_id':   widget.batchId,
        'teacher_id': _uid,
        'date':       Timestamp.fromDate(
            DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day)),
        'records':    recordsMap,
        'updated_at': FieldValue.serverTimestamp(),
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
            const SizedBox(width: 10),
            Text(
              'Attendance saved for ${DateFormat('d MMM yyyy').format(_selectedDate)}',
            ),
          ]),
          backgroundColor: _kSuccess,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _errorMessage = e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  // ── Summary counts ────────────────────────────────────────────────────────
  int get _presentCount =>
      _records.values.where((s) => s == AttStatus.present).length;
  int get _absentCount =>
      _records.values.where((s) => s == AttStatus.absent).length;
  int get _lateCount =>
      _records.values.where((s) => s == AttStatus.late).length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: FadeTransition(
        opacity: _fade,
        child: Column(
          children: [
            // ── Header ──────────────────────────────────────────────────────
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [_kPrimary, _kPurple],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: Column(
                  children: [
                    // Top row
                    Padding(
                      padding: const EdgeInsets.fromLTRB(4, 8, 16, 0),
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back_ios_new_rounded,
                                color: Colors.white, size: 20),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Attendance',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.2,
                                  ),
                                ),
                                Text(
                                  widget.batchName,
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.75),
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Save button
                          if (!_loadingStudents && _students.isNotEmpty)
                            _saving
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                        color: Colors.white, strokeWidth: 2.5),
                                  )
                                : GestureDetector(
                                    onTap: _saveAttendance,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 14, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                            color:
                                                Colors.white.withOpacity(0.4)),
                                      ),
                                      child: const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.save_rounded,
                                              color: Colors.white, size: 16),
                                          SizedBox(width: 6),
                                          Text('Save',
                                              style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w700)),
                                        ],
                                      ),
                                    ),
                                  ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Date picker row
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: GestureDetector(
                        onTap: _pickDate,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 11),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: Colors.white.withOpacity(0.3)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.calendar_month_rounded,
                                  color: Colors.white, size: 18),
                              const SizedBox(width: 10),
                              Text(
                                DateFormat('EEEE, d MMMM yyyy')
                                    .format(_selectedDate),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const Spacer(),
                              const Icon(Icons.keyboard_arrow_down_rounded,
                                  color: Colors.white, size: 20),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Summary bar ─────────────────────────────────────────────────
            if (!_loadingStudents && _students.isNotEmpty)
              Container(
                color: _kCard,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Row(
                  children: [
                    _SummaryChip(
                        label: 'Present',
                        count: _presentCount,
                        color: _kSuccess),
                    const SizedBox(width: 10),
                    _SummaryChip(
                        label: 'Absent',
                        count: _absentCount,
                        color: _kError),
                    const SizedBox(width: 10),
                    _SummaryChip(
                        label: 'Late', count: _lateCount, color: _kWarning),
                    const Spacer(),
                    // Mark all buttons
                    _QuickMarkButton(
                      label: 'All P',
                      color: _kSuccess,
                      onTap: () => _markAll(AttStatus.present),
                    ),
                    const SizedBox(width: 6),
                    _QuickMarkButton(
                      label: 'All A',
                      color: _kError,
                      onTap: () => _markAll(AttStatus.absent),
                    ),
                  ],
                ),
              ),

            if (!_loadingStudents && _students.isNotEmpty)
              const Divider(color: _kBorder, height: 1),

            // ── Content ─────────────────────────────────────────────────────
            Expanded(
              child: _loadingStudents
                  ? const Center(
                      child: CircularProgressIndicator(color: _kPrimary))
                  : _errorMessage != null
                      ? _ErrorView(
                          message: _errorMessage!,
                          onRetry: _loadStudents,
                        )
                      : _students.isEmpty
                          ? const _EmptyView()
                          : ListView.builder(
                              physics: const BouncingScrollPhysics(),
                              padding: const EdgeInsets.fromLTRB(16, 14, 16, 100),
                              itemCount: _students.length,
                              itemBuilder: (_, i) {
                                final s = _students[i];
                                final id = s['id']!;
                                final status = _records[id] ?? AttStatus.absent;
                                return _StudentAttCard(
                                  name: s['name']!,
                                  phone: s['phone']!,
                                  status: status,
                                  onStatusChanged: (v) =>
                                      setState(() => _records[id] = v),
                                );
                              },
                            ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Student attendance card ──────────────────────────────────────────────────
class _StudentAttCard extends StatelessWidget {
  final String name;
  final String phone;
  final AttStatus status;
  final ValueChanged<AttStatus> onStatusChanged;

  const _StudentAttCard({
    required this.name,
    required this.phone,
    required this.status,
    required this.onStatusChanged,
  });

  @override
  Widget build(BuildContext context) {
    final initials = name.trim().isNotEmpty ? name.trim()[0].toUpperCase() : '?';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: status.color.withOpacity(0.25),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: status.color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  initials,
                  style: TextStyle(
                    color: status.color,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Name + phone
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      color: _kTextDark,
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (phone.isNotEmpty)
                    Text(
                      phone,
                      style: const TextStyle(
                        color: _kTextMuted,
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Status toggle buttons
            Row(
              mainAxisSize: MainAxisSize.min,
              children: AttStatus.values.map((s) {
                final selected = status == s;
                return Padding(
                  padding: const EdgeInsets.only(left: 6),
                  child: GestureDetector(
                    onTap: () => onStatusChanged(s),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: selected
                            ? s.color
                            : s.color.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: selected
                              ? s.color
                              : s.color.withOpacity(0.2),
                          width: 1.5,
                        ),
                      ),
                      child: Icon(
                        s.icon,
                        size: 18,
                        color: selected ? Colors.white : s.color,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Summary chip ─────────────────────────────────────────────────────────────
class _SummaryChip extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  const _SummaryChip(
      {required this.label, required this.count, required this.color});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                    color: color, shape: BoxShape.circle)),
            const SizedBox(width: 6),
            Text(
              '$count $label',
              style: TextStyle(
                  color: color, fontSize: 12, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      );
}

// ─── Quick mark button ────────────────────────────────────────────────────────
class _QuickMarkButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _QuickMarkButton(
      {required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Text(
            label,
            style: TextStyle(
                color: color, fontSize: 12, fontWeight: FontWeight.w700),
          ),
        ),
      );
}

// ─── Empty view ───────────────────────────────────────────────────────────────
class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.people_outline_rounded,
                size: 60, color: _kTextMuted.withOpacity(0.35)),
            const SizedBox(height: 14),
            const Text(
              'No students enrolled',
              style: TextStyle(
                  color: _kTextDark,
                  fontSize: 16,
                  fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            const Text(
              'Add students to this batch first',
              style: TextStyle(color: _kTextMuted, fontSize: 13.5),
            ),
          ],
        ),
      );
}

// ─── Error view ───────────────────────────────────────────────────────────────
class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded,
                  size: 48, color: _kError),
              const SizedBox(height: 12),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: _kTextMuted, fontSize: 13),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: onRetry,
                child: const Text('Retry',
                    style: TextStyle(
                        color: _kPrimary, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        ),
      );
}
