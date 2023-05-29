import 'dart:typed_data';

extension Float32ListExtension on Float32List {
  List<List<List<List<double>>>> reshape(List<int> shape) {
    int batchSize = shape[0];
    int height = shape[1];
    int width = shape[2];
    int channels = shape[3];

    List<List<List<List<double>>>> result = List.generate(
        batchSize,
        (_) => List.generate(
            height,
            (_) => List.generate(
                width, (_) => List.generate(channels, (_) => 0.0))));

    int index = 0;
    for (int b = 0; b < batchSize; b++) {
      for (int h = 0; h < height; h++) {
        for (int w = 0; w < width; w++) {
          for (int c = 0; c < channels; c++) {
            result[b][h][w][c] = this[index++];
          }
        }
      }
    }
    return result;
  }
}
