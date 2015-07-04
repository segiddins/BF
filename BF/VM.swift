import func Darwin.fputc

private final class MutableBox<T> {
    var val: T
    init(_ x: T) {
        val = x
    }
}

extension IntegerArithmeticType where Self: IntegerLiteralConvertible {
    mutating func incrNoTrap() {
        self = self &+ 1
    }

    mutating func decrNoTrap() {
        self = self &- 1
    }
}

public class VM {
    let dataSize = 1024 * 1024
    var data: UnsafeMutablePointer<UInt8>
    var dataPointer: Int = 0

    var out = Pipe.stdout
    var input = Pipe.stdin

    private let commands: [Command]
    var instructionPointer = 0

    public init?(program: String) {
        self.data = UnsafeMutablePointer<UInt8>.alloc(dataSize)
        var commands = program.characters.flatMap { Command.fromString(String($0)) }

        var index = 0
        var pairs = [Int]()
        for command in commands {
            switch command {
            case .LoopStart(_):
                pairs.append(index)
            case .LoopEnd(let endBox):
                if pairs.count == 0 {
                    print("invalid program")
                    self.commands = []
                    return nil
                }
                let start = pairs.removeLast()
                switch commands[start] {
                case .LoopStart(let startBox):
                    startBox.val = index
                    endBox.val = start
                default:
                    self.commands = []
                    return nil
                }
            default: ()
            }
            index++
        }

        if pairs.count != 0 {
            print("invalid program")
            self.commands = []
            return nil
        }

        self.commands = commands
    }

    private enum Command {

        static func fromString(string: String) -> Command? {
            switch string {
            case ">": return .IncrData
            case "<": return .DecrData
            case "+": return .Incr
            case "-": return .Decr
            case ".": return .Output
            case ",": return .Input
            case "[": return .LoopStart(MutableBox(-1))
            case "]": return .LoopEnd(MutableBox(-1))
            default: return nil
            }
        }

        case IncrData
        case DecrData
        case Incr
        case Decr
        case Output
        case Input
        case LoopStart(MutableBox<Int>)
        case LoopEnd(MutableBox<Int>)
    }

    public func run() {
        while instructionPointer != commands.endIndex {
            execute(commands[instructionPointer++])
        }
    }

    private func execute(command: Command) {
        switch command {
        case .IncrData: dataPointer++
        case .DecrData: dataPointer--
        case .Incr: data[dataPointer].incrNoTrap()
        case .Decr: data[dataPointer].decrNoTrap()
        case .Output:
            fputc(Int32(data[dataPointer]), out.file)
        case .Input:
            let character = input.read()
            data[dataPointer] = UInt8(character)
        case .LoopStart(let jumpTarget):
            if data[dataPointer] == 0 {
                instructionPointer = jumpTarget.val
            }
        case .LoopEnd(let jumpTarget):
            if data[dataPointer] != 0 {
                instructionPointer = jumpTarget.val
            }
        }
    }
}
