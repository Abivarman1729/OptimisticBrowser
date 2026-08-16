import 'package:flutter_test/flutter_test.dart';
import 'package:optimistic_browser/core/features/feature_registry.dart';

void main() {
  test('registry distinguishes implemented, partial and planned capabilities', () {
    final privateTabs = FeatureRegistry.all.firstWhere((f) => f.id == 'private_tabs');
    final downloads = FeatureRegistry.all.firstWhere((f) => f.id == 'downloads');
    final askPage = FeatureRegistry.all.firstWhere((f) => f.id == 'ask_page');

    expect(privateTabs.status, FeatureStatus.partial);
    expect(downloads.status, FeatureStatus.planned);
    expect(askPage.status, FeatureStatus.partial);
  });
}
