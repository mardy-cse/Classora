import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'batch_detail_screen.dart';
import 'create_batch_screen.dart';
import 'login_screen.dart';

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

class BatchesTab extends StatefulWidget {
  const BatchesTab({super.key});

  @override
  State<BatchesTab> createState() => _BatchesTabState();
}

class _BatchesTabState extends State<BatchesTab> {
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(() {
      setState(() => _query = _searchCtrl.text.trim().toLowerCase());
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final uid      = FirebaseAuth.instance.currentUser!.uid;
    final user      = FirebaseAuth.instance.currentUser;
    final firstName = ((user?.displayName ?? user?.email ?? 'T').split(' ').first);
    final initial   = firstName.isNotEmpty ? firstName[0].toUpperCase() : 'T';
    final safeTop = MediaQuery.of(context).padding.top;

    return Column(
      children: [
        // ── Header ──────────────────────────────────────────────────────────
        Container(
          color: _kBg,
          padding: EdgeInsets.fromLTRB(20, safeTop + 12, 20, 14),
          child: Row(
            children: [
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
                child: const Icon(Icons.school_rounded, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 10),
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
              const SizedBox(width: 10),
              // Profile avatar
              GestureDetector(
                onTap: _showProfileSheet,
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [_kPrimary, _kPurple],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: _kPrimary.withOpacity(0.35),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      initial,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // ── Search ───────────────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
          child: TextField(
            controller: _searchCtrl,
            style: const TextStyle(
              color: _kTextDark,
              fontSize: 14.5,
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              hintText: 'Search by name, subject or code…',
              hintStyle: TextStyle(color: _kTextMuted.withOpacity(0.65), fontSize: 14),
              prefixIcon: const Icon(Icons.search_rounded, color: _kTextMuted, size: 20),
              suffixIcon: _query.isNotEmpty
                  ? GestureDetector(
                      onTap: () => _searchCtrl.clear(),
                      child: const Icon(Icons.close_rounded, color: _kTextMuted, size: 18),
                    )
                  : null,
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: _kBorder),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: _kBorder),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: _kPrimary, width: 1.5),
              ),
            ),
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

              final filtered = _query.isEmpty
                  ? docs
                  : docs.where((d) {
                      final data = d.data() as Map<String, dynamic>;
                      final name    = (data['name']        as String? ?? '').toLowerCase();
                      final subject = (data['subject']     as String? ?? '').toLowerCase();
                      final code    = (data['batch_code']  as String? ?? '').toLowerCase();
                      return name.contains(_query) ||
                             subject.contains(_query) ||
                             code.contains(_query);
                    }).toList();

              if (docs.isEmpty) return const _EmptyState();
              if (filtered.isEmpty) {
                return Center(
                  child: Text(
                    'No batches match "$_query"',
                    style: const TextStyle(color: _kTextMuted, fontSize: 14),
                  ),
                );
              }

              return ListView.builder(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
                itemCount: filtered.length,
                itemBuilder: (_, i) {
                  final data = filtered[i].data() as Map<String, dynamic>;
                  return _BatchCard(docId: filtered[i].id, data: data);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  // ── Logout ────────────────────────────────────────────────────────────────
  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Logout', style: TextStyle(fontWeight: FontWeight.w700)),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _kPrimary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, a, __) => const LoginScreen(),
        transitionsBuilder: (_, a, __, child) =>
            FadeTransition(opacity: a, child: child),
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  // ── Profile sheet ─────────────────────────────────────────────────────────
  void _showProfileSheet() {
    final user = FirebaseAuth.instance.currentUser;
    final firstName = ((user?.displayName ?? user?.email ?? 'T').split(' ').first);
    final initial = firstName.isNotEmpty ? firstName[0].toUpperCase() : 'T';
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      backgroundColor: Colors.white,
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: _kBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Container(
              width: 64, height: 64,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [_kPrimary, _kPurple],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Center(
                child: Text(
                  initial,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 26,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              user?.displayName ?? 'Teacher',
              style: const TextStyle(
                color: _kTextDark,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              user?.email ?? '',
              style: const TextStyle(color: _kTextMuted, fontSize: 13),
            ),
            const SizedBox(height: 24),
            const Divider(color: _kBorder),
            const SizedBox(height: 8),
            ListTile(
              onTap: () => Navigator.pop(context),
              leading: const Icon(Icons.settings_outlined, color: _kTextDark, size: 22),
              title: const Text('Settings',
                  style: TextStyle(color: _kTextDark, fontSize: 15, fontWeight: FontWeight.w600)),
              trailing: Icon(Icons.chevron_right_rounded, color: _kTextMuted.withOpacity(0.5)),
              contentPadding: EdgeInsets.zero,
            ),
            ListTile(
              onTap: () {
                Navigator.pop(context);
                _logout();
              },
              leading: const Icon(Icons.logout_rounded, color: Colors.red, size: 22),
              title: const Text('Logout',
                  style: TextStyle(color: Colors.red, fontSize: 15, fontWeight: FontWeight.w600)),
              trailing: Icon(Icons.chevron_right_rounded, color: _kTextMuted.withOpacity(0.5)),
              contentPadding: EdgeInsets.zero,
            ),
          ],
        ),
      ),
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
