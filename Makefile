NVIM_COMMAND = "lua MiniTest.run()"

ifdef file
NVIM_COMMAND = "lua MiniTest.run_file([["$(file)"]])"
endif

ifdef coverage
export COVERAGE = 1
endif

# Clean out temporary files or other artifacts.
.PHONY: clean
clean:
	rm -rf target

# Format code
.PHONY: format
format:
	stylua .
	alejandra .

# Run all test files, or the file specified by `file=`.
.PHONY: test
test: target
	nvim --headless --noplugin -u ./scripts/mini_test_init.lua -c $(NVIM_COMMAND)
ifdef COVERAGE
	make target/coverage-report
endif

target/coverage.stats: export COVERAGE = 1
target/coverage.stats:
	make test

# Generate an HTML coverage report and fail if there are untested lines.
target/coverage-report target/coverage-summary.txt: target target/coverage.lcov
	genhtml target/coverage.lcov \
		--no-function-coverage \
		--no-branch-coverage \
		--output-directory target/coverage-report
	lcov --summary target/coverage.lcov \
		--fail-under-lines 100 \
		| tee target/coverage-summary.txt
	lcov --list target/coverage.lcov \
		| tee --append target/coverage-summary.txt

target/coverage.lcov: target/coverage.stats
	luacov -r lcov

# Create the `target` directory.
target:
	mkdir -p target
