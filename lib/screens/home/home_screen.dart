import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../theme/app_theme.dart';
import '../../models/lesion.dart';
import '../../widgets/risk_badge.dart';
import '../../routing/app_router.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/sync_service.dart';
import 'package:cached_network_image/cached_network_image.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _navIndex = 0;
  bool _isFetchingFromServer = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final auth = context.read<AuthService>();
      if (auth.isAuthenticated) {
        // Fetch latest data from server on every home screen visit
        setState(() => _isFetchingFromServer = true);
        await SyncService.fetchHistoryFromServer(token: auth.token!);
        if (mounted) setState(() => _isFetchingFromServer = false);
        // Also sync any pending offline scans
        SyncService.syncPendingScans(token: auth.token);
      }
    });
  }
  
  @override
  Widget build(BuildContext context) {
    final lesions = context.watch<LesionStore>().lesions;
    DateTime? lastScan;
    bool hasOverdue = false;

    if (lesions.isNotEmpty) {
      lastScan = lesions
          .map((l) => l.lastScan)
          .reduce((a, b) => a.isAfter(b) ? a : b);
      hasOverdue = lesions.any((l) => l.isOverdue);
    }

    return Scaffold(
      body: _isFetchingFromServer && lesions.isEmpty
          ? _buildLoadingState()
          : _buildHomeTab(lesions, lastScan, hasOverdue),
      bottomNavigationBar: _buildBottomNav(),
      floatingActionButton: _buildFab(),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(
            'Loading your scans...',
            style: TextStyle(
              color: AppColors.getAdaptiveTextSecondary(context),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHomeTab(List<Lesion> lesions, DateTime? lastScan, bool hasOverdue) {
    return CustomScrollView(
      slivers: [
        _buildHeader(),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (lesions.isNotEmpty) ...[
                  _buildSummaryCard(lesions, lastScan, hasOverdue),
                  const SizedBox(height: 24),
                  _buildSectionTitle('Your Lesions', '${lesions.length}'),
                ],
              ],
            ),
          ),
        ),
        if (lesions.isEmpty)
          SliverFillRemaining(child: _buildEmptyState())
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => _buildLesionCard(lesions[index]),
                childCount: lesions.length,
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
      automaticallyImplyLeading: false,
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
                          'Hello, ${context.select<AuthService, String>((auth) => auth.userName).split(' ').first} 👋',
                          style: Theme.of(context)
                              .textTheme
                              .headlineMedium
                              ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Monitor your skin health daily',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
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

  Widget _buildSummaryCard(List<Lesion> lesions, DateTime? lastScan, bool hasOverdue) {
    final df = DateFormat('MMM d, yyyy');
    final isDarkMode = context.select<AuthService, bool>((auth) => auth.isDarkMode);
    
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: isDarkMode
            ? AppColors.darkCardGradient
            : AppColors.cardGradient,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.divider),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.06),
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
              value: '${lesions.length}',
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
              value: lastScan != null ? df.format(lastScan) : '—',
              label: 'Last Scan',
              color: AppColors.secondary,
            ),
          ),
          if (hasOverdue) ...[
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
              child: const Column(
                children: [
                  Icon(Icons.schedule_rounded,
                      color: AppColors.riskMedium, size: 18),
                  SizedBox(height: 2),
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
            Expanded(
              child: Text(
                value,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title, String count) {
    return Row(
      children: [
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: AppColors.primaryLight.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            count,
            style: const TextStyle(
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
          color: Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.divider),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
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
                color: Theme.of(context).scaffoldBackgroundColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.divider),
              ),
              clipBehavior: Clip.antiAlias,
              child: (lesion.imagePath != null && lesion.imagePath != 'demo_lesion.jpg')
                  ? (lesion.imagePath!.startsWith('http')
                      ? CachedNetworkImage(
                          imageUrl: lesion.imagePath!,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(color: Colors.grey[300]),
                          errorWidget: (context, url, error) => const Icon(Icons.error),
                        )
                      : Image.file(File(lesion.imagePath!), fit: BoxFit.cover))
                  : Icon(
                      Icons.image_search_rounded,
                      color: AppColors.getAdaptiveTextMuted(context),
                      size: 28,
                     ),
            ),
            const SizedBox(width: 14),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(lesion.name,
                      style: Theme.of(context)
                          .textTheme
                          .bodyLarge
                          ?.copyWith(fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Icon(Icons.location_on_outlined,
                          size: 13,
                          color: AppColors.getAdaptiveTextMuted(context)),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(lesion.bodyLocation,
                            style: Theme.of(context).textTheme.labelSmall,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                      ),
                      const SizedBox(width: 10),
                      Icon(Icons.history_rounded,
                          size: 13,
                          color: AppColors.getAdaptiveTextMuted(context)),
                      const SizedBox(width: 3),
                      Text(df.format(lesion.lastScan),
                          style: Theme.of(context).textTheme.labelSmall),
                    ],
                  ),
                  const SizedBox(height: 6),
                  RiskBadge(risk: lesion.latestRisk),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded,
                color: AppColors.getAdaptiveTextMuted(context), size: 22),
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
                gradient: context.watch<AuthService>().isDarkMode
                    ? AppColors.darkCardGradient
                    : AppColors.cardGradient,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.divider, width: 2),
              ),
              child: Icon(
                Icons.document_scanner_rounded,
                size: 48,
                color: AppColors.primary.withValues(alpha: 0.40),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No lesions yet',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondary,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Start scanning to track your skin health and catch changes early.',
              style: TextStyle(
                  fontSize: 14,
                  color: AppColors.getAdaptiveTextSecondary(context)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: 200,
              child: ElevatedButton.icon(
                onPressed: () => Navigator.pushNamed(context, AppRoutes.camera),
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

  Widget _buildBottomNav() {
    return BottomNavigationBar(
      currentIndex: _navIndex,
      onTap: (i) {
        if (i == 1) {
          Navigator.pushNamed(context, AppRoutes.profile);
        } else {
          setState(() => _navIndex = i);
        }
      },
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
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
