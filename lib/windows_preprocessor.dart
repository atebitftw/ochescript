import 'dart:io';

import 'package:oche_script/oche_script.dart' show IncludesPreprocesser;

/// OcheScript Includes Preprocessor for windows platform.
class WindowsPlatformPreProcessor extends IncludesPreprocesser {
  final Set<String> librarySearchPaths;

  WindowsPlatformPreProcessor({required this.librarySearchPaths});

  /// Returns a list of files to be included in the compilation process.
  @override
  Future<Map<String, String>> getLibraries(String source) async {
    final libraries = getLibraryNamesToInclude(source);
    // using map ensures that duplicate library dependencies are resolved only once.
    final processed = <String, String>{};

    if (libraries.isEmpty) {
      return processed;
    }

    for (final libraryName in libraries) {
      final librarySourceCode = _getLibraryFile(libraryName);
      if (librarySourceCode.isNotEmpty) {
        processed[libraryName] = librarySourceCode;
        // recursively process the library dependencies.
        processed.addAll(await getLibraries(librarySourceCode));
      }
    }

    return processed;
  }

  String _getLibraryFile(String lib) {
    for (final path in librarySearchPaths) {
      final file = File("$path/$lib.oche");
      if (file.existsSync()) {
        return file.readAsStringSync();
      }
    }

    throw Exception("Library $lib not found on any provided path(s). Paths: $librarySearchPaths");
  }
}
