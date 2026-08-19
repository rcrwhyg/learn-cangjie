// 函数式编程示例
main() {
    let numbers = [1, 2, 3, 4, 5]
    
    // 高阶函数：map
    let doubled = numbers.map({ x => x * 2 })
    println("加倍: ${doubled}")  // [2, 4, 6, 8, 10]
    
    // 高阶函数：filter
    let evens = numbers.filter({ x => x % 2 == 0 })
    println("偶数: ${evens}")  // [2, 4]
    
    // 高阶函数：reduce
    let sum = numbers.reduce(0, { acc, x => acc + x })
    println("总和: ${sum}")  // 15
}