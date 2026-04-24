import 'dart:math' as math;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'add_student_screen.dart';
import 'batches_tab.dart';
import 'create_batch_screen.dart';
import 'login_screen.dart';
import 'students_tab.dart';

// ─── Brand palette ─────────────────────────────────────────────────────────
const _kPrimary     = Color(0xFF2563EB);
const _kAccent      = Color(0xFF3B82F6);
const _kPurple      = Color(0xFF7C3AED);
const _kBg          = Color(0xFFF1F5FB);
const _kCard        = Colors.white;
const _kTextDark    = Color(0xFF0F172A);
const _kTextMuted   = Color(0xFF64748B);
const _kBorder      = Color(0xFFE2E8F0);
const _kSuccess     = Color(0xFF10B981);
const _kWarning     = Color(0xFFF59E0B);

// ─── Fake data model ────────────────────────────────────────────────────────
class _Student {
  final String name;
  final String username;
  final bool active;
  final String avatar;
  const _Student({
    required this.name,
    required this.username,
    required this.active,
    required this.avatar,
  });
}

const _kRecentStudents = [
  _Student(name: 'Arif Hossain',   username: 'STU-1001', active: true,  avatar: 'AH'),
  _Student(name: 'Nusrat Jahan',   username: 'STU-1002', active: true,  avatar: 'NJ'),
  _Student(name: 'Rakibul Islam',  username: 'STU-1003', active: false, avatar: 'RI'),
  _Student(name: 'Sumaiya Akter',  username: 'STU-1004', active: true,  avatar: 'SA'),
  _Student(name: 'Tanvir Ahmed',   username: 'STU-1005', active: true,  avatar: 'TA'),
];

// ══════════════════════════════════════════════════════════════════════════════
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with TickerProviderStateMixin {
  int _navIndex = 0;
  bool _loading = true;

  late final AnimationController _fadeCtrl;
  late final Animation<double>   _fadeAnim;
  late final AnimationController _statsCtrl;

  String get _displayName {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return 'Teacher';
    final name = user.displayName ?? user.email ?? 'Teacher';
    return name.split(' ').first;
  }

  @override
  void initState() {
    super.initState();

    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);

    _statsCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    // Simulate loading
    Future.delayed(const Duration(milliseconds: 800), () {
      if (!mounted) return;
      setState(() => _loading = false);
      _fadeCtrl.forward();
      _statsCtrl.forward();
    });
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _statsCtrl.dispose();
    super.dispose();
  }

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

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: _kBg,
        floatingActionButton: _navIndex == 0 ? _buildFab() : null,
        bottomNavigationBar: _buildBottomNav(),
        body: _loading
            ? _buildSkeleton()
            : IndexedStack(
                index: _navIndex,
                children: [
                  _buildBody(),
                  const StudentsTab(),
                  const BatchesTab(),
                  _buildProfileTab(),
                ],
              ),
      ),
    );
  }

  // ── Skeleton loading ───────────────────────────────────────────────────────
  Widget _buildSkeleton() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _SkeletonBox(width: 120, height: 20, radius: 8),
                _SkeletonBox(width: 40, height: 40, radius: 20),
              ],
            ),
            const SizedBox(height: 24),
            _SkeletonBox(width: double.infinity, height: 110, radius: 16),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(child: _SkeletonBox(height: 90, radius: 14)),
                const SizedBox(width: 12),
                Expanded(child: _SkeletonBox(height: 90, radius: 14)),
                const SizedBox(width: 12),
                Expanded(child: _SkeletonBox(height: 90, radius: 14)),
              ],
            ),
            const SizedBox(height: 20),
            _SkeletonBox(width: double.infinity, height: 160, radius: 16),
            const SizedBox(height: 20),
            _SkeletonBox(width: 140, height: 18, radius: 8),
            const SizedBox(height: 12),
            ...List.generate(3, (_) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _SkeletonBox(width: double.infinity, height: 64, radius: 12),
            )),
          ],
        ),
      ),
    );
  }

  // ── Main body ──────────────────────────────────────────────────────────────
  Widget _buildBody() {
    return FadeTransition(
      opacity: _fadeAnim,
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildAppBar(),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                const SizedBox(height: 20),
                _buildWelcomeCard(),
                const SizedBox(height: 20),
                _buildStatsRow(),
                const SizedBox(height: 24),
                _buildQuickActions(),
                const SizedBox(height: 24),
                _buildRecentStudents(),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  // ── App Bar ────────────────────────────────────────────────────────────────
  Widget _buildAppBar() {
    return SliverAppBar(
      backgroundColor: _kBg,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      floating: true,
      snap: true,
      automaticallyImplyLeading: false,
      titleSpacing: 20,
      title: Row(
        children: [
          // Logo
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
            child: const Icon(Icons.school_rounded, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 10),
          const Text(
            'Dashboard',
            style: TextStyle(
              color: _kTextDark,
              fontSize: 20,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
            ),
          ),
        ],
      ),
      actions: [
        GestureDetector(
          onTap: _showProfileSheet,
          child: Container(
            margin: const EdgeInsets.only(right: 20),
            width: 40,
            height: 40,
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
                _displayName.isNotEmpty ? _displayName[0].toUpperCase() : 'T',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Profile bottom sheet ───────────────────────────────────────────────────
  void _showProfileSheet() {
    final user = FirebaseAuth.instance.currentUser;
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
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [_kPrimary, _kPurple],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Center(
                child: Text(
                  _displayName.isNotEmpty ? _displayName[0].toUpperCase() : 'T',
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
            _SheetTile(
              icon: Icons.settings_outlined,
              label: 'Settings',
              onTap: () => Navigator.pop(context),
            ),
            _SheetTile(
              icon: Icons.logout_rounded,
              label: 'Logout',
              color: Colors.red,
              onTap: () {
                Navigator.pop(context);
                _logout();
              },
            ),
          ],
        ),
      ),
    );
  }

  // ── Welcome card ───────────────────────────────────────────────────────────
  Widget _buildWelcomeCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2563EB), Color(0xFF7C3AED)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _kPrimary.withOpacity(0.35),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Decorative circle
          Positioned(
            right: -20,
            top: -20,
            child: Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.08),
              ),
            ),
          ),
          Positioned(
            right: 20,
            bottom: -30,
            child: Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.06),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Welcome back, $_displayName! 👋',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Manage your students and classes easily',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.78),
                  fontSize: 13.5,
                  fontWeight: FontWeight.w400,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.calendar_today_rounded, color: Colors.white, size: 14),
                    SizedBox(width: 6),
                    Text(
                      'Thursday, April 24',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Stats row ──────────────────────────────────────────────────────────────
  Widget _buildStatsRow() {
    final stats = [
      _StatData(icon: Icons.people_rounded,      color: _kPrimary, value: '128', label: 'Total\nStudents'),
      _StatData(icon: Icons.class_rounded,        color: _kPurple,  value: '6',   label: 'Total\nBatches'),
      _StatData(icon: Icons.how_to_reg_rounded,  color: _kSuccess, value: '42',  label: 'Active\nToday'),
    ];

    return Row(
      children: stats.asMap().entries.map((e) {
        final i = e.key;
        final s = e.value;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(left: i == 0 ? 0 : 6, right: i == 2 ? 0 : 6),
            child: AnimatedBuilder(
              animation: _statsCtrl,
              builder: (_, __) {
                final delay = i * 0.2;
                final t = (((_statsCtrl.value - delay) / (1.0 - delay)).clamp(0.0, 1.0));
                final curve = Curves.easeOutCubic.transform(t);
                final count = (int.parse(s.value) * curve).toInt();

                return Container(
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
                  decoration: BoxDecoration(
                    color: _kCard,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.055),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: s.color.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(s.icon, color: s.color, size: 20),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        '$count',
                        style: TextStyle(
                          color: s.color,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        s.label,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: _kTextMuted,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w500,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        );
      }).toList(),
    );
  }

  // ── Quick actions ──────────────────────────────────────────────────────────
  Widget _buildQuickActions() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.055),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Quick Actions',
            style: TextStyle(
              color: _kTextDark,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          _ActionButton(
            icon: Icons.person_add_rounded,
            label: 'Add Student',
            gradient: const LinearGradient(
              colors: [_kPrimary, _kAccent],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            onTap: _openAddStudent,
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _ActionButtonOutlined(
                  icon: Icons.group_add_rounded,
                  label: 'Create Batch',
                  color: _kPurple,
                  onTap: _openCreateBatch,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ActionButtonOutlined(
                  icon: Icons.vpn_key_rounded,
                  label: 'Credentials',
                  color: _kWarning,
                  onTap: () {},
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Recent students ────────────────────────────────────────────────────────
  Widget _buildRecentStudents() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Recent Students',
              style: TextStyle(
                color: _kTextDark,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
            GestureDetector(
              onTap: () {},
              child: const Text(
                'See all',
                style: TextStyle(
                  color: _kPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_kRecentStudents.isEmpty)
          _buildEmptyState()
        else
          Container(
            decoration: BoxDecoration(
              color: _kCard,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.055),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _kRecentStudents.length,
              separatorBuilder: (_, __) => const Divider(
                color: _kBorder, height: 1, indent: 68,
              ),
              itemBuilder: (_, i) => _StudentTile(student: _kRecentStudents[i]),
            ),
          ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 48),
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.people_outline_rounded,
              size: 56, color: _kTextMuted.withOpacity(0.4)),
          const SizedBox(height: 14),
          const Text(
            'No students yet',
            style: TextStyle(
              color: _kTextMuted,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Add your first student to get started',
            style: TextStyle(color: _kTextMuted, fontSize: 13),
          ),
        ],
      ),
    );
  }

  // ── Open Add Student screen ────────────────────────────────────────────────
  Future<void> _openAddStudent() async {
    await Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (_, a, __) => const AddStudentScreen(),
        transitionsBuilder: (_, a, __, child) => SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 1),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: a, curve: Curves.easeOutCubic)),
          child: child,
        ),
        transitionDuration: const Duration(milliseconds: 420),
      ),
    );
  }

  // ── Open Create Batch screen ──────────────────────────────────────────────
  Future<void> _openCreateBatch() async {
    await Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (_, a, __) => const CreateBatchScreen(),
        transitionsBuilder: (_, a, __, child) => SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 1),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: a, curve: Curves.easeOutCubic)),
          child: child,
        ),
        transitionDuration: const Duration(milliseconds: 420),
      ),
    );
  }

  // ── Profile tab ────────────────────────────────────────────────────────────
  Widget _buildProfileTab() {
    final user    = FirebaseAuth.instance.currentUser;
    final name    = user?.displayName ?? 'Teacher';
    final email   = user?.email ?? '';
    final initial = name.isNotEmpty ? name[0].toUpperCase() : 'T';
    final safeTop = MediaQuery.of(context).padding.top;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: [
          // Header gradient
          Container(
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(24, safeTop + 24, 24, 32),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF2563EB), Color(0xFF7C3AED)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
            ),
            child: Column(
              children: [
                Container(
                  width: 80, height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.2),
                    border: Border.all(color: Colors.white.withOpacity(0.5), width: 2),
                  ),
                  child: Center(
                    child: Text(
                      initial,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  email,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.78),
                    fontSize: 13.5,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Teacher',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Menu items
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                _ProfileMenuItem(
                  icon: Icons.person_outline_rounded,
                  label: 'Edit Profile',
                  onTap: () {},
                ),
                _ProfileMenuItem(
                  icon: Icons.lock_outline_rounded,
                  label: 'Change Password',
                  onTap: () {},
                ),
                _ProfileMenuItem(
                  icon: Icons.notifications_outlined,
                  label: 'Notifications',
                  onTap: () {},
                ),
                _ProfileMenuItem(
                  icon: Icons.help_outline_rounded,
                  label: 'Help & Support',
                  onTap: () {},
                ),
                const SizedBox(height: 8),
                _ProfileMenuItem(
                  icon: Icons.logout_rounded,
                  label: 'Logout',
                  color: const Color(0xFFEF4444),
                  onTap: _logout,
                ),
              ],
            ),
          ),

          const SizedBox(height: 100),
        ],
      ),
    );
  }

  // ── FAB ────────────────────────────────────────────────────────────────────
  Widget _buildFab() {
    return FloatingActionButton(
      onPressed: _openAddStudent,
      backgroundColor: _kPrimary,
      foregroundColor: Colors.white,
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: const Icon(Icons.add_rounded, size: 28),
    );
  }

  // ── Bottom nav ─────────────────────────────────────────────────────────────
  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(icon: Icons.dashboard_rounded,    label: 'Dashboard', active: _navIndex == 0, onTap: () => setState(() => _navIndex = 0)),
              _NavItem(icon: Icons.people_rounded,       label: 'Students',  active: _navIndex == 1, onTap: () => setState(() => _navIndex = 1)),
              _NavItem(icon: Icons.class_rounded,        label: 'Batches',   active: _navIndex == 2, onTap: () => setState(() => _navIndex = 2)),
              _NavItem(icon: Icons.person_rounded,       label: 'Profile',   active: _navIndex == 3, onTap: () => setState(() => _navIndex = 3)),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Stat data model ──────────────────────────────────────────────────────────
class _StatData {
  final IconData icon;
  final Color    color;
  final String   value;
  final String   label;
  const _StatData({
    required this.icon,
    required this.color,
    required this.value,
    required this.label,
  });
}

// ─── Action button (filled) ──────────────────────────────────────────────────
class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Gradient gradient;
  final VoidCallback onTap;
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.gradient,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: double.infinity,
          height: 52,
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: _kPrimary.withOpacity(0.30),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      );
}

// ─── Action button (outlined) ─────────────────────────────────────────────────
class _ActionButtonOutlined extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _ActionButtonOutlined({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          height: 52,
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withOpacity(0.25), width: 1.3),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 19),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      );
}

// ─── Student tile ─────────────────────────────────────────────────────────────
class _StudentTile extends StatelessWidget {
  final _Student student;
  const _StudentTile({required this.student});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    _avatarColor(student.avatar),
                    _avatarColor(student.avatar).withOpacity(0.7),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Center(
                child: Text(
                  student.avatar,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    student.name,
                    style: const TextStyle(
                      color: _kTextDark,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    student.username,
                    style: const TextStyle(
                      color: _kTextMuted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            // Status badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: student.active
                    ? _kSuccess.withOpacity(0.1)
                    : _kTextMuted.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                student.active ? 'Active' : 'Inactive',
                style: TextStyle(
                  color: student.active ? _kSuccess : _kTextMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );

  Color _avatarColor(String initials) {
    final colors = [
      _kPrimary, _kPurple, _kSuccess, _kWarning, const Color(0xFFEF4444),
    ];
    final hash = initials.codeUnits.fold(0, (a, b) => a + b);
    return colors[hash % colors.length];
  }
}

// ─── Bottom nav item ──────────────────────────────────────────────────────────
class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _NavItem({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: active ? _kPrimary.withOpacity(0.1) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: active ? _kPrimary : _kTextMuted,
                size: 22,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: active ? _kPrimary : _kTextMuted,
                  fontSize: 10.5,
                  fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
}

// ─── Profile sheet tile ───────────────────────────────────────────────────────
class _SheetTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;
  const _SheetTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color = _kTextDark,
  });

  @override
  Widget build(BuildContext context) => ListTile(
        onTap: onTap,
        leading: Icon(icon, color: color, size: 22),
        title: Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
        trailing: Icon(Icons.chevron_right_rounded,
            color: _kTextMuted.withOpacity(0.5)),
        contentPadding: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      );
}

// ─── Skeleton box ─────────────────────────────────────────────────────────────
class _SkeletonBox extends StatefulWidget {
  final double? width;
  final double height;
  final double radius;
  const _SkeletonBox({this.width, required this.height, required this.radius});

  @override
  State<_SkeletonBox> createState() => _SkeletonBoxState();
}

class _SkeletonBoxState extends State<_SkeletonBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _anim,
        builder: (_, __) => Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: Color.lerp(
              const Color(0xFFE2E8F0),
              const Color(0xFFF1F5F9),
              _anim.value,
            ),
            borderRadius: BorderRadius.circular(widget.radius),
          ),
        ),
      );
}

// ─── Profile menu item ────────────────────────────────────────────────────────
class _ProfileMenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;
  const _ProfileMenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color = const Color(0xFF0F172A),
  });

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ListTile(
          onTap: onTap,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          leading: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          title: Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 14.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          trailing: Icon(Icons.chevron_right_rounded,
              color: const Color(0xFF64748B).withOpacity(0.5)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
        ),
      );
}
