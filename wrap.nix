{runCommandNoCC}: {wine}:
runCommandNoCC "wine-wrapped" {inherit wine;} ''
  mkdir -p $out/bin
  for f in $wine/bin/*; do
    ln -s "$f" $out/bin
  done
  ln -s "$wine/bin/wine" $out/bin/wine64
  for dir in include lib share; do
    ln -s "$wine/$dir" $out
  done
''
