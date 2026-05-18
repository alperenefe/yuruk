import 'package:flutter/material.dart';
import '../../core/config/gps_filter_params.dart';

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
      builder: (_) => ConfigEditSheet(
        initial: initial,
        title: title,
        onSave: onSave,
      ),
    );
  }

  @override
  State<ConfigEditSheet> createState() => _ConfigEditSheetState();
}

class _ConfigEditSheetState extends State<ConfigEditSheet> {
  late final TextEditingController _nameController;
  late Color _color;
  late bool _useKalman;
  late double _kalmanQ;
  late double _kalmanR;
  late double _accuracyThreshold;
  late double _maxSpeedKmh;
  late double _maxImpliedSpeedKmh;
  late double _warmUpCount;
  late double _warmUpMinDistance;
  late double _postWarmUpMinDistance;
  late double _stationarySpeedThreshold;
  late double _poorAccuracyThreshold;

  static const List<double> _kalmanQOptions = [
    0.000001, 0.00001, 0.0001, 0.001, 0.01,
  ];
  static const List<double> _kalmanROptions = [
    0.0001, 0.001, 0.01, 0.05, 0.1,
  ];

  @override
  void initState() {
    super.initState();
    final p = widget.initial;
    _nameController = TextEditingController(text: p.name);
    _color = p.color;
    _useKalman = p.useKalman;
    _kalmanQ = p.kalmanLatLngQ;
    _kalmanR = p.kalmanLatLngR;
    _accuracyThreshold = p.accuracyThreshold.clamp(1, 200);
    _maxSpeedKmh = p.maxSpeedKmh.clamp(5, 200);
    _maxImpliedSpeedKmh = p.maxImpliedSpeedKmh.clamp(10, 300);
    _warmUpCount = p.warmUpCount.toDouble().clamp(0, 30);
    _warmUpMinDistance = p.warmUpMinDistance.clamp(0, 20);
    _postWarmUpMinDistance = p.postWarmUpMinDistance.clamp(0, 30);
    _stationarySpeedThreshold = p.stationarySpeedThreshold.clamp(0, 3);
    _poorAccuracyThreshold = p.poorAccuracyThreshold.clamp(1, 100);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  GpsFilterParams _buildParams() => GpsFilterParams(
        name: _nameController.text.isEmpty ? 'Config' : _nameController.text,
        color: _color,
        useKalman: _useKalman,
        kalmanLatLngQ: _kalmanQ,
        kalmanLatLngR: _kalmanR,
        accuracyThreshold: _accuracyThreshold == 200 ? 9999 : _accuracyThreshold,
        maxSpeedKmh: _maxSpeedKmh == 200 ? 9999 : _maxSpeedKmh,
        maxImpliedSpeedKmh: _maxImpliedSpeedKmh == 300 ? 9999 : _maxImpliedSpeedKmh,
        warmUpCount: _warmUpCount.round(),
        warmUpMinDistance: _warmUpMinDistance == 0 ? 0 : _warmUpMinDistance,
        postWarmUpMinDistance: _postWarmUpMinDistance,
        stationarySpeedThreshold: _stationarySpeedThreshold,
        poorAccuracyThreshold: _poorAccuracyThreshold == 100 ? 9999 : _poorAccuracyThreshold,
      );

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.92,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Column(
          children: [
            _SheetHandle(),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
              child: Row(
                children: [
                  Text(
                    widget.title,
                    style: const TextStyle(
                        fontSize: 17, fontWeight: FontWeight.w600),
                  ),
                  const Spacer(),
                  FilledButton(
                    onPressed: () {
                      widget.onSave(_buildParams());
                      Navigator.pop(context);
                    },
                    child: const Text('Uygula'),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                children: [
                  _SectionTitle('Genel'),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Config adı',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text('Renk',
                      style: TextStyle(
                          fontSize: 13, color: Colors.grey.shade600)),
                  const SizedBox(height: 8),
                  _ColorPicker(
                    selected: _color,
                    onChanged: (c) => setState(() => _color = c),
                  ),
                  const SizedBox(height: 20),

                  _SectionTitle('GPS Filtre Eşikleri'),
                  _SliderRow(
                    label: 'Doğruluk eşiği',
                    unit: 'm',
                    value: _accuracyThreshold,
                    min: 1,
                    max: 200,
                    divisions: 199,
                    maxLabel: '∞ (kapalı)',
                    onChanged: (v) =>
                        setState(() => _accuracyThreshold = v),
                    displayValue: _accuracyThreshold >= 200
                        ? '∞'
                        : '${_accuracyThreshold.round()} m',
                    hint:
                        'GPS cihazının raporladığı yatay hata. Düşük = daha katı.',
                  ),
                  _SliderRow(
                    label: 'Maks. hız',
                    unit: 'km/h',
                    value: _maxSpeedKmh,
                    min: 5,
                    max: 200,
                    divisions: 195,
                    maxLabel: '∞ (kapalı)',
                    onChanged: (v) => setState(() => _maxSpeedKmh = v),
                    displayValue: _maxSpeedKmh >= 200
                        ? '∞'
                        : '${_maxSpeedKmh.round()} km/h',
                    hint: 'Anlık hız bu değeri geçen noktalar reddedilir.',
                  ),
                  _SliderRow(
                    label: 'Maks. örtülü hız',
                    unit: 'km/h',
                    value: _maxImpliedSpeedKmh,
                    min: 10,
                    max: 300,
                    divisions: 290,
                    maxLabel: '∞ (kapalı)',
                    onChanged: (v) =>
                        setState(() => _maxImpliedSpeedKmh = v),
                    displayValue: _maxImpliedSpeedKmh >= 300
                        ? '∞'
                        : '${_maxImpliedSpeedKmh.round()} km/h',
                    hint:
                        'İki ardışık nokta arasındaki mesafe/zaman oranı. GPS sıçramalarını yakalar.',
                  ),
                  _SliderRow(
                    label: 'Dur. hız eşiği',
                    unit: 'm/s',
                    value: _stationarySpeedThreshold,
                    min: 0,
                    max: 3,
                    divisions: 30,
                    onChanged: (v) =>
                        setState(() => _stationarySpeedThreshold = v),
                    displayValue:
                        '${_stationarySpeedThreshold.toStringAsFixed(1)} m/s',
                    hint:
                        'Bu hızın altındaki noktalar "duruyorsun" sayılır, zayıf GPS ile birleşince reddedilir.',
                  ),
                  _SliderRow(
                    label: 'Zayıf doğruluk eşiği',
                    unit: 'm',
                    value: _poorAccuracyThreshold,
                    min: 1,
                    max: 100,
                    divisions: 99,
                    maxLabel: '∞ (kapalı)',
                    onChanged: (v) =>
                        setState(() => _poorAccuracyThreshold = v),
                    displayValue: _poorAccuracyThreshold >= 100
                        ? '∞'
                        : '${_poorAccuracyThreshold.round()} m',
                    hint:
                        '"Duruyorsun" kontrolü için kullanılır: bu değerin üstündeki doğruluk = zayıf GPS.',
                  ),

                  const SizedBox(height: 20),
                  _SectionTitle('Mesafe Eşikleri'),
                  _SliderRow(
                    label: 'Isınma süresi',
                    unit: 'nokta',
                    value: _warmUpCount,
                    min: 0,
                    max: 30,
                    divisions: 30,
                    onChanged: (v) => setState(() => _warmUpCount = v),
                    displayValue: '${_warmUpCount.round()} nokta',
                    hint:
                        'İlk N noktada filtreler gevşetilir (GPS henüz sabitlenmemiştir).',
                  ),
                  _SliderRow(
                    label: 'Min. mesafe (ısınma)',
                    unit: 'm',
                    value: _warmUpMinDistance,
                    min: 0,
                    max: 20,
                    divisions: 40,
                    onChanged: (v) =>
                        setState(() => _warmUpMinDistance = v),
                    displayValue:
                        '${_warmUpMinDistance.toStringAsFixed(1)} m',
                    hint:
                        'Isınma evresinde iki nokta arasındaki minimum mesafe.',
                  ),
                  _SliderRow(
                    label: 'Min. mesafe (normal)',
                    unit: 'm',
                    value: _postWarmUpMinDistance,
                    min: 0,
                    max: 30,
                    divisions: 60,
                    onChanged: (v) =>
                        setState(() => _postWarmUpMinDistance = v),
                    displayValue:
                        '${_postWarmUpMinDistance.toStringAsFixed(1)} m',
                    hint:
                        'Isınma sonrasında iki nokta arasındaki minimum mesafe.',
                  ),

                  const SizedBox(height: 20),
                  Row(
                    children: [
                      _SectionTitle('Kalman Filtresi'),
                      const Spacer(),
                      Switch(
                        value: _useKalman,
                        onChanged: (v) =>
                            setState(() => _useKalman = v),
                      ),
                    ],
                  ),
                  if (_useKalman) ...[
                    const SizedBox(height: 4),
                    _DiscreteRow(
                      label: 'Process Noise (Q)',
                      options: _kalmanQOptions,
                      selected: _kalmanQ,
                      onChanged: (v) => setState(() => _kalmanQ = v),
                      hint:
                          'Küçük Q = modele daha fazla güven → daha düzgün ama yavaş tepki.\nBüyük Q = ölçüme daha fazla güven → hızlı tepki ama daha az düzgün.',
                    ),
                    _DiscreteRow(
                      label: 'Measurement Noise (R)',
                      options: _kalmanROptions,
                      selected: _kalmanR,
                      onChanged: (v) => setState(() => _kalmanR = v),
                      hint:
                          'Büyük R = GPS ölçümüne az güven → daha fazla düzleştirme.',
                    ),
                  ] else
                    Padding(
                      padding: const EdgeInsets.only(top: 4, bottom: 8),
                      child: Text(
                        'Kalman kapalıyken GPS noktaları ham koordinatlarıyla kullanılır.',
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey.shade500),
                      ),
                    ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _SheetHandle extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 4),
      child: Center(
        child: Container(
          width: 36,
          height: 4,
          decoration: BoxDecoration(
            color: Colors.grey.shade300,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: Theme.of(context).colorScheme.primary,
      ),
    );
  }
}

class _ColorPicker extends StatelessWidget {
  final Color selected;
  final ValueChanged<Color> onChanged;

  const _ColorPicker({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      children: GpsFilterParams.selectableColors.map((color) {
        final isSelected = color.value == selected.value;
        return GestureDetector(
          onTap: () => onChanged(color),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? Colors.black87 : Colors.transparent,
                width: 2.5,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: color.withValues(alpha: 0.5),
                        blurRadius: 6,
                      )
                    ]
                  : null,
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _SliderRow extends StatelessWidget {
  final String label;
  final String unit;
  final double value;
  final double min;
  final double max;
  final int divisions;
  final String? maxLabel;
  final ValueChanged<double> onChanged;
  final String displayValue;
  final String hint;

  const _SliderRow({
    required this.label,
    required this.unit,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    this.maxLabel,
    required this.onChanged,
    required this.displayValue,
    required this.hint,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(label,
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w500)),
              ),
              Text(
                displayValue,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 3,
              thumbShape:
                  const RoundSliderThumbShape(enabledThumbRadius: 8),
              overlayShape:
                  const RoundSliderOverlayShape(overlayRadius: 16),
            ),
            child: Slider(
              value: value,
              min: min,
              max: max,
              divisions: divisions,
              onChanged: onChanged,
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('$min $unit',
                  style: TextStyle(
                      fontSize: 10, color: Colors.grey.shade400)),
              Text(maxLabel ?? '$max $unit',
                  style: TextStyle(
                      fontSize: 10, color: Colors.grey.shade400)),
            ],
          ),
          const SizedBox(height: 2),
          Text(hint,
              style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
          const SizedBox(height: 10),
        ],
      ),
    );
  }
}

class _DiscreteRow extends StatelessWidget {
  final String label;
  final List<double> options;
  final double selected;
  final ValueChanged<double> onChanged;
  final String hint;

  const _DiscreteRow({
    required this.label,
    required this.options,
    required this.selected,
    required this.onChanged,
    required this.hint,
  });

  String _fmt(double v) {
    if (v < 0.001) return v.toStringAsExponential(0);
    return v.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          Row(
            children: options.map((opt) {
              final isSelected = (opt - selected).abs() < opt * 0.01;
              return Expanded(
                child: GestureDetector(
                  onTap: () => onChanged(opt),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    padding: const EdgeInsets.symmetric(vertical: 7),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Theme.of(context).colorScheme.primary
                          : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      _fmt(opt),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isSelected
                            ? Colors.white
                            : Colors.grey.shade700,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 6),
          Text(hint,
              style:
                  TextStyle(fontSize: 11, color: Colors.grey.shade500)),
        ],
      ),
    );
  }
}
