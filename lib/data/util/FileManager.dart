import 'dart:io';

import '../../models/gas_network.dart';

class FileManager {
  static File writeGasNetwork(GasNetwork network, String filename) {
    final jsonString = network.toJson();
    final file = File(filename);
    file.writeAsStringSync(jsonString);
    return file;
  }

  static GasNetwork readPointsAndEdgesFromFile(File file) {
    final jsonString = file.readAsStringSync();
    return GasNetworkMapper.fromJson(jsonString);
  }
}
