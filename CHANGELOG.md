# 1.0.0
Public release.

# 1.0.0+2
- Fixed static type annotations.

# 1.0.1
- Updated dartdocs
- Updated README.md

# 1.0.2
- Fixed documentation.

# 1.0.3
- Changed [IncludesPreprocesser] to return a `Future<Map<String, String>>` instead of `Map<String, String>`.

# 1.0.4
- Linter pass.

# 1.0.5
- `dart format` pass.

# 1.0.6
- Linter pass.

# 1.0.7
- Dart CI workflow and badge.

# 1.1.0
- Added try/catch feature.

# 1.1.1
- Enchanced documentation.

# 1.1.2
- More documentation enhancements.

# 1.1.3
- Improved unhandled exceptions so that they report to the calling dart code via the returned map:
```js
{
  "error": "message",
  "return_code": 1
}
```