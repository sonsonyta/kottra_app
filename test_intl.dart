import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

void main() async {
  await initializeDateFormatting();
  var date = DateTime.now();
  print(DateFormat.yMMMMEEEEd('en').format(date));
  print(DateFormat.yMMMMEEEEd('km').format(date));
}
