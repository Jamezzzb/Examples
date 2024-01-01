public final class Session: NSObject {
    private var task: Process?
    private var childHandle: FileHandle?
    private(set) var parentHandle: FileHandle?
    
    public override init() {
        self.task = Process()
        var parentFD: Int32 = 0
        parentFD = posix_openpt(O_RDWR)
        grantpt(parentFD)
        unlockpt(parentFD)
        self.parentHandle = FileHandle.init(fileDescriptor: parentFD, closeOnDealloc: true)
        let childPath = String.init(cString: ptsname(parentFD))
        self.childHandle = FileHandle.init(forUpdatingAtPath: childPath)
        self.task?.executableURL = URL(fileURLWithPath: "/bin/zsh")
        // set "-i" for interactive
        self.task?.arguments = ["-i"]
        self.task?.standardOutput = childHandle
        self.task?.standardInput = childHandle
        self.task?.standardError = childHandle
        
    }
    
    public func write(_ command: String) {
        parentHandle?.write(Data(command.utf8))
    }
    
    public func run()  {
        do {
            try task?.run()
        } catch {
            fatalError("PseudoTTY Failed To Start")
        }
    }
}

