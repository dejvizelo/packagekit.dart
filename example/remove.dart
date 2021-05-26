import 'dart:async';
import 'package:packagekit/packagekit.dart';

void main(List<String> args) async {
  if (args.isEmpty) {
    print('Need package name(s)');
    return;
  }
  var packageNames = args;

  var client = PackageKitClient();
  await client.connect();

  var resolveTransaction = await client.createTransaction();
  var resolveCompleter = Completer();
  var packageIds = <PackageKitPackageId>[];
  resolveTransaction.events.listen((event) {
    if (event is PackageKitPackageEvent) {
      packageIds.add(event.packageId);
    } else if (event is PackageKitFinishedEvent) {
      resolveCompleter.complete();
    }
  });
  await resolveTransaction.resolve(packageNames);
  await resolveCompleter.future;
  if (packageIds.isEmpty) {
    print('No packages found');
    await client.close();
    return;
  }

  var removeTransaction = await client.createTransaction();
  var removeCompleter = Completer();
  removeTransaction.events.listen((event) {
    if (event is PackageKitPackageEvent) {
      print('[${event.packageId.name}] ${event.info}');
    } else if (event is PackageKitItemProgressEvent) {
      print('[${event.packageId.name}] ${event.status} ${event.percentage}%');
    } else if (event is PackageKitErrorCodeEvent) {
      print('${event.code}: ${event.details}');
    } else if (event is PackageKitFinishedEvent) {
      removeCompleter.complete();
    }
  });
  await removeTransaction.removePackages(packageIds);
  await removeCompleter.future;

  await client.close();
}
