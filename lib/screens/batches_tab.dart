import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'batch_detail_screen.dart';
import 'create_batch_screen.dart';

// ─── Brand palette ─────────────────────────────────────────────────────────
const _kPrimary   = Color(0xFF2563EB);
const _kPurple    = Color(0xFF7C3AED);
const _kBg        = Color(0xFFF1F5FB);
const _kCard      = Colors.white;
const _kTextDark  = Color(0xFF0F172A);
const _kTextMuted = Color(0xFF64748B);
const _kBorder    = Color(0xFFE2E8F0);
const _kSuccess   = Color(0xFF10B981);
const _kWarning   = Color(0xFFF59E0B);

class BatchesTab extends StatelessWidget {
  const BatchesTab({super.key});

  @override
  Widget build(BuildContext context) {
    final uid     = FirebaseAuth.instance.currentUser!.uid;
    final safeTop = MediaQuery.of(context).padding.top;

    return Column(
      children: [
        // ── Header ──────────────────────────────────────────────────────────
        Container(
          color: _kBg,
          padding: EdgeInsets.fromLTRB(20, safeTop + 12, 20, 14),
          child: Row(
            children: [
              const Expanded(
                child: Text(
                  'Batches',
                  style: TextStyle(
                    color: _kTextDark,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                ),
              ),
              _AddButton(
                onTap: () => Navigator.of(context).push(
                  PageRouteBuilder(
                    pageBuilder: (_, a, __) => const CreateBatchScreen(),
                    transitionsBuilder: (_, a, __, child) => SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, 1),
                        end: Offset.zero,
                      ).animate(
                          CurvedAnimation(parent: a, curve: Curves.easeOutCubic)),
                      child: child,
                    ),
                    transitionDuration: const Duration(milliseconds: 420),
                  ),
                ),
              ),
            ],
          ),
        ),

        // ── List ─────────────────────────────────────────────────────────────
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('batches')
                .where('teacher_id', isEqualTo: uid)
                .snapshots(),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(color: _kPrimary),
                );
              }
              if (snap.hasError) {
                return _ErrorState(message: snap.error.toString());
              }
              final docs = List.of(snap.data?.docs ?? []);
              docs.sort((a, b) {
                final aTime = (a.data() as Map)['created_at'] as Timestamp?;
                final bTime = (b.data() as Map)['created_at'] as Timestamp?;
                if (aTime == null || bTime == null) return 0;
                return bTime.compareTo(aTime);
              });
              if (docs.isEmpty) return const _EmptyState();

              return ListView.builder(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                itemCount: docs.length,
                itemBuilder: (_, i) {
                  final data = docs[i].data() as Map<String, dynamic>;
                  return _BatchCard(docId: docs[i].id, data: data);
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

// ─── Batch card ───────────────────────────────────────────────────────────────
class _BatchCard extends StatelessWidget {
  final String docId;
  final Map<String, dynamic> data;
  const _BatchCard({required this.docId, required this.data});

  Color get _statusColor {
    return switch (data['status'] as String? ?? 'upcoming') {
      'Active'   => _kSuccess,
      'Inactive' => _kTextMuted,
      _          => _kWarning,  // Upcoming
    };
  }

  @override
  Widget build(BuildContext context) {
    final name       = data['name'] as String? ?? '-';
    final batchCode  = data['batch_code'] as String? ?? '-';
    final classLevel = data['class_level'] as String? ?? '';
    final session    = data['session'] as String? ?? '';
    final subject    = data['subject'] as String? ?? '';
    final status     = data['status'] as String? ?? 'Upcoming';
    final maxStudents= (data['max_students'] as num?)?.toInt() ?? 0;
    final days       = (data['schedule_days'] as List?)?.cast<String>() ?? [];
    final classTime  = data['class_time'] as String? ?? '';

    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        PageRouteBuilder(
          pageBuilder: (_, a, __) => BatchDetailScreen(
            docId: docId,
            initialData: data,
          ),
          transitionsBuilder: (_, a, __, child) => SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(1, 0),
              end: Offset.zero,
            ).animate(CurvedAnimation(parent: a, curve: Curves.easeOutCubic)),
            child: child,
          ),
          transitionDuration: const Duration(milliseconds: 380),
        ),
      ),
      child: Container(
      margin: const EdgeInsets.only(bottom: 12),
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
        children: [
          // Top row
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [_kPrimary, _kPurple],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: const Icon(Icons.class_rounded,
                      color: Colors.white, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          color: _kTextDark,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        batchCode,
                        style: const TextStyle(
                          color: _kPrimary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ),
                // Status badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: _statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _statusColor.withOpacity(0.3)),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(
                      color: _statusColor,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Divider
          const Divider(color: _kBorder, height: 1, indent: 16, endIndent: 16),

          // Details row
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
            child: Wrap(
              spacing: 16,
              runSpacing: 6,
              children: [
                if (classLevel.isNotEmpty)
                  _InfoChip(icon: Icons.school_outlined, label: classLevel),
                if (session.isNotEmpty)
                  _InfoChip(icon: Icons.calendar_today_outlined, label: session),
                if (subject.isNotEmpty)
                  _InfoChip(icon: Icons.menu_book_outlined, label: subject),
                if (maxStudents > 0)
                  _InfoChip(
                      icon: Icons.people_outlined,
                      label: 'Max $maxStudents'),
                if (days.isNotEmpty)
                  _InfoChip(
                      icon: Icons.date_range_outlined,
                      label: days.join(', ')),
                if (classTime.isNotEmpty)
                  _InfoChip(icon: Icons.access_time_outlined, label: classTime),
              ],
            ),
          ),
        ],
      ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: _kTextMuted),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(color: _kTextMuted, fontSize: 12.5),
          ),
        ],
      );
}

// ─── Add button ───────────────────────────────────────────────────────────────
class _AddButton extends StatelessWidget {
  final VoidCallback onTap;
  const _AddButton({required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [_kPrimary, _kPurple]),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: _kPrimary.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.add_rounded, color: Colors.white, size: 18),
              SizedBox(width: 5),
              Text(
                'New',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
      );
}

// ─── Empty state ──────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.class_outlined,
                size: 64, color: _kTextMuted.withOpacity(0.35)),
            const SizedBox(height: 16),
            const Text(
              'No batches yet',
              style: TextStyle(
                  color: _kTextDark, fontSize: 17, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            const Text(
              'Tap "New" to create your first batch',
              style: TextStyle(color: _kTextMuted, fontSize: 13.5),
            ),
          ],
        ),
      );
}

// ─── Error state ──────────────────────────────────────────────────────────────
class _ErrorState extends StatelessWidget {
  final String message;
  const _ErrorState({required this.message});

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'Error: $message',
            style: const TextStyle(color: Color(0xFFEF4444), fontSize: 13),
            textAlign: TextAlign.center,
          ),
        ),
      );
}
