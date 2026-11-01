import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../providers/auth_provider.dart';
import '../../../shared/widgets/app_button.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});
  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _pass = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() { _email.dispose(); _pass.dispose(); super.dispose(); }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    await ref.read(authProvider.notifier).signIn(email: _email.text, password: _pass.text);
    final err = ref.read(authProvider).error;
    if (err != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(err), backgroundColor: AppColors.danger));
    }
  }

  @override
  Widget build(BuildContext context) {
    final loading = ref.watch(authProvider).isLoading;
    return ClayScaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _form,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const SizedBox(height: 40),
              Center(
                child: Image.asset('assets/images/hero_login.png',
                    height: 170,
                    errorBuilder: (_, __, ___) => const SizedBox(height: 170)),
              ).animate().scale(duration: 500.ms, curve: Curves.easeOutBack),
              const SizedBox(height: 24),
              const Text('Welcome back', style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w800))
                  .animate().fadeIn(delay: 100.ms).slideX(begin: -0.2),
              const SizedBox(height: 6),
              const Text('Sign in to continue your studies', style: TextStyle(color: AppColors.darkMuted, fontSize: 15))
                  .animate().fadeIn(delay: 150.ms),
              const SizedBox(height: 36),
              _Field(controller: _email, label: 'Email', hint: 'your@email.com',
                keyboardType: TextInputType.emailAddress,
                validator: (v) => v!.contains('@') ? null : 'Enter valid email'),
              const SizedBox(height: 16),
              _Field(controller: _pass, label: 'Password', hint: '••••••••',
                obscure: _obscure,
                suffix: IconButton(icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility, color: AppColors.darkMuted, size: 20),
                  onPressed: () => setState(() => _obscure = !_obscure)),
                validator: (v) => (v?.length ?? 0) >= 6 ? null : 'Min 6 characters'),
              const SizedBox(height: 8),
              Align(alignment: Alignment.centerRight,
                child: TextButton(onPressed: () => context.go('/forgot-password'),
                  child: const Text('Forgot password?', style: TextStyle(color: AppColors.primary)))),
              const SizedBox(height: 24),
              AppButton(label: 'Sign In', loading: loading, onTap: _submit)
                  .animate().fadeIn(delay: 300.ms),
              const SizedBox(height: 20),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Text("Don't have an account? ", style: TextStyle(color: AppColors.darkMuted)),
                GestureDetector(onTap: () => context.go('/register'),
                  child: const Text('Sign Up', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700))),
              ]),
            ]),
          ),
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String label, hint;
  final bool obscure;
  final Widget? suffix;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  const _Field({required this.controller, required this.label, required this.hint,
    this.obscure = false, this.suffix, this.keyboardType, this.validator});
  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
      const SizedBox(height: 8),
      TextFormField(
        controller: controller, obscureText: obscure,
        keyboardType: keyboardType, validator: validator,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(hintText: hint, suffixIcon: suffix),
      ),
    ]);
  }
}
