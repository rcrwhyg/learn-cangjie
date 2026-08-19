// 面向对象示例
interface Drawable {
    func draw(): Unit
}

class Circle implements Drawable {
    let radius: Double
    
    init(radius: Double) {
        this.radius = radius
    }
    
    func draw() {
        println("画一个半径为${radius}的圆")
    }
}

main() {
    let circle = Circle(radius: 5.0)
    circle.draw()
}