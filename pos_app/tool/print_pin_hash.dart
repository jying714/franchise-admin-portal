import 'package:pos_app/core/utils/pin_hash.dart';

void main() {
  // ignore: avoid_print
  print(PinHash.hashPin('2222', saltHex: 'devsalt1'));
}
