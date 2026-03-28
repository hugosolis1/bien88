import SwiftUI

// MARK: - Gann Square of 9 Engine
struct GannEngine {

    // Find which "ring" (level) and angle a number falls on
    struct GannCell {
        let value: Double
        let ring: Int          // 0 = center (1), 1 = first ring, etc.
        let angle: Double      // degrees 0-360 (cardinal/fixed angles)
        let cardinal: String   // "0°","90°","180°","270°" or between
    }

    // Core: position of any number on the spiral
    static func position(of n: Double) -> (ring: Int, angle: Double) {
        if n <= 1 { return (0, 0) }
        // Each completed ring k covers numbers from (2k-1)^2 + 1 to (2k+1)^2
        let sqrtN = sqrt(n)
        let ring = Int(ceil((sqrtN - 1) / 2))
        let ringSize = 8 * ring  // numbers in ring
        let ringStart = Double((2 * ring - 1) * (2 * ring - 1)) + 1  // first number of ring

        let posInRing = n - ringStart  // 0-based position within ring
        let angle = (posInRing / Double(ringSize)) * 360.0
        return (ring, angle)
    }

    // Key Gann levels for a given number: same angle different rings
    static func keyLevels(for value: Double, count: Int = 8) -> [Double] {
        let (ring, angle) = position(of: value)
        var levels: [Double] = []

        // Numbers at the same angle in other rings (past and future)
        for r in max(0, ring - count/2) ... ring + count {
            let candidate = numberAt(ring: r, angle: angle)
            if candidate > 0 { levels.append(candidate) }
        }
        return levels.sorted()
    }

    // Number at a given ring and angle
    static func numberAt(ring: Int, angle: Double) -> Double {
        if ring == 0 { return 1 }
        let ringStart = Double((2 * ring - 1) * (2 * ring - 1)) + 1
        let ringSize  = Double(8 * ring)
        let pos = (angle / 360.0) * ringSize
        return ringStart + pos
    }

    // 8 cardinal + cross angles (0,45,90,135,180,225,270,315)
    static let cardinalAngles: [(Double, String)] = [
        (0,   "0° — Este"),
        (45,  "45° — NE"),
        (90,  "90° — Norte"),
        (135, "135° — NO"),
        (180, "180° — Oeste"),
        (225, "225° — SO"),
        (270, "270° — Sur"),
        (315, "315° — SE")
    ]

    // Price/time targets at cardinal angles from the input number
    static func cardinalTargets(for value: Double) -> [(label: String, values: [Double])] {
        let (ring, _) = position(of: value)
        var result: [(String, [Double])] = []

        for (deg, label) in cardinalAngles {
            var vals: [Double] = []
            for r in max(1, ring - 3) ... ring + 4 {
                let v = numberAt(ring: r, angle: deg)
                if v > 0 { vals.append(v) }
            }
            result.append((label, vals.sorted()))
        }
        return result
    }

    // Build a small spiral matrix for display (rings 0..maxRing)
    static func spiralMatrix(maxRing: Int) -> [[Double]] {
        let size = 2 * maxRing + 1
        var grid = Array(repeating: Array(repeating: 0.0, count: size), count: size)
        var x = maxRing, y = maxRing
        grid[y][x] = 1
        var num = 2.0
        var step = 1, dir = 0
        let dx = [1, 0, -1, 0]
        let dy = [0, -1, 0, 1]

        while num <= Double((2 * maxRing + 1) * (2 * maxRing + 1)) {
            for _ in 0..<2 {
                for _ in 0..<step {
                    x += dx[dir % 4]
                    y += dy[dir % 4]
                    if x >= 0 && x < size && y >= 0 && y < size {
                        grid[y][x] = num
                        num += 1
                    }
                }
                dir += 1
            }
            step += 1
        }
        return grid
    }
}

// MARK: - View
struct GannSquareView: View {
    @State private var inputText = "100"
    @State private var result: GannResult? = nil
    @State private var showGrid = true

    struct GannResult {
        let value: Double
        let ring: Int
        let angle: Double
        let cardinalTargets: [(label: String, values: [Double])]
        let keyLevels: [Double]
    }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(red: 0.06, green: 0.03, blue: 0.01),
                         Color(red: 0.02, green: 0.01, blue: 0.05)],
                startPoint: .top, endPoint: .bottom
            ).ignoresSafeArea()

            VStack(spacing: 0) {
                // Input bar
                VStack(spacing: 10) {
                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("VALOR A CALCULAR")
                                .font(.caption2).foregroundColor(.gray).tracking(1)
                            TextField("ej. 100", text: $inputText)
                                .keyboardType(.decimalPad)
                                .font(.system(.title2, design: .monospaced))
                                .font(.body.weight(.bold))
                                .foregroundColor(.orange)
                                .padding(10)
                                .background(RoundedRectangle(cornerRadius: 10).fill(Color.white.opacity(0.08)))
                        }

                        Button(action: calculate) {
                            VStack(spacing: 2) {
                                Image(systemName: "squareshape.split.3x3")
                                    .font(.title2)
                                Text("Calcular")
                                    .font(.caption2)
                            }
                            .padding(10)
                            .background(RoundedRectangle(cornerRadius: 10).fill(Color.orange.opacity(0.8)))
                            .foregroundColor(.white)
                        }
                    }
                    .padding(.horizontal)

                    Picker("Vista", selection: $showGrid) {
                        Text("Cuadrado").tag(true)
                        Text("Niveles Clave").tag(false)
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)
                }
                .padding(.vertical, 12)
                .background(Color.black.opacity(0.35))

                if let r = result {
                    ScrollView {
                        VStack(spacing: 16) {
                            // Position summary
                            HStack(spacing: 16) {
                                GannInfoCard(title: "Valor", value: String(format: "%.2f", r.value), color: .orange)
                                GannInfoCard(title: "Anillo", value: "\(r.ring)", color: .yellow)
                                GannInfoCard(title: "Ángulo", value: String(format: "%.1f°", r.angle), color: .cyan)
                            }
                            .padding(.horizontal)

                            if showGrid {
                                GannGridView(centerValue: r.value)
                                    .padding(.horizontal)
                            } else {
                                // Cardinal targets
                                VStack(spacing: 8) {
                                    Text("NIVELES CARDINALES")
                                        .font(.caption).foregroundColor(.gray).tracking(2)

                                    ForEach(r.cardinalTargets, id: \.label) { row in
                                        CardinalRow(label: row.label, values: row.values, highlightValue: r.value)
                                    }
                                }
                                .padding(.horizontal)

                                // Key levels
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("MISMO ÁNGULO — DIFERENTES ANILLOS")
                                        .font(.caption).foregroundColor(.gray).tracking(2)
                                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 8) {
                                        ForEach(r.keyLevels, id: \.self) { v in
                                            Text(String(format: "%.2f", v))
                                                .font(.system(.caption, design: .monospaced))
                                                .fontWeight(abs(v - r.value) < 0.5 ? .bold : .regular)
                                                .foregroundColor(abs(v - r.value) < 0.5 ? .orange : .white)
                                                .padding(6)
                                                .frame(maxWidth: .infinity)
                                                .background(
                                                    RoundedRectangle(cornerRadius: 8)
                                                        .fill(abs(v - r.value) < 0.5 ? Color.orange.opacity(0.25) : Color.white.opacity(0.06))
                                                )
                                        }
                                    }
                                }
                                .padding(.horizontal)
                            }

                            // Explanation
                            VStack(alignment: .leading, spacing: 6) {
                                Text("ℹ️ Cómo leer el Cuadrado de 9")
                                    .font(.caption).fontWeight(.bold).foregroundColor(.orange)
                                Text("El Cuadrado de 9 de Gann organiza números en espiral. Los valores en el mismo ángulo (misma 'spoke') comparten resonancia temporal o de precio. Las cruces cardinales (0°, 90°, 180°, 270°) y diagonales (45°, 135°, 225°, 315°) son los soportes/resistencias más importantes.")
                                    .font(.caption2).foregroundColor(.gray).fixedSize(horizontal: false, vertical: true)
                            }
                            .padding()
                            .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.05)))
                            .padding(.horizontal)
                        }
                        .padding(.bottom, 30)
                    }
                } else {
                    Spacer()
                    VStack(spacing: 10) {
                        Image(systemName: "squareshape.split.3x3")
                            .font(.system(size: 50))
                            .foregroundColor(.orange.opacity(0.3))
                        Text("Ingresa un valor para calcular\nel Cuadrado de 9 de Gann")
                            .multilineTextAlignment(.center)
                            .foregroundColor(.gray)
                            .font(.subheadline)
                    }
                    Spacer()
                }
            }
        }
        .navigationTitle("Cuadrado de 9 — Gann")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { calculate() }
    }

    func calculate() {
        guard let v = Double(inputText), v > 0 else { return }
        let (ring, angle) = GannEngine.position(of: v)
        result = GannResult(
            value: v,
            ring: ring,
            angle: angle,
            cardinalTargets: GannEngine.cardinalTargets(for: v),
            keyLevels: GannEngine.keyLevels(for: v, count: 16)
        )
    }
}

// MARK: - Gann Grid Visual
struct GannGridView: View {
    let centerValue: Double
    private let maxRing = 4   // show 9x9 grid
    private var grid: [[Double]] { GannEngine.spiralMatrix(maxRing: maxRing) }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("ESPIRAL — CENTRO: 1")
                .font(.caption2).foregroundColor(.gray).tracking(2)

            let (_, targetAngle) = GannEngine.position(of: centerValue)

            ForEach(0..<grid.count, id: \.self) { row in
                HStack(spacing: 3) {
                    ForEach(0..<grid[row].count, id: \.self) { col in
                        let v = grid[row][col]
                        let isTarget = abs(v - centerValue) < 0.5
                        let (_, angle) = GannEngine.position(of: v)
                        let sameAngle = abs(angle - targetAngle) < 5.0 && v > 1

                        Text(v > 0 ? "\(Int(v))" : "")
                            .font(.system(size: 9, design: .monospaced))
                            .fontWeight(isTarget ? .black : .regular)
                            .foregroundColor(
                                isTarget ? .black :
                                sameAngle ? .orange :
                                isCardinal(v) ? .cyan :
                                .white.opacity(0.7)
                            )
                            .frame(maxWidth: .infinity)
                            .frame(height: 22)
                            .background(
                                RoundedRectangle(cornerRadius: 3)
                                    .fill(
                                        isTarget ? Color.orange :
                                        sameAngle ? Color.orange.opacity(0.2) :
                                        isCardinal(v) ? Color.cyan.opacity(0.12) :
                                        Color.white.opacity(0.05)
                                    )
                            )
                    }
                }
            }

            // Legend
            HStack(spacing: 16) {
                LegendDot(color: .orange, label: "Valor ingresado")
                LegendDot(color: .orange.opacity(0.5), label: "Mismo ángulo")
                LegendDot(color: .cyan.opacity(0.7), label: "Cardinal")
            }
            .font(.caption2)
            .foregroundColor(.gray)
            .padding(.top, 4)
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 14).fill(Color.white.opacity(0.04)))
    }

    func isCardinal(_ v: Double) -> Bool {
        if v <= 1 { return false }
        let (_, angle) = GannEngine.position(of: v)
        let cardinals = [0.0, 45.0, 90.0, 135.0, 180.0, 225.0, 270.0, 315.0]
        return cardinals.contains { abs(angle - $0) < 3.0 }
    }
}

// MARK: - Sub-views
struct GannInfoCard: View {
    let title: String
    let value: String
    let color: Color
    var body: some View {
        VStack(spacing: 4) {
            Text(title).font(.caption2).foregroundColor(.gray)
            Text(value).font(.system(.headline, design: .monospaced)).fontWeight(.bold).foregroundColor(color)
        }
        .frame(maxWidth: .infinity)
        .padding(10)
        .background(RoundedRectangle(cornerRadius: 10).fill(Color.white.opacity(0.06)))
    }
}

struct CardinalRow: View {
    let label: String
    let values: [Double]
    let highlightValue: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption2).foregroundColor(.yellow).fontWeight(.semibold)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(values, id: \.self) { v in
                        Text(String(format: "%.2f", v))
                            .font(.system(size: 11, design: .monospaced))
                            .padding(.horizontal, 8).padding(.vertical, 4)
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(abs(v - highlightValue) < 0.5 ? Color.orange.opacity(0.35) : Color.white.opacity(0.07))
                            )
                            .foregroundColor(abs(v - highlightValue) < 0.5 ? .orange : .white)
                    }
                }
            }
        }
        .padding(10)
        .background(RoundedRectangle(cornerRadius: 10).fill(Color.white.opacity(0.04)))
    }
}

struct LegendDot: View {
    let color: Color
    let label: String
    var body: some View {
        HStack(spacing: 4) {
            Circle().fill(color).frame(width: 8, height: 8)
            Text(label)
        }
    }
}
