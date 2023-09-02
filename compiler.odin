package main

import "core:fmt"
import "core:time"

Byte_Code :: enum (u8) {
	Inc,
	Dec,
	IncBy,
	DecBy,
	Mem_Left,
	Mem_Right,
	Mem_Left_By,
	Mem_Right_By,
	Print,
	Input,
	Jz,
	Jnz,
}

Compiler :: struct {
	source: []u8,
	code:   [dynamic]u8,
	ip:     int,
}

opcode_map := map[u8]Byte_Code {
	'+' = Byte_Code.Inc,
	'-' = Byte_Code.Dec,
	'<' = Byte_Code.Mem_Left,
	'>' = Byte_Code.Mem_Right,
}

many_opcode_map := map[u8]Byte_Code {
	'+' = Byte_Code.IncBy,
	'-' = Byte_Code.DecBy,
	'<' = Byte_Code.Mem_Left_By,
	'>' = Byte_Code.Mem_Right_By,
}

compiler_new :: proc(source: []u8) -> Compiler {
	return Compiler{source, make([dynamic]u8), 0}
}

compiler_destroy :: proc() {
	delete(opcode_map)
	delete(many_opcode_map)
}

compile :: proc(compiler: ^Compiler) -> ([]u8, bool) {
	for compiler.ip < len(compiler.source) {
		if !compile_inst(compiler) {
			delete(compiler.code)
			return nil, false
		}
	}

	return compiler.code[:], true
}

peek :: proc(compiler: ^Compiler) -> u8 {
	if compiler.ip >= len(compiler.source) {
		return 0
	}

	return compiler.source[compiler.ip]
}

advance :: #force_inline proc(compiler: ^Compiler) {
	compiler.ip += 1
}

compile_inst :: proc(compiler: ^Compiler) -> bool {
	switch peek(compiler) {
	case '+':
		compile_many_op(compiler, '+')
	case '-':
		compile_many_op(compiler, '-')

	case '>':
		compile_many_op(compiler, '>')
	case '<':
		compile_many_op(compiler, '<')

	case ',':
		append(&compiler.code, u8(Byte_Code.Input))
		advance(compiler)
	case '.':
		append(&compiler.code, u8(Byte_Code.Print))
		advance(compiler)

	case '[':
		return compile_block(compiler)
	}


	return true
}

compile_many_op :: proc(compiler: ^Compiler, char: u8) -> bool {
	count := 0

	for c := peek(compiler); c != 0 && c == char; c = peek(compiler) {
		count += 1
		advance(compiler)
	}

	single_operator := opcode_map[char] or_return
	many_operator := many_opcode_map[char] or_return

	for count > 0 {
		if count >= 255 {
			append(&compiler.code, u8(many_operator), u8(255))
			count -= 255
		} else if count > 1 {
			append(&compiler.code, u8(many_operator), u8(count))
			count = 0
		} else {
			append(&compiler.code, u8(single_operator))
			count = 0
		}
	}

	return true
}

compile_jump :: proc(compiler: ^Compiler, op: Byte_Code, loc: u8) {
	append(&compiler.code, u8(op), loc)
	compiler.ip += 1
}

compile_block :: proc(compiler: ^Compiler) -> bool {
	loc := u8(len(compiler.code))
	compile_jump(compiler, .Jz, 0)

	for compiler.ip < len(compiler.source) && compiler.source[compiler.ip] != ']' {
		compile_inst(compiler) or_return
	}

	if compiler.ip >= len(compiler.source) || compiler.source[compiler.ip] != ']' {
		fmt.printf(
			"End of block expected at %d but received '%c'\n",
			compiler.ip,
			compiler.ip >= len(compiler.source) ? 0 : compiler.source[compiler.ip],
		)
		return false
	}

	compile_jump(compiler, .Jnz, loc)
	compiler.code[int(loc + 1)] = u8(len(compiler.code))

	return true
}

debug_code :: proc(code: []u8) {
	fmt.printf("=== Code %d ===\n", len(code))

	index := 0
	for index < len(code) {
		fmt.printf("%04d | ", index)

		switch cast(Byte_Code)code[index] {
		case .Inc:
			simple_instruction(&index, "INC")
		case .Dec:
			simple_instruction(&index, "DEC")

		case .IncBy:
			byte_instruction(&index, "INC_BY", code)
		case .DecBy:
			byte_instruction(&index, "DEC_BY", code)

		case .Mem_Left:
			simple_instruction(&index, "MEM_LEFT")
		case .Mem_Right:
			simple_instruction(&index, "MEM_RIGHT")

		case .Mem_Left_By:
			byte_instruction(&index, "MEM_LEFT_BY", code)
		case .Mem_Right_By:
			byte_instruction(&index, "MEM_RIGHT_BY", code)

		case .Input:
			simple_instruction(&index, "INPUT")
		case .Print:
			simple_instruction(&index, "PRINT")

		case .Jz:
			jump_instruction(&index, "JUMP_ZERO", code)
		case .Jnz:
			jump_instruction(&index, "JUMP_NON_ZERO", code)
		}
	}
}

simple_instruction :: proc(index: ^int, label: string) {
	fmt.println(label)
	index^ += 1
}

jump_instruction :: proc(index: ^int, label: string, code: []u8) {
	fmt.printf("%s %d\n", label, code[index^ + 1] + 1)
	index^ += 2
}

byte_instruction :: proc(index: ^int, label: string, code: []u8) {
	fmt.printf("%s %d\n", label, code[index^ + 1])
	index^ += 2
}
