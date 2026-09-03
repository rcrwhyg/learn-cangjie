package utdemo

// 单元测试：文件名以 _test.cj 结尾，cjpm 会识别它并"只在测试模式"下编译。
// 用法：cjpm test   （无需手动加 --test；cjpm 会调 cjc --test 把入口从 main 换成 test_entry）
import std.unittest.*
import std.unittest.testmacro.*

// 1) 独立测试函数：@Test 直接修饰一个顶层函数
@Test
public func addIdentity() {
    @Expect(add(7, 0), 7)          // @Expect：相等断言，失败也继续跑后续断言
}

// 2) 测试类：@Test 修饰 class，内部用 @TestCase 划分用例，可挂生命周期钩子
@Test
public class AdderTests {
    @BeforeEach
    public func setUp() {}          // 每个用例前执行

    @AfterEach
    public func tearDown() {}       // 每个用例后执行

    @TestCase
    public func addPositives() {
        @Expect(add(2, 3), 5)
        @Expect(add(0, 0), 0)
    }

    @TestCase
    public func addNegatives() {
        @Assert(add(-1, -1), -2)    // @Assert：fail-fast，本用例后续断言不再执行
        @Expect(add(-2, 5), 3)
    }
}
