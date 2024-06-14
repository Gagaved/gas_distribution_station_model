import 'dart:io';

import 'package:file_picker/file_picker.dart';

import '../../models/gas_network.dart';

class FileManager {
  static Future<bool> writeGasNetwork(
    GasNetwork network,
    String fileName,
  ) async {
    String? outputFile = await FilePicker.platform.saveFile(
      dialogTitle: 'Please select an output file:',
      fileName: '$fileName.json',
    );

    if (outputFile != null) {
      final jsonString = network.toJson();
      final file = File(outputFile);
      file.writeAsStringSync(jsonString);
      return true;
    }
    return false;
  }

  static Future<GasNetwork?> getGraphFromFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();

    if (result != null) {
      File file = File(result.files.single.path!);
      final jsonString = file.readAsStringSync();
      return GasNetworkMapper.fromJson(jsonString);
    }
    return null;
  }
}
