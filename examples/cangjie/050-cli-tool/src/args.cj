package clitool

// 手写参数解析：演示"参数解析 + 错误处理"。没依赖 std.argopt——它的宏 API
// （@Option 等）在本机 1.0.5 SDK 上与内建 Option 类型撞名、无法在不臆造前提下确认，
// 故用最朴素、最可移植的 while + 分支手写（见文章 48 正文对 argopt 的说明）。

public struct Config {
    public let verbose: Bool
    public let text: String          // 为让 CI 输出确定，把待统计文本作为位置参数直接传入
    public init(verbose: Bool, text: String) {
        this.verbose = verbose
        this.text = text
    }
}

public struct ParseResult {
    public let help: Bool
    public let error: Option<String>
    public let config: Option<Config>
    public init(help: Bool, error: Option<String>, config: Option<Config>) {
        this.help = help
        this.error = error
        this.config = config
    }
}

// 规则：-h/--help 帮助；-v/--verbose 详细；单个位置参数=待统计文本；
// 无位置参数按"帮助"处理（CI 的 cjpm run 不带参数时退出码为 0）。
public func parseArgs(args: Array<String>): ParseResult {
    var verbose = false
    var gotText = false
    var text = ""
    var i = 0
    while (i < args.size) {
        let a = args[i]
        if (a == "-h" || a == "--help") {
            return ParseResult(true, None, None)
        }
        if (a == "-v" || a == "--verbose") {
            verbose = true
        } else if (a.startsWith("-")) {
            return ParseResult(false, Some("unknown option: ${a}"), None)
        } else {
            if (gotText) {
                return ParseResult(false, Some("only one <text> argument expected"), None)
            }
            text = a
            gotText = true
        }
        i += 1
    }
    if (!gotText) {
        return ParseResult(true, None, None)
    }
    return ParseResult(false, None, Some(Config(verbose, text)))
}
