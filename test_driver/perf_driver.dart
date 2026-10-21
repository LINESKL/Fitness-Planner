import 'package:integration_test/integration_test_driver.dart';

/// Пишет отчёт о кадрах в build/catalog_perf.json.
Future<void> main() => integrationDriver(
  responseDataCallback: (data) async {
    if (data != null) {
      await writeResponseData(data, testOutputFilename: 'catalog_perf');
    }
  },
);
