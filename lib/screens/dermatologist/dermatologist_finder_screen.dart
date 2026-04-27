import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:geolocator/geolocator.dart';
import '../../theme/app_theme.dart';
import '../../widgets/primary_button.dart';

class DermatologistFinderScreen extends StatefulWidget {
  const DermatologistFinderScreen({super.key});

  @override
  State<DermatologistFinderScreen> createState() => _DermatologistFinderScreenState();
}

class _DermatologistFinderScreenState extends State<DermatologistFinderScreen> {
  final TextEditingController _cityController = TextEditingController();
  bool _isLoadingLocation = false;

  @override
  void dispose() {
    _cityController.dispose();
    super.dispose();
  }

  Future<void> _openMapSearch(String query) async {
    final Uri url = Uri.parse('https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(query)}');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open map.')),
        );
      }
    }
  }

  Future<void> _findNearMe() async {
    setState(() => _isLoadingLocation = true);
    
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Location services are disabled. Please enable them in your device settings.');
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permissions are denied');
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        throw Exception('Location permissions are permanently denied, we cannot request permissions.');
      } 

      Position position = await Geolocator.getCurrentPosition();
      // Use coordinates to search nearby
      final String query = 'dermatologist near ${position.latitude},${position.longitude}';
      await _openMapSearch(query);

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            action: SnackBarAction(
              label: 'Settings',
              onPressed: () => Geolocator.openLocationSettings(),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingLocation = false);
      }
    }
  }

  void _searchByCity() {
    final city = _cityController.text.trim();
    if (city.isEmpty) return;
    _openMapSearch('dermatologist in $city');
  }

  Future<void> _callHotline() async {
    final Uri url = Uri.parse('tel:911'); // Example hotline
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open dialer.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Find a Dermatologist'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header illustration
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.05),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.person_search_rounded,
                size: 80,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 32),
            
            Text(
              'Get a Professional Opinion',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'We recommend consulting a certified dermatologist for any concerning skin lesions.',
              style: TextStyle(color: AppColors.getAdaptiveTextSecondary(context)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 48),

            // Near Me
            PrimaryButton(
              onPressed: _isLoadingLocation ? () {} : _findNearMe,
              label: _isLoadingLocation ? 'Locating...' : 'Find Near Me',
              icon: _isLoadingLocation ? null : Icons.my_location_rounded,
            ),
            
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Row(
                children: [
                  Expanded(child: Divider()),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text('OR', style: TextStyle(color: Colors.grey)),
                  ),
                  Expanded(child: Divider()),
                ],
              ),
            ),

            // Search by City
            TextField(
              controller: _cityController,
              decoration: InputDecoration(
                hintText: 'Enter city or zip code',
                prefixIcon: const Icon(Icons.location_city_rounded),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search_rounded),
                  onPressed: _searchByCity,
                ),
              ),
              onSubmitted: (_) => _searchByCity(),
            ),
            const SizedBox(height: 16),
            PrimaryButton(
              onPressed: _searchByCity,
              label: 'Search by City/Zip',
              icon: Icons.search_rounded,
            ),
            
            const SizedBox(height: 48),

            // Emergency / Hotline card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.riskHigh.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.riskHigh.withValues(alpha: 0.3)),
              ),
              child: Column(
                children: [
                  const Icon(Icons.emergency_rounded, color: AppColors.riskHigh, size: 32),
                  const SizedBox(height: 12),
                  const Text(
                    'High Risk or Changing Lesion?',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.riskHigh,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'If you notice rapid changes, bleeding, or have immediate concerns, please seek medical attention right away.',
                    style: TextStyle(color: AppColors.getAdaptiveTextSecondary(context), fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _callHotline,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.riskHigh,
                      foregroundColor: Colors.white,
                    ),
                    icon: const Icon(Icons.phone_rounded),
                    label: const Text('Call Helpline'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
