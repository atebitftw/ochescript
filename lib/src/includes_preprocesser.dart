import 'package:meta/meta.dart';

/// A base class for "includes" preprocessers.  Includes preprocessers are used to returns a list of files to include in the
/// source code file before it is compiled.  This allows for some platform specific preprocessing.
///
/// For example, the Windows preprocesser will look for #include directives and include the appropriate
/// files from the file system.
///
/// A flutter app may source the files from an asset bundle.
abstract class IncludesPreprocesser {
  /// Returns a map of files to be included in the compilation process.
  ///
  /// The key is the library name and the value is the source code of the library.
  Map<String, String> getLibraries(String source);

  /// A helper method that parses the source code and returns a list of library names to include.
  /// This method should not be overridden.
  @nonVirtual
  List<String> getLibraryNamesToInclude(String source) {
    return source
        .split('\n')
        .where((line) {
          return line.trim().toLowerCase().startsWith("#include");
        })
        .map((line) {
          final includeLibrary = line.trim().split(" ")[1];
          return includeLibrary.trim().toLowerCase();
        })
        .toList();
  }
}
