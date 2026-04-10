import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../blocs/auth/auth_bloc.dart';
import '../../demo/demo_repository.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  DemoRole _selectedRole = DemoRole.mother;
  bool _obscure = true;

  @override
  void initState() {
    super.initState();
    _fillAccountDefaults();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _fillAccountDefaults() {
    _emailController.text = _selectedRole == DemoRole.mother
        ? 'mother.nusrat@maternify.app'
        : 'doctor.fatema@maternify.app';
    _passwordController.text = 'Maternify@123';
  }

  // Pre-fills credentials silently so the sign-in flow works in demo without
  // exposing "Auto fill" in the UI.

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    context.read<AuthBloc>().add(
          AuthEmailSignInRequested(
            email: _emailController.text.trim(),
            password: _passwordController.text.trim(),
            role: _selectedRole,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                behavior: SnackBarBehavior.floating,
                backgroundColor: const Color(0xFFE24B4A),
                content: Text(state.message),
              ),
            );
          }
        },
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF6F1D3A),
                Color(0xFF993556),
                Color(0xFFF7F4F1),
              ],
              stops: [0, 0.34, 0.34],
            ),
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 22, 24, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Maternify',
                    style: GoogleFonts.nunito(
                      color: Colors.white,
                      fontSize: 34,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Bangla-first maternal monitoring for the critical days between clinic visits.',
                    style: GoogleFonts.nunito(
                      color: Colors.white.withValues(alpha: 0.88),
                      fontSize: 14,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _HeroStatusCard(role: _selectedRole),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 24,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Sign in',
                            style: GoogleFonts.nunito(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Choose your role to continue to your care dashboard.',
                            style: GoogleFonts.nunito(
                              color: const Color(0xFF655B61),
                              fontSize: 13,
                              height: 1.45,
                            ),
                          ),
                          const SizedBox(height: 18),
                          _RolePicker(
                            selectedRole: _selectedRole,
                            onChanged: (role) {
                              setState(() {
                                _selectedRole = role;
                                _fillAccountDefaults();
                              });
                            },
                          ),
                          const SizedBox(height: 18),
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: const InputDecoration(
                              labelText: 'Email',
                              prefixIcon: Icon(Icons.alternate_email_rounded),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Enter your email address.';
                              }
                              if (!value.contains('@')) {
                                return 'Enter a valid email address.';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscure,
                            decoration: InputDecoration(
                              labelText: 'Password',
                              prefixIcon:
                                  const Icon(Icons.lock_outline_rounded),
                              suffixIcon: IconButton(
                                onPressed: () =>
                                    setState(() => _obscure = !_obscure),
                                icon: Icon(
                                  _obscure
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                ),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Enter your password.';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 14),
                          const SizedBox(height: 6),
                          BlocBuilder<AuthBloc, AuthState>(
                            builder: (context, state) {
                              final isLoading = state is AuthLoading;
                              return ElevatedButton(
                                onPressed: isLoading ? null : _submit,
                                child: isLoading
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2.2,
                                        ),
                                      )
                                    : Text(
                                        _selectedRole == DemoRole.mother
                                            ? 'Continue as Mother'
                                            : 'Continue as Clinician',
                                      ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: const [
                      _PitchChip(label: 'ব্যক্তিগত মাতৃত্ব রেকর্ড'),
                      _PitchChip(label: 'বাংলা AI ট্রায়েজ'),
                      _PitchChip(label: 'জরুরি SOS সহায়তা'),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HeroStatusCard extends StatelessWidget {
  final DemoRole role;

  const _HeroStatusCard({required this.role});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  role == DemoRole.mother
                      ? Icons.favorite_border
                      : Icons.monitor_heart_outlined,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  role == DemoRole.mother
                      ? 'আপনার মাতৃস্বাস্থ্য সঙ্গী'
                      : 'ক্লিনিক ড্যাশবোর্ড',
                  style: GoogleFonts.nunito(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            role == DemoRole.mother
                ? 'Track daily vitals, report symptoms in Bangla, and get urgent guidance when needed.'
                : 'Review patient risk status, monitor alerts, and respond quickly to urgent maternal cases.',
            style: GoogleFonts.nunito(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 13,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

class _RolePicker extends StatelessWidget {
  final DemoRole selectedRole;
  final ValueChanged<DemoRole> onChanged;

  const _RolePicker({
    required this.selectedRole,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF4ECEF),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Expanded(
            child: _RoleSegment(
              selected: selectedRole == DemoRole.mother,
              icon: Icons.pregnant_woman_outlined,
              label: 'Mother',
              onTap: () => onChanged(DemoRole.mother),
            ),
          ),
          Expanded(
            child: _RoleSegment(
              selected: selectedRole == DemoRole.doctor,
              icon: Icons.medical_services_outlined,
              label: 'Doctor',
              onTap: () => onChanged(DemoRole.doctor),
            ),
          ),
        ],
      ),
    );
  }
}

class _RoleSegment extends StatelessWidget {
  final bool selected;
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _RoleSegment({
    required this.selected,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color:
                  selected ? const Color(0xFF993556) : const Color(0xFF7A6570),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.nunito(
                fontWeight: FontWeight.w800,
                color: selected
                    ? const Color(0xFF993556)
                    : const Color(0xFF7A6570),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PitchChip extends StatelessWidget {
  final String label;

  const _PitchChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: GoogleFonts.nunito(
          fontWeight: FontWeight.w700,
          color: const Color(0xFF5A4650),
        ),
      ),
    );
  }
}
