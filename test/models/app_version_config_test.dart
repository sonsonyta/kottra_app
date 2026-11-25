import 'package:flutter_test/flutter_test.dart';
import 'package:kottra_app/models/app_version_config.dart';

void main() {
  group('compareVersions', () {
    test('orders by major, minor, patch', () {
      expect(compareVersions('1.9.7', '1.9.8'), lessThan(0));
      expect(compareVersions('1.10.0', '1.9.9'), greaterThan(0));
      expect(compareVersions('2.0', '1.99.99'), greaterThan(0));
      expect(compareVersions('1.9.8', '1.9.8'), 0);
    });

    test('the build number only matters when both sides have one', () {
      expect(compareVersions('1.9.8+30', '1.9.8'), 0);
      expect(compareVersions('1.9.8+29', '1.9.8+30'), lessThan(0));
    });
  });

  group('AppVersionConfig.fromMap', () {
    test('needs a numeric latestVersion', () {
      expect(AppVersionConfig.fromMap(null), isNull);
      expect(AppVersionConfig.fromMap({}), isNull);
      expect(AppVersionConfig.fromMap({'latestVersion': 'soon'}), isNull);
      expect(AppVersionConfig.fromMap({'latestVersion': ' '}), isNull);
    });

    test('reads the optional fields and picks notes by language', () {
      final c = AppVersionConfig.fromMap({
        'latestVersion': '1.9.8',
        'minVersion': '',
        'iosUrl': 'https://apps.apple.com/app/id1',
        'releaseNotes': 'Holiday pay',
      })!;
      expect(c.minVersion, isNull);
      expect(c.iosUrl, 'https://apps.apple.com/app/id1');
      expect(c.notesFor('km'), 'Holiday pay'); // falls back to English
    });
  });

  group('AppVersionConfig.fromRemoteValues', () {
    test('maps the Remote Config parameters; unset ones are empty', () {
      final values = {
        'latest_version': '1.9.8',
        'min_version': '1.9.5',
        'release_notes_kh': 'ប្រាក់ធ្វើការថ្ងៃបុណ្យ',
      };
      final c = AppVersionConfig.fromRemoteValues((k) => values[k] ?? '')!;
      expect(c.latestVersion, '1.9.8');
      expect(c.minVersion, '1.9.5');
      expect(c.iosUrl, isNull);
      expect(c.androidUrl, isNull);
      expect(c.notesFor('km'), 'ប្រាក់ធ្វើការថ្ងៃបុណ្យ');
      expect(c.notesFor('en'), isNull);
    });

    test('nothing published → no config', () {
      expect(AppVersionConfig.fromRemoteValues((_) => ''), isNull);
    });
  });

  group('updateStatusFor', () {
    const config = AppVersionConfig(
      latestVersion: '1.9.8',
      minVersion: '1.9.5',
    );

    test('newer release → optional; below minimum → required', () {
      expect(updateStatusFor('1.9.7+29', config), UpdateStatus.optional);
      expect(updateStatusFor('1.9.4+20', config), UpdateStatus.required);
    });

    test('up to date, ahead, or no config → none', () {
      expect(updateStatusFor('1.9.8+30', config), UpdateStatus.none);
      expect(updateStatusFor('1.9.9', config), UpdateStatus.none);
      expect(updateStatusFor('1.9.7', null), UpdateStatus.none);
    });
  });

  group('shouldRemind', () {
    final now = DateTime(2026, 11, 25, 9);

    test('reminds again a day after Later, or at once for a newer release', () {
      bool remind(String snoozed, Duration ago) => shouldRemind(
        latestVersion: '1.9.8',
        snoozedVersion: snoozed,
        snoozedAt: now.subtract(ago),
        now: now,
      );
      expect(remind('1.9.8', const Duration(hours: 2)), isFalse);
      expect(remind('1.9.8', const Duration(hours: 25)), isTrue);
      expect(remind('1.9.7', const Duration(hours: 2)), isTrue);
    });

    test('reminds when never snoozed', () {
      expect(
        shouldRemind(
          latestVersion: '1.9.8',
          snoozedVersion: null,
          snoozedAt: null,
          now: now,
        ),
        isTrue,
      );
    });
  });
}
