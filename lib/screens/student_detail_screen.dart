import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'edit_student_screen.dart';

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

// ══════════════════════════════════════════════════════════════════════════════
class StudentDetailScreen extends StatefulWidget {
  final String docId;
  final Map<String, dynamic> initialData;

  const StudentDetailScreen({
    super.key,
    required this.docId,
    required this.initialData,
  });

  @override
  State<StudentDetailScreen> createState() => _StudentDetailScreenState();
}

class _StudentDetailScreenState extends State<StudentDetailScreen>
    with SingleTickerProviderStateMixin {
  late Map<String, dynamic> _data;
  bool _deleting = false;

  String? _batchName;

  late final AnimationController _anim;
  late final Animation<double>   _fade;
  late final Animation<Offset>   _slide;

  @override
  void initState() {
    super.initState();
    _data = Map.from(widget.initialData);
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    )..forward();
    _fade  = CurvedAnimation(parent: _anim, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _anim, curve: Curves.easeOutCubic));

    _loadBatchName();
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  // ── Load batch name ────────────────────────────────────────────────────────
  Future<void> _loadBatchName() async {
    final batchId = _data['batch_id'] as String?;
    if (batchId == null || batchId.isEmpty) return;
    try {
      final doc = await FirebaseFirestore.instance
          .collection('batches')
          .doc(batchId)
          .get();
      if (!mounted) return;
      if (doc.exists) {
        setState(() => _batchName = doc.data()?['name'] as String? ?? batchId);
      }
    } catch (_) {}
  }

  // ── Getters ────────────────────────────────────────────────────────────────
  String get _name       => _data['name']        as String? ?? '-';
  String get _username   => _data['username']    as String? ?? '-';
  String get _phone      => _data['phone']       as String? ?? '-';
  String get _fatherName => _data['father_name'] as String? ?? '';
  String get _school     => _data['school']      as String? ?? '';
  String get _address    => _data['address']     as String? ?? '';
  String get _password   => _data['password']    as String? ?? '-';
  bool   get _isActive   => (_data['status'] as String? ?? 'active') == 'active';

  String get _initials {
    final n = _name.trim();
    if (n.isEmpty) return '?';
    return n.split(' ').map((w) => w[0]).take(2).join().toUpperCase();
  }

  Color get _avatarColor {
    const colors = [
      _kPrimary, _kPurple, _kSuccess,
      Color(0xFFF59E0B), Color(0xFFEF4444),
    ];
    final hash = _initials.codeUnits.fold(0, (a, b) => a + b);
    return colors[hash % colors.length];
  }

  // ── Toggle status ──────────────────────────────────────────────────────────
  Future<void> _toggleStatus() async {
    final newStatus = _isActive ? 'inactive' : 'active';
    setState(() => _data['status'] = newStatus);
    try {
      await FirebaseFirestore.instance
          .collection('students')
          .doc(widget.docId)
          .update({'status': newStatus});
    } catch (_) {
      if (mounted) setState(() => _data['status'] = _isActive ? 'active' : 'inactive');
    }
  }

  // ── Delete ─────────────────────────────────────────────────────────────────
  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _DeleteDialog(name: _name),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _deleting = true);
    try {
      await FirebaseFirestore.instance
          .collection('students')
          .doc(widget.docId)
          .delete();
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _deleting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Delete failed: $e'),
          backgroundColor: _kError,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // ── Copy to clipboard ──────────────────────────────────────────────────────
  void _copy(String value, String label) {
    Clipboard.setData(ClipboardData(text: value));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label copied'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: _kSuccess,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // ── Navigate to edit ───────────────────────────────────────────────────────
  Future<void> _openEdit() async {
    final updated = await Navigator.of(context).push<Map<String, dynamic>>(
      PageRouteBuilder(
        pageBuilder: (_, a, __) => EditStudentScreen(
          docId: widget.docId,
          initialData: _data,
        ),
        transitionsBuilder: (_, a, __, child) => SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1, 0),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: a, curve: Curves.easeOutCubic)),
          child: child,
        ),
        transitionDuration: const Duration(milliseconds: 360),
      ),
    );
    if (updated != null && mounted) {
      setState(() {
        _data.addAll(updated);
        _batchName = null; // reset so it reloads
      });
      _loadBatchName();
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
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: _kBg,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: _kBg,
        body: Stack(
          children: [
            // Background blobs
            Positioned(
              bottom: -80, left: -40,
              child: _Blob(220, _kPurple.withOpacity(0.05)),
            ),

            Column(
              children: [
                // ── Gradient header ──────────────────────────────────────────
                _buildHeader(safeTop),

                // ── Body ─────────────────────────────────────────────────────
                Expanded(
                  child: FadeTransition(
                    opacity: _fade,
                    child: SlideTransition(
                      position: _slide,
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        padding: EdgeInsets.fromLTRB(20, 20, 20, safeBottom + 32),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // ── Personal information ─────────────────────────
                            const _SectionTitle(label: 'Personal Information'),
                            const SizedBox(height: 12),
                            _InfoCard(
                              children: [
                                _InfoRow(
                                  icon: Icons.person_outline_rounded,
                                  label: 'Full Name',
                                  value: _name,
                                ),
                                _InfoRow(
                                  icon: Icons.people_outline_rounded,
                                  label: "Father's Name",
                                  value: _fatherName.isEmpty ? '—' : _fatherName,
                                ),
                                _InfoRow(
                                  icon: Icons.phone_outlined,
                                  label: 'Phone',
                                  value: _phone,
                                ),
                                if (_school.isNotEmpty)
                                  _InfoRow(
                                    icon: Icons.school_outlined,
                                    label: 'School',
                                    value: _school,
                                  ),
                                _InfoRow(
                                  icon: Icons.location_on_outlined,
                                  label: 'Address',
                                  value: _address.isEmpty ? '—' : _address,
                                ),
                                _InfoRow(
                                  icon: Icons.groups_outlined,
                                  label: 'Assigned Batch',
                                  value: _batchName ?? '—',
                                  isLast: true,
                                ),
                              ],
                            ),

                            const SizedBox(height: 20),

                            // ── Login credentials ────────────────────────────
                            const _SectionTitle(label: 'Login Credentials'),
                            const SizedBox(height: 12),
                            _InfoCard(
                              children: [
                                _CopyRow(
                                  icon: Icons.alternate_email_rounded,
                                  label: 'Username (Email)',
                                  value: _username,
                                  onCopy: () => _copy(_username, 'Username'),
                                ),
                                _CopyRow(
                                  icon: Icons.lock_outline_rounded,
                                  label: 'Password',
                                  value: _password,
                                  onCopy: () => _copy(_password, 'Password'),
                                  isLast: true,
                                ),
                              ],
                            ),

                            const SizedBox(height: 20),

                            // ── Status ───────────────────────────────────────
                            const _SectionTitle(label: 'Status'),
                            const SizedBox(height: 12),
                            _StatusToggleCard(
                              isActive: _isActive,
                              onToggle: _toggleStatus,
                            ),

                            const SizedBox(height: 32),

                            // ── Delete ───────────────────────────────────────
                            _DeleteButton(
                              deleting: _deleting,
                              onTap: _confirmDelete,
                            ),
                          ],
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

  // ── Header with gradient ───────────────────────────────────────────────────
  Widget _buildHeader(double safeTop) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_avatarColor, _avatarColor.withOpacity(0.75)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        children: [
          // Top bar row
          Padding(
            padding: EdgeInsets.fromLTRB(8, safeTop + 8, 12, 0),
            child: Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.arrow_back_ios_new_rounded,
                      color: Colors.white, size: 20),
                ),
                const Spacer(),
                // Edit button
                GestureDetector(
                  onTap: _openEdit,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: Colors.white.withOpacity(0.4)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.edit_outlined,
                            color: Colors.white, size: 15),
                        SizedBox(width: 5),
                        Text(
                          'Edit',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),

          // Avatar
          Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.25),
              border: Border.all(
                  color: Colors.white.withOpacity(0.6), width: 3),
            ),
            child: Center(
              child: Text(
                _initials,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Name
          Text(
            _name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
            ),
          ),

          const SizedBox(height: 8),

          // Status badge
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: _isActive
                  ? _kSuccess.withOpacity(0.25)
                  : Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _isActive
                    ? _kSuccess.withOpacity(0.5)
                    : Colors.white.withOpacity(0.3),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _isActive
                        ? _kSuccess
                        : Colors.white.withOpacity(0.5),
                  ),
                ),
                const SizedBox(width: 5),
                Text(
                  _isActive ? 'Active' : 'Inactive',
                  style: TextStyle(
                    color: _isActive
                        ? _kSuccess
                        : Colors.white.withOpacity(0.8),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

// ─── Info card container ──────────────────────────────────────────────────────
class _InfoCard extends StatelessWidget {
  final List<Widget> children;
  const _InfoCard({required this.children});

  @override
  Widget build(BuildContext context) => Container(
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
        child: Column(children: children),
      );
}

// ─── Info row ─────────────────────────────────────────────────────────────────
class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String   label;
  final String   value;
  final bool     isLast;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) => Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: _kPrimary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, size: 17, color: _kPrimary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: const TextStyle(
                          color: _kTextMuted,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        value,
                        style: const TextStyle(
                          color: _kTextDark,
                          fontSize: 14.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (!isLast)
            const Divider(height: 1, indent: 64, color: _kBorder),
        ],
      );
}

// ─── Copy row (credential with copy button) ───────────────────────────────────
class _CopyRow extends StatelessWidget {
  final IconData     icon;
  final String       label;
  final String       value;
  final VoidCallback onCopy;
  final bool         isLast;

  const _CopyRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.onCopy,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) => Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: _kSuccess.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, size: 17, color: _kSuccess),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: const TextStyle(
                          color: _kTextMuted,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        value,
                        style: const TextStyle(
                          color: _kTextDark,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: onCopy,
                  child: Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: _kPrimary.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.copy_rounded,
                        size: 15, color: _kPrimary),
                  ),
                ),
              ],
            ),
          ),
          if (!isLast)
            const Divider(height: 1, indent: 64, color: _kBorder),
        ],
      );
}

// ─── Status toggle card ───────────────────────────────────────────────────────
class _StatusToggleCard extends StatelessWidget {
  final bool         isActive;
  final VoidCallback onToggle;

  const _StatusToggleCard({
    required this.isActive,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: (isActive ? _kSuccess : _kTextMuted).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                isActive
                    ? Icons.toggle_on_outlined
                    : Icons.toggle_off_outlined,
                size: 20,
                color: isActive ? _kSuccess : _kTextMuted,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Student Status',
                    style: TextStyle(
                      color: _kTextDark,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isActive
                        ? 'Active — student can log in'
                        : 'Inactive — login disabled',
                    style: const TextStyle(
                        color: _kTextMuted, fontSize: 12),
                  ),
                ],
              ),
            ),
            Switch.adaptive(
              value: isActive,
              onChanged: (_) => onToggle(),
              activeColor: _kSuccess,
            ),
          ],
        ),
      );
}

// ─── Delete button ────────────────────────────────────────────────────────────
class _DeleteButton extends StatelessWidget {
  final bool         deleting;
  final VoidCallback onTap;

  const _DeleteButton({required this.deleting, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: deleting ? null : onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: double.infinity,
          height: 52,
          decoration: BoxDecoration(
            color: _kError.withOpacity(deleting ? 0.4 : 0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _kError.withOpacity(0.25)),
          ),
          child: Center(
            child: deleting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: _kError,
                    ),
                  )
                : const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.delete_outline_rounded,
                          color: _kError, size: 19),
                      SizedBox(width: 8),
                      Text(
                        'Delete Student',
                        style: TextStyle(
                          color: _kError,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      );
}

// ─── Delete confirmation dialog ───────────────────────────────────────────────
class _DeleteDialog extends StatelessWidget {
  final String name;
  const _DeleteDialog({required this.name});

  @override
  Widget build(BuildContext context) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.white,
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: _kError, size: 22),
            SizedBox(width: 8),
            Text(
              'Delete Student',
              style: TextStyle(
                color: _kTextDark,
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to delete "$name"?\nThis action cannot be undone.',
          style: const TextStyle(
              color: _kTextMuted, fontSize: 14, height: 1.5),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => Navigator.of(context).pop(false),
                  child: Container(
                    height: 44,
                    decoration: BoxDecoration(
                      color: _kBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _kBorder),
                    ),
                    child: const Center(
                      child: Text(
                        'Cancel',
                        style: TextStyle(
                          color: _kTextMuted,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: GestureDetector(
                  onTap: () => Navigator.of(context).pop(true),
                  child: Container(
                    height: 44,
                    decoration: BoxDecoration(
                      color: _kError,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(
                      child: Text(
                        'Delete',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      );
}

// ─── Section title ────────────────────────────────────────────────────────────
class _SectionTitle extends StatelessWidget {
  final String label;
  const _SectionTitle({required this.label});

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Container(
            width: 4,
            height: 16,
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
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      );
}

// ─── Decorative blob ──────────────────────────────────────────────────────────
class _Blob extends StatelessWidget {
  final double size;
  final Color  color;
  const _Blob(this.size, this.color);

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration:
            BoxDecoration(shape: BoxShape.circle, color: color),
      );
}
