import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

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
        child: Column(
          children: [
            // ── Dark header — always tall enough to contain its content ──────
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF6F1D3A), Color(0xFF993556)],
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: Padding(
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
                    ],
                  ),
                ),
              ),
            ),
            // ── Light scrollable form section ─────────────────────────────
            Expanded(
              child: Container(
                color: const Color(0xFFF7F4F1),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 28),
                  child: Column(
                    children: [
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
                                  prefixIcon:
                                      Icon(Icons.alternate_email_rounded),
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
                              const SizedBox(height: 20),
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
                      const SizedBox(height: 16),
                      _EmergencyButton(),
                    ],
                  ),
                ),
              ),
            ),
          ],
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
                      ? 'Maternal Health Companion'
                      : 'Clinic Dashboard',
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

class _EmergencyButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: () => showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => const _EmergencySheet(),
      ),
      icon: const Icon(
        Icons.emergency_rounded,
        size: 18,
        color: Color(0xFFD1423B),
      ),
      label: Text(
        'Emergency? Get help without signing in',
        style: GoogleFonts.nunito(
          color: const Color(0xFFD1423B),
          fontWeight: FontWeight.w700,
          fontSize: 13.5,
        ),
      ),
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: Color(0xFFD1423B), width: 1.5),
        backgroundColor: const Color(0xFFD1423B).withValues(alpha: 0.06),
        foregroundColor: const Color(0xFFD1423B),
        minimumSize: const Size.fromHeight(48),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
      ),
    );
  }
}

class _EmergencySheet extends StatelessWidget {
  const _EmergencySheet();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 36),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE0D0D5),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFD1423B).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.emergency_rounded,
                  color: Color(0xFFD1423B),
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Emergency Contacts',
                      style: GoogleFonts.nunito(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      'Call immediately — no account needed.',
                      style: GoogleFonts.nunito(
                        color: const Color(0xFF655B61),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          _EmergencyContactTile(
            icon: Icons.local_hospital_rounded,
            label: 'National Emergency',
            number: '999',
            description: 'Police, Fire, Ambulance',
            color: const Color(0xFFD1423B),
          ),
          const SizedBox(height: 12),
          _EmergencyContactTile(
            icon: Icons.pregnant_woman_rounded,
            label: 'Maternal Helpline',
            number: '16743',
            description: 'DGHS maternal health hotline',
            color: const Color(0xFF993556),
          ),
          const SizedBox(height: 12),
          _EmergencyContactTile(
            icon: Icons.medical_services_rounded,
            label: 'Health Helpline',
            number: '16767',
            description: 'DGHS 24/7 health support',
            color: const Color(0xFF197A5B),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF3E0),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color: const Color(0xFFFFB74D).withValues(alpha: 0.5)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline_rounded,
                    color: Color(0xFFB17616), size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Warning signs: heavy bleeding, severe headache, blurred vision, no fetal movement, convulsions.',
                    style: GoogleFonts.nunito(
                      fontSize: 12.5,
                      color: const Color(0xFF7A5210),
                      height: 1.45,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () async {
              final uri = Uri.parse(
                'https://www.google.com/maps/search/government+maternal+hospital+near+me',
              );
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              }
            },
            icon: const Icon(Icons.map_rounded, size: 18),
            label: Text(
              'Find Nearest Clinic',
              style: GoogleFonts.nunito(fontWeight: FontWeight.w800),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF197A5B),
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmergencyContactTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String number;
  final String description;
  final Color color;

  const _EmergencyContactTile({
    required this.icon,
    required this.label,
    required this.number,
    required this.description,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.nunito(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
                Text(
                  description,
                  style: GoogleFonts.nunito(
                    color: const Color(0xFF8A7A80),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Text(
            number,
            style: GoogleFonts.nunito(
              color: color,
              fontWeight: FontWeight.w900,
              fontSize: 22,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }
}
