# 官方文档核验规范

> 所有仓颉语言知识文章必须以对应版本的官方文档为事实依据。

## 强制流程

每篇文章开始前，必须完成以下步骤：

1. 明确文章对应的仓颉版本和后端；当前项目基线为仓颉 1.0.5 LTS、CJNative。
2. 使用官方 1.0.5 文档入口查找并读取主题相关的完整章节，而不是只看搜索摘要、博客或零散示例。
3. 建立知识核验表，至少记录语法形式、语义、约束、默认行为、反例和版本差异。
4. 建立“官方章节 -> 文章”的覆盖矩阵，确保每个官方章节都有当前文章或后续文章承接，不能遗漏或无计划地拆分。
5. 对文章中的每个类型名、关键字、默认推断、边界条件和命令逐条回到官方原文核对。
6. 将“官方文档明确说明”“由编译器验证”“尚未核实”三类事实分开，不能用编译通过替代语义核验。
7. 只有在官方资料、覆盖矩阵和本地验证都完成后，才能开始文章正文撰写。

## 官方资料入口

- 1.0.5 开发指南：https://docs.cangjie-lang.cn/docs/1.0.5/dev-guide/source_zh_cn/first_understanding/basic.html
- 1.0.5 程序结构与变量：https://docs.cangjie-lang.cn/docs/1.0.5/dev-guide/source_zh_cn/basic_programming_concepts/program_structure.html
- 1.0.5 整数类型：https://docs.cangjie-lang.cn/docs/1.0.5/dev-guide/source_zh_cn/basic_data_type/integer.html
- 1.0.5 浮点类型：https://docs.cangjie-lang.cn/docs/1.0.5/dev-guide/source_zh_cn/basic_data_type/float.html
- 1.0.5 字符类型：https://docs.cangjie-lang.cn/docs/1.0.5/dev-guide/source_zh_cn/basic_data_type/characters.html
- 1.0.5 字符串类型：https://docs.cangjie-lang.cn/docs/1.0.5/dev-guide/source_zh_cn/basic_data_type/strings.html
- 1.0.5 元组类型：https://docs.cangjie-lang.cn/docs/1.0.5/dev-guide/source_zh_cn/basic_data_type/tuple.html
- 1.0.5 数组类型：https://docs.cangjie-lang.cn/docs/1.0.5/dev-guide/source_zh_cn/basic_data_type/array.html
- 1.0.5 区间、Unit 和 Nothing 类型：https://docs.cangjie-lang.cn/docs/1.0.5/dev-guide/source_zh_cn/basic_data_type/range.html
- 1.0.5 常量求值：https://docs.cangjie-lang.cn/docs/1.0.5/dev-guide/source_zh_cn/function/const_func_and_eval.html
- 1.0.5 官方下载中心：https://cangjie-lang.cn/download/1.0.5

## 无法获取资料时

- 如果官方页面无法访问、版本页面内容不完整或关键章节无法读取，必须停止相关文章的技术撰写。
- 不得用记忆、其他语言经验、搜索摘要、第三方教程或“代码能编译”推断未核实的语言语义。
- 应明确告诉用户缺少哪一部分官方资料，并请求用户提供文档内容、文件或可访问链接。
- 在资料补齐前，只能整理已确认的事实，不能扩展文章范围。

## 文章审查清单

- [ ] 文章使用的每个关键字都在对应版本官方文档中确认。
- [ ] 对应官方章节的全部知识点已分配到当前文章或明确的后续文章。
- [ ] 每个基础类型的准确名称、位宽、默认字面量类型和转换规则都已核对。
- [ ] `let`、`var`、`const` 等相近概念已分别说明，未用其他语言语义类比替代官方定义。
- [ ] 文章没有把项目基线版本误写成永久的最新版本。
- [ ] 文章中的代码示例已在规范源中验证，语义说明也已单独核对。
- [ ] 对无法确认的内容已标记为待核实或向用户提问。

## 参考资料链接检查

- 每篇文章完成或修改参考资料后，必须逐条访问文章中列出的 URL，不能只检查 URL 字符串是否存在。
- 链接检查必须确认请求成功并返回目标内容；重定向、登录页、错误页或版本不匹配页面不能视为有效资料链接。
- 官方文档链接必须指向文章声明的版本；发现链接指向其他版本时，必须修正或明确说明版本差异。
- 检查时记录访问日期、URL 和结果；如果官方站点暂时不可访问，必须向用户报告，不能默认为可用。
- 参考资料链接检查与代码编译测试相互独立，两者都通过后文章才可进入审核确认。
