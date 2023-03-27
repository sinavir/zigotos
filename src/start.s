.global _start
.type _start, @function

_start:
    movl $stack_bytes, %esp
    //push %ebx
    //push %eax
    call kmain
