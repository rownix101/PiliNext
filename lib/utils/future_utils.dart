import 'dart:async';

Future<List<T>> limitedFutureWait<T>(
  Iterable<Future<T>> futures, {
  int maxConcurrency = 6,
}) async {
  if (futures.isEmpty) return <T>[];
  if (maxConcurrency <= 0) maxConcurrency = 1;

  final results = <T>[];
  final iterator = futures.iterator;
  var active = 0;

  final completer = Completer<List<T>>();

  void schedule() {
    while (active < maxConcurrency) {
      if (!iterator.moveNext()) {
        if (active == 0) {
          completer.complete(results);
        }
        return;
      }
      active++;
      iterator.current.then((value) {
        results.add(value);
        active--;
        schedule();
      }).catchError((_) {
        active--;
        schedule();
      });
    }
  }

  schedule();
  return completer.future;
}
