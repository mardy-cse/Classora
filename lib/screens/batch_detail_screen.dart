import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'attendance_history_screen.dart';
import 'attendance_screen.dart';
import 'edit_batch_screen.dart';

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

// ══════════════════════════════════════════════════════════════════════════════
class BatchDetailScreen extends StatefulWidget {
  final String docId;
  final Map<String, dynamic> initialData;

  const BatchDetailScreen({
    super.key,
    required this.docId,
    required this.initialData,
  });

  @override
  State<BatchDetailScreen> createState() => _BatchDetailScreenState();
}

class _BatchDetailScreenState extends State<BatchDetailScreen>
    with SingleTickerProviderStateMixin {
  late Map<String, dynamic> _data;

  late final AnimationController _anim;
  late final Animation<double>   _fade;
  late final Animation<Offset>   _slide;

  @override
  void initState() {
    super.initState();
    _data = Map.from(widget.initialData);

    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    )..forward();
    _fade  = CurvedAnimation(parent: _anim, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _anim, curve: Curves.easeOutCubic));
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  Color get _statusColor {
    return switch (_data['status'] as String? ?? 'Upcoming') {
      'Active'   => _kSuccess,
      'Inactive' => _kTextMuted,
      _          => _kWarning,
    };
  }

  // ── Edit batch ────────────────────────────────────────────────────────────
  Future<void> _editBatch() async {
    final updated = await Navigator.of(context).push<bool>(
      PageRouteBuilder(
        pageBuilder: (_, a, __) => EditBatchScreen(
          docId: widget.docId,
          initialData: _data,
        ),
        transitionsBuilder: (_, a, __, child) => SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 1),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: a, curve: Curves.easeOutCubic)),
          child: child,
        ),
        transitionDuration: const Duration(milliseconds: 380),
      ),
    );
    if (updated == true && mounted) {
      // Reload from Firestore to get updated data
      final doc = await FirebaseFirestore.instance
          .collection('batches')
          .doc(widget.docId)
          .get();
      if (doc.exists && mounted) {
        setState(() => _data = doc.data()!);
      }
    }
  }

  // ── Delete batch ───────────────────────────────────────────────────────────
  Future<void> _deleteBatch() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Batch',
            style: TextStyle(fontWeight: FontWeight.w700, color: _kTextDark)),
        content: const Text(
          'Are you sure you want to delete this batch? This action cannot be undone.',
          style: TextStyle(color: _kTextMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel',
                style: TextStyle(color: _kTextMuted)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete',
                style: TextStyle(color: _kError, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    try {
      await FirebaseFirestore.instance
          .collection('batches')
          .doc(widget.docId)
          .delete();
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to delete: $e'),
          backgroundColor: _kError,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final name       = _data['name'] as String? ?? '-';
    final batchCode  = _data['batch_code'] as String? ?? '-';
    final classLevel = _data['class_level'] as String? ?? '';
    final session    = _data['session'] as String? ?? '';
    final subject    = _data['subject'] as String? ?? '';
    final status     = _data['status'] as String? ?? 'Upcoming';
    final maxStudents= ((_data['max_students'] as num?)?.toInt() ?? 0);
    final days       = (_data['schedule_days'] as List?)?.cast<String>() ?? [];
    final classTime  = _data['class_time'] as String? ?? '';

    return Scaffold(
      backgroundColor: _kBg,
      body: FadeTransition(
        opacity: _fade,
        child: SlideTransition(
          position: _slide,
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // ── App Bar ───────────────────────────────────────────────────
              SliverAppBar(
                expandedHeight: 180,
                pinned: true,
                backgroundColor: _kPrimary,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded,
                      color: Colors.white, size: 20),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.edit_rounded,
                        color: Colors.white, size: 22),
                    onPressed: _editBatch,
                    tooltip: 'Edit Batch',
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded,
                        color: Colors.white, size: 22),
                    onPressed: _deleteBatch,
                    tooltip: 'Delete Batch',
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [_kPrimary, _kPurple],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 56, 20, 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            // Status badge
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                    color: Colors.white.withOpacity(0.4)),
                              ),
                              child: Text(
                                status,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.3,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              batchCode,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.75),
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // ── Body ─────────────────────────────────────────────────────
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // ── Batch Info Card ─────────────────────────────────
                    _SectionCard(
                      title: 'Batch Information',
                      icon: Icons.info_outline_rounded,
                      children: [
                        if (subject.isNotEmpty)
                          _DetailRow(
                            icon: Icons.menu_book_outlined,
                            label: 'Subject',
                            value: subject,
                          ),
                        if (classLevel.isNotEmpty)
                          _DetailRow(
                            icon: Icons.school_outlined,
                            label: 'Class Level',
                            value: classLevel,
                          ),
                        if (session.isNotEmpty)
                          _DetailRow(
                            icon: Icons.calendar_today_outlined,
                            label: 'Session',
                            value: session,
                          ),
                        if (maxStudents > 0)
                          _DetailRow(
                            icon: Icons.people_outlined,
                            label: 'Max Students',
                            value: '$maxStudents',
                          ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // ── Schedule Card ───────────────────────────────────
                    if (days.isNotEmpty || classTime.isNotEmpty)
                      _SectionCard(
                        title: 'Schedule',
                        icon: Icons.schedule_rounded,
                        children: [
                          if (days.isNotEmpty)
                            _DetailRow(
                              icon: Icons.date_range_outlined,
                              label: 'Days',
                              value: days.join(', '),
                            ),
                          if (classTime.isNotEmpty)
                            _DetailRow(
                              icon: Icons.access_time_outlined,
                              label: 'Time',
                              value: classTime,
                            ),
                        ],
                      ),

                    const SizedBox(height: 16),

                    // ── Enrolled Students ───────────────────────────────
                    _EnrolledStudentsSection(
                      batchId: widget.docId,
                      teacherId: FirebaseAuth.instance.currentUser!.uid,
                    ),

                    const SizedBox(height: 16),

                    // ── Take Attendance button ──────────────────────────
                    GestureDetector(
                      onTap: () => Navigator.of(context).push(
                        PageRouteBuilder(
                          pageBuilder: (_, a, __) => AttendanceScreen(
                            batchId: widget.docId,
                            batchName: _data['name'] as String? ?? '-',
                          ),
                          transitionsBuilder: (_, a, __, child) =>
                              SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(1, 0),
                              end: Offset.zero,
                            ).animate(CurvedAnimation(
                                parent: a, curve: Curves.easeOutCubic)),
                            child: child,
                          ),
                          transitionDuration:
                              const Duration(milliseconds: 380),
                        ),
                      ),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [_kPrimary, _kPurple],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: _kPrimary.withOpacity(0.3),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.fact_check_rounded,
                                color: Colors.white, size: 20),
                            SizedBox(width: 10),
                            Text(
                              'Take Attendance',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),

                    // ── View History button ─────────────────────────────
                    GestureDetector(
                      onTap: () => Navigator.of(context).push(
                        PageRouteBuilder(
                          pageBuilder: (_, a, __) => AttendanceHistoryScreen(
                            batchId: widget.docId,
                            batchName: _data['name'] as String? ?? '-',
                          ),
                          transitionsBuilder: (_, a, __, child) =>
                              SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(1, 0),
                              end: Offset.zero,
                            ).animate(CurvedAnimation(
                                parent: a, curve: Curves.easeOutCubic)),
                            child: child,
                          ),
                          transitionDuration:
                              const Duration(milliseconds: 380),
                        ),
                      ),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: _kCard,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: _kBorder, width: 1.5),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.history_rounded,
                                color: _kPrimary, size: 20),
                            const SizedBox(width: 10),
                            const Text(
                              'View Attendance History',
                              style: TextStyle(
                                color: _kPrimary,
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Section card ─────────────────────────────────────────────────────────────
class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) return const SizedBox.shrink();
    return Container(
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              children: [
                Icon(icon, size: 18, color: _kPrimary),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    color: _kTextDark,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const Divider(color: _kBorder, height: 1, indent: 16, endIndent: 16),
          ...children.map((child) => child),
        ],
      ),
    );
  }
}

// ─── Detail row ───────────────────────────────────────────────────────────────
class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 11, 16, 11),
      child: Row(
        children: [
          Icon(icon, size: 16, color: _kTextMuted),
          const SizedBox(width: 10),
          Text(
            label,
            style: const TextStyle(
              color: _kTextMuted,
              fontSize: 13,
            ),
          ),
          const Spacer(),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(
                color: _kTextDark,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Enrolled students section ────────────────────────────────────────────────
class _EnrolledStudentsSection extends StatelessWidget {
  final String batchId;
  final String teacherId;

  const _EnrolledStudentsSection({
    required this.batchId,
    required this.teacherId,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('students')
          .where('teacher_id', isEqualTo: teacherId)
          .where('batch_id', isEqualTo: batchId)
          .snapshots(),
      builder: (context, snap) {
        if (snap.hasError) {
          return _EnrolledError(message: snap.error.toString());
        }
        final students = snap.data?.docs ?? [];
        final count = students.length;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  const Icon(Icons.people_rounded, size: 18, color: _kPrimary),
                  const SizedBox(width: 8),
                  const Text(
                    'Enrolled Students',
                    style: TextStyle(
                      color: _kTextDark,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  if (snap.connectionState != ConnectionState.waiting)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: _kPrimary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '$count',
                        style: const TextStyle(
                          color: _kPrimary,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            if (snap.connectionState == ConnectionState.waiting)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(color: _kPrimary),
                ),
              )
            else if (students.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: _kCard,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Icon(Icons.person_off_outlined,
                        size: 40, color: _kTextMuted.withOpacity(0.4)),
                    const SizedBox(height: 10),
                    const Text(
                      'No students enrolled',
                      style: TextStyle(
                          color: _kTextMuted,
                          fontSize: 13.5,
                          fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: students.length,
                itemBuilder: (context, i) {
                  final s = students[i].data() as Map<String, dynamic>;
                  final sName    = s['name'] as String? ?? '-';
                  final phone    = s['phone'] as String? ?? '';
                  final isActive = (s['status'] as String? ?? '').toLowerCase() == 'active';
                  final initials = sName.trim().isNotEmpty
                      ? sName.trim()[0].toUpperCase()
                      : '?';

                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(
                      color: _kCard,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                      child: Row(
                        children: [
                          // Avatar
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [_kPrimary, _kPurple],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: Text(
                                initials,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
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
                                  sName,
                                  style: const TextStyle(
                                    color: _kTextDark,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                if (phone.isNotEmpty) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    phone,
                                    style: const TextStyle(
                                      color: _kTextMuted,
                                      fontSize: 12.5,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Status icon
                          Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              color: (isActive ? _kSuccess : _kTextMuted)
                                  .withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              isActive
                                  ? Icons.check_circle_rounded
                                  : Icons.pause_circle_rounded,
                              color: isActive ? _kSuccess : _kTextMuted,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Call button
                          if (phone.isNotEmpty)
                            GestureDetector(
                              onTap: () async {
                                final digits = phone.replaceAll(
                                    RegExp(r'[^\d+]'), '');
                                final uri = Uri.parse('tel:$digits');
                                if (await canLaunchUrl(uri)) {
                                  await launchUrl(uri);
                                }
                              },
                              child: Container(
                                width: 34,
                                height: 34,
                                decoration: BoxDecoration(
                                  color: _kPrimary.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  Icons.phone_rounded,
                                  color: _kPrimary,
                                  size: 17,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
          ],
        );
      },
    );
  }
}

// ─── Enrolled error widget ────────────────────────────────────────────────────
class _EnrolledError extends StatelessWidget {
  final String message;
  const _EnrolledError({required this.message});

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _kError.withOpacity(0.07),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _kError.withOpacity(0.2)),
        ),
        child: Text(
          'Error loading students: $message',
          style: const TextStyle(color: _kError, fontSize: 12.5),
        ),
      );
}
