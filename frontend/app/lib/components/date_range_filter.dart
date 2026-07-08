import 'package:fluent_ui/fluent_ui.dart';

enum DateRangeType {
  last7Days,
  currentMonth,
  lastMonth,
  last30Days,
  last60Days,
}

class DateRangeFilter extends StatefulWidget {
  final void Function(DateTime? startDate, DateTime? endDate) onRangeSelected;
  final DateRangeType? initialValue;

  const DateRangeFilter({
    super.key,
    required this.onRangeSelected,
    this.initialValue,
  });

  @override
  State<DateRangeFilter> createState() => _DateRangeFilterState();
}

class _DateRangeFilterState extends State<DateRangeFilter> {
  DateRangeType? _selectedValue;

  @override
  void initState() {
    super.initState();
    _selectedValue = widget.initialValue;
  }

  void _applyRange(DateRangeType? type) {
    setState(() {
      _selectedValue = type;
    });

    if (type == null) {
      widget.onRangeSelected(null, null);
      return;
    }

    final now = DateTime.now();
    DateTime? startDate;
    DateTime? endDate = now;

    switch (type) {
      case DateRangeType.last7Days:
        startDate = now.subtract(const Duration(days: 7));
        break;
      case DateRangeType.currentMonth:
        startDate = DateTime(now.year, now.month, 1);
        break;
      case DateRangeType.lastMonth:
        startDate = DateTime(now.year, now.month - 1, 1);
        endDate = DateTime(now.year, now.month, 0); // Ultimo dia del mes pasado
        break;
      case DateRangeType.last30Days:
        startDate = now.subtract(const Duration(days: 30));
        break;
      case DateRangeType.last60Days:
        startDate = now.subtract(const Duration(days: 60));
        break;
    }

    widget.onRangeSelected(startDate, endDate);
  }

  @override
  Widget build(BuildContext context) {
    return ComboBox<DateRangeType>(
      value: _selectedValue,
      placeholder: const Text('Filtrar por Fecha'),
      items: const [
        ComboBoxItem(
          value: DateRangeType.last7Days,
          child: Text('7 días'),
        ),
        ComboBoxItem(
          value: DateRangeType.currentMonth,
          child: Text('Mes actual'),
        ),
        ComboBoxItem(
          value: DateRangeType.lastMonth,
          child: Text('Mes pasado'),
        ),
        ComboBoxItem(
          value: DateRangeType.last30Days,
          child: Text('1 mes (últimos 30)'),
        ),
        ComboBoxItem(
          value: DateRangeType.last60Days,
          child: Text('2 meses (últimos 60)'),
        ),
      ],
      onChanged: _applyRange,
    );
  }
}
