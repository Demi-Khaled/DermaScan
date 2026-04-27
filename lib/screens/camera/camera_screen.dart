import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../services/ai_service.dart';
import '../../routing/app_router.dart';
import '../../widgets/primary_button.dart';
import '../../services/sync_service.dart';
import '../../services/auth_service.dart';

class CameraScreen extends StatefulWidget {
  final String? existingLesionId;
  const CameraScreen({super.key, this.existingLesionId});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen>
    with WidgetsBindingObserver {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  bool _isInitialized = false;
  bool _hasError = false;
  XFile? _capturedFile;
  bool _isAnalyzing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras == null || _cameras!.isEmpty) {
        setState(() => _hasError = true);
        return;
      }
      _controller = CameraController(
        _cameras!.first,
        ResolutionPreset.high,
        enableAudio: false,
      );
      await _controller!.initialize();
      if (mounted) setState(() => _isInitialized = true);
    } catch (e) {
      if (mounted) setState(() => _hasError = true);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_controller == null || !_controller!.value.isInitialized) return;
    if (state == AppLifecycleState.inactive) {
      _controller!.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initCamera();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _capture() async {
    if (_controller == null || !_controller!.value.isInitialized) return;
    try {
      final file = await _controller!.takePicture();
      setState(() => _capturedFile = file);
    } catch (_) {}
  }

  Future<void> _analyze() async {
    if (_capturedFile == null) return;
    final auth = context.read<AuthService>();
    final aiService = context.read<AiService>();
    setState(() => _isAnalyzing = true);
    try {
      final result = await aiService.analyzeLesion(
        File(_capturedFile!.path),
        token: auth.token,
      );
      if (!mounted) return;
      Navigator.pushReplacementNamed(
        context,
        AppRoutes.analysisResult,
        arguments: {
          'result': result,
          'imagePath': _capturedFile!.path,
          'existingLesionId': widget.existingLesionId,
        },
      );
    } catch (e) {
      if (!mounted) return;
      
      // Offer to queue for offline sync
      _showOfflineOption();
    } finally {
      if (mounted) setState(() => _isAnalyzing = false);
    }
  }

  void _showOfflineOption() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_rounded, color: AppColors.warning, size: 48),
            const SizedBox(height: 16),
            const Text(
              'Analysis Offline',
              style: AppTextStyles.h2,
            ),
            const SizedBox(height: 8),
            const Text(
              'We couldn\'t connect to our AI server. Would you like to save this photo and analyze it automatically once you\'re back online?',
              textAlign: TextAlign.center,
              style: AppTextStyles.caption,
            ),
            const SizedBox(height: 24),
            PrimaryButton(
              label: 'Save & Sync Later',
              onPressed: () async {
                await SyncService.queueScan(_capturedFile!.path);
                if (!mounted) return;
                Navigator.pop(context); // close sheet
                Navigator.pop(context); // back to home
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Photo saved! We\'ll analyze it when you have internet.'),
                    backgroundColor: AppColors.primary,
                  ),
                );
              },
              icon: Icons.sync_rounded,
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Try Again Later', style: TextStyle(color: AppColors.textMuted)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_capturedFile != null) return _buildPreview();
    return _buildCamera();
  }

  Widget _buildCamera() {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Camera preview
          if (_isInitialized && _controller != null)
            SizedBox.expand(child: CameraPreview(_controller!))
          else if (_hasError)
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.no_photography_rounded,
                      color: Colors.white54, size: 64),
                  const SizedBox(height: 12),
                  const Text(
                    'Camera unavailable\n(running in emulator?)',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white60, fontSize: 15),
                  ),
                  const SizedBox(height: 20),
                  OutlinedButton(
                    onPressed: _useDemoImage,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white38),
                    ),
                    child: const Text('Use Demo Image'),
                  ),
                ],
              ),
            )
          else
            const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),

          // Guide frame overlay
          if (_isInitialized)
            Center(
              child: Container(
                width: 260,
                height: 260,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white, width: 1.5),
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),

          // Top bar
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  _circleBtn(Icons.close_rounded, () => Navigator.pop(context)),
                  const Expanded(
                    child: Center(
                      child: Text(
                        'New Scan',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 44),
                ],
              ),
            ),
          ),

          // Tip bubble
          if (_isInitialized)
            Positioned(
              bottom: 150,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  margin: const EdgeInsets.symmetric(horizontal: 40),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.wb_sunny_outlined,
                          color: Colors.amber, size: 18),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          'Use good lighting and hold steady',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.90),
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Capture button
          Positioned(
            bottom: 48,
            left: 0,
            right: 0,
            child: Center(
              child: GestureDetector(
                onTap: _isInitialized ? _capture : null,
                child: Container(
                  width: 76,
                  height: 76,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    border: Border.all(
                      color: _isInitialized ? Colors.white : Colors.white38,
                      width: 4,
                    ),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withValues(alpha: 0.60),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Container(
                    margin: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _isInitialized ? AppColors.primary : Colors.grey,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreview() {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Image
          SizedBox.expand(
            child: InteractiveViewer(
              child: Image.file(
                File(_capturedFile!.path),
                fit: BoxFit.contain,
              ),
            ),
          ),

          // Top bar
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  _circleBtn(
                    Icons.arrow_back_rounded,
                    () => setState(() => _capturedFile = null),
                  ),
                  const Expanded(
                    child: Center(
                      child: Text(
                        'Preview',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 44),
                ],
              ),
            ),
          ),

          // Bottom actions
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 36),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.85),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  PrimaryButton(
                    label: 'Confirm & Analyze',
                    onPressed: _isAnalyzing ? null : _analyze,
                    isLoading: _isAnalyzing,
                    icon: Icons.analytics_rounded,
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton.icon(
                      onPressed: _isAnalyzing
                          ? null
                          : () => setState(() => _capturedFile = null),
                      icon: const Icon(Icons.refresh_rounded,
                          color: Colors.white70),
                      label: const Text(
                        'Retake',
                        style: TextStyle(color: Colors.white70),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.white38),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _circleBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.45),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white24),
        ),
        child: Icon(icon, color: Colors.white, size: 22),
      ),
    );
  }

  void _useDemoImage() {
    // On emulator use a synthetic demo path which AiService handles gracefully
    setState(() => _capturedFile = XFile('demo_lesion.jpg'));
  }
}
