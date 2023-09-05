package main

import "core:fmt"
import "core:mem"
import "core:os"
import "core:strconv"
import "core:strings"

Dummy_Struct :: struct {
	hash: u32,
	code: []u8,
}

main :: proc() {
	defer delete(os.args)
	if len(os.args) != 2 {
		fmt.println("Usage: brainfrick file.bf")
		return
	}
	defer compiler_destroy()

	code, flags, ok := compile_or_load_src(os.args[1])
	if !ok {
		fmt.println("Failed to compile")
		return
	}
	defer delete(code)

	real_code := code
	if flags == Flags.From_File {
		real_code = code[8:]
	}

	vm := vm_new(flags, real_code)
	defer vm_destroy(&vm)

	// debug_code(code)

	fmt.printf("Result %s\n", vm_run(&vm))
	// vm_dump_memory(&vm)
}


compile_or_load_src :: proc(file_path: string) -> ([]u8, Flags, bool) {
	if !os.exists(file_path) {
		return nil, Flags.Error, false
	}

	source, ferr := os.read_entire_file(file_path)
	if !ferr {
		return nil, Flags.Error, false
	}
	defer delete(source)
	source_hash := hash_bytes(source)

	compiled_out_file := fmt.aprintf("%sc", file_path)
	defer delete(compiled_out_file)

	if os.exists(compiled_out_file) {
		code, ok := os.read_entire_file(compiled_out_file)
		if !ok {
			return nil, Flags.Error, false
		}

		hash: u64 = (^u64)(&code[0])^

		if hash == source_hash {
			fmt.printf("Reading from compiled file with hash %d\n", hash)
			return code, Flags.From_File, ok
		}
	}

	compiler := compiler_new(source)
	code, ok := compile(&compiler)
	if !ok {
		return nil, Flags.Error, false
	}

	b, err := strings.builder_make()
	if err != nil {
		return nil, Flags.Error, false
	}
	defer strings.builder_destroy(&b)

	strings.write_bytes(&b, mem.any_to_bytes(source_hash))
	strings.write_bytes(&b, code)

	os.write_entire_file(compiled_out_file, b.buf[:])
	return code, Flags.Compiled, true
}

hash_bytes :: proc(str: []u8) -> u64 {
	hash: u64 = 2166136261
	for b in str {
		hash ~= u64(b)
		hash *= 16777619
	}
	return hash
}
