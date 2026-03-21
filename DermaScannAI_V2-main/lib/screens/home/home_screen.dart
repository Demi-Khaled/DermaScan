import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../theme/app_theme.dart';
import '../../models/lesion.dart';
import '../../services/lesion_service.dart';
import 'package:provider/provider.dart';
import '../../widgets/risk_badge.dart';
import '../../routing/app_router.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _navIndex = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        await Provider.of<LesionService>(context, listen: false).fetchLesions();
      } catch (e) {
        // ignore for now
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    });
  }

  List<Lesion> get _lesions => Provider.of<LesionService>(context).lesions;

  DateTime? get _lastScan {
    if (_lesions.isEmpty) return null;
    return _lesions
        .map((l) => l.lastScan)
        .reduce((a, b) => a.isAfter(b) ? a : b);
  }

  bool get _hasOverdue => _lesions.any((l) => l.isOverdue);

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }
    return Scaffold(
      backgroundColor: AppColors.background,
      body: IndexedStack(
        index: _navIndex,
        children: [_buildHomeTab(), _buildProfilePlaceholder()],
      ),
      bottomNavigationBar: _buildBottomNav(),
      floatingActionButton: _navIndex == 0 ? _buildFab() : null,
    );
  }

  Widget _buildHomeTab() {
    return CustomScrollView(
      slivers: [
        _buildHeader(),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_lesions.isNotEmpty) ...[
                  _buildSummaryCard(),
                  const SizedBox(height: 24),
                  _buildSectionTitle('Your Lesions', '${_lesions.length}'),
                ],
              ],
            ),
          ),
        ),
        if (_lesions.isEmpty)
          SliverFillRemaining(child: _buildEmptyState())
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => _buildLesionCard(_lesions[index]),
                childCount: _lesions.length,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildHeader() {
    return SliverAppBar(
      expandedHeight: 140,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(gradient: AppColors.headerGradient),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 16),
                        Text(
                          'Hello, Ahmed 👋',
                          style: AppTextStyles.h2.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Monitor your skin health daily',
                          style: AppTextStyles.caption.copyWith(
                            color: Colors.white.withOpacity(0.80),
                          ),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () =>
                        Navigator.pushNamed(context, AppRoutes.profile),
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.20),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.40),
                          width: 1.5,
                        ),
                      ),
                      child: const Icon(
                        Icons.person_rounded,
                        color: Colors.white,
                        size: 26,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      backgroundColor: AppColors.primary,
    );
  }

  Widget _buildSummaryCard() {
    final lastScanDate = _lastScan;
    final df = DateFormat('MMM d, yyyy');
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: AppColors.cardGradient,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.divider),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _statPill(
              icon: Icons.healing_rounded,
              value: '${_lesions.length}',
              label: 'Lesions',
              color: AppColors.accent,
            ),
          ),
          Container(
            width: 1,
            height: 50,
            color: AppColors.divider,
            margin: const EdgeInsets.symmetric(horizontal: 16),
          ),
          Expanded(
            child: _statPill(
              icon: Icons.calendar_today_rounded,
              value: lastScanDate != null ? df.format(lastScanDate) : '—',
              label: 'Last Scan',
              color: AppColors.secondary,
            ),
          ),
          if (_hasOverdue) ...[
            Container(
              width: 1,
              height: 50,
              color: AppColors.divider,
              margin: const EdgeInsets.symmetric(horizontal: 16),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.riskMediumBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                children: [
                  Icon(Icons.schedule_rounded,
                      color: AppColors.riskMedium, size: 18),
                  const SizedBox(height: 2),
                  Text(
                    'Overdue',
                    style: TextStyle(
                      color: AppColors.riskMedium,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _statPill({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 6),
            Text(
              value,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(label, style: AppTextStyles.small),
      ],
    );
  }

  Widget _buildSectionTitle(String title, String count) {
    return Row(
      children: [
        Text(title, style: AppTextStyles.h3),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: AppColors.primaryLight.withOpacity(0.12),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            count,
            style: TextStyle(
              color: AppColors.primary,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLesionCard(Lesion lesion) {
    final df = DateFormat('MMM d');
    return GestureDetector(
      onTap: () => Navigator.pushNamed(
        context,
        AppRoutes.lesionDetail,
        arguments: {'lesion': lesion},
      ).then((_) => setState(() {})),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.divider),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Thumbnail
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.divider),
              ),
              child: Icon(
                Icons.image_search_rounded,
                color: AppColors.textMuted,
                size: 28,
              ),
            ),
            const SizedBox(width: 14),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(lesion.name, style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Icon(Icons.location_on_outlined,
                          size: 13, color: AppColors.textMuted),
                      const SizedBox(width: 3),
                      Text(lesion.bodyLocation, style: AppTextStyles.small),
                      const SizedBox(width: 10),
                      Icon(Icons.history_rounded,
                          size: 13, color: AppColors.textMuted),
                      const SizedBox(width: 3),
                      Text(df.format(lesion.lastScan), style: AppTextStyles.small),
                    ],
                  ),
                  const SizedBox(height: 6),
                  RiskBadge(risk: lesion.latestRisk),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                color: AppColors.textMuted, size: 22),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                gradient: AppColors.cardGradient,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.divider, width: 2),
              ),
              child: Icon(
                Icons.document_scanner_rounded,
                size: 48,
                color: AppColors.primary.withOpacity(0.40),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No lesions yet',
              style: AppTextStyles.h3.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 8),
            Text(
              'Start scanning to track your skin health and catch changes early.',
              style: AppTextStyles.caption,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: 200,
              child: ElevatedButton.icon(
                onPressed: () =>
                    Navigator.pushNamed(context, AppRoutes.camera),
                icon: const Icon(Icons.camera_alt_rounded),
                label: const Text('Start First Scan'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfilePlaceholder() {
    return const ProfileTab();
  }

  Widget _buildBottomNav() {
    return BottomNavigationBar(
      currentIndex: _navIndex,
      onTap: (i) => setState(() => _navIndex = i),
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home_rounded),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person_rounded),
          label: 'Profile',
        ),
      ],
    );
  }

  Widget _buildFab() {
    return FloatingActionButton.extended(
      onPressed: () => Navigator.pushNamed(context, AppRoutes.camera)
          .then((_) => setState(() {})),
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      elevation: 4,
      icon: const Icon(Icons.add_a_photo_rounded),
      label: const Text(
        'New Scan',
        style: TextStyle(fontWeight: FontWeight.w600),
      ),
    );
  }
}

// Inline profile tab used within the bottom nav
class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_rounded, size: 64, color: AppColors.primary),
            const SizedBox(height: 16),
            Text('Profile', style: AppTextStyles.h2),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () =>
                  Navigator.pushNamed(context, AppRoutes.profile),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                minimumSize: const Size(180, 48),
              ),
              child: const Text('Open Profile'),
            ),
          ],
        ),
      ),
    );
  }
}
