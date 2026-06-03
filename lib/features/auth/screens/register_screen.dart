import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../providers/auth_provider.dart';
import '../../../data/models/models.dart';
import '../../../shared/widgets/app_button.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});
  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _pass = TextEditingController();
  UserRole _role = UserRole.student;
  bool _obscure = true;

  @override
  void dispose() { _name.dispose(); _email.dispose(); _pass.dispose(); super.dispose(); }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    await ref.read(authProvider.notifier).signUp(
      email: _email.text, password: _pass.text,
      fullName: _name.text.trim(), role: _role);
    final err = ref.read(authProvider).error;
    if (err != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(err), backgroundColor: AppColors.danger));
    }
  }

  @override
  Widget build(BuildContext context) {
    final loading = ref.watch(authProvider).isLoading;
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _form,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const SizedBox(height: 20),
              GestureDetector(onTap: () => context.go('/login'),
                child: const Icon(Icons.arrow_back, color: Colors.white)),
              const SizedBox(height: 24),
              const Text('Create Account', style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w800)),
              const SizedBox(height: 6),
              const Text('Join StudyLock today', style: TextStyle(color: AppColors.darkMuted, fontSize: 15)),
              const SizedBox(height: 32),
              _buildRolePicker(),
              const SizedBox(height: 20),
              _label('Full Name'),
              TextFormField(controller: _name, style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(hintText: 'Your full name'),
                validator: (v) => (v?.trim().length ?? 0) > 2 ? null : 'Enter your name'),
              const SizedBox(height: 16),
              _label('Email'),
              TextFormField(controller: _email, style: const TextStyle(color: Colors.white),
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(hintText: 'your@email.com'),
                validator: (v) => v!.contains('@') ? null : 'Enter valid email'),
              const SizedBox(height: 16),
              _label('Password'),
              TextFormField(controller: _pass, obscureText: _obscure,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(hintText: '••••••••',
                  suffixIcon: IconButton(
                    icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility, color: AppColors.darkMuted, size: 20),
                    onPressed: () => setState(() => _obscure = !_obscure))),
                validator: (v) => (v?.length ?? 0) >= 6 ? null : 'Min 6 characters'),
              const SizedBox(height: 28),
              AppButton(label: 'Create Account', loading: loading, onTap: _submit),
              const SizedBox(height: 20),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Text('Already have an account? ', style: TextStyle(color: AppColors.darkMuted)),
                GestureDetector(onTap: () => context.go('/login'),
                  child: const Text('Sign In', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700))),
              ]),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _buildRolePicker() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _label('I am a'),
      const SizedBox(height: 8),
      // Only allow student and lecturer roles during public signup
      // Admin accounts must be created by existing admins only
      Row(children: [UserRole.student, UserRole.lecturer].map((r) {
        final selected = _role == r;
        return Expanded(child: GestureDetector(
          onTap: () => setState(() => _role = r),
          child: Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: selected ? AppColors.primary.withValues(alpha: 0.2) : AppColors.darkCard,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: selected ? AppColors.primary : AppColors.darkBorder, width: selected ? 1.5 : 1),
            ),
            child: Column(children: [
              Icon(r == UserRole.student ? Icons.school : r == UserRole.lecturer ? Icons.person_outline : Icons.admin_panel_settings_outlined,
                color: selected ? AppColors.primary : AppColors.darkMuted, size: 22),
              const SizedBox(height: 4),
              Text(r.name[0].toUpperCase() + r.name.substring(1),
                style: TextStyle(color: selected ? AppColors.primary : AppColors.darkMuted, fontSize: 12, fontWeight: FontWeight.w600)),
            ]),
          ),
        ));
      }).toList()),
    ]);
  }

  Widget _label(String t) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(t, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)));
}
