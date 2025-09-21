import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide LocalStorage;
import '../utils/local_storage.dart';
import '../services/staff_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _staffService = StaffService();
  bool _isSignIn = false;
  bool _isSignUp = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final savedEmail = LocalStorage.getString('user_email');
    if (savedEmail != null && savedEmail.isNotEmpty) {
      _emailController.text = savedEmail;
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _isSignIn = true; _error = null; });
    try {
      // First validate that the email belongs to an active staff member
      final isValidStaff = await _staffService.validateStaffLogin(_emailController.text.trim());
      if (!isValidStaff) {
        setState(() { _error = 'Access denied. Your account may be pending approval.'; });
        return;
      }

      final auth = Supabase.instance.client.auth;
      final response = await auth.signInWithPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      if (response.session != null) {
        await LocalStorage.setString('user_email', _emailController.text.trim());
      }
    } on AuthException catch (e) {
      setState(() { _error = e.message; });
    } catch (e) {
      setState(() { _error = 'Unexpected error, please try again.'; });
    } finally {
      if (mounted) setState(() { _isSignIn = false; });
    }
  }

  Future<void> _requestAccount() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _isSignUp = true; _error = null; });
    try {
      final staff = await _staffService.requestAccount(email: _emailController.text.trim());
      if (!mounted) return;
      if (staff != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Request submitted. You\'ll be notified when approved.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } on AuthException catch (e) {
      setState(() { _error = e.message; });
    } catch (e) {
      setState(() { _error = 'Failed to submit request. Please try again.'; });
    } finally {
      if (mounted) setState(() { _isSignUp = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Image.asset('assets/images/logo.png'),
                const SizedBox(height: 24),
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: const InputDecoration(labelText: 'Email'),
                            validator: (v) => (v == null || v.isEmpty || !v.contains('@')) ? 'Enter a valid email' : null,
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _passwordController,
                            obscureText: true,
                            decoration: const InputDecoration(labelText: 'Password'),
                            validator: (v) => (v == null || v.length < 6) ? 'Min 6 characters' : null,
                          ),
                          if (_error != null) ...[
                            const SizedBox(height: 12),
                            Text(_error!, style: const TextStyle(color: Colors.red)),
                          ],
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: _isSignIn ? null : _signIn,
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                                  child: _isSignIn ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Sign In'),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: _isSignUp ? null : _requestAccount,
                                  child: _isSignUp ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Get Account'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}


