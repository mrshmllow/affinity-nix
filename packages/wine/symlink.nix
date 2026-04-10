{ runCommand }:
{ wine }:
runCommand "wine-symlink" { inherit wine; } ''
  mkdir -p $out/bin
  for f in $wine/bin/*; do
    cp -L "$f" $out/bin/
  done

  ln -s "$wine/bin/wine" $out/bin/wine64
  for dir in include lib share; do
    ln -s "$wine/$dir" $out
  done

  patchShebangs $out
''
