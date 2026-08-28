// 属性 vs 成员变量示例
// 演示：为什么有了成员变量还需要属性
// 属性提供 getter/setter 间接访问：封装、校验、派生值（计算属性）

class Circle {
    private var _radius: Float64 = 0.0    // 私有成员变量：外部不可直接访问

    // 属性：对外像普通变量，内部可以加校验逻辑
    public mut prop radius: Float64 {
        get() { _radius }
        set(v) {
            if (v >= 0.0) {
                _radius = v
            }
        }
    }

    // 派生属性：不存储值，读取时实时计算——这是纯成员变量做不到的
    public prop area: Float64 {
        get() { 3.14159 * _radius * _radius }
    }
}

main() {
    var c = Circle()
    c.radius = -5.0                         // setter 拒绝非法值，_radius 保持 0.0
    println(c.radius == 0.0)                // true：非法赋值被拦截
    c.radius = 2.0                          // 合法赋值
    println(c.radius == 2.0)                // true
    println(c.area > 12.5 && c.area < 12.6) // true：面积随 radius 实时算出
}
