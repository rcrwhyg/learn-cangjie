// 控制流示例
func readScore(): Int64 {
    82
}

main() {
    let score = readScore()
    let level = if (score >= 90) {
        "A"
    } else if (score >= 60) {
        "B"
    } else {
        "C"
    }

    println("等级: ${level}")

    match (level) {
        case "A" => println("优秀")
        case "B" => println("合格")
        case _ => println("需要继续练习")
    }

    var sum: Int64 = 0
    for (number in 1..=5) {
        if (number == 3) {
            continue
        }
        sum += number
    }
    println("跳过 3 后的总和: ${sum}")

    var countdown: Int64 = 3
    while (countdown > 0) {
        countdown -= 1
    }

    var attempts: Int64 = 0
    do {
        attempts += 1
    } while (attempts < 2)
    println("do-while 执行次数: ${attempts}")

    var firstMultiple: Int64 = 0
    for (number in 1..=20) {
        if (number % 4 == 0) {
            firstMultiple = number
            break
        }
    }
    println("第一个 4 的倍数: ${firstMultiple}")
}
