// 面向对象示例
interface Drawable {
    func draw(): Unit
}

class Circle <: Drawable {
    let radius: Float64
    
    init(radius: Float64) {
        this.radius = radius
    }
    
    public func draw(): Unit {
        println("画一个半径为${radius}的圆")
    }
}

main() {
    let circle = Circle(5.0)
    circle.draw()
}