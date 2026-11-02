import 'package:flutter/material.dart';
import '../services/url_launcher_service.dart';
import '../core/theme/app_colors.dart';

/// Reusable "Get it now" button for app posts
/// Handles Play Store URL validation and launching
class GetItNowButtonWidget extends StatefulWidget {
  final String playStoreUrl;
  final VoidCallback? onSuccess;
  final Function(String)? onError;
  final String buttonText;
  final bool isLoading;

  const GetItNowButtonWidget({
    super.key,
    required this.playStoreUrl,
    this.onSuccess,
    this.onError,
    this.buttonText = 'Get it now',
    this.isLoading = false,
  });

  @override
  State<GetItNowButtonWidget> createState() => _GetItNowButtonWidgetState();
}

class _GetItNowButtonWidgetState extends State<GetItNowButtonWidget> {
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _isLoading = widget.isLoading;
  }

  Future<void> _handleOpenPlayStore() async {
    // Validate URL first
    if (!UrlLauncherService.isValidPlayStoreUrl(widget.playStoreUrl)) {
      _showErrorDialog('Invalid Play Store URL',
          'The app link is not valid. Please contact the administrator.');
      widget.onError?.call('Invalid Play Store URL format');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final success =
          await UrlLauncherService.openPlayStoreUrl(widget.playStoreUrl, context);

      if (!mounted) return;

      setState(() => _isLoading = false);

      if (success) {
        widget.onSuccess?.call();
        _showSuccessSnackBar('Opening Play Store...');
      } else {
        _showErrorDialog('Cannot Open Link',
            'Unable to open the Play Store link. Please try again.');
        widget.onError?.call('Failed to open Play Store URL');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showErrorDialog('Error', 'An error occurred: ${e.toString()}');
      widget.onError?.call(e.toString());
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 12),
            Text(message),
          ],
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _isLoading ? null : _handleOpenPlayStore,
        icon: _isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor:
                      AlwaysStoppedAnimation<Color>(AppColors.cyan),
                ),
              )
            : const Icon(Icons.shopping_bag),
        label: Text(
          _isLoading ? 'Opening...' : widget.buttonText,
          style: Theme.of(context).textTheme.labelLarge,
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.cyan,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }
}
