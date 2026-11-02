import 'package:flutter/material.dart';
import '../services/url_launcher_service.dart';

/// Widget for safely handling external links (articles, jobs)
class PostLinkHandlerWidget extends StatefulWidget {
  final String url;
  final String label;
  final IconData icon;
  final VoidCallback? onSuccess;
  final Function(String)? onError;

  const PostLinkHandlerWidget({
    super.key,
    required this.url,
    required this.label,
    this.icon = Icons.open_in_new,
    this.onSuccess,
    this.onError,
  });

  @override
  State<PostLinkHandlerWidget> createState() => _PostLinkHandlerWidgetState();
}

class _PostLinkHandlerWidgetState extends State<PostLinkHandlerWidget> {
  bool _isLoading = false;

  Future<void> _handleOpenUrl() async {
    // Validate URL
    if (!UrlLauncherService.isValidHttpsUrl(widget.url)) {
      _showErrorDialog('Invalid URL',
          'The link format is not valid. Please contact the administrator.');
      widget.onError?.call('Invalid URL format');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final success = await UrlLauncherService.openExternalUrl(widget.url, context);

      if (!mounted) return;

      setState(() => _isLoading = false);

      if (success) {
        widget.onSuccess?.call();
        _showSuccessSnackBar('Opening link...');
      } else {
        _showErrorDialog('Cannot Open Link',
            'Unable to open this link. Please try again.');
        widget.onError?.call('Failed to open URL');
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
        onPressed: _isLoading ? null : _handleOpenUrl,
        icon: _isLoading
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Theme.of(context).primaryColor,
                  ),
                ),
              )
            : Icon(widget.icon),
        label: Text(
          _isLoading ? 'Opening...' : widget.label,
          style: Theme.of(context).textTheme.labelLarge,
        ),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }
}
