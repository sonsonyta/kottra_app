import 'package:flutter_test/flutter_test.dart';
import 'package:kottra_app/models/pending_attendance_action.dart';
import 'package:kottra_app/services/offline_attendance_queue.dart';

class InMemoryPendingStore implements PendingActionStore {
  final Map<String, List<String>> data = {};

  @override
  Future<List<String>> read(String key) async => data[key] ?? const [];

  @override
  Future<void> write(String key, List<String> values) async {
    if (values.isEmpty) {
      data.remove(key);
    } else {
      data[key] = List.of(values);
    }
  }
}

PendingAttendanceAction _action(String id, {PendingAttendanceKind? kind}) =>
    PendingAttendanceAction(
      localId: id,
      kind: kind ?? PendingAttendanceKind.checkIn,
      storeId: 'store-1',
      employeeId: 'emp-1',
      clientEventAt: 1000,
    );

void main() {
  group('OfflineAttendanceQueue', () {
    test('enqueues, keeps FIFO order, and removes by id', () async {
      final queue = OfflineAttendanceQueue(store: InMemoryPendingStore());
      await queue.loadFor('store-1', 'emp-1');

      await queue.enqueue(_action('a'));
      await queue.enqueue(_action('b', kind: PendingAttendanceKind.checkOut));

      expect(queue.actions.map((a) => a.localId), ['a', 'b']);

      await queue.remove('a');
      expect(queue.actions.map((a) => a.localId), ['b']);
      expect(queue.isNotEmpty, isTrue);
    });

    test('persists across reloads through the backing store', () async {
      final store = InMemoryPendingStore();
      final queue = OfflineAttendanceQueue(store: store);
      await queue.loadFor('store-1', 'emp-1');
      await queue.enqueue(_action('a'));

      final reloaded = OfflineAttendanceQueue(store: store);
      await reloaded.loadFor('store-1', 'emp-1');

      expect(reloaded.actions.single.localId, 'a');
      expect(reloaded.actions.single.clientEventAt, 1000);
    });

    test('scopes actions per employee', () async {
      final store = InMemoryPendingStore();
      final queue = OfflineAttendanceQueue(store: store);
      await queue.loadFor('store-1', 'emp-1');
      await queue.enqueue(_action('a'));

      final other = OfflineAttendanceQueue(store: store);
      await other.loadFor('store-1', 'emp-2');

      expect(other.isEmpty, isTrue,
          reason: 'a different employee sees its own empty queue');
    });

    test('notifies listeners on change', () async {
      final queue = OfflineAttendanceQueue(store: InMemoryPendingStore());
      await queue.loadFor('store-1', 'emp-1');
      var notifications = 0;
      queue.addListener(() => notifications++);

      await queue.enqueue(_action('a'));
      await queue.remove('a');

      expect(notifications, 2);
    });
  });
}
