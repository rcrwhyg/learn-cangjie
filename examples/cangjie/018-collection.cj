// Collection 集合类型示例
// 演示：ArrayList<T>（动态数组）、HashSet<T>（哈希集合）、HashMap<K, V>（哈希映射）
// 以及集合间的关系运算（|  并集、&  交集、-  差集）
// 涵盖：构造、添加、删除、查询、遍历、常用属性与方法

import std.collection.ArrayList
import std.collection.HashSet
import std.collection.HashMap
import std.sort.sort

main() {
    // ========== 1) ArrayList 动态数组 ==========

    // 1.1 创建 ArrayList
    let list1: ArrayList<Int64> = ArrayList<Int64>([1, 2, 3, 4, 5])
    let list2: ArrayList<Int64> = ArrayList<Int64>(3, {_ => 0})  // [0, 0, 0]
    let list3: ArrayList<String> = ArrayList<String>(["仓颉", "ArrayList"])
    println("list1.size = ${list1.size}, list1.first = ${list1.first}, list1.last = ${list1.last}")
    println("list2.size = ${list2.size}")
    println("list3.size = ${list3.size}")

    // 1.2 增删改查
    list1.add(6)                    // 末尾追加
    list1.add(0, at: 0)             // 在下标 0 处插入 0
    println("list1 after add = ${list1.size}")
    println("list1[0] = ${list1[0]}")
    println("list1[2] = ${list1[2]}")

    // 修改元素
    list1[0] = 100
    println("list1[0] (after set) = ${list1[0]}")

    // 删除元素
    list1.remove(at: 1)             // 删除下标 1 的元素
    list1.remove(1..3)              // 删除下标 [1, 3) 区间
    println("list1 after remove = ${list1.size}")

    // 查询
    println("list1 contains 5: ${list1.contains(5)}")
    println("list1 get(0): ${list1.get(0)}")
    println("list1 isEmpty: ${list1.isEmpty()}")

    // 1.3 排序（使用 std.sort 全局函数）
    let unsorted: ArrayList<Int64> = ArrayList<Int64>([3, 1, 4, 1, 5, 9, 2, 6])
    sort(unsorted)
    print("sorted: ")
    for (x in unsorted) {
        print("${x} ")
    }
    println("")

    // 1.4 转换为 Array
    let arr: Array<Int64> = list1.toArray()
    println("arr.size = ${arr.size}")

    // 1.5 反转 / 切片
    let r: ArrayList<Int64> = ArrayList<Int64>([1, 2, 3, 4, 5])
    r.reverse()
    println("reversed: ${r[0]}, ${r[1]}, ${r[2]}, ${r[3]}, ${r[4]}")
    let slice: ArrayList<Int64> = r[1..4]   // [r[1], r[2], r[3]]
    println("slice size = ${slice.size}")

    // 1.6 清空
    r.clear()
    println("after clear: r.size = ${r.size}")

    // ========== 2) HashSet 哈希集合 ==========

    // 2.1 创建 HashSet
    let set1: HashSet<String> = HashSet<String>(["仓颉", "ArrayList", "HashSet"])
    let set2: HashSet<Int64> = HashSet<Int64>([1, 2, 3, 4, 5])
    println("set1.size = ${set1.size}, set2.size = ${set2.size}")

    // 2.2 增删改查
    set1.add("HashMap")
    println("set1 after add: size = ${set1.size}")
    println("set1 contains HashMap: ${set1.contains("HashMap")}")

    set1.remove("ArrayList")
    println("set1 after remove: size = ${set1.size}")

    // 2.3 集合运算：并 |、交 &、差 -
    let sa: HashSet<Int64> = HashSet<Int64>([1, 2, 3, 4])
    let sb: HashSet<Int64> = HashSet<Int64>([3, 4, 5, 6])
    let unionSet: HashSet<Int64> = sa | sb        // {1,2,3,4,5,6}
    let interSet: HashSet<Int64> = sa & sb        // {3,4}
    let diffSet: HashSet<Int64>  = sa - sb        // {1,2}
    println("union size = ${unionSet.size}")
    println("inter size = ${interSet.size}")
    println("diff  size = ${diffSet.size}")

    // 2.4 子集判断
    let small: HashSet<Int64> = HashSet<Int64>([3, 4])
    println("small subsetOf sa: ${small.subsetOf(sa)}")

    // 2.5 遍历（顺序不保证）
    print("set1: ")
    for (x in set1) {
        print("${x} ")
    }
    println("")

    // 2.6 转换为 Array
    let setArr: Array<String> = set1.toArray()
    println("setArr.size = ${setArr.size}")

    // ========== 3) HashMap 哈希映射 ==========

    // 3.1 创建 HashMap
    let map1: HashMap<String, Int64> = HashMap<String, Int64>([("Alice", 30), ("Bob", 25), ("Carol", 28)])
    let map2: HashMap<String, String> = HashMap<String, String>()
    println("map1.size = ${map1.size}")
    println("map2.size = ${map2.size}, isEmpty = ${map2.isEmpty()}")

    // 3.2 增删改查
    map1.add("Dave", 35)
    println("map1[Alice] = ${map1["Alice"]}")
    map1["Alice"] = 31
    println("map1[Alice] (after set) = ${map1["Alice"]}")
    println("map1 contains Bob: ${map1.contains("Bob")}")
    println("map1 contains Eve: ${map1.contains("Eve")}")

    // 3.3 删除
    let old: Int64 = map1.remove("Bob") ?? -1
    println("removed Bob: ${old}, map1.size = ${map1.size}")

    // 3.4 遍历（顺序不保证）
    for ((k, v) in map1) {
        println("  ${k} -> ${v}")
    }

    // 3.5 keys() / values()：返回 Collection
    let keys: Collection<String> = map1.keys()
    let values: Collection<Int64> = map1.values()
    println("keys.size = ${keys.size}, values.size = ${values.size}")

    // 3.6 map2 添加内容
    map2.add("lang", "仓颉")
    map2.add("version", "1.0.5")
    println("map2.size = ${map2.size}")
    println("map2[lang] = ${map2["lang"]}")

    // ========== 4) 综合场景：统计单词频率 ==========

    let text: String = "仓颉 仓颉 cangjie cangjie cangjie 1.0.5"
    let words: Array<String> = text.split(" ")
    let freq: HashMap<String, Int64> = HashMap<String, Int64>()
    for (w in words) {
        if (freq.contains(w)) {
            freq[w] = freq[w] + 1
        } else {
            freq.add(w, 1)
        }
    }
    println("--- 词频统计 ---")
    for ((w, c) in freq) {
        println("  ${w}: ${c}")
    }
}
