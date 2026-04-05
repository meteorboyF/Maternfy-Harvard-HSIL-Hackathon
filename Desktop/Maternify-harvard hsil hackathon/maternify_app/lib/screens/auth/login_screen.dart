import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../blocs/auth/auth_bloc.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  static const _primary = Color(0xFF993556);

  final _formKey   = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl  = TextEditingController();
  bool _obscure    = true;
  bool _isDoctor   = false;   // doctor toggle

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  void _prefillDemo() {
    setState(() {
      _emailCtrl.text = _isDoctor ? 'demo.doctor@maternify.app' : 'demo.mother@maternify.app';
      _passCtrl.text  = 'Demo@1234';
    });
  }

  void _submit(BuildContext context) {
    if (!_formKey.currentState!.validate()) return;
    context.read<AuthBloc>().add(AuthEmailSignInRequested(
      email: _emailCtrl.text.trim(),
      password: _passCtrl.text,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: const Color(0xFFE24B4A),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment(0, 0.4),
              colors: [Color(0xFF993556), Color(0xFFBF6080)],
            ),
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // ── Hero area ─────────────────────────────────────────────
                  const SizedBox(height: 48),
                  _LogoHero(),
                  const SizedBox(height: 8),
                  Text(
                    'আপনার সুস্বাস্থ্য, আমাদের অগ্রাধিকার',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.nunito(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 40),

                  // ── White card form ────────────────────────────────────────
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 24),
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Role toggle
                          _RoleToggle(
                            isDoctor: _isDoctor,
                            onChanged: (v) => setState(() => _isDoctor = v),
                          ),
                          const SizedBox(height: 20),

                          // Email
                          TextFormField(
                            controller: _emailCtrl,
                            keyboardType: TextInputType.emailAddress,
                            decoration: InputDecoration(
                              labelText: 'ইমেইল',
                              hintText: 'example@mail.com',
                              prefixIcon: const Icon(Icons.email_outlined, color: _primary),
                            ),
                            validator: (v) {
                              if (v == null || v.isEmpty) return 'ইমেইল লিখুন';
                              if (!v.contains('@')) return 'সঠিক ইমেইল লিখুন';
                              return null;
                            },
                          ),
                          const SizedBox(height: 14),

                          // Password
                          TextFormField(
                            controller: _passCtrl,
                            obscureText: _obscure,
                            decoration: InputDecoration(
                              labelText: 'পাসওয়ার্ড',
                              prefixIcon: const Icon(Icons.lock_outline, color: _primary),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscure ? Icons.visibility_off : Icons.visibility,
                                  color: Colors.grey,
                                ),
                                onPressed: () => setState(() => _obscure = !_obscure),
                              ),
                            ),
                            validator: (v) {
                              if (v == null || v.isEmpty) return 'পাসওয়ার্ড লিখুন';
                              if (v.length < 6) return 'কমপক্ষে ৬ অক্ষর দিন';
                              return null;
                            },
                          ),
                          const SizedBox(height: 8),

                          // Demo prefill hint
                          GestureDetector(
                            onTap: _prefillDemo,
                            child: Text(
                              'Demo: ট্যাপ করুন অটো-ফিল করতে →',
                              style: GoogleFonts.nunito(
                                fontSize: 12,
                                color: _primary,
                                decoration: TextDecoration.underline,
                              ),
                              textAlign: TextAlign.right,
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Sign in button
                          BlocBuilder<AuthBloc, AuthState>(
                            builder: (context, state) {
                              final loading = state is AuthLoading;
                              return ElevatedButton(
                                onPressed: loading ? null : () => _submit(context),
                                child: loading
                                    ? const SizedBox(
                                        height: 22,
                                        width: 22,
                                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                      )
                                    : Text(
                                        _isDoctor ? 'ডাক্তার হিসেবে প্রবেশ' : 'প্রবেশ করুন',
                                        style: GoogleFonts.nunito(fontSize: 16, fontWeight: FontWeight.w700),
                                      ),
                              );
                            },
                          ),
                          const SizedBox(height: 16),

                          // Divider
                          Row(children: [
                            const Expanded(child: Divider()),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              child: Text('অথবা', style: GoogleFonts.nunito(color: Colors.grey, fontSize: 12)),
                            ),
                            const Expanded(child: Divider()),
                          ]),
                          const SizedBox(height: 16),

                          // Google sign-in
                          BlocBuilder<AuthBloc, AuthState>(
                            builder: (context, state) {
                              final loading = state is AuthLoading;
                              return OutlinedButton.icon(
                                onPressed: loading
                                    ? null
                                    : () => context.read<AuthBloc>().add(AuthGoogleSignInRequested()),
                                icon: const _GoogleIcon(),
                                label: Text(
                                  'Google দিয়ে প্রবেশ করুন',
                                  style: GoogleFonts.nunito(
                                    color: Colors.black87,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                style: OutlinedButton.styleFrom(
                                  minimumSize: const Size(double.infinity, 52),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  side: const BorderSide(color: Color(0xFFE0E0E0)),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),
                  Text(
                    'Maternify · Harvard HSIL Hackathon',
                    style: GoogleFonts.nunito(color: Colors.white54, fontSize: 11),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Hero logo ─────────────────────────────────────────────────────────────────

class _LogoHero extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: const Center(
            child: Text('🤱', style: TextStyle(fontSize: 40)),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Maternify',
          style: GoogleFonts.nunito(
            fontSize: 36,
            fontWeight: FontWeight.w800,
            color: Colors.white,
            letterSpacing: -0.5,
          ),
        ),
      ],
    );
  }
}

// ── Role toggle ───────────────────────────────────────────────────────────────

class _RoleToggle extends StatelessWidget {
  final bool isDoctor;
  final ValueChanged<bool> onChanged;
  const _RoleToggle({required this.isDoctor, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          _Tab(label: '🤱  রোগী', selected: !isDoctor, onTap: () => onChanged(false)),
          _Tab(label: '👨‍⚕️  ডাক্তার', selected: isDoctor, onTap: () => onChanged(true)),
        ],
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _Tab({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: selected
                ? [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 4)]
                : [],
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.nunito(
              fontSize: 13,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
              color: selected ? const Color(0xFF993556) : Colors.grey,
            ),
          ),
        ),
      ),
    );
  }
}

// ── Google G icon (painted, no asset needed) ──────────────────────────────────

class _GoogleIcon extends StatelessWidget {
  const _GoogleIcon();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 20,
      height: 20,
      child: CustomPaint(painter: _GooglePainter()),
    );
  }
}

class _GooglePainter extends CustomPainter {
  const _GooglePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.width / 2;
    final paint = Paint()..style = PaintingStyle.fill;

    // Simplified Google G using arcs
    paint.color = const Color(0xFF4285F4);
    canvas.drawArc(Rect.fromCircle(center: c, radius: r), -1.6, 3.1, false, paint..style = PaintingStyle.stroke..strokeWidth = size.width * 0.22);
    paint
      ..color = const Color(0xFF34A853)
      ..style = PaintingStyle.fill;
    // Just draw a coloured circle for simplicity
    final colors = [const Color(0xFF4285F4), const Color(0xFF34A853), const Color(0xFFFBBC05), const Color(0xFFEA4335)];
    for (var i = 0; i < 4; i++) {
      paint.color = colors[i];
      canvas.drawArc(
        Rect.fromCircle(center: c, radius: r * 0.9),
        (i * 3.14159 / 2) - 0.1,
        3.14159 / 2,
        false,
        paint..style = PaintingStyle.stroke..strokeWidth = r * 0.4,
      );
    }
  }

  @override
  bool shouldRepaint(_) => false;
}
