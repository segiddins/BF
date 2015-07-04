public class VM {
    let dataSize = 1024 * 1024
    var data: Array<UInt8>
    var dataPointer: Int = 0

    var out = Pipe.stdout
    var input = Pipe.stdin

    let program: String.CharacterView
    var instructionPointer: String.CharacterView.Index

    public init(program: String) {
        self.data = Array(count: dataSize, repeatedValue: 0)
        self.program = program.characters
        self.instructionPointer = program.startIndex
    }

    enum Command: String {
        case IncrData = ">"
        case DecrData = "<"
        case Incr = "+"
        case Decr = "-"
        case Output = "."
        case Input = ","
        case LoopStart = "["
        case LoopEnd = "]"

        func execute(vm: VM) {
            switch self {
            case .IncrData: vm.dataPointer++
            case .DecrData: vm.dataPointer--
            case .Incr: vm.data[vm.dataPointer]++
            case .Decr: vm.data[vm.dataPointer]--
            case .Output:
                String(UnicodeScalar(vm.data[vm.dataPointer])).writeTo(&vm.out)
            case .Input:
                let character = vm.input.read()
                vm.data[vm.dataPointer] = UInt8(character)
            case .LoopStart:
                if vm.data[vm.dataPointer] == 0 {
                    var starts = 1
                    while starts != 0 {
                        vm.instructionPointer++
                        if vm.program[vm.instructionPointer] == "[" {
                            starts++
                        }
                        else if vm.program[vm.instructionPointer] == "]" {
                            starts--
                        }
                    }
                }
            case .LoopEnd:
                if vm.data[vm.dataPointer] != 0 {
                    var ends = 1
                    while ends != 0 {
                        vm.instructionPointer--
                        if vm.program[vm.instructionPointer] == "]" {
                            ends++
                        }
                        else if vm.program[vm.instructionPointer] == "[" {
                            ends--
                        }
                    }
                }
            }
        }
    }

    public func run() {
        while instructionPointer != program.endIndex {
            if let command = Command(rawValue: String(program[instructionPointer])) {
                command.execute(self)
            }
            instructionPointer++
        }
    }
}
