import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../demo/demo_repository.dart';
import '../../models/vitals_log.dart';
import '../../utils/l10n.dart';

class VitalsScreen extends StatefulWidget {
  final String patientId;

  const VitalsScreen({super.key, required this.patientId});

  @override
  State<VitalsScreen> createState() => _VitalsScreenState();
}

class _VitalsScreenState extends State<VitalsScreen> {
  final DemoRepository _repository = DemoRepository.instance;
  final _formKey = GlobalKey<FormState>();
  final _systolicController = TextEditingController();
  final _diastolicController = TextEditingController();
  final _weightController = TextEditingController();
  final _glucoseController = TextEditingController();
  final _kickController = TextEditingController();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _clearForm();
  }

  @override
  void dispose() {
    _systolicController.dispose();
    _diastolicController.dispose();
    _weightController.dispose();
    _glucoseController.dispose();
    _kickController.dispose();
    super.dispose();
  }

  void _clearForm() {
    _systolicController.clear();
    _diastolicController.clear();
    _weightController.clear();
    _glucoseController.clear();
    _kickController.clear();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    final log = VitalsLog(
      id: const Uuid().v4(),
      patientId: widget.patientId,
      systolicBp: int.parse(_systolicController.text),
      diastolicBp: int.parse(_diastolicController.text),
      weightKg: double.parse(_weightController.text),
      bloodGlucose: double.parse(_glucoseController.text),
      kickCount: int.parse(_kickController.text),
      loggedAt: DateTime.now(),
    );

    await _repository.submitVitals(log);
    if (!mounted) return;
    setState(() => _isSaving = false);
    final en = _repository.isEnglish;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Text(L.t(en, 'রিডিং সেভ হয়েছে।', 'Reading saved.')),
      ),
    );
    _clearForm();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBuilder(
        animation: _repository,
        builder: (context, _) {
          final en = _repository.isEnglish;
          final logs = _repository.vitalsLogs;
          final latest = _repository.latestVitals;
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF8B2E50), Color(0xFFB44C71)],
                  ),
                  borderRadius: BorderRadius.circular(26),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      L.t(en, 'আজকের স্বাস্থ্য রিডিং', "Today's Health Readings"),
                      style: GoogleFonts.nunito(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      L.t(en,
                        'প্রতিদিন রিডিং লগ করুন যাতে আপনার চিকিৎসক সঠিক সময়ে পরামর্শ দিতে পারেন।',
                        'Log your readings daily so your care team can advise you at the right time.',
                      ),
                      style: GoogleFonts.nunito(
                        color: Colors.white.withValues(alpha: 0.88),
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        _TopMetric(
                            label: L.t(en, 'সর্বশেষ BP', 'Latest BP'),
                            value: '${latest.systolicBp}/${latest.diastolicBp}'),
                        const SizedBox(width: 10),
                        _TopMetric(
                            label: L.t(en, 'গ্লুকোজ', 'Glucose'),
                            value: latest.bloodGlucose.toStringAsFixed(1)),
                        const SizedBox(width: 10),
                        _TopMetric(
                            label: L.t(en, 'কিক', 'Kick'),
                            value: '${latest.kickCount}'),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              if (_repository.lastVitalsUpdateAt != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAF4EE),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle_outline,
                          color: Color(0xFF197A5B)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          L.t(en,
                            '${DateFormat('h:mm a').format(_repository.lastVitalsUpdateAt!)}-এ রিডিং সেভ হয়েছে। আপনার ড্যাশবোর্ড আপডেট হয়েছে।',
                            'Reading saved at ${DateFormat('h:mm a').format(_repository.lastVitalsUpdateAt!)}. Your dashboard has been updated.',
                          ),
                          style: GoogleFonts.nunito(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                ),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(L.t(en, 'রক্তচাপের ধারা', 'Blood Pressure Trend'),
                          style: GoogleFonts.nunito(
                              fontSize: 16, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 12),
                      SizedBox(height: 220, child: _BpChart(logs: logs)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(L.t(en, 'কিক কাউন্ট ও ওজন', 'Kick Count & Weight'),
                          style: GoogleFonts.nunito(
                              fontSize: 16, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 12),
                      SizedBox(
                          height: 180, child: _KickWeightChart(logs: logs)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          L.t(en, 'নতুন রিডিং লগ করুন', 'Log New Reading'),
                          style: GoogleFonts.nunito(
                              fontSize: 16, fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _VitalsField(
                                controller: _systolicController,
                                label: L.t(en, 'সিস্টোলিক', 'Systolic'),
                                suffix: 'mmHg',
                                isEnglish: en,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _VitalsField(
                                controller: _diastolicController,
                                label: L.t(en, 'ডায়াস্টোলিক', 'Diastolic'),
                                suffix: 'mmHg',
                                isEnglish: en,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: _VitalsField(
                                controller: _weightController,
                                label: L.t(en, 'ওজন', 'Weight'),
                                suffix: 'kg',
                                isEnglish: en,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _VitalsField(
                                controller: _glucoseController,
                                label: L.t(en, 'গ্লুকোজ', 'Glucose'),
                                suffix: 'mmol/L',
                                isEnglish: en,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        _VitalsField(
                          controller: _kickController,
                          label: L.t(en, '২ ঘণ্টায় কিক', 'Kicks in 2h'),
                          suffix: L.t(en, 'কিক', 'kicks'),
                          isEnglish: en,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _isSaving ? null : _submit,
                          child: _isSaving
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(L.t(en, 'রিডিং সেভ করুন', 'Save Reading')),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                L.t(en, 'সাম্প্রতিক রিডিং', 'Recent Readings'),
                style: GoogleFonts.nunito(
                    fontSize: 17, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              ...logs.reversed.take(5).map((log) => _ReadingCard(log: log, en: en)),
            ],
          );
        },
      ),
    );
  }
}

class _TopMetric extends StatelessWidget {
  final String label;
  final String value;

  const _TopMetric({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: GoogleFonts.nunito(color: Colors.white70, fontSize: 11)),
            const SizedBox(height: 4),
            Text(
              value,
              style: GoogleFonts.nunito(
                color: Colors.white,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VitalsField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String suffix;
  final bool isEnglish;

  const _VitalsField({
    required this.controller,
    required this.label,
    required this.suffix,
    this.isEnglish = false,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: label,
        suffixText: suffix,
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return L.t(isEnglish, 'প্রয়োজনীয়', 'Required');
        }
        if (num.tryParse(value) == null) {
          return L.t(isEnglish, 'সঠিক সংখ্যা দিন', 'Enter a valid number');
        }
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
    final systolic = logs.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value.systolicBp.toDouble());
    }).toList();
    final diastolic = logs.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value.diastolicBp.toDouble());
    }).toList();

    return LineChart(
      LineChartData(
        minY: 70,
        maxY: 165,
        gridData: FlGridData(show: true, horizontalInterval: 10),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 32,
              getTitlesWidget: (value, meta) => Text(
                value.toInt().toString(),
                style: GoogleFonts.nunito(fontSize: 11),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 3,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= logs.length)
                  return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    DateFormat('d MMM').format(logs[index].loggedAt),
                    style: GoogleFonts.nunito(fontSize: 10),
                  ),
                );
              },
            ),
          ),
        ),
        extraLinesData: ExtraLinesData(
          horizontalLines: [
            HorizontalLine(
                y: 140,
                color: const Color(0xFFD1423B).withValues(alpha: 0.4),
                dashArray: [5, 5]),
            HorizontalLine(
                y: 90,
                color: const Color(0xFFB17616).withValues(alpha: 0.4),
                dashArray: [5, 5]),
          ],
        ),
        lineBarsData: [
          LineChartBarData(
            spots: systolic,
            isCurved: true,
            color: const Color(0xFF983755),
            barWidth: 3,
            dotData: const FlDotData(show: false),
          ),
          LineChartBarData(
            spots: diastolic,
            isCurved: true,
            color: const Color(0xFF5D53B7),
            barWidth: 3,
            dotData: const FlDotData(show: false),
          ),
        ],
      ),
    );
  }
}

class _KickWeightChart extends StatelessWidget {
  final List<VitalsLog> logs;

  const _KickWeightChart({required this.logs});

  @override
  Widget build(BuildContext context) {
    final kicks = logs.asMap().entries.map((entry) {
      return BarChartGroupData(
        x: entry.key,
        barRods: [
          BarChartRodData(
            toY: entry.value.kickCount.toDouble(),
            color: const Color(0xFF0F6E56),
            width: 10,
            borderRadius: BorderRadius.circular(3),
          ),
        ],
      );
    }).toList();

    return BarChart(
      BarChartData(
        maxY: 16,
        borderData: FlBorderData(show: false),
        gridData: FlGridData(show: true, horizontalInterval: 2),
        titlesData: FlTitlesData(
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              getTitlesWidget: (value, meta) => Text(
                value.toInt().toString(),
                style: GoogleFonts.nunito(fontSize: 10),
              ),
            ),
          ),
          bottomTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        barGroups: kicks,
      ),
    );
  }
}

class _ReadingCard extends StatelessWidget {
  final VitalsLog log;
  final bool en;

  const _ReadingCard({required this.log, this.en = false});

  @override
  Widget build(BuildContext context) {
    final elevated = log.systolicBp >= 140 || log.diastolicBp >= 90;
    final color = elevated ? const Color(0xFFD1423B) : const Color(0xFF197A5B);
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.12),
          foregroundColor: color,
          child: Icon(elevated
              ? Icons.warning_amber_rounded
              : Icons.check_circle_outline),
        ),
        title: Text(
          '${log.systolicBp}/${log.diastolicBp} mmHg',
          style: GoogleFonts.nunito(fontWeight: FontWeight.w900, color: color),
        ),
        subtitle: Text(
          L.t(en,
            'ওজন ${log.weightKg.toStringAsFixed(1)} কেজি • গ্লুকোজ ${log.bloodGlucose.toStringAsFixed(1)} • কিক ${log.kickCount}',
            'Weight ${log.weightKg.toStringAsFixed(1)} kg • Glucose ${log.bloodGlucose.toStringAsFixed(1)} • Kick ${log.kickCount}',
          ),
          style: GoogleFonts.nunito(height: 1.35),
        ),
        trailing: Text(
          DateFormat('d MMM\nh:mm a').format(log.loggedAt),
          textAlign: TextAlign.right,
          style:
              GoogleFonts.nunito(fontSize: 11, color: const Color(0xFF756871)),
        ),
      ),
    );
  }
}
