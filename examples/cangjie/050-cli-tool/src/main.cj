package clitool

// CLI 入口：只做"解析 → 分派 → 退出码"。多语句逻辑放进各函数，避免 match 分支里写块。

func usage(): Int64 {
    println("usage: clitool [-v] <text>")
    return 0
}

func fail(msg: String): Int64 {
    eprintln("error: ${msg}")
    return 1
}

func run(cfg: Config): Int64 {
    println("lines=${countLines(cfg.text)} words=${countWords(cfg.text)} chars=${countChars(cfg.text)}")
    if (cfg.verbose) {
        println("verbose: text_len=${cfg.text.size}")
    }
    return 0
}

main(args: Array<String>): Int64 {
    let res = parseArgs(args)
    if (res.help) {
        return usage()
    }
    match (res.error) {
        case Some(e) => return fail(e)
        case None => ()
    }
    match (res.config) {
        case Some(cfg) => return run(cfg)
        case None => return 2
    }
}
