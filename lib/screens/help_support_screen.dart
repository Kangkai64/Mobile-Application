import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  Future<void> _callSupport(BuildContext context) async {
    // Try multiple phone number formats
    final List<String> phoneNumbers = [
      '+60362633933',
      'tel:+60362633933',
      'tel:60362633933',
      'tel:+603-6263-3933',
    ];
    
    for (String phone in phoneNumbers) {
      try {
        print('Attempting to call: $phone');
        final Uri uri = Uri.parse(phone);
        
        // Try different launch modes
        final bool launched = await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
        
        print('Launch result for $phone: $launched');
        
        if (launched) {
          return; // Success, exit function
        }
      } catch (e) {
        print('Error launching $phone: $e');
      }
    }
    
    // If all attempts failed
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to open dialer. Please call +603-6263-3933 manually.'),
          duration: Duration(seconds: 5),
        ),
      );
    }
  }

  Future<void> _emailSupport(BuildContext context) async {
    // Try multiple email formats and launch modes
    final List<LaunchMode> launchModes = [
      LaunchMode.externalApplication,
      LaunchMode.externalNonBrowserApplication,
      LaunchMode.platformDefault,
    ];
    
    for (LaunchMode mode in launchModes) {
      try {
        final Uri uri = Uri.parse('mailto:admin@greenstem.com.my');
        print('Attempting to email with mode $mode: ${uri.toString()}');
        
        final bool launched = await launchUrl(
          uri,
          mode: mode,
        );
        
        print('Email launch result with mode $mode: $launched');
        
        if (launched) {
          return; // Success, exit function
        }
      } catch (e) {
        print('Error launching email with mode $mode: $e');
      }
    }
    
    // If all attempts failed
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to open email app. Please email admin@greenstem.com.my manually.'),
          duration: Duration(seconds: 5),
        ),
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
              textAlign: TextAlign.justify,
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
                    subtitle: const Text('(6)03-6263-3933'),
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


