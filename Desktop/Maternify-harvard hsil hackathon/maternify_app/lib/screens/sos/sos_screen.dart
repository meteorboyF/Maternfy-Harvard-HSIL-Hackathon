import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/firebase_service.dart';
import '../../services/supabase_service.dart';
import '../../models/patient.dart';

/// F13 — SOS Screen. One tap sends GPS + last 24h vitals snapshot + blood
/// type to Firestore. Creates a critical alert visible to the provider in <2s.
class SosScreen extends StatefulWidget {
  final Patient patient;
  const SosScreen({super.key, required this.patient});

  @override
  State<SosScreen> createState() => _SosScreenState();
}

class _SosScreenState extends State<SosScreen>
    with SingleTickerProviderStateMixin {
  bool _sending = false;
  bool _sent = false;
  late AnimationController _pulseCtrl;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendSos() async {
    setState(() => _sending = true);

    try {
      // 1. Get GPS location
      Position? position;
      try {
        await Geolocator.requestPermission();
        position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
          timeLimit: const Duration(seconds: 5),
        );
      } catch (_) {
        // Location unavailable — still send SOS without coords
      }

      // 2. Fetch last 24h vitals snapshot
      final since = DateTime.now().subtract(const Duration(hours: 24));
      final vitalsData = await SupabaseService.client
          .from('vitals_logs')
          .select('systolic_bp, diastolic_bp, weight_kg, blood_glucose, kick_count, logged_at')
          .eq('patient_id', widget.patient.id)
          .gte('logged_at', since.toIso8601String())
          .order('logged_at', ascending: false)
          .limit(3);

      // 3. Write SOS to Firestore (real-time push to doctor dashboard)
      await FirebaseService.firestore.collection('sos_alerts').add({
        'patient_id': widget.patient.id,
        'patient_name': widget.patient.name,
        'provider_id': widget.patient.providerId,
        'blood_type': widget.patient.bloodType,
        'weeks_gestation': widget.patient.weeksGestation,
        'phone': widget.patient.phone,
        'latitude': position?.latitude,
        'longitude': position?.longitude,
        'last_vitals': vitalsData,
        'message': 'EMERGENCY SOS — ${widget.patient.name} needs immediate assistance',
        'read': false,
        'created_at': FieldValue.serverTimestamp(),
      });

      // 4. Also write to Supabase alerts table
      await SupabaseService.client.from('alerts').insert({
        'patient_id': widget.patient.id,
        'provider_id': widget.patient.providerId,
        'alert_type': 'red_triage',
        'message': 'SOS: ${widget.patient.name} (${widget.patient.weeksGestation}w, ${widget.patient.bloodType}) — emergency alert with GPS',
        'read': false,
      });

      setState(() { _sending = false; _sent = true; });
    } catch (e) {
      setState(() => _sending = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('SOS failed: $e. Call emergency services directly!')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF0F5),
      appBar: AppBar(
        title: const Text('জরুরি সাহায্য'),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_sent) ...[
                const Icon(Icons.check_circle, size: 100, color: Colors.green),
                const SizedBox(height: 24),
                const Text(
                  'SOS পাঠানো হয়েছে!',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.green),
                ),
                const SizedBox(height: 12),
                const Text(
                  'আপনার ডাক্তার এখনই সতর্ক হয়েছেন।\nশান্ত থাকুন, সাহায্য আসছে।',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.black54),
                ),
              ] else ...[
                // Pulsing SOS button
                AnimatedBuilder(
                  animation: _pulseCtrl,
                  builder: (_, child) {
                    final scale = 1.0 + (_pulseCtrl.value * 0.05);
                    return Transform.scale(scale: scale, child: child);
                  },
                  child: GestureDetector(
                    onTap: _sending ? null : _sendSos,
                    child: Container(
                      width: 180,
                      height: 180,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _sending ? Colors.grey : Colors.red,
                        boxShadow: [
                          BoxShadow(color: Colors.red.withOpacity(0.4), blurRadius: 30, spreadRadius: 10),
                        ],
                      ),
                      child: _sending
                          ? const Center(child: CircularProgressIndicator(color: Colors.white, strokeWidth: 4))
                          : const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.sos, size: 64, color: Colors.white),
                                SizedBox(height: 4),
                                Text('চাপুন', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                              ],
                            ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  'এই বোতাম চাপলে আপনার ডাক্তার\nতাৎক্ষণিক সতর্কতা পাবেন',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 15, color: Colors.red.shade700),
                ),
                const SizedBox(height: 24),
                // Patient info card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('পাঠানো হবে:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red.shade700)),
                      const SizedBox(height: 8),
                      _InfoRow('নাম', widget.patient.name),
                      _InfoRow('রক্তের গ্রুপ', widget.patient.bloodType),
                      _InfoRow('গর্ভাবস্থা', '${widget.patient.weeksGestation} সপ্তাহ'),
                      _InfoRow('শেষ ভাইটালস', 'শেষ ২৪ ঘণ্টার রেকর্ড'),
                      _InfoRow('অবস্থান', 'GPS লোকেশন'),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label, value;
  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          children: [
            SizedBox(width: 110, child: Text(label, style: const TextStyle(color: Colors.grey))),
            Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500))),
          ],
        ),
      );
}
