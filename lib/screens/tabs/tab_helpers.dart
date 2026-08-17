import 'package:intl/intl.dart';
import 'package:kottra_app/theme/locale_controller.dart';

String fmtTime(DateTime? t) {
  if (t == null) return '--:--';
  final h = t.hour.toString().padLeft(2, '0');
  final m = t.minute.toString().padLeft(2, '0');
  return '$h:$m';
}

String fmtDuration(Duration d) {
  final h = d.inHours;
  final m = d.inMinutes.remainder(60);
  return '${h}h ${m.toString().padLeft(2, '0')}m';
}

String fmtDateShort(DateTime d) =>
    DateFormat.MMMEd(LocaleController.instance.locale.languageCode).format(d);

String fmtDateFull(DateTime d) =>
    DateFormat.yMMMMEEEEd(LocaleController.instance.locale.languageCode)
        .format(d);

String greeting() {
  final h = DateTime.now().hour;
  if (h < 12) return 'Good morning';
  if (h < 17) return 'Good afternoon';
  return 'Good evening';
}

String fmtMoney(double amount, String currency) {
  final isUsd = currency == 'USD';
  final symbol = isUsd ? '\$' : '៛';
  final value = isUsd
      ? amount.toStringAsFixed(2)
      : amount.toStringAsFixed(0);
  return '$symbol$value';
}
