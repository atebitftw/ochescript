class SourceLocation {
  final String file;
  final int line;

  SourceLocation(this.file, this.line);

  @override
  String toString() => "$file:$line";
}

class _SourceRange {
  final String name;
  final int start; // 1-based, inclusive
  final int end; // 1-based, inclusive

  _SourceRange(this.name, this.start, this.end);

  int get length => end - start + 1;
}

class SourceMapper {
  final List<_SourceRange> _ranges = [];
  final String _defaultFile;

  SourceMapper(String source, {String defaultFile = "script"}) : _defaultFile = defaultFile {
    _parse(source);
  }

  void _parse(String source) {
    final lines = source.split('\n');
    String? currentName;
    int? startLine;

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      final lineNum = i + 1;

      if (line.startsWith("// #source ")) {
        currentName = line.substring("// #source ".length).trim();
        startLine = lineNum;
      } else if (line.startsWith("// #end_source ") && currentName != null && startLine != null) {
        final endName = line.substring("// #end_source ".length).trim();
        if (endName == currentName) {
          _ranges.add(_SourceRange(currentName, startLine, lineNum));
          currentName = null;
          startLine = null;
        }
      }
    }
  }

  SourceLocation map(int line) {
    // Check if line is within any range
    for (final range in _ranges) {
      if (line >= range.start && line <= range.end) {
        // Found in a library/injected block
        // Line inside block.
        // If range starts at N. Marker is N. Content starts N+1.
        // We want Content Line 1 to be reported as 1.
        // So: line - startLine?
        // StartLine = N. line = N+1. Result 1. Correct.
        return SourceLocation(range.name, line - range.start);
      }
    }

    // Not in a range, so it's in the default file (main script)
    // Calculate offset by subtracting lengths of all ranges that appear *before* this line.
    int offset = 0;
    for (final range in _ranges) {
      if (range.end < line) {
        offset += range.length;
      }
    }

    return SourceLocation(_defaultFile, line - offset);
  }
}
