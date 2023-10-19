{
  checks,
  luacov,
  cluacov,
  lcov,
}:
checks.tests.overrideCheck (old: {
  name = "luacov";
  description = ''
    Run tests, checking code coverage with `luacov` and `lcov`.
  '';

  nativeCheckInputs =
    (old.nativeCheckInputs or [])
    ++ [
      luacov
      cluacov
      lcov
    ];

  COVERAGE = true;

  installPhase = ''
    mkdir $out
    cp target/coverage.lcov $out/
    cp target/coverage-summary.txt $out/
    cp --recursive target/coverage-report $out/
  '';
})
