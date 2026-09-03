/**
 * 质量工具链示例：cjfmt 规范化、cjlint 代码合规、cjdoc 文档注释。
 * cjdoc 是仓颉的 API 文档生成器（思路接 Doxygen），识别块文档注释。
 * 提示：cjlint 也检查文件名，本文件名含连字符会触发一条 G.NAM.02 建议（见正文）。
 */
package quality

/**
 * 摄氏转华氏（整数版）。
 * @param celsius 摄氏温度
 * @returns 对应的华氏温度
 */
public func celsiusToFahrenheit(celsius: Int64): Int64 {
    return celsius * 9 / 5 + 32
}

main(): Int64 {
    println("0C -> ${celsiusToFahrenheit(0)}F")
    println("100C -> ${celsiusToFahrenheit(100)}F")
    return 0
}
