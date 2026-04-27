import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../theme/app_theme.dart';
import '../../routing/app_router.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/auth_service.dart';
import '../../models/article.dart';
import '../../services/notification_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../../services/pdf_service.dart';
import '../../models/lesion.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  // Profile state
  String _name = '';
  String _email = '';
  bool _editingProfile = false;
  late TextEditingController _nameCtrl;
  late TextEditingController _emailCtrl;
  late TextEditingController _ageCtrl;
  late TextEditingController _skinTypeCtrl;
  late TextEditingController _medicalConditionsCtrl;

  // Settings state
  bool _notifications = true;
  String _language = 'English';
  List<PendingNotificationRequest> _pendingReminders = [];

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthService>();
    _name = auth.userName;
    _email = auth.userEmail;

    _tabCtrl = TabController(length: 3, vsync: this);
    _nameCtrl = TextEditingController(text: auth.userName);
    _emailCtrl = TextEditingController(text: auth.userEmail);
    _ageCtrl = TextEditingController(text: auth.age?.toString() ?? '');
    _skinTypeCtrl = TextEditingController(text: auth.skinType ?? '');
    _medicalConditionsCtrl = TextEditingController(text: auth.medicalConditions ?? '');
    _loadPendingReminders();
  }

  Future<void> _loadPendingReminders() async {
    final reminders = await NotificationService.getPendingReminders();
    if (mounted) setState(() => _pendingReminders = reminders);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _ageCtrl.dispose();
    _skinTypeCtrl.dispose();
    _medicalConditionsCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.20),
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: Colors.white.withValues(alpha: 0.60), width: 2),
                      image: context.watch<AuthService>().profilePicture != null
                          ? DecorationImage(
                              image: NetworkImage(
                                  context.watch<AuthService>().profilePicture!),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: context.watch<AuthService>().profilePicture == null
                        ? const Icon(Icons.camera_alt_rounded,
                            color: Colors.white, size: 28)
                        : null,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  _name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  _email,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.75),
                    fontSize: 13,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
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
      color: Theme.of(context).cardTheme.color,
      child: TabBar(
        controller: _tabCtrl,
        labelColor: AppColors.primary,
        unselectedLabelColor: AppColors.getAdaptiveTextMuted(context),
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
                const SizedBox(height: 12),
                Column(
                  children: [
                    TextFormField(
                      controller: _ageCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Age',
                        prefixIcon: Icon(Icons.calendar_today_rounded),
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: _skinTypeCtrl.text.isEmpty ? null : _skinTypeCtrl.text,
                      decoration: const InputDecoration(
                        labelText: 'Skin Type',
                        prefixIcon: Icon(Icons.opacity_rounded),
                      ),
                      isExpanded: true,
                      items: ['', 'Oily', 'Dry', 'Combination', 'Normal', 'Sensitive']
                          .map((s) => DropdownMenuItem(value: s, child: Text(s.isEmpty ? 'Select' : s)))
                          .toList(),
                      onChanged: (v) => setState(() => _skinTypeCtrl.text = v ?? ''),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _medicalConditionsCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Medical History / Conditions',
                    prefixIcon: Icon(Icons.history_edu_rounded),
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () =>
                            setState(() => _editingProfile = false),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          final auth = context.read<AuthService>();
                          try {
                            final success = await auth.updateProfile(
                              name: _nameCtrl.text.trim(),
                              email: _emailCtrl.text.trim(),
                              age: int.tryParse(_ageCtrl.text),
                              skinType: _skinTypeCtrl.text,
                              medicalConditions: _medicalConditionsCtrl.text.trim(),
                            );
                            if (success && mounted) {
                              setState(() {
                                _name = auth.userName;
                                _email = auth.userEmail;
                                _editingProfile = false;
                              });
                              _showStub('Profile updated successfully!');
                            }
                          } catch (e) {
                            _showStub(e.toString().replaceAll('Exception: ', ''));
                          }
                        },
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
                if (context.watch<AuthService>().age != null) ...[
                  const Divider(height: 20),
                  _infoRow(Icons.calendar_today_rounded, 'Age', context.watch<AuthService>().age.toString()),
                ],
                if (context.watch<AuthService>().skinType != null && context.watch<AuthService>().skinType!.isNotEmpty) ...[
                  const Divider(height: 20),
                  _infoRow(Icons.opacity_rounded, 'Skin Type', context.watch<AuthService>().skinType!),
                ],
                if (context.watch<AuthService>().medicalConditions != null && context.watch<AuthService>().medicalConditions!.isNotEmpty) ...[
                  const Divider(height: 20),
                  Row(
                    children: [
                      Icon(Icons.history_edu_rounded, color: AppColors.getAdaptiveTextMuted(context), size: 18),
                      const SizedBox(width: 10),
                      Text('Medical History', style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    context.watch<AuthService>().medicalConditions!,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontSize: 14),
                  ),
                ],
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
          () => Navigator.pushNamed(context, AppRoutes.forgotPassword),
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
                context.watch<AuthService>().isDarkMode,
                (v) => context.read<AuthService>().toggleDarkMode(v),
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
                    color: AppColors.secondary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.language_rounded,
                      color: AppColors.secondary, size: 18),
                ),
                title: const Text('Language'),
                subtitle: Text(_language,
                    style: TextStyle(color: AppColors.getAdaptiveTextMuted(context))),
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
        _buildScheduledRemindersSection(),
        const SizedBox(height: 12),
        _actionTile(
          'Export Data',
          Icons.download_rounded,
          AppColors.accent,
          _exportData,
        ),
        const SizedBox(height: 12),
        _actionTile(
          'Logout',
          Icons.logout_rounded,
          AppColors.danger,
          () async {
            if (!mounted) return;
            await context.read<AuthService>().logout();
            if (!mounted) return;
            Navigator.pushReplacementNamed(context, AppRoutes.auth);
          },
          textColor: AppColors.danger,
        ),
      ],
    );
  }

  Future<void> _exportData() async {
    final lesions = LesionStore().lesions;
    if (lesions.isEmpty) {
      _showError('No lesion data to export.');
      return;
    }

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final auth = context.read<AuthService>();
      await PdfService.generateFullHistoryReport(
        lesions: lesions,
        auth: auth,
      );
    } catch (e) {
      _showError('Export failed: $e');
    } finally {
      if (mounted) Navigator.pop(context); // close loading
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: AppColors.danger),
    );
  }

  Widget _buildScheduledRemindersSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.alarm_rounded, color: AppColors.secondary, size: 18),
              const SizedBox(width: 8),
              Text('Scheduled Reminders',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 16)),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.refresh_rounded, size: 18),
                onPressed: _loadPendingReminders,
                color: AppColors.getAdaptiveTextMuted(context),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                tooltip: 'Refresh',
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Divider(height: 1),
          const SizedBox(height: 8),
          if (_pendingReminders.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                children: [
                  Icon(Icons.notifications_none_rounded,
                      size: 20, color: AppColors.getAdaptiveTextMuted(context)),
                  const SizedBox(width: 10),
                  Text(
                    'No scheduled reminders',
                    style: TextStyle(
                      color: AppColors.getAdaptiveTextMuted(context),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            )
          else
            ...(_pendingReminders.map((r) {
              DateTime? scheduledDate;
              if (r.payload != null) {
                final parts = r.payload!.split('|');
                if (parts.length >= 3) {
                  scheduledDate = DateTime.tryParse(parts[2]);
                }
              }

              final df = DateFormat('MMM d, h:mm a');
              final dateStr = scheduledDate != null ? df.format(scheduledDate) : 'Unknown time';

              return ListTile(
                contentPadding: EdgeInsets.zero,
                onTap: () => _showReminderDetails(r, scheduledDate),
                leading: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.notification_add_rounded,
                      color: AppColors.secondary, size: 18),
                ),
                title: Text(
                  r.title ?? 'Follow-up Reminder',
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  'Set for $dateStr',
                  style: TextStyle(
                      fontSize: 12, color: AppColors.getAdaptiveTextMuted(context)),
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.cancel_rounded, color: AppColors.danger, size: 20),
                  onPressed: () async {
                    await NotificationService.cancelReminder(r.id);
                    _loadPendingReminders();
                  },
                  tooltip: 'Cancel reminder',
                ),
              );
            })),
        ],
      ),
    );
  }

  void _showReminderDetails(PendingNotificationRequest r, DateTime? date) {
    final df = DateFormat('EEEE, MMMM d, yyyy');
    final tf = DateFormat('h:mm a');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.notifications_active_rounded, color: AppColors.primary),
            const SizedBox(width: 12),
            const Text('Reminder Details'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              r.title ?? 'Reminder',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              r.body ?? '',
              style: TextStyle(color: AppColors.getAdaptiveTextSecondary(context)),
            ),
            const Divider(height: 32),
            if (date != null) ...[
              Row(
                children: [
                  const Icon(Icons.calendar_today_rounded, size: 16, color: AppColors.secondary),
                  const SizedBox(width: 8),
                  Text(df.format(date), style: const TextStyle(fontSize: 14)),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.access_time_rounded, size: 16, color: AppColors.secondary),
                  const SizedBox(width: 8),
                  Text(tf.format(date), style: const TextStyle(fontSize: 14)),
                ],
              ),
            ] else
              const Text('Scheduled time unknown', style: TextStyle(fontStyle: FontStyle.italic)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () async {
              await NotificationService.cancelReminder(r.id);
              if (mounted) {
                Navigator.pop(context);
                _loadPendingReminders();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
            ),
            child: const Text('Cancel Reminder'),
          ),
        ],
      ),
    );
  }

  // ─── Education Tab ─────────────────────────────────────────────────────────

  Widget _buildEducationTab() {
    const articles = [
      Article(
        icon: Icons.local_hospital_rounded,
        color: AppColors.danger,
        title: 'What is Melanoma?',
        description:
            'Learn the key characteristics of melanoma, the most serious type of skin cancer, including ABCDE criteria.',
        content: 'Melanoma is the most serious type of skin cancer because it has a high tendency to spread to other parts of the body if not caught early.\n\nIt develops in the cells (melanocytes) that produce melanin — the pigment that gives your skin its color.\n\nThe most important warning sign of melanoma is a new spot on the skin or a spot that is changing in size, shape, or color.\n\nRemember the ABCDE rule:\n\n• Asymmetry: One half of a mole or birthmark does not match the other.\n\n• Border: The edges are irregular, ragged, notched, or blurred.\n\n• Color: The color is not the same all over and may include different shades of brown or black, or sometimes with patches of pink, red, white, or blue.\n\n• Diameter: The spot is larger than 6 millimeters across (about the size of a pencil eraser), although melanomas can sometimes be smaller than this.\n\n• Evolving: The mole is changing in size, shape, or color.',
      ),
      Article(
        icon: Icons.wb_sunny_rounded,
        color: AppColors.warning,
        title: 'Prevention Tips',
        description:
            'Practical steps to reduce UV exposure: sunscreen, protective clothing, shade-seeking, and regular self-checks.',
        content: 'Skin cancer is one of the most preventable types of cancer. The key is to protect your skin from the sun\'s harmful ultraviolet (UV) rays.\n\nHere are some essential prevention tips:\n\n• Seek shade: Avoid the sun during peak hours, typically between 10 a.m. and 4 p.m., when the sun\'s rays are strongest.\n\n• Wear protective clothing: Cover up with long-sleeved shirts, pants, a wide-brimmed hat, and sunglasses with UV protection.\n\n• Use sunscreen: Apply a broad-spectrum, water-resistant sunscreen with an SPF of 30 or higher. Reapply every two hours, or after swimming or sweating.\n\n• Avoid tanning beds: UV radiation from tanning beds can cause skin cancer and premature skin aging.\n\n• Perform regular self-exams: Check your skin head-to-toe once a month for any new or changing spots.\n\n• Get checked: Visit a dermatologist for a professional skin exam annually, or sooner if you notice anything suspicious.',
      ),
      Article(
        icon: Icons.medical_services_rounded,
        color: AppColors.secondary,
        title: 'When to Visit a Doctor?',
        description:
            'Identify warning signs that require an immediate dermatologist visit: rapid growth, bleeding, or ulceration.',
        content: 'It is crucial to consult a dermatologist if you notice any unusual changes in your skin.\n\nSchedule an appointment if a mole or spot:\n\n• Is changing quickly: Rapid growth in size, changing shape, or darkening in color.\n\n• Looks different: The "Ugly Duckling" sign - a mole that looks completely different from the other moles on your body.\n\n• Is bleeding or oozing: A mole that bleeds easily, oozes, or crusts over.\n\n• Is itchy or painful: Any lesion that causes discomfort, pain, or persistent itching.\n\n• Won\'t heal: A sore that does not heal within a few weeks, or heals and then returns.\n\nEarly detection is the most important factor in successfully treating skin cancer. Do not wait to get checked if you are concerned.',
      ),
      Article(
        icon: Icons.info_rounded,
        color: AppColors.accent,
        title: 'Understanding Risk Levels',
        description:
            'How DermaScann AI classifies lesions and what each risk level means for your follow-up actions.',
        content: 'DermaScan uses advanced AI to analyze images of skin lesions and estimate their risk level based on visual characteristics. However, remember this is a screening tool, not a diagnostic one.\n\nRisk Level Meanings:\n\n• Low Risk (Green): The lesion has benign characteristics typical of a normal mole or freckle. Continue regular monthly self-checks.\n\n• Medium Risk (Yellow/Orange): The lesion shows some atypical features that warrant closer attention. It is recommended to consult a dermatologist for a professional evaluation.\n\n• High Risk (Red): The lesion has significant features commonly associated with skin cancer, such as high asymmetry, irregular borders, or multiple colors. Urgent medical attention from a dermatologist is required for a biopsy and definitive diagnosis.\n\nAlways err on the side of caution. If your instinct tells you something is wrong, see a doctor regardless of the AI result.',
      ),
    ];

    return ListView(
      padding: const EdgeInsets.all(20),
      children: articles.map((a) => _articleCard(a)).toList(),
    );
  }

  Widget _articleCard(Article article) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(
        context,
        AppRoutes.articleDetail,
        arguments: {'article': article},
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.divider),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: article.color.withValues(alpha: 0.12),
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
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Theme.of(context).brightness == Brightness.dark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded,
                color: AppColors.getAdaptiveTextMuted(context), size: 20),
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
        color: Theme.of(context).cardTheme.color,
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
              Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 16)),
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
        Icon(icon, color: AppColors.getAdaptiveTextMuted(context), size: 18),
        const SizedBox(width: 10),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
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
          color: Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.divider),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: textColor ?? Theme.of(context).colorScheme.onSurface,
                  fontSize: 15,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Icon(Icons.chevron_right_rounded,
                color: AppColors.getAdaptiveTextMuted(context), size: 20),
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
          color: AppColors.primary.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: AppColors.primary, size: 18),
      ),
      title: Text(label, style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontSize: 15)),
      value: value,
      onChanged: onChanged,
      activeThumbColor: AppColors.primary,
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
            onPressed: () async {
              Navigator.pop(context);
              try {
                if (!mounted) return;
                await context.read<AuthService>().deleteAccount();
                if (!mounted) return;
                Navigator.pushReplacementNamed(context, AppRoutes.auth);
                _showStub('Account successfully deleted.');
              } catch (e) {
                _showStub(e.toString().replaceAll('Exception: ', ''));
              }
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
  
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 85,
    );

    if (image != null && mounted) {
      try {
        _showStub('Uploading image...');
        final auth = context.read<AuthService>();
        await auth.uploadAvatar(image.path);
        _showStub('Profile picture updated!');
      } catch (e) {
        _showStub('Upload failed: $e');
      }
    }
  }


  void _showStub(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}


