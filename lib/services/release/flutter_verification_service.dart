import 'dart:io';

enum VerificationStatus { passed, failed, skipped }

class VerificationStep {
  const VerificationStep({
    required this.name,
    required this.status,
    required this.output,
  });

  final String name;
  final VerificationStatus status;
  final String output;
}

class FlutterVerificationService {
  Future<List<VerificationStep>> run({
    bool runAnalyze = true,
    bool runTests = true,
    bool runBuild = true,
  }) async {
    final steps = <VerificationStep>[];

    if (runAnalyze) {
      steps.add(await _run('flutter analyze'));
    }
    if (runTests) {
      steps.add(await _run('flutter test'));
    }
    if (runBuild) {
      steps.add(await _run('flutter build apk --release'));
    }
    return steps;
  }

  Future<VerificationStep> _run(String command) async {
    final parts = command.split(' ');
    try {
      final process = await Process.run(parts.first, parts.skip(1).toList());
      final output = '${process.stdout}\n${process.stderr}'.trim();
      return VerificationStep(
        name: command,
        status: process.exitCode == 0
            ? VerificationStatus.passed
            : VerificationStatus.failed,
        output: output,
      );
    } catch (error) {
      return VerificationStep(
        name: command,
        status: VerificationStatus.failed,
        output: error.toString(),
      );
    }
  }
}
