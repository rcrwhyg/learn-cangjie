package clitool

import std.unittest.*
import std.unittest.testmacro.*

// 单元测试：文件名以 _test.cj 结尾 → cjpm test 才编它（承文章 38）。
// 核心纯函数好测——这正是 wc.cj 把计数与 IO 分开的收益。
// 注：@Expect/@Fail 等断言宏不写在 match 分支里（`=> {` 会被当作 lambda），
// 而是先用 match 把值取出、再断言。

@Test
public class WcTests {
    @TestCase
    public func counts() {
        @Expect(countLines("a\nb\nc"), 3)         // 2 个换行 → 3 行
        @Expect(countWords("hello world foo"), 3)
        @Expect(countChars("hi"), 2)
    }

    @TestCase
    public func edges() {
        @Expect(countLines(""), 0)                 // 空串 0 行
        @Expect(countWords("   "), 0)              // 全空白 0 词
        @Expect(countLines("no newline"), 1)       // 无换行仍是 1 行
    }
}

@Test
public class ArgTests {
    @TestCase
    public func ok() {
        let parsed = parseArgs(["-v", "hello world"])
        let cfg = match (parsed.config) {
            case Some(c) => c
            case None => Config(false, "")
        }
        @Expect(cfg.verbose, true)
        @Expect(cfg.text, "hello world")
    }

    @TestCase
    public func unknownOptionIsError() {
        let gotErr = match (parseArgs(["-x"]).error) {
            case Some(_) => true
            case None => false
        }
        @Expect(gotErr, true)
    }

    @TestCase
    public func noArgsMeansHelp() {
        @Expect(parseArgs([]).help, true)          // CI 的 cjpm run（无参）走这里、退出 0
    }
}
