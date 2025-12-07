## How to run scripts
if the bin/oche.dart is executable, then run:
```bash
oche {script_file}
```

If the bin/oche.dart is not executable, then run:
```bash
dart run bin/oche.dart {script_file}
```

### Path Considerations
In both cases make sure you are in the same diretory as the script and that the script has access to any libraries it needs in the "includes" directory, which should reside in the same directory as the script.  See `tool/scripts`.