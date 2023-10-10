
NVIM_COMMAND = "lua MiniTest.run()"

ifdef file
NVIM_COMMAND = "lua MiniTest.run_file([["$(file)"]])"
endif

# Run all test files
.PHONY: test
test:
	nvim --headless --noplugin -u ./scripts/mini_test_init.lua -c $(NVIM_COMMAND)

# Format code
.PHONY: format
format:
	stylua .
	alejandra .
