import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../routing/app_router.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  // Profile state
  String _name = 'Ahmed Al-Rashid';
  String _email = 'ahmed@example.com';
  bool _editingProfile = false;
  late TextEditingController _nameCtrl;
  late TextEditingController _emailCtrl;

  // Settings state
  bool _darkMode = false;
  bool _notifications = true;
  String _language = 'English';

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
    _nameCtrl = TextEditingController(text: _name);
    _emailCtrl = TextEditingController(text: _email);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: NestedScrollView(
        headerSliverBuilder: (_, __) => [_buildHeader()],
        body: Column(
          children: [
            _buildTabBar(),
            Expanded(
              child: TabBarView(
                controller: _tabCtrl,
                children: [
                  _buildProfileTab(),
                  _buildSettingsTab(),
                  _buildEducationTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return SliverAppBar(
      expandedHeight: 160,
      pinned: true,
      backgroundColor: AppColors.primary,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(gradient: AppColors.headerGradient),
          child: SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 20),
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.20),
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: Colors.white.withOpacity(0.60), width: 2),
                  ),
                  child: const Icon(Icons.person_rounded,
                      color: Colors.white, size: 38),
                ),
                const SizedBox(height: 10),
                Text(
                  _name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _email,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.75),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: Colors.white,
      child: TabBar(
        controller: _tabCtrl,
        labelColor: AppColors.primary,
        unselectedLabelColor: AppColors.textMuted,
        indicatorColor: AppColors.primary,
        indicatorWeight: 3,
        labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        tabs: const [
          Tab(text: 'Profile'),
          Tab(text: 'Settings'),
          Tab(text: 'Education'),
        ],
      ),
    );
  }

  // ─── Profile Tab ───────────────────────────────────────────────────────────

  Widget _buildProfileTab() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        if (_editingProfile) ...[
          _section(
            title: 'Edit Profile',
            icon: Icons.edit_rounded,
            child: Column(
              children: [
                TextFormField(
                  controller: _nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Full Name',
                    prefixIcon: Icon(Icons.person_outline_rounded),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => setState(() => _editingProfile = false),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => setState(() {
                          _name = _nameCtrl.text.trim().isEmpty
                              ? _name
                              : _nameCtrl.text.trim();
                          _email = _emailCtrl.text.trim().isEmpty
                              ? _email
                              : _emailCtrl.text.trim();
                          _editingProfile = false;
                        }),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(0, 46),
                        ),
                        child: const Text('Save'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ] else ...[
          _section(
            title: 'Personal Info',
            icon: Icons.person_rounded,
            child: Column(
              children: [
                _infoRow(Icons.person_outline, 'Full Name', _name),
                const Divider(height: 20),
                _infoRow(Icons.email_outlined, 'Email', _email),
              ],
            ),
          ),
          const SizedBox(height: 4),
          _actionTile(
            'Edit Profile',
            Icons.edit_rounded,
            AppColors.accent,
            () => setState(() => _editingProfile = true),
          ),
        ],
        const SizedBox(height: 12),
        _actionTile(
          'Change Password',
          Icons.lock_reset_rounded,
          AppColors.secondary,
          () => _showStub('Password change coming soon!'),
        ),
        const SizedBox(height: 12),
        _actionTile(
          'Delete Account',
          Icons.delete_forever_rounded,
          AppColors.danger,
          _confirmDelete,
          textColor: AppColors.danger,
        ),
      ],
    );
  }

  // ─── Settings Tab ──────────────────────────────────────────────────────────

  Widget _buildSettingsTab() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _section(
          title: 'Preferences',
          icon: Icons.tune_rounded,
          child: Column(
            children: [
              _switchTile(
                'Dark Mode',
                Icons.dark_mode_rounded,
                _darkMode,
                (v) => setState(() => _darkMode = v),
              ),
              const Divider(height: 1),
              _switchTile(
                'Notifications',
                Icons.notifications_rounded,
                _notifications,
                (v) => setState(() => _notifications = v),
              ),
              const Divider(height: 1),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.language_rounded,
                      color: AppColors.secondary, size: 18),
                ),
                title: const Text('Language'),
                subtitle: Text(_language,
                    style: const TextStyle(color: AppColors.textMuted)),
                trailing: DropdownButton<String>(
                  value: _language,
                  underline: const SizedBox(),
                  items: ['English', 'Arabic', 'French']
                      .map((l) => DropdownMenuItem(value: l, child: Text(l)))
                      .toList(),
                  onChanged: (v) => setState(() => _language = v!),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _actionTile(
          'Export Data',
          Icons.download_rounded,
          AppColors.accent,
          () => _showStub('Export feature coming soon!'),
        ),
        const SizedBox(height: 12),
        _actionTile(
          'Logout',
          Icons.logout_rounded,
          AppColors.danger,
          () => Navigator.pushReplacementNamed(context, AppRoutes.auth),
          textColor: AppColors.danger,
        ),
      ],
    );
  }

  // ─── Education Tab ─────────────────────────────────────────────────────────

  Widget _buildEducationTab() {
    final articles = [
      _Article(
        icon: Icons.local_hospital_rounded,
        color: AppColors.danger,
        title: 'What is Melanoma?',
        description:
            'Learn the key characteristics of melanoma, the most serious type of skin cancer, including ABCDE criteria.',
      ),
      _Article(
        icon: Icons.wb_sunny_rounded,
        color: AppColors.warning,
        title: 'Prevention Tips',
        description:
            'Practical steps to reduce UV exposure: sunscreen, protective clothing, shade-seeking, and regular self-checks.',
      ),
      _Article(
        icon: Icons.medical_services_rounded,
        color: AppColors.secondary,
        title: 'When to Visit a Doctor?',
        description:
            'Identify warning signs that require an immediate dermatologist visit: rapid growth, bleeding, or ulceration.',
      ),
      _Article(
        icon: Icons.info_rounded,
        color: AppColors.accent,
        title: 'Understanding Risk Levels',
        description:
            'How DermaScann AI classifies lesions and what each risk level means for your follow-up actions.',
      ),
    ];

    return ListView(
      padding: const EdgeInsets.all(20),
      children: articles.map((a) => _articleCard(a)).toList(),
    );
  }

  Widget _articleCard(_Article article) {
    return GestureDetector(
      onTap: () => _showStub('Article detail coming soon!'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.divider),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: article.color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(article.icon, color: article.color, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    article.title,
                    style: AppTextStyles.body.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    article.description,
                    style: AppTextStyles.small.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                color: AppColors.textMuted, size: 20),
          ],
        ),
      ),
    );
  }

  // ─── Helpers ───────────────────────────────────────────────────────────────

  Widget _section({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.primary, size: 18),
              const SizedBox(width: 8),
              Text(title, style: AppTextStyles.h3.copyWith(fontSize: 16)),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: AppColors.textMuted, size: 18),
        const SizedBox(width: 10),
        Text(label, style: AppTextStyles.caption),
        const Spacer(),
        Text(value,
            style: AppTextStyles.caption.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            )),
      ],
    );
  }

  Widget _actionTile(
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap, {
    Color? textColor,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.divider),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 14),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: textColor ?? AppColors.textPrimary,
                fontSize: 15,
              ),
            ),
            const Spacer(),
            Icon(Icons.chevron_right_rounded,
                color: AppColors.textMuted, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _switchTile(
    String label,
    IconData icon,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      secondary: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.10),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: AppColors.primary, size: 18),
      ),
      title: Text(label, style: AppTextStyles.body.copyWith(fontSize: 15)),
      value: value,
      onChanged: onChanged,
      activeColor: AppColors.primary,
    );
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Account?'),
        content: const Text(
          'This action is irreversible. All your data and scan history will be permanently deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushReplacementNamed(context, AppRoutes.auth);
              _showStub('Account deleted (stub).');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
              minimumSize: const Size(0, 40),
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showStub(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}

class _Article {
  final IconData icon;
  final Color color;
  final String title;
  final String description;
  _Article({
    required this.icon,
    required this.color,
    required this.title,
    required this.description,
  });
}
