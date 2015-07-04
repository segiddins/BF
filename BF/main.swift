import Darwin

if case let args = Process.arguments where args.count > 1, case let file = args[1] {
    if case let fd = fopen(file, "rb") where fd != nil {
        defer { fclose(fd) }
        fseek(fd, 0, SEEK_END)
        let fileSize = ftell(fd)
        fseek(fd, 0, SEEK_SET)
        var buffer = UnsafeMutablePointer<CChar>.alloc(fileSize)
        defer { buffer.destroy() }
        if fread(buffer, sizeof(CChar), fileSize, fd) == fileSize {
            buffer[fileSize] = 0
            if let program = String.fromCString(buffer) {
                if let vm = VM(program: program) {
                    vm.run()
                    exit(EXIT_SUCCESS)
                }
                else {
                    print("Invalid BF program in '\(file)'.")
                }
            }
        }
    }
    print("Failed to open file '\(file)'.")
    exit(EXIT_FAILURE)
}
else {
    print("> ", appendNewline: false)
    var input = ""
    while let line = readLine() {
        input += line
    }
    if let vm = VM(program: input) {
        vm.run()
    }
    else {
        print("Invalid BF program")
        exit(EXIT_FAILURE)
    }
}

// Hello world
// VM(program: "++++++++[>++++[>++>+++>+++>+<<<<-]>+>+>->>+[<]<-]>>.>---.+++++++..+++.>>.<-.<.+++.------.--------.>>+.>++.").run()
