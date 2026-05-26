import 'package:flutter/material.dart';
import '../../core/config/gps_filter_params.dart';
import 'filter_config_controls.dart';

class ConfigEditSheet extends StatefulWidget {
  final GpsFilterParams initial;
  final String title;
  final void Function(GpsFilterParams) onSave;

  const ConfigEditSheet({
    super.key,
    required this.initial,
    required this.title,
    required this.onSave,
  });

  static Future<void> show({
    required BuildContext context,
    required GpsFilterParams initial,
    required String title,
    required void Function(GpsFilterParams) onSave,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => ConfigEditSheet(initial: initial, title: title, onSave: onSave),
    );
  }

  @override
  State<ConfigEditSheet> createState() => _ConfigEditSheetState();
}

class _ConfigEditSheetState extends State<ConfigEditSheet> {
  // ── Alan state'leri ──────────────────────────────────────────────────────
  late final TextEditingController _nameCtrl;
  late Color _color;

  // GPS eşikleri
  late double _accuracyThreshold;
  late double _maxSpeedKmh;
  late double _maxImpliedSpeedKmh;
  late double _stationarySpeedThreshold;
  late double _poorAccuracyThreshold;

  // Mesafe
  late double _warmUpCount;
  late double _warmUpMinDistance;
  late double _postWarmUpMinDistance;

  // Spike Guard
  late double _rawSpikeSpeedMs;

  // IIR Adaptive
  late bool _useAdaptiveIir;
  late double _iirAlphaSteady;
  late double _iirAlphaPaceChange;
  late double _iirAlphaStop;
  late double _speedChangeThresholdMs;

  // Kalman
  late bool _useKalman;
  late double _kalmanQ;
  late double _kalmanR;

  static const _kalmanQOptions = [0.000001, 0.00001, 0.0001, 0.001, 0.01];
  static const _kalmanROptions = [0.0001, 0.001, 0.01, 0.05, 0.1];

  @override
  void initState() {
    super.initState();
    final p = widget.initial;
    _nameCtrl = TextEditingController(text: p.name);
    _color = p.color;
    _accuracyThreshold = p.accuracyThreshold.clamp(1, 200);
    _maxSpeedKmh = p.maxSpeedKmh.clamp(5, 200);
    _maxImpliedSpeedKmh = p.maxImpliedSpeedKmh.clamp(10, 300);
    _stationarySpeedThreshold = p.stationarySpeedThreshold.clamp(0, 3);
    _poorAccuracyThreshold = p.poorAccuracyThreshold.clamp(1, 100);
    _warmUpCount = p.warmUpCount.toDouble().clamp(0, 30);
    _warmUpMinDistance = p.warmUpMinDistance.clamp(0, 20);
    _postWarmUpMinDistance = p.postWarmUpMinDistance.clamp(0, 30);
    _rawSpikeSpeedMs = p.rawSpikeSpeedMs.clamp(0, 20);
    _useAdaptiveIir = p.useAdaptiveIir;
    _iirAlphaSteady = p.iirAlphaSteady.clamp(0.0, 1.0);
    _iirAlphaPaceChange = p.iirAlphaPaceChange.clamp(0.0, 1.0);
    _iirAlphaStop = p.iirAlphaStop.clamp(0.0, 0.5);
    _speedChangeThresholdMs = p.speedChangeThresholdMs.clamp(0.1, 3.0);
    _useKalman = p.useKalman;
    _kalmanQ = p.kalmanLatLngQ;
    _kalmanR = p.kalmanLatLngR;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  GpsFilterParams _buildParams() => GpsFilterParams(
        name: _nameCtrl.text.isEmpty ? 'Config' : _nameCtrl.text,
        color: _color,
        useKalman: _useAdaptiveIir ? false : _useKalman,
        kalmanLatLngQ: _kalmanQ,
        kalmanLatLngR: _kalmanR,
        accuracyThreshold: _accuracyThreshold >= 200 ? 9999 : _accuracyThreshold,
        maxSpeedKmh: _maxSpeedKmh >= 200 ? 9999 : _maxSpeedKmh,
        maxImpliedSpeedKmh: _maxImpliedSpeedKmh >= 300 ? 9999 : _maxImpliedSpeedKmh,
        warmUpCount: _warmUpCount.round(),
        warmUpMinDistance: _warmUpMinDistance,
        postWarmUpMinDistance: _postWarmUpMinDistance,
        stationarySpeedThreshold: _stationarySpeedThreshold,
        poorAccuracyThreshold: _poorAccuracyThreshold >= 100 ? 9999 : _poorAccuracyThreshold,
        rawSpikeSpeedMs: _rawSpikeSpeedMs,
        useAdaptiveIir: _useAdaptiveIir,
        iirAlphaSteady: _iirAlphaSteady,
        iirAlphaPaceChange: _iirAlphaPaceChange,
        iirAlphaStop: _iirAlphaStop,
        speedChangeThresholdMs: _speedChangeThresholdMs,
      );

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.92,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scroll) => Column(
        children: [
          const SheetHandle(),
          _SheetAppBar(
            title: widget.title,
            onApply: () {
              widget.onSave(_buildParams());
              Navigator.pop(context);
            },
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView(
              controller: scroll,
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
              children: [
                _GeneralSection(
                  nameCtrl: _nameCtrl,
                  color: _color,
                  onColorChanged: (c) => setState(() => _color = c),
                ),
                _GpsThresholdsSection(
                  accuracyThreshold: _accuracyThreshold,
                  maxSpeedKmh: _maxSpeedKmh,
                  maxImpliedSpeedKmh: _maxImpliedSpeedKmh,
                  stationarySpeedThreshold: _stationarySpeedThreshold,
                  poorAccuracyThreshold: _poorAccuracyThreshold,
                  onAccuracyChanged: (v) =>
                      setState(() => _accuracyThreshold = v),
                  onMaxSpeedChanged: (v) =>
                      setState(() => _maxSpeedKmh = v),
                  onMaxImpliedSpeedChanged: (v) =>
                      setState(() => _maxImpliedSpeedKmh = v),
                  onStationaryChanged: (v) =>
                      setState(() => _stationarySpeedThreshold = v),
                  onPoorAccuracyChanged: (v) =>
                      setState(() => _poorAccuracyThreshold = v),
                ),
                _DistanceSection(
                  warmUpCount: _warmUpCount,
                  warmUpMinDistance: _warmUpMinDistance,
                  postWarmUpMinDistance: _postWarmUpMinDistance,
                  onWarmUpCountChanged: (v) =>
                      setState(() => _warmUpCount = v),
                  onWarmUpDistChanged: (v) =>
                      setState(() => _warmUpMinDistance = v),
                  onPostWarmUpDistChanged: (v) =>
                      setState(() => _postWarmUpMinDistance = v),
                ),
                _SpikeGuardSection(
                  rawSpikeSpeedMs: _rawSpikeSpeedMs,
                  onChanged: (v) => setState(() => _rawSpikeSpeedMs = v),
                ),
                _IirSection(
                  useAdaptiveIir: _useAdaptiveIir,
                  iirAlphaSteady: _iirAlphaSteady,
                  iirAlphaPaceChange: _iirAlphaPaceChange,
                  iirAlphaStop: _iirAlphaStop,
                  speedChangeThresholdMs: _speedChangeThresholdMs,
                  onToggle: (v) => setState(() {
                    _useAdaptiveIir = v;
                    if (v) _useKalman = false;
                  }),
                  onSteadyChanged: (v) =>
                      setState(() => _iirAlphaSteady = v),
                  onPaceChangeChanged: (v) =>
                      setState(() => _iirAlphaPaceChange = v),
                  onStopChanged: (v) => setState(() => _iirAlphaStop = v),
                  onSpeedThresholdChanged: (v) =>
                      setState(() => _speedChangeThresholdMs = v),
                ),
                _KalmanSection(
                  useKalman: _useKalman,
                  iirActive: _useAdaptiveIir,
                  kalmanQ: _kalmanQ,
                  kalmanR: _kalmanR,
                  kalmanQOptions: _kalmanQOptions,
                  kalmanROptions: _kalmanROptions,
                  onToggle: (v) => setState(() => _useKalman = v),
                  onQChanged: (v) => setState(() => _kalmanQ = v),
                  onRChanged: (v) => setState(() => _kalmanR = v),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Stateless bölüm widgetları ──────────────────────────────────────────────

class _SheetAppBar extends StatelessWidget {
  final String title;
  final VoidCallback onApply;
  const _SheetAppBar({required this.title, required this.onApply});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
      child: Row(
        children: [
          Text(title,
              style:
                  const TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
          const Spacer(),
          FilledButton(onPressed: onApply, child: const Text('Uygula')),
        ],
      ),
    );
  }
}

class _GeneralSection extends StatelessWidget {
  final TextEditingController nameCtrl;
  final Color color;
  final ValueChanged<Color> onColorChanged;
  const _GeneralSection(
      {required this.nameCtrl,
      required this.color,
      required this.onColorChanged});

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const SectionTitle('Genel'),
      const SizedBox(height: 8),
      TextField(
        controller: nameCtrl,
        decoration: const InputDecoration(
            labelText: 'Config adı',
            border: OutlineInputBorder(),
            isDense: true),
      ),
      const SizedBox(height: 14),
      Text('Renk',
          style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
      const SizedBox(height: 8),
      ColorPicker(selected: color, onChanged: onColorChanged),
      const SizedBox(height: 20),
    ]);
  }
}

class _GpsThresholdsSection extends StatelessWidget {
  final double accuracyThreshold;
  final double maxSpeedKmh;
  final double maxImpliedSpeedKmh;
  final double stationarySpeedThreshold;
  final double poorAccuracyThreshold;
  final ValueChanged<double> onAccuracyChanged;
  final ValueChanged<double> onMaxSpeedChanged;
  final ValueChanged<double> onMaxImpliedSpeedChanged;
  final ValueChanged<double> onStationaryChanged;
  final ValueChanged<double> onPoorAccuracyChanged;

  const _GpsThresholdsSection({
    required this.accuracyThreshold,
    required this.maxSpeedKmh,
    required this.maxImpliedSpeedKmh,
    required this.stationarySpeedThreshold,
    required this.poorAccuracyThreshold,
    required this.onAccuracyChanged,
    required this.onMaxSpeedChanged,
    required this.onMaxImpliedSpeedChanged,
    required this.onStationaryChanged,
    required this.onPoorAccuracyChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const SectionTitle('GPS Filtre Eşikleri'),
      SliderRow(
        label: 'Doğruluk eşiği', unit: 'm',
        value: accuracyThreshold, min: 1, max: 200, divisions: 199,
        maxLabel: '∞ (kapalı)', onChanged: onAccuracyChanged,
        displayValue: accuracyThreshold >= 200 ? '∞' : '${accuracyThreshold.round()} m',
        hint: 'GPS cihazının raporladığı yatay hata. Düşük = daha katı.',
      ),
      SliderRow(
        label: 'Maks. hız', unit: 'km/h',
        value: maxSpeedKmh, min: 5, max: 200, divisions: 195,
        maxLabel: '∞ (kapalı)', onChanged: onMaxSpeedChanged,
        displayValue: maxSpeedKmh >= 200 ? '∞' : '${maxSpeedKmh.round()} km/h',
        hint: 'Anlık hız bu değeri geçen noktalar reddedilir.',
      ),
      SliderRow(
        label: 'Maks. örtülü hız', unit: 'km/h',
        value: maxImpliedSpeedKmh, min: 10, max: 300, divisions: 290,
        maxLabel: '∞ (kapalı)', onChanged: onMaxImpliedSpeedChanged,
        displayValue: maxImpliedSpeedKmh >= 300 ? '∞' : '${maxImpliedSpeedKmh.round()} km/h',
        hint: 'İki ardışık nokta arasındaki mesafe/zaman oranı. GPS sıçramalarını yakalar.',
      ),
      SliderRow(
        label: 'Dur. hız eşiği', unit: 'm/s',
        value: stationarySpeedThreshold, min: 0, max: 3, divisions: 30,
        onChanged: onStationaryChanged,
        displayValue: '${stationarySpeedThreshold.toStringAsFixed(1)} m/s',
        hint: 'Bu hızın altındaki noktalar "duruyorsun" sayılır.',
      ),
      SliderRow(
        label: 'Zayıf doğruluk eşiği', unit: 'm',
        value: poorAccuracyThreshold, min: 1, max: 100, divisions: 99,
        maxLabel: '∞ (kapalı)', onChanged: onPoorAccuracyChanged,
        displayValue: poorAccuracyThreshold >= 100 ? '∞' : '${poorAccuracyThreshold.round()} m',
        hint: '"Duruyorsun" kontrolü için kullanılır: bu değerin üstü = zayıf GPS.',
      ),
      const SizedBox(height: 20),
    ]);
  }
}

class _DistanceSection extends StatelessWidget {
  final double warmUpCount;
  final double warmUpMinDistance;
  final double postWarmUpMinDistance;
  final ValueChanged<double> onWarmUpCountChanged;
  final ValueChanged<double> onWarmUpDistChanged;
  final ValueChanged<double> onPostWarmUpDistChanged;

  const _DistanceSection({
    required this.warmUpCount,
    required this.warmUpMinDistance,
    required this.postWarmUpMinDistance,
    required this.onWarmUpCountChanged,
    required this.onWarmUpDistChanged,
    required this.onPostWarmUpDistChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const SectionTitle('Mesafe Eşikleri'),
      SliderRow(
        label: 'Isınma süresi', unit: 'nokta',
        value: warmUpCount, min: 0, max: 30, divisions: 30,
        onChanged: onWarmUpCountChanged,
        displayValue: '${warmUpCount.round()} nokta',
        hint: 'İlk N noktada filtreler gevşetilir (GPS henüz sabitlenmemiştir).',
      ),
      SliderRow(
        label: 'Min. mesafe (ısınma)', unit: 'm',
        value: warmUpMinDistance, min: 0, max: 20, divisions: 40,
        onChanged: onWarmUpDistChanged,
        displayValue: '${warmUpMinDistance.toStringAsFixed(1)} m',
        hint: 'Isınma evresinde iki nokta arasındaki minimum mesafe.',
      ),
      SliderRow(
        label: 'Min. mesafe (normal)', unit: 'm',
        value: postWarmUpMinDistance, min: 0, max: 30, divisions: 60,
        onChanged: onPostWarmUpDistChanged,
        displayValue: '${postWarmUpMinDistance.toStringAsFixed(1)} m',
        hint: 'Isınma sonrasında iki nokta arasındaki minimum mesafe.',
      ),
      const SizedBox(height: 20),
    ]);
  }
}

class _SpikeGuardSection extends StatelessWidget {
  final double rawSpikeSpeedMs;
  final ValueChanged<double> onChanged;
  const _SpikeGuardSection(
      {required this.rawSpikeSpeedMs, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const SectionTitle('Spike Guard'),
      SliderRow(
        label: 'Ham GPS hız eşiği', unit: 'm/s',
        value: rawSpikeSpeedMs, min: 0, max: 20, divisions: 40,
        maxLabel: '∞ (kapalı)', onChanged: onChanged,
        displayValue:
            rawSpikeSpeedMs == 0 ? 'Kapalı' : '${rawSpikeSpeedMs.toStringAsFixed(1)} m/s',
        hint:
            'Kalman\'dan önce: iki ham GPS noktası arasındaki hız bu eşiği geçerse spike olarak reddedilir.',
      ),
      const SizedBox(height: 20),
    ]);
  }
}

class _IirSection extends StatelessWidget {
  final bool useAdaptiveIir;
  final double iirAlphaSteady;
  final double iirAlphaPaceChange;
  final double iirAlphaStop;
  final double speedChangeThresholdMs;
  final ValueChanged<bool> onToggle;
  final ValueChanged<double> onSteadyChanged;
  final ValueChanged<double> onPaceChangeChanged;
  final ValueChanged<double> onStopChanged;
  final ValueChanged<double> onSpeedThresholdChanged;

  const _IirSection({
    required this.useAdaptiveIir,
    required this.iirAlphaSteady,
    required this.iirAlphaPaceChange,
    required this.iirAlphaStop,
    required this.speedChangeThresholdMs,
    required this.onToggle,
    required this.onSteadyChanged,
    required this.onPaceChangeChanged,
    required this.onStopChanged,
    required this.onSpeedThresholdChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        const SectionTitle('IIR Adaptif Filtre'),
        const Spacer(),
        Switch(value: useAdaptiveIir, onChanged: onToggle),
      ]),
      if (useAdaptiveIir) ...[
        const SizedBox(height: 4),
        SliderRow(
          label: 'Alpha (sabit koşu)', unit: '',
          value: iirAlphaSteady, min: 0.0, max: 1.0, divisions: 20,
          onChanged: onSteadyChanged,
          displayValue: iirAlphaSteady.toStringAsFixed(2),
          hint: 'Sabit hızda EMA alpha. Düşük = güçlü yumuşatma. 0.3 önerilir.',
        ),
        SliderRow(
          label: 'Alpha (hız değişimi)', unit: '',
          value: iirAlphaPaceChange, min: 0.0, max: 1.0, divisions: 20,
          onChanged: onPaceChangeChanged,
          displayValue: iirAlphaPaceChange.toStringAsFixed(2),
          hint: 'Pace değişiminde EMA alpha. Yüksek = hızlı tepki. 0.7 önerilir.',
        ),
        SliderRow(
          label: 'Alpha (durma)', unit: '',
          value: iirAlphaStop, min: 0.0, max: 0.5, divisions: 10,
          onChanged: onStopChanged,
          displayValue: iirAlphaStop == 0.0 ? 'Dondur' : iirAlphaStop.toStringAsFixed(2),
          hint: '0.0 = durunca pozisyonu dondur. >0 = yavaş sürükle.',
        ),
        SliderRow(
          label: 'Hız değişim eşiği', unit: 'm/s',
          value: speedChangeThresholdMs, min: 0.1, max: 3.0, divisions: 29,
          onChanged: onSpeedThresholdChanged,
          displayValue: '${speedChangeThresholdMs.toStringAsFixed(1)} m/s',
          hint: 'Bu kadar anlık hız farkı PACE_CHANGE durumunu tetikler. 0.8 m/s önerilir.',
        ),
      ] else
        Padding(
          padding: const EdgeInsets.only(top: 4, bottom: 8),
          child: Text('IIR kapalıyken Kalman veya ham GPS kullanılır.',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
        ),
      const SizedBox(height: 20),
    ]);
  }
}

class _KalmanSection extends StatelessWidget {
  final bool useKalman;
  final bool iirActive;
  final double kalmanQ;
  final double kalmanR;
  final List<double> kalmanQOptions;
  final List<double> kalmanROptions;
  final ValueChanged<bool> onToggle;
  final ValueChanged<double> onQChanged;
  final ValueChanged<double> onRChanged;

  const _KalmanSection({
    required this.useKalman,
    required this.iirActive,
    required this.kalmanQ,
    required this.kalmanR,
    required this.kalmanQOptions,
    required this.kalmanROptions,
    required this.onToggle,
    required this.onQChanged,
    required this.onRChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        const SectionTitle('Kalman Filtresi'),
        const Spacer(),
        Switch(
          value: useKalman && !iirActive,
          onChanged: iirActive ? null : onToggle,
        ),
      ]),
      if (iirActive)
        Padding(
          padding: const EdgeInsets.only(top: 4, bottom: 8),
          child: Text('IIR Adaptif açıkken Kalman devre dışı.',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
        )
      else if (useKalman) ...[
        const SizedBox(height: 4),
        DiscreteRow(
          label: 'Process Noise (Q)',
          options: kalmanQOptions,
          selected: kalmanQ,
          onChanged: onQChanged,
          hint: 'Küçük Q = modele daha fazla güven → daha düzgün ama yavaş tepki.',
        ),
        DiscreteRow(
          label: 'Measurement Noise (R)',
          options: kalmanROptions,
          selected: kalmanR,
          onChanged: onRChanged,
          hint: 'Büyük R = GPS ölçümüne az güven → daha fazla düzleştirme.',
        ),
      ] else
        Padding(
          padding: const EdgeInsets.only(top: 4, bottom: 8),
          child: Text('Kalman kapalıyken GPS noktaları ham koordinatlarıyla kullanılır.',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
        ),
    ]);
  }
}
