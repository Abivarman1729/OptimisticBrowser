from pathlib import Path
import json

root = Path(__file__).resolve().parents[1]
required = [
    'lib/services/advanced/search_advanced_service.dart',
    'lib/services/advanced/privacy_policy_service.dart',
    'lib/services/advanced/ai_workspace_service.dart',
    'lib/services/advanced/notebook_service.dart',
    'lib/services/advanced/library_service.dart',
    'test/advanced/v5_services_test.dart',
]
missing = [p for p in required if not (root / p).exists()]
if missing:
    raise SystemExit('Missing required V5 files: ' + ', '.join(missing))
print('V5 structural verification: PASS')
print('Required advanced modules:', len(required))
print('Flutter compile/test must still be run on a machine with Flutter SDK installed.')
