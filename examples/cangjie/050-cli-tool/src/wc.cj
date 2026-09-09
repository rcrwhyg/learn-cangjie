package clitool

// 纯函数核心：把"计数逻辑"和"参数解析/IO"分开——这是命令行工具最重要的结构决策，
// 因为它让核心可被 cjpm test 直接测（见 wc_test.cj），不依赖真去读文件。

// 行数：空串算 0 行，否则 = 换行数 + 1
public func countLines(text: String): Int64 {
    if (text.size == 0) {
        return 0
    }
    var lines: Int64 = 1
    for (r in text.runes()) {
        if (r == r'\n') {
            lines += 1
        }
    }
    return lines
}

// 词数：以空白（空格/换行/制表）为分隔，连续非空白算一词
public func countWords(text: String): Int64 {
    var words: Int64 = 0
    var inWord = false
    for (r in text.runes()) {
        if (r == r' ' || r == r'\n' || r == r'\t' || r == r'\r') {
            inWord = false
        } else {
            if (!inWord) {
                words += 1
                inWord = true
            }
        }
    }
    return words
}

// 字符数：码点数（承文章 13：String.size 是码点、不是字节）
public func countChars(text: String): Int64 {
    return text.size
}
