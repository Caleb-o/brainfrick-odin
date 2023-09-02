package main

import "core:fmt"
import "core:time"

Run_Result :: enum {
	Ok,
	Err,
}

VM :: struct {
	ip:     int,
	mp:     int,
	code:   []u8,
	memory: [dynamic]u8,
}

vm_new :: proc(code: []u8) -> VM {
	return VM{0, 0, code, make([dynamic]u8, 32)}
}

vm_destroy :: proc(vm: ^VM) {
	delete(vm.code)
	delete(vm.memory)
}

vm_run :: proc(vm: ^VM) -> Run_Result {
	for vm.ip < len(vm.code) {
		switch cast(Byte_Code)vm_read_byte(vm) {
		case .Inc:
			vm.memory[vm.mp] += 1
		case .Dec:
			vm.memory[vm.mp] -= 1

		case .IncBy:
			count := vm_read_byte(vm)
			vm.memory[vm.mp] += count
		case .DecBy:
			count := vm_read_byte(vm)
			vm.memory[vm.mp] -= count

		case .Mem_Left:
			vm.mp -= 1
			if vm.mp < 0 {
				vm.mp = len(vm.memory) - 1
			}
		case .Mem_Right:
			vm.mp += 1
			if vm.mp >= len(vm.memory) {
				resize(&vm.memory, len(vm.memory) * 2)
			}

		case .Jz:
			loc := vm_read_byte(vm)
			if vm_read_cell(vm) == 0 {
				vm.ip = int(loc)
			}
		case .Jnz:
			loc := vm_read_byte(vm)
			if vm_read_cell(vm) != 0 {
				vm.ip = int(loc)
			}

		case .Input:
			fmt.println("Input")

		case .Print:
			fmt.printf("%c", vm.memory[vm.mp])
		}
	}

	fmt.println()
	return .Ok
}

vm_read_cell :: #force_inline proc(vm: ^VM) -> u8 {
	return vm.memory[vm.mp]
}

vm_read_byte :: proc(vm: ^VM) -> u8 {
	b := vm.code[vm.ip]
	vm.ip += 1
	return b
}

vm_dump_memory :: proc(vm: ^VM) {
	fmt.printf("%v\n", vm.memory)
}
