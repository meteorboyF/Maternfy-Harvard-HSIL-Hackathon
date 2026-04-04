import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../models/patient.dart';
import '../../services/supabase_service.dart';
import '../vitals/vitals_screen.dart';
import '../triage/triage_screen.dart';
import '../sos/sos_screen.dart';
import '../calendar/calendar_screen.dart';
import '../dietary/dietary_screen.dart';
import '../journal/journal_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  Patient? _patient;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPatient();
  }

  Future<void> _loadPatient() async {
    try {
      final authState = context.read<AuthBloc>().state;
      if (authState is! AuthAuthenticated) return;
      final uid = authState.user.uid;

      final data = await SupabaseService.client
          .from('patients')
          .select()
          .eq('id', uid)
          .maybeSingle();

      if (mounted) {
        setState(() {
          _patient = data != null ? Patient.fromJson(data) : null;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Maternify'),
        backgroundColor: const Color(0xFFE91E8C),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () =>
                context.read<AuthBloc>().add(AuthSignOutRequested()),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _ErrorView(error: _error!, onRetry: _loadPatient)
              : _patient == null
                  ? const _NoProfileView()
                  : _buildBody(),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (i) => setState(() => _selectedIndex = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home), label: 'হোম'),
          NavigationDestination(
              icon: Icon(Icons.monitor_heart), label: 'ভাইটালস'),
          NavigationDestination(icon: Icon(Icons.chat), label: 'ট্রায়াজ'),
          NavigationDestination(
              icon: Icon(Icons.calendar_month), label: 'ক্যালেন্ডার'),
          NavigationDestination(icon: Icon(Icons.sos), label: 'SOS'),
        ],
      ),
    );
  }

  Widget _buildBody() {
    final patient = _patient!;
    return switch (_selectedIndex) {
      0 => _HomeTab(
          patient: patient,
          onNavigate: (i) => setState(() => _selectedIndex = i),
        ),
      1 => VitalsScreen(patientId: patient.id),
      2 => TriageScreen(patientId: patient.id),
      3 => CalendarScreen(
          patientId: patient.id,
          weeksGestation: patient.weeksGestation,
        ),
      4 => SosScreen(patient: patient),
      _ => const SizedBox.shrink(),
    };
  }
}

// ─── Home tab dashboard ───────────────────────────────────────────────────────

class _HomeTab extends StatelessWidget {
  final Patient patient;
  final ValueChanged<int> onNavigate;
  const _HomeTab({required this.patient, required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final weeksLeft = 40 - patient.weeksGestation;
    final dueDate = today.add(Duration(days: weeksLeft * 7));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Greeting card
          Card(
            elevation: 3,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: const LinearGradient(
                  colors: [Color(0xFFE91E8C), Color(0xFFFF6B9D)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'স্বাগতম, ${patient.name}!',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('EEEE, d MMMM yyyy', 'en').format(today),
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _StatChip(
                          label: 'গর্ভাবস্থা',
                          value: '${patient.weeksGestation} সপ্তাহ'),
                      const SizedBox(width: 10),
                      _StatChip(
                          label: 'বাকি',
                          value: '$weeksLeft সপ্তাহ'),
                      const SizedBox(width: 10),
                      _StatChip(
                          label: 'রক্তের গ্রুপ',
                          value: patient.bloodType),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Due date card
          Card(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              leading: const CircleAvatar(
                backgroundColor: Color(0xFFFCE4EC),
                child: Text('🍼', style: TextStyle(fontSize: 20)),
              ),
              title: const Text('প্রত্যাশিত প্রসব তারিখ',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text(DateFormat('d MMMM yyyy', 'en').format(dueDate)),
              trailing: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFFFCE4EC),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'আর ${dueDate.difference(today).inDays} দিন',
                  style: const TextStyle(
                      color: Color(0xFFE91E8C),
                      fontWeight: FontWeight.bold,
                      fontSize: 12),
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Quick-action grid
          const Text('দ্রুত কার্যক্রম',
              style:
                  TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 2.4,
            children: [
              _QuickAction(
                icon: Icons.monitor_heart,
                label: 'ভাইটালস লগ করুন',
                color: const Color(0xFF1976D2),
                onTap: () => onNavigate(1),
              ),
              _QuickAction(
                icon: Icons.chat,
                label: 'ট্রায়াজ চ্যাট',
                color: const Color(0xFF388E3C),
                onTap: () => onNavigate(2),
              ),
              _QuickAction(
                icon: Icons.calendar_month,
                label: 'ক্যালেন্ডার দেখুন',
                color: const Color(0xFF7B1FA2),
                onTap: () => onNavigate(3),
              ),
              _QuickAction(
                icon: Icons.sos,
                label: 'জরুরি SOS',
                color: const Color(0xFFD32F2F),
                onTap: () => onNavigate(4),
              ),
              _QuickAction(
                icon: Icons.restaurant_menu,
                label: 'খাদ্য পরামর্শ',
                color: const Color(0xFF00897B),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => DietaryScreen(
                      patientId: patient.id,
                      weeksGestation: patient.weeksGestation,
                    ),
                  ),
                ),
              ),
              _QuickAction(
                icon: Icons.menu_book,
                label: 'মেজাজ জার্নাল',
                color: const Color(0xFF6A1B9A),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        JournalScreen(patientId: patient.id),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Patient info card
          Card(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('রোগীর তথ্য',
                      style: TextStyle(
                          fontSize: 14, fontWeight: FontWeight.bold)),
                  const Divider(),
                  _InfoRow('গ্রাভিডা', '${patient.gravida}'),
                  _InfoRow('প্যারিটি', '${patient.parity}'),
                  _InfoRow('বয়স', '${patient.age} বছর'),
                  _InfoRow('ফোন', patient.phone),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  const _StatChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white24,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(color: Colors.white70, fontSize: 10)),
          Text(value,
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13)),
        ],
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickAction(
      {required this.icon,
      required this.label,
      required this.color,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(width: 8),
            Expanded(
              child: Text(label,
                  style: TextStyle(
                      color: color,
                      fontSize: 13,
                      fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          SizedBox(
              width: 80,
              child: Text(label,
                  style: const TextStyle(
                      color: Colors.black54, fontSize: 13))),
          Text(value,
              style: const TextStyle(
                  fontWeight: FontWeight.w500, fontSize: 13)),
        ],
      ),
    );
  }
}

// ─── Error / no-profile states ────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;
  const _ErrorView({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 12),
            Text(error, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: onRetry, child: const Text('পুনরায় চেষ্টা করুন')),
          ],
        ),
      ),
    );
  }
}

class _NoProfileView extends StatelessWidget {
  const _NoProfileView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('🤱', style: TextStyle(fontSize: 64)),
            SizedBox(height: 16),
            Text(
              'আপনার প্রোফাইল এখনো তৈরি হয়নি।\nঅনুগ্রহ করে আপনার ডাক্তারের সাথে যোগাযোগ করুন।',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
