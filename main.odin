package main

import "core:fmt"
import "core:os"

main :: proc() {
	source := "++++++++[>++++[>++>+++>+++>+<<<<-]>+>+>->>+[<]<-]>>.>---.+++++++..+++.>>.<-.<.+++.------.--------.>>+.>++."

	compiler := compiler_new(transmute([]u8)source)
	defer compiler_destroy()

	code, ok := compile(&compiler)
	if !ok {
		fmt.println("Failed to compile")
		return
	}

	vm := vm_new(code)
	defer vm_destroy(&vm)

	// debug_code(code)

	fmt.printf("Result %s\n", vm_run(&vm))
}
