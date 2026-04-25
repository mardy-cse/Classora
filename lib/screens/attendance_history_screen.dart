import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'attendance_screen.dart';

// ─── Brand palette ────────────────────────────────────────────────────────────
const _kPrimary   = Color(0xFF2563EB);
const _kPurple    = Color(0xFF7C3AED);
const _kBg        = Color(0xFFF1F5FB);
const _kCard      = Colors.white;
const _kTextDark  = Color(0xFF0F172A);
const _kTextMuted = Color(0xFF64748B);
const _kBorder    = Color(0xFFE2E8F0);
const _kSuccess   = Color(0xFF10B981);
const _kError     = Color(0xFFEF4444);
const _kWarning   = Color(0xFFF59E0B);

// ══════════════════════════════════════════════════════════════════════════════
class AttendanceHistoryScreen extends StatefulWidget {
  final String batchId;
  final String batchName;

  const AttendanceHistoryScreen({
    super.key,
    required this.batchId,
    required this.batchName,
  });

  @override
  State<AttendanceHistoryScreen> createState() =>
      _AttendanceHistoryScreenState();
}

class _AttendanceHistoryScreenState extends State<AttendanceHistoryScreen>
    with SingleTickerProviderStateMixin {
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _records = [];
  bool _showTitle = false;

  final _uid = FirebaseAuth.instance.currentUser!.uid;

  late final AnimationController _anim;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    )..forward();
    _fade = CurvedAnimation(parent: _anim, curve: Curves.easeOut);
    _load();
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final snap = await FirebaseFirestore.instance
          .collection('attendance')
          .where('teacher_id', isEqualTo: _uid)
          .where('batch_id', isEqualTo: widget.batchId)
          .get();

      final list = snap.docs.map((d) {
        final data = d.data();
        final records = (data['records'] as Map?)?.cast<String, String>() ?? {};
        int present = 0, absent = 0, late = 0;
        for (final v in records.values) {
          if (v == 'present') present++;
          else if (v == 'late') late++;
          else absent++;
        }
        return {
          'docId': d.id,
          'date': data['date'] as Timestamp?,
          'present': present,
          'absent': absent,
          'late': late,
          'total': records.length,
        };
      }).toList();

      // Sort by date descending
      list.sort((a, b) {
        final aTs = a['date'] as Timestamp?;
        final bTs = b['date'] as Timestamp?;
        if (aTs == null || bTs == null) return 0;
        return bTs.compareTo(aTs);
      });

      if (!mounted) return;
      setState(() { _records = list; _loading = false; });
      _anim.reset();
      _anim.forward();
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  void _openAttendance(DateTime date) {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (_, a, __) => AttendanceScreen(
          batchId: widget.batchId,
          batchName: widget.batchName,
          initialDate: date,
        ),
        transitionsBuilder: (_, a, __, child) => SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1, 0),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: a, curve: Curves.easeOutCubic)),
          child: child,
        ),
        transitionDuration: const Duration(milliseconds: 340),
      ),
    ).then((_) => _load());
  }

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    final expandedHeight = 140.0;

    return Scaffold(
      backgroundColor: _kBg,
      body: NotificationListener<ScrollNotification>(
        onNotification: (n) {
          if (n is ScrollUpdateNotification) {
            final collapsed = n.metrics.pixels > 60;
            if (collapsed != _showTitle) setState(() => _showTitle = collapsed);
          }
          return false;
        },
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // ── AppBar ──────────────────────────────────────────────────────
            SliverAppBar(
              pinned: true,
              expandedHeight: expandedHeight,
              backgroundColor: _kPrimary,
              foregroundColor: Colors.white,
              elevation: 0,
              automaticallyImplyLeading: false,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded,
                    size: 20, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
              ),
              title: AnimatedOpacity(
                opacity: _showTitle ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 200),
                child: Text(
                  widget.batchName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              flexibleSpace: FlexibleSpaceBar(
                collapseMode: CollapseMode.pin,
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [_kPrimary, _kPurple],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(20, topPad + kToolbarHeight, 16, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        const Text(
                          'Attendance History',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          widget.batchName,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.75),
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // ── Content ──────────────────────────────────────────────────────
            if (_loading)
              const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator(color: _kPrimary)),
              )
            else if (_error != null)
              SliverFillRemaining(child: _ErrorView(error: _error!, onRetry: _load))
            else if (_records.isEmpty)
              const SliverFillRemaining(child: _EmptyView())
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (_, i) {
                      final r = _records[i];
                      final ts = r['date'] as Timestamp?;
                      final date = ts?.toDate() ?? DateTime.now();
                      return _HistoryCard(
                        date: date,
                        present: r['present'] as int,
                        absent: r['absent'] as int,
                        late: r['late'] as int,
                        total: r['total'] as int,
                        onTap: () => _openAttendance(date),
                      );
                    },
                    childCount: _records.length,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ─── History Card ─────────────────────────────────────────────────────────────
class _HistoryCard extends StatelessWidget {
  final DateTime date;
  final int present;
  final int absent;
  final int late;
  final int total;
  final VoidCallback onTap;

  const _HistoryCard({
    required this.date,
    required this.present,
    required this.absent,
    required this.late,
    required this.total,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final pct = total > 0 ? (present / total) : 0.0;
    final dayName  = DateFormat('EEEE').format(date);
    final dateStr  = DateFormat('d MMM yyyy').format(date);

    Color barColor;
    if (pct >= 0.8) barColor = _kSuccess;
    else if (pct >= 0.5) barColor = _kWarning;
    else barColor = _kError;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: _kCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _kBorder, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Date icon
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [_kPrimary, _kPurple],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '${date.day}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            height: 1,
                          ),
                        ),
                        Text(
                          DateFormat('MMM').format(date),
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.85),
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          dayName,
                          style: const TextStyle(
                            color: _kTextDark,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          dateStr,
                          style: const TextStyle(
                            color: _kTextMuted,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Attendance pct chip
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: barColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: barColor.withOpacity(0.3), width: 1),
                    ),
                    child: Text(
                      total > 0
                          ? '${(pct * 100).toStringAsFixed(0)}%'
                          : '—',
                      style: TextStyle(
                        color: barColor,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.chevron_right_rounded,
                      color: _kTextMuted, size: 20),
                ],
              ),
              const SizedBox(height: 12),
              // Progress bar
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: pct,
                  backgroundColor: _kBorder,
                  valueColor: AlwaysStoppedAnimation<Color>(barColor),
                  minHeight: 5,
                ),
              ),
              const SizedBox(height: 10),
              // Stat chips
              Row(
                children: [
                  _StatChip(
                      count: present, label: 'Present', color: _kSuccess),
                  const SizedBox(width: 8),
                  _StatChip(count: absent, label: 'Absent', color: _kError),
                  const SizedBox(width: 8),
                  _StatChip(count: late, label: 'Late', color: _kWarning),
                  const Spacer(),
                  Text(
                    '$total students',
                    style: const TextStyle(
                      color: _kTextMuted,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final int count;
  final String label;
  final Color color;

  const _StatChip(
      {required this.count, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          '$count $label',
          style: TextStyle(
            color: color,
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

// ─── Empty ────────────────────────────────────────────────────────────────────
class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: _kPrimary.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.history_rounded,
                color: _kPrimary, size: 34),
          ),
          const SizedBox(height: 16),
          const Text(
            'No attendance records yet',
            style: TextStyle(
              color: _kTextDark,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Take attendance to see history here',
            style: TextStyle(color: _kTextMuted, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

// ─── Error ────────────────────────────────────────────────────────────────────
class _ErrorView extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;

  const _ErrorView({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded,
                color: _kError, size: 48),
            const SizedBox(height: 12),
            Text(
              error,
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
}
