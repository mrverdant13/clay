import 'package:test/test.dart';

import 'helpers/clay_api.dart';
import 'helpers/integration_fixture.dart';

void main() {
  test(
    'discovers and loads clay.yaml from integration fixtures',
    () async {
      final fixture = IntegrationFixture.loadForTest('common');
      final project = await resolveClayProject(cwd: fixture.workingRoot.path);

      expect(project.configPath, fixture.configFile.path);
      expect(project.projectRoot, fixture.workingRoot.path);
      expect(project.config.reference, 'reference');
      expect(project.config.target, 'target');
      expect(project.referencePath, fixture.referenceDir.path);
    },
    tags: const ['e2e'],
  );
}
