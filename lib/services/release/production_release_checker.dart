import 'dart:io';

enum ReleaseCheckSeverity { info, warning, error }

class ReleaseCheck {
  const ReleaseCheck({
    required this.name,
    required this.severity,
    required this.message,
  });

  final String name;
  final ReleaseCheckSeverity severity;
  final String message;

  bool get passed => severity != ReleaseCheckSeverity.error;
}

class ProductionReleaseReport {
  const ProductionReleaseReport(this.checks);

  final List<ReleaseCheck> checks;

  bool get passed => checks.every((e) => e.passed);
  int get errors =>
      checks.where((e) => e.severity == ReleaseCheckSeverity.error).length;
  int get warnings =>
      checks.where((e) => e.severity == ReleaseCheckSeverity.warning).length;
}

class ProductionReleaseChecker {
  Future<ProductionReleaseReport> run({
    required String version,
    required bool debugMode,
    required bool hasSigningConfig,
    required bool hasTests,
    required bool hasPrivacyPolicy,
  }) async {
    final checks = <ReleaseCheck>[
      ReleaseCheck(
        name: 'version',
        severity: version.trim().isEmpty
            ? ReleaseCheckSeverity.error
            : ReleaseCheckSeverity.info,
        message: version.trim().isEmpty
            ? 'Release version is missing.'
            : 'Version $version is configured.',
      ),
      ReleaseCheck(
        name: 'debug',
        severity:
            debugMode ? ReleaseCheckSeverity.error : ReleaseCheckSeverity.info,
        message: debugMode
            ? 'Debug mode must be disabled for production.'
            : 'Production mode enabled.',
      ),
      ReleaseCheck(
        name: 'signing',
        severity: hasSigningConfig
            ? ReleaseCheckSeverity.info
            : ReleaseCheckSeverity.error,
        message: hasSigningConfig
            ? 'Release signing is configured.'
            : 'Release signing configuration is missing.',
      ),
      ReleaseCheck(
        name: 'tests',
        severity:
            hasTests ? ReleaseCheckSeverity.info : ReleaseCheckSeverity.error,
        message: hasTests ? 'Automated tests are present.' : 'Tests are missing.',
      ),
      ReleaseCheck(
        name: 'privacy',
        severity: hasPrivacyPolicy
            ? ReleaseCheckSeverity.info
            : ReleaseCheckSeverity.warning,
        message: hasPrivacyPolicy
            ? 'Privacy policy is configured.'
            : 'Privacy policy should be reviewed.',
      ),
      ReleaseCheck(
        name: 'platform',
        severity: Platform.isAndroid || Platform.isIOS
            ? ReleaseCheckSeverity.info
            : ReleaseCheckSeverity.warning,
        message: 'Release check executed on ${Platform.operatingSystem}.',
      ),
    ];
    return ProductionReleaseReport(checks);
  }
}
