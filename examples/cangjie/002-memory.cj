// 内存管理示例
class Person {
    let name: String
    let age: Int

    init(name: String, age: Int) {
        this.name = name
        this.age = age
    }
}

main() {
    let person = Person("Alice", 25)
    println(person.name)
    // 当 person 不再使用时，GC会自动回收内存
}
