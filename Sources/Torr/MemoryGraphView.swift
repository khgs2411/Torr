import SwiftUI

struct SparklineShape: Shape {
    let data: [Double]

    func path(in rect: CGRect) -> Path {
        guard data.count >= 2 else { return Path() }

        var path = Path()
        let stepX = rect.width / CGFloat(data.count - 1)

        for (index, value) in data.enumerated() {
            let x = CGFloat(index) * stepX
            let y = rect.height * (1.0 - CGFloat(value))
            if index == 0 {
                path.move(to: CGPoint(x: x, y: y))
            } else {
                path.addLine(to: CGPoint(x: x, y: y))
            }
        }
        return path
    }
}

struct SparklineAreaShape: Shape {
    let data: [Double]

    func path(in rect: CGRect) -> Path {
        guard data.count >= 2 else { return Path() }

        var path = Path()
        let stepX = rect.width / CGFloat(data.count - 1)

        path.move(to: CGPoint(x: 0, y: rect.height))

        for (index, value) in data.enumerated() {
            let x = CGFloat(index) * stepX
            let y = rect.height * (1.0 - CGFloat(value))
            path.addLine(to: CGPoint(x: x, y: y))
        }

        path.addLine(to: CGPoint(x: CGFloat(data.count - 1) * stepX, y: rect.height))
        path.closeSubpath()

        return path
    }
}

struct MemoryGraphView: View {
    let data: [Double]
    let lineColor: Color
    let fillColor: Color

    init(data: [Double], lineColor: Color = .green, fillColor: Color = .green.opacity(0.2)) {
        self.data = data
        self.lineColor = lineColor
        self.fillColor = fillColor
    }

    var body: some View {
        ZStack {
            SparklineAreaShape(data: data)
                .fill(fillColor)

            SparklineShape(data: data)
                .stroke(lineColor, lineWidth: 1.5)
        }
        .background(gridBackground)
    }

    private var gridBackground: some View {
        Canvas { context, size in
            let lineColor = Color.white.opacity(0.08)
            for fraction in [0.25, 0.5, 0.75] {
                let y = size.height * fraction
                var path = Path()
                path.move(to: CGPoint(x: 0, y: y))
                path.addLine(to: CGPoint(x: size.width, y: y))
                context.stroke(path, with: .color(lineColor), lineWidth: 0.5)
            }
        }
    }
}
