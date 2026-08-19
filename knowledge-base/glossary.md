# 仓颉编程语言术语表

> 仓颉1.0.5 LTS版本核心术语和概念解释

## 基础术语

### 语言基础
- **仓颉 (Cangjie)**: 华为自研的编程语言，面向全场景应用开发
- **STS (Standard Technical Specification)**: 标准技术规范版本
- **cjc**: 仓颉编译器命令行工具
- **cpm**: 仓颉包管理器
- **cjnative**: 仓颉原生开发环境

### 类型系统
- **类型推断 (Type Inference)**: 编译器自动推断变量类型的能力
- **类型注解 (Type Annotation)**: 显式指定变量类型
- **静态类型 (Static Type)**: 编译时确定的类型
- **动态类型 (Dynamic Type)**: 运行时确定的类型
- **强类型 (Strong Type)**: 类型检查严格的类型系统
- **弱类型 (Weak Type)**: 类型检查宽松的类型系统

### 数据类型
- **基本类型 (Primitive Type)**: Int、Float、Double、Bool、Char、String
- **引用类型 (Reference Type)**: 类、接口、数组等
- **值类型 (Value Type)**: 结构体、枚举等
- **可选类型 (Optional Type)**: 表示可能为空的类型，使用?标记
- **泛型 (Generic)**: 参数化类型，支持类型复用

## 面向对象术语

### 类与对象
- **类 (Class)**: 对象的蓝图或模板
- **对象 (Object)**: 类的实例
- **实例化 (Instantiation)**: 创建对象的过程
- **属性 (Property)**: 类的数据成员
- **方法 (Method)**: 类的函数成员
- **构造函数 (Constructor)**: 初始化对象的特殊方法
- **析构函数 (Destructor)**: 清理对象的特殊方法

### 继承与多态
- **继承 (Inheritance)**: 子类继承父类的特性
- **多态 (Polymorphism)**: 同一接口不同实现
- **方法重写 (Method Overriding)**: 子类重新实现父类方法
- **方法重载 (Method Overloading)**: 同名不同参数的方法
- **抽象类 (Abstract Class)**: 不能实例化的类
- **接口 (Interface)**: 定义行为规范的类型

### 访问控制
- **公开 (Public)**: 所有地方可访问
- **私有 (Private)**: 只有类内部可访问
- **保护 (Protected)**: 类内部和子类可访问
- **内部 (Internal)**: 同一模块内可访问

## 函数式编程术语

### 函数概念
- **纯函数 (Pure Function)**: 无副作用，相同输入相同输出
- **高阶函数 (Higher-Order Function)**: 接受或返回函数的函数
- **匿名函数 (Anonymous Function)**: 没有名字的函数
- **闭包 (Closure)**: 捕获外部变量的函数
- **函数组合 (Function Composition)**: 组合多个函数
- **柯里化 (Currying)**: 将多参数函数转换为单参数函数链

### 不可变性
- **不可变 (Immutable)**: 创建后不能修改
- **可变 (Mutable)**: 创建后可以修改
- **持久化数据结构 (Persistent Data Structure)**: 修改时创建新版本

## 并发编程术语

### 并发模型
- **并发 (Concurrency)**: 多个任务同时进行
- **并行 (Parallelism)**: 多个任务真正同时执行
- **协程 (Coroutine)**: 轻量级线程，用户态调度
- **线程 (Thread)**: 操作系统调度的基本单位
- **进程 (Process)**: 程序执行的实例

### 协程相关
- **协程调度器 (Coroutine Scheduler)**: 管理协程执行的组件
- **协程上下文 (Coroutine Context)**: 协程的执行环境
- **协程作用域 (Coroutine Scope)**: 协程的生命周期范围
- **挂起函数 (Suspend Function)**: 可以暂停执行的函数
- **异步 (Asynchronous)**: 非阻塞执行模式

### 同步原语
- **互斥锁 (Mutex)**: 互斥访问共享资源
- **读写锁 (Read-Write Lock)**: 允许多读单写
- **条件变量 (Condition Variable)**: 线程间通信机制
- **信号量 (Semaphore)**: 控制并发数量
- **原子操作 (Atomic Operation)**: 不可中断的操作

## 错误处理术语

### 错误类型
- **异常 (Exception)**: 程序执行中的错误情况
- **错误 (Error)**: 可恢复的错误情况
- **故障 (Fault)**: 系统级错误
- **失败 (Failure)**: 程序无法继续执行

### 错误处理
- **try-catch**: 异常处理机制
- **Result类型**: 表示成功或失败的类型
- **错误传播 (Error Propagation)**: 将错误传递给调用者
- **错误恢复 (Error Recovery)**: 从错误中恢复
- **防御性编程 (Defensive Programming)**: 预防错误发生的编程方式

## 模块系统术语

### 模块概念
- **模块 (Module)**: 代码组织的基本单位
- **包 (Package)**: 模块的集合
- **库 (Library)**: 可重用的代码集合
- **依赖 (Dependency)**: 程序需要的外部库
- **导入 (Import)**: 引入其他模块的代码
- **导出 (Export)**: 使模块内的代码可被外部访问

### 包管理
- **包管理器 (Package Manager)**: 管理项目依赖的工具
- **语义化版本 (Semantic Versioning)**: 版本号规范
- **依赖解析 (Dependency Resolution)**: 解决依赖冲突
- **锁定文件 (Lock File)**: 记录确切依赖版本

## 内存管理术语

### 内存概念
- **栈 (Stack)**: 自动管理的内存区域
- **堆 (Heap)**: 动态分配的内存区域
- **垃圾回收 (Garbage Collection)**: 自动内存管理
- **引用计数 (Reference Counting)**: 基于引用数量的内存管理
- **内存泄漏 (Memory Leak)**: 未释放的内存
- **悬垂指针 (Dangling Pointer)**: 指向已释放内存的指针

### GC相关
- **GC算法**: 分代收集、标记清除、标记整理等
- **GC停顿 (GC Pause)**: 垃圾回收时的程序暂停
- **GC调优 (GC Tuning)**: 优化垃圾回收性能
- **内存分配 (Memory Allocation)**: 分配内存的过程
- **内存释放 (Memory Deallocation)**: 释放内存的过程

## 性能优化术语

### 性能概念
- **时间复杂度 (Time Complexity)**: 算法执行时间随输入规模增长的关系
- **空间复杂度 (Space Complexity)**: 算法内存使用随输入规模增长的关系
- **瓶颈 (Bottleneck)**: 限制性能的关键点
- **性能分析 (Performance Analysis)**: 分析程序性能
- **性能优化 (Performance Optimization)**: 提高程序性能

### 优化技术
- **缓存 (Cache)**: 临时存储常用数据
- **懒加载 (Lazy Loading)**: 延迟初始化
- **对象池 (Object Pool)**: 重用对象
- **内联 (Inline)**: 将函数调用替换为函数体
- **循环展开 (Loop Unrolling)**: 减少循环开销

## 开发工具术语

### 编译器相关
- **编译器 (Compiler)**: 将源代码转换为机器代码
- **解释器 (Interpreter)**: 逐行执行源代码
- **前端 (Frontend)**: 词法分析、语法分析
- **后端 (Backend)**: 代码生成、优化
- **中间表示 (Intermediate Representation)**: 编译器中间代码

### 调试工具
- **调试器 (Debugger)**: 程序调试工具
- **断点 (Breakpoint)**: 程序暂停点
- **单步执行 (Step Execution)**: 逐行执行代码
- **变量监视 (Variable Watch)**: 监视变量值
- **堆栈跟踪 (Stack Trace)**: 函数调用链

### 测试相关
- **单元测试 (Unit Test)**: 测试最小代码单元
- **集成测试 (Integration Test)**: 测试组件间交互
- **系统测试 (System Test)**: 测试整个系统
- **测试覆盖率 (Test Coverage)**: 测试覆盖的代码比例
- **模拟对象 (Mock Object)**: 模拟依赖对象

## 设计模式术语

### 创建型模式
- **单例模式 (Singleton)**: 确保只有一个实例
- **工厂模式 (Factory)**: 创建对象的接口
- **抽象工厂 (Abstract Factory)**: 创建相关对象族
- **建造者模式 (Builder)**: 分步构建复杂对象
- **原型模式 (Prototype)**: 通过复制创建对象

### 结构型模式
- **适配器模式 (Adapter)**: 接口转换
- **桥接模式 (Bridge)**: 分离抽象和实现
- **组合模式 (Composite)**: 树形结构
- **装饰器模式 (Decorator)**: 动态添加功能
- **外观模式 (Facade)**: 简化接口

### 行为型模式
- **观察者模式 (Observer)**: 一对多依赖
- **策略模式 (Strategy)**: 算法族
- **模板方法 (Template Method)**: 算法骨架
- **状态模式 (State)**: 状态机
- **命令模式 (Command)**: 请求封装

## 仓颉特有术语

### 语言特性
- **模式匹配 (Pattern Matching)**: 类似switch的增强版
- **解构赋值 (Destructuring Assignment)**: 从对象中提取值
- **扩展函数 (Extension Function)**: 为现有类型添加函数
- **操作符重载 (Operator Overloading)**: 自定义操作符行为
- **属性委托 (Property Delegation)**: 委托属性访问

### 并发特性
- **结构化并发 (Structured Concurrency)**: 并发任务的组织方式
- **协程构建器 (Coroutine Builder)**: 创建协程的函数
- **协程取消 (Coroutine Cancellation)**: 取消协程执行
- **协程异常处理 (Coroutine Exception Handling)**: 处理协程中的异常

### 类型系统特性
- **联合类型 (Union Type)**: 多种类型之一
- **交叉类型 (Intersection Type)**: 同时满足多种类型
- **类型别名 (Type Alias)**: 为类型创建别名
- **类型投影 (Type Projection)**: 泛型类型参数的限定

## 工具链术语

### 开发环境
- **IDE (Integrated Development Environment)**: 集成开发环境
- **LSP (Language Server Protocol)**: 语言服务器协议
- **DAP (Debug Adapter Protocol)**: 调试适配器协议
- **CLI (Command Line Interface)**: 命令行界面

### 构建工具
- **构建系统 (Build System)**: 自动化构建过程
- **依赖管理 (Dependency Management)**: 管理项目依赖
- **任务运行器 (Task Runner)**: 执行自定义任务
- **插件系统 (Plugin System)**: 扩展工具功能

### 版本控制
- **Git**: 分布式版本控制系统
- **分支 (Branch)**: 代码的独立开发线
- **合并 (Merge)**: 合并分支
- **冲突 (Conflict)**: 合并时的代码冲突
- **标签 (Tag)**: 版本标记

## 社区术语

### 开源社区
- **开源 (Open Source)**: 公开源代码
- **贡献 (Contribution)**: 为项目做出贡献
- **维护者 (Maintainer)**: 项目维护人员
- **贡献者 (Contributor)**: 项目贡献人员
- **问题 (Issue)**: bug报告或功能请求
- **拉取请求 (Pull Request)**: 代码合并请求

### 文档相关
- **API文档 (API Documentation)**: 接口文档
- **用户手册 (User Manual)**: 用户使用指南
- **教程 (Tutorial)**: 学习教程
- **示例 (Example)**: 代码示例
- **最佳实践 (Best Practice)**: 推荐做法

---

*本术语表基于仓颉1.0.5 LTS版本，将随版本更新而更新*