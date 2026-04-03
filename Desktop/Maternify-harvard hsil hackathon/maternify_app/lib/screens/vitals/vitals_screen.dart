import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:uuid/uuid.dart';
import '../../blocs/vitals/vitals_bloc.dart';
import '../../models/vitals_log.dart';

class VitalsScreen extends StatelessWidget {
  final String patientId;
  const VitalsScreen({super.key, required this.patientId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => VitalsBloc()..add(VitalsLoadRequested(patientId: patientId)),
      child: _VitalsView(patientId: patientId),
    );
  }
}

class _VitalsView extends StatefulWidget {
  final String patientId;
  const _VitalsView({required this.patientId});

  @override
  State<_VitalsView> createState() => _VitalsViewState();
}

class _VitalsViewState extends State<_VitalsView> {
  final _formKey = GlobalKey<FormState>();
  final _systolicCtrl = TextEditingController();
  final _diastolicCtrl = TextEditingController();
  final _weightCtrl = TextEditingController();
  final _glucoseCtrl = TextEditingController();
  final _kickCtrl = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _systolicCtrl.dispose();
    _diastolicCtrl.dispose();
    _weightCtrl.dispose();
    _glucoseCtrl.dispose();
    _kickCtrl.dispose();
    super.dispose();
  }

  void _submit(BuildContext context) {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);

    final log = VitalsLog(
      id: const Uuid().v4(),
      patientId: widget.patientId,
      systolicBp: int.parse(_systolicCtrl.text),
      diastolicBp: int.parse(_diastolicCtrl.text),
      weightKg: double.parse(_weightCtrl.text),
      bloodGlucose: double.parse(_glucoseCtrl.text),
      kickCount: int.parse(_kickCtrl.text),
      loggedAt: DateTime.now(),
    );

    context.read<VitalsBloc>().add(VitalsLogSubmitted(vitals: log));
    _systolicCtrl.clear();
    _diastolicCtrl.clear();
    _weightCtrl.clear();
    _glucoseCtrl.clear();
    _kickCtrl.clear();
    setState(() => _submitting = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ভাইটালস লগ'),
        backgroundColor: const Color(0xFFE91E8C),
        foregroundColor: Colors.white,
      ),
      body: BlocBuilder<VitalsBloc, VitalsState>(
        builder: (context, state) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // BP Trend Chart
                if (state is VitalsLoaded && state.logs.isNotEmpty) ...[
                  _SectionTitle('রক্তচাপের ট্রেন্ড (শেষ ১৪ দিন)'),
                  const SizedBox(height: 8),
                  _BpChart(logs: state.logs),
                  const SizedBox(height: 24),
                ],

                // Log Form
                _SectionTitle('আজকের ভাইটালস লিখুন'),
                const SizedBox(height: 12),
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      Row(children: [
                        Expanded(child: _VitalsField(ctrl: _systolicCtrl, label: 'সিস্টোলিক BP', hint: '120', unit: 'mmHg', min: 60, max: 200)),
                        const SizedBox(width: 12),
                        Expanded(child: _VitalsField(ctrl: _diastolicCtrl, label: 'ডায়াস্টোলিক BP', hint: '80', unit: 'mmHg', min: 40, max: 130)),
                      ]),
                      const SizedBox(height: 12),
                      Row(children: [
                        Expanded(child: _VitalsField(ctrl: _weightCtrl, label: 'ওজন', hint: '60.5', unit: 'kg', isDecimal: true, min: 30, max: 120)),
                        const SizedBox(width: 12),
                        Expanded(child: _VitalsField(ctrl: _glucoseCtrl, label: 'রক্তের সুগার', hint: '5.5', unit: 'mmol/L', isDecimal: true, min: 2, max: 20)),
                      ]),
                      const SizedBox(height: 12),
                      _VitalsField(ctrl: _kickCtrl, label: 'কিক কাউন্ট (২ ঘণ্টায়)', hint: '10', unit: 'kicks', min: 0, max: 50),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: _submitting ? null : () => _submit(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFE91E8C),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: _submitting
                              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : const Text('সেভ করুন', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ),

                // Recent readings
                if (state is VitalsLoaded && state.logs.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  _SectionTitle('সাম্প্রতিক রিডিং'),
                  const SizedBox(height: 8),
                  ...state.logs.reversed.take(5).map((log) => _VitalsCard(log: log)),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF333333)),
      );
}

class _VitalsField extends StatelessWidget {
  final TextEditingController ctrl;
  final String label, hint, unit;
  final bool isDecimal;
  final int min, max;

  const _VitalsField({
    required this.ctrl,
    required this.label,
    required this.hint,
    required this.unit,
    this.isDecimal = false,
    required this.min,
    required this.max,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: ctrl,
      keyboardType: isDecimal ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.number,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        suffixText: unit,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFE91E8C), width: 2),
        ),
      ),
      validator: (v) {
        if (v == null || v.isEmpty) return 'প্রয়োজন';
        final n = num.tryParse(v);
        if (n == null) return 'সংখ্যা লিখুন';
        if (n < min || n > max) return '$min–$max';
        return null;
      },
    );
  }
}

class _BpChart extends StatelessWidget {
  final List<VitalsLog> logs;
  const _BpChart({required this.logs});

  @override
  Widget build(BuildContext context) {
    final systolicSpots = logs.asMap().entries
        .map((e) => FlSpot(e.key.toDouble(), e.value.systolicBp.toDouble()))
        .toList();
    final diastolicSpots = logs.asMap().entries
        .map((e) => FlSpot(e.key.toDouble(), e.value.diastolicBp.toDouble()))
        .toList();

    return SizedBox(
      height: 180,
      child: LineChart(
        LineChartData(
          gridData: const FlGridData(show: true),
          titlesData: const FlTitlesData(show: false),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: systolicSpots,
              isCurved: true,
              color: const Color(0xFFE91E8C),
              barWidth: 2.5,
              dotData: const FlDotData(show: false),
            ),
            LineChartBarData(
              spots: diastolicSpots,
              isCurved: true,
              color: const Color(0xFF9C27B0),
              barWidth: 2.5,
              dotData: const FlDotData(show: false),
            ),
          ],
          // Red danger lines
          extraLinesData: ExtraLinesData(horizontalLines: [
            HorizontalLine(y: 140, color: Colors.red.withOpacity(0.4), strokeWidth: 1, dashArray: [5, 5]),
            HorizontalLine(y: 90, color: Colors.orange.withOpacity(0.4), strokeWidth: 1, dashArray: [5, 5]),
          ]),
        ),
      ),
    );
  }
}

class _VitalsCard extends StatelessWidget {
  final VitalsLog log;
  const _VitalsCard({required this.log});

  @override
  Widget build(BuildContext context) {
    final bpColor = log.isBpElevated ? Colors.red.shade700 : Colors.green.shade700;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(
              child: Text(
                '${log.systolicBp}/${log.diastolicBp} mmHg',
                style: TextStyle(fontWeight: FontWeight.bold, color: bpColor, fontSize: 16),
              ),
            ),
            Text('${log.weightKg}kg · ${log.bloodGlucose}mmol/L · ${log.kickCount} kicks',
                style: const TextStyle(color: Colors.grey, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
