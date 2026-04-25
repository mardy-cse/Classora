import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'add_student_screen.dart';
import 'student_detail_screen.dart';

// ─── Brand palette ─────────────────────────────────────────────────────────
const _kPrimary   = Color(0xFF2563EB);
const _kPurple    = Color(0xFF7C3AED);
const _kBg        = Color(0xFFF1F5FB);
const _kCard      = Colors.white;
const _kTextDark  = Color(0xFF0F172A);
const _kTextMuted = Color(0xFF64748B);
const _kBorder    = Color(0xFFE2E8F0);
const _kSuccess   = Color(0xFF10B981);

class StudentsTab extends StatelessWidget {
  const StudentsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final uid  = FirebaseAuth.instance.currentUser!.uid;
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
                  'Students',
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
                    pageBuilder: (_, a, __) => const AddStudentScreen(),
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
                .collection('students')
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
                  final doc  = docs[i];
                  final data = doc.data() as Map<String, dynamic>;
                  return _StudentCard(
                    docId: doc.id,
                    data: data,
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

// ─── Student card ─────────────────────────────────────────────────────────────
class _StudentCard extends StatelessWidget {
  final String             docId;
  final Map<String, dynamic> data;
  const _StudentCard({required this.docId, required this.data});

  @override
  Widget build(BuildContext context) {
    final name     = data['name'] as String? ?? '-';
    final username = data['username'] as String? ?? '-';
    final phone    = data['phone'] as String? ?? '-';
    final status   = data['status'] as String? ?? 'active';
    final school   = data['school'] as String? ?? '';
    final isActive = status == 'active';
    final initials = name.trim().isNotEmpty
        ? name.trim().split(' ').map((w) => w[0]).take(2).join().toUpperCase()
        : '?';

    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        PageRouteBuilder(
          pageBuilder: (_, a, __) => StudentDetailScreen(
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
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [_avatarColor(initials), _avatarColor(initials).withOpacity(0.7)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Center(
                child: Text(
                  initials,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Info
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
                    username,
                    style: const TextStyle(color: _kPrimary, fontSize: 12.5, fontWeight: FontWeight.w500),
                  ),
                  if (phone.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(Icons.phone_outlined, size: 12, color: _kTextMuted),
                        const SizedBox(width: 4),
                        Text(phone, style: const TextStyle(color: _kTextMuted, fontSize: 12)),
                      ],
                    ),
                  ],
                  if (school.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(Icons.school_outlined, size: 12, color: _kTextMuted),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            school,
                            style: const TextStyle(color: _kTextMuted, fontSize: 12),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            // Status
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: isActive
                    ? _kSuccess.withOpacity(0.1)
                    : _kTextMuted.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                isActive ? 'Active' : 'Inactive',
                style: TextStyle(
                  color: isActive ? _kSuccess : _kTextMuted,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    ),
    );
  }

  Color _avatarColor(String initials) {
    const colors = [_kPrimary, _kPurple, _kSuccess, Color(0xFFF59E0B), Color(0xFFEF4444)];
    final hash = initials.codeUnits.fold(0, (a, b) => a + b);
    return colors[hash % colors.length];
  }
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
                'Add',
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
            Icon(Icons.people_outline_rounded,
                size: 64, color: _kTextMuted.withOpacity(0.35)),
            const SizedBox(height: 16),
            const Text(
              'No students yet',
              style: TextStyle(
                  color: _kTextDark, fontSize: 17, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            const Text(
              'Tap "Add" to add your first student',
              style: TextStyle(color: _kTextMuted, fontSize: 13.5),
            ),
          ],
        ),
      );
}

// ─── Error state ───────────────────────────────────────────────────────────────
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
