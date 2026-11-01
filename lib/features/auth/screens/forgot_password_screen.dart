import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../providers/auth_provider.dart';
import '../../../shared/widgets/app_button.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});
  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _email = TextEditingController();
  bool _sent = false, _loading = false;

  Future<void> _submit() async {
    if (_email.text.trim().isEmpty) return;
    setState(() => _loading = true);
    try {
      await ref.read(authProvider.notifier).forgotPassword(_email.text);
      if (mounted) setState(() { _sent = true; _loading = false; });
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: AppColors.danger));
      }
    }
  }

  @override
  void dispose() { _email.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return ClayScaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(backgroundColor: Colors.transparent,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: () => context.go('/login'))),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: _sent ? Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.mark_email_read_outlined, size: 72, color: AppColors.success),
          const SizedBox(height: 24),
          const Text('Check your email', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          Text('We sent a reset link to ${_email.text}', style: const TextStyle(color: AppColors.darkMuted, fontSize: 15), textAlign: TextAlign.center),
          const SizedBox(height: 32),
          AppButton(label: 'Back to Login', onTap: () => context.go('/login')),
        ]) : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const SizedBox(height: 20),
          const Text('Forgot Password', style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          const Text("Enter your email and we'll send a reset link.", style: TextStyle(color: AppColors.darkMuted)),
          const SizedBox(height: 32),
          const Text('Email', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          TextField(controller: _email, keyboardType: TextInputType.emailAddress,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(hintText: 'your@email.com')),
          const SizedBox(height: 24),
          AppButton(label: 'Send Reset Link', loading: _loading, onTap: _submit),
        ]),
      ),
    );
  }
}
