import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  Future<void> _callSupport(BuildContext context) async {
    final Uri uri = Uri(scheme: 'tel', path: '+60362633933');
    final bool canLaunch = await canLaunchUrl(uri);
    if (canLaunch) {
      final bool launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to open dialer on this device.')),
        );
      }
    } else if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No app available to handle phone calls.')),
      );
    }
  }

  Future<void> _emailSupport(BuildContext context) async {
    final Uri uri = Uri(
      scheme: 'mailto',
      path: 'admin@greenstem.com.my',
    );
    final bool canLaunch = await canLaunchUrl(uri);
    if (canLaunch) {
      final bool launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to open email app on this device.')),
        );
      }
    } else if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No email app configured to send email.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color onBg = Theme.of(context).colorScheme.onBackground;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Help & Support'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 8),
            // Logo
            Center(
              child: Image.asset(
                'assets/images/logo.png',
                width: 120,
                height: 120,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 16),
            // Company name and reg
            Text(
              'Greenstem Business Software Sdn Bhd (387389-H)',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: onBg,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            // Tagline / description
            Text(
              "Elevate your business with Greenstem, delivering top-tier web, mobile, and desktop software solutions, including Accounting and Inventory control. Committed to customer satisfaction and continual innovation, we're your dedicated partner for success.",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: onBg.withOpacity(0.8),
                fontSize: 14,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            // Contacts card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Phone row
                  ListTile(
                    leading: const Icon(Icons.call),
                    title: const Text('Technical Support'),
                    subtitle: const Text('(6)03 6263 3933'),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () => _callSupport(context),
                  ),
                  const Divider(height: 1),
                  // Email row
                  ListTile(
                    leading: const Icon(Icons.drafts),
                    title: const Text('admin@greenstem.com.my'),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () => _emailSupport(context),
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


