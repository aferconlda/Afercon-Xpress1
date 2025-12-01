
import 'package:intl/intl.dart';

class CurrencyFormatter {
  static String format(num amount) {
    // O NumberFormat pode não ter o locale 'pt_AO' por defeito, então vamos construir manualmente
    final customFormat = NumberFormat('#,##0.00 AOA', 'pt_PT');

    return customFormat.format(amount);
  }
}
