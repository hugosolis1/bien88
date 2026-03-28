import SwiftUI

// MARK: - Result model
struct DegreeArrival: Identifiable {
    let id = UUID()
    let planetName: String
    let planetSymbol: String
    let date: Date
    let exactLongitude: Double
    let direction: String   // "Directo" / "Retrógrado"
}

// MARK: - View
struct DegreeFinderView: View {
    @State private var targetDegree: String = "111"
    @State private var searchYear: Int = Calendar.current.component(.year, from: Date())
    @State private var results: [DegreeArrival] = []
    @State private var isSearching = false
    @State private var searched = false

    private let planets = ["Sol","Luna","Mercurio","Venus","Marte","Júpiter","Saturno","Urano","Neptuno","Plutón"]
    private let symbols = ["☉","☽","☿","♀","♂","♃","♄","♅","♆","♇"]

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(red: 0.04, green: 0.01, blue: 0.12),
                         Color(red: 0.00, green: 0.01, blue: 0.08)],
                startPoint: .top, endPoint: .bottom
            ).ignoresSafeArea()

            VStack(spacing: 0) {
                // Controls
                VStack(spacing: 12) {
                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("GRADO (0°–359°)")
                                .font(.caption2).foregroundColor(.gray).tracking(1)
                            TextField("ej. 111", text: $targetDegree)
                                .keyboardType(.numberPad)
                                .font(.system(.title2, design: .monospaced))
                                .fontWeight(.bold)
                                .foregroundColor(.yellow)
                                .padding(10)
                                .background(RoundedRectangle(cornerRadius: 10).fill(Color.white.opacity(0.08)))
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            Text("AÑO")
                                .font(.caption2).foregroundColor(.gray).tracking(1)
                            HStack {
                                Button { searchYear -= 1 } label: { Image(systemName: "chevron.left") }
                                    .foregroundColor(.yellow)
                                Text("\(searchYear)")
                                    .font(.system(.title2, design: .monospaced))
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                    .frame(minWidth: 55)
                                Button { searchYear += 1 } label: { Image(systemName: "chevron.right") }
                                    .foregroundColor(.yellow)
                            }
                            .padding(10)
                            .background(RoundedRectangle(cornerRadius: 10).fill(Color.white.opacity(0.08)))
                        }
                    }
                    .padding(.horizontal)

                    Button(action: search) {
                        HStack {
                            if isSearching {
                                ProgressView().tint(.white)
                                Text("Buscando...").fontWeight(.semibold)
                            } else {
                                Image(systemName: "magnifyingglass.circle.fill")
                                Text("Buscar Tránsitos al \(targetDegree)°").fontWeight(.semibold)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(isSearching ? Color.gray : Color.indigo)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    .disabled(isSearching)
                    .padding(.horizontal)
                }
                .padding(.vertical, 12)
                .background(Color.black.opacity(0.3))

                // Results
                if isSearching {
                    Spacer()
                    VStack(spacing: 12) {
                        ProgressView()
                            .scaleEffect(1.4)
                            .tint(.yellow)
                        Text("Calculando tránsitos para \(searchYear)…")
                            .foregroundColor(.gray)
                            .font(.subheadline)
                    }
                    Spacer()
                } else if searched && results.isEmpty {
                    Spacer()
                    Text("Sin resultados para \(targetDegree)° en \(searchYear)")
                        .foregroundColor(.gray)
                    Spacer()
                } else if !results.isEmpty {
                    ScrollView {
                        LazyVStack(spacing: 8) {
                            Text("\(results.count) tránsitos encontrados")
                                .font(.caption)
                                .foregroundColor(.gray)
                                .padding(.top, 8)

                            ForEach(results) { r in
                                ArrivalRow(arrival: r)
                            }
                        }
                        .padding()
                    }
                } else {
                    Spacer()
                    VStack(spacing: 8) {
                        Image(systemName: "sparkles")
                            .font(.largeTitle)
                            .foregroundColor(.indigo.opacity(0.5))
                        Text("Ingresa un grado y el año a buscar")
                            .foregroundColor(.gray)
                            .font(.subheadline)
                    }
                    Spacer()
                }
            }
        }
        .navigationTitle("Buscador de Grados")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Search logic
    func search() {
        guard let deg = Double(targetDegree), deg >= 0, deg < 360 else { return }
        isSearching = true
        searched = false
        results = []

        DispatchQueue.global(qos: .userInitiated).async {
            var found: [DegreeArrival] = []

            // Build date range: full year, step every 1 hour for inner planets, 6h for outer
            let cal = Calendar(identifier: .gregorian)
            guard
                let startDate = cal.date(from: DateComponents(year: searchYear, month: 1, day: 1)),
                let endDate   = cal.date(from: DateComponents(year: searchYear + 1, month: 1, day: 1))
            else { return }

            // Steps: 1h for Sun/Moon/Mercury/Venus, 6h for others
            let fastStep: Double = 3600        // 1 hour
            let slowStep: Double = 6 * 3600    // 6 hours

            // For each planet, scan with binary search refinement
            for (idx, planetName) in planets.enumerated() {
                let step: Double = (idx <= 3) ? fastStep : slowStep
                var t = startDate
                var prevLon = planetLon(name: planetName, date: t)
                t = t.addingTimeInterval(step)

                while t <= endDate {
                    let curLon = planetLon(name: planetName, date: t)
                    let prevT = t.addingTimeInterval(-step)

                    // Check if target degree falls between prevLon and curLon
                    if crossesDegree(prev: prevLon, cur: curLon, target: deg) {
                        // Binary search for exact crossing moment
                        let exact = binarySearchCrossing(name: planetName, target: deg,
                                                          low: prevT, high: t, iterations: 40)
                        let exactLon = planetLon(name: planetName, date: exact)
                        let speed = (curLon - prevLon)
                        let dir = angularDelta(from: prevLon, to: curLon) < 0 ? "Retrógrado" : "Directo"

                        found.append(DegreeArrival(
                            planetName: planetName,
                            planetSymbol: symbols[idx],
                            date: exact,
                            exactLongitude: exactLon,
                            direction: dir
                        ))
                    }

                    prevLon = curLon
                    t = t.addingTimeInterval(step)
                }
            }

            found.sort { $0.date < $1.date }

            DispatchQueue.main.async {
                self.results = found
                self.isSearching = false
                self.searched = true
            }
        }
    }

    func planetLon(name: String, date: Date) -> Double {
        let jd = AstronomicalEngine.julianDay(date: date)
        let t = AstronomicalEngine.T(jd: jd)
        switch name {
        case "Sol":      return AstronomicalEngine.sunLongitude(T: t)
        case "Luna":     return AstronomicalEngine.moonLongitude(T: t).lon
        case "Mercurio": return AstronomicalEngine.mercuryLongitude(T: t).lon
        case "Venus":    return AstronomicalEngine.venusLongitude(T: t).lon
        case "Marte":    return AstronomicalEngine.marsLongitude(T: t).lon
        case "Júpiter":  return AstronomicalEngine.jupiterLongitude(T: t).lon
        case "Saturno":  return AstronomicalEngine.saturnLongitude(T: t).lon
        case "Urano":    return AstronomicalEngine.uranusLongitude(T: t).lon
        case "Neptuno":  return AstronomicalEngine.neptuneLongitude(T: t).lon
        case "Plutón":   return AstronomicalEngine.plutoLongitude(T: t).lon
        default:         return 0
        }
    }

    // Detects if the target degree is crossed between prev and cur (handles 359->0 wrap)
    func crossesDegree(prev: Double, cur: Double, target: Double) -> Bool {
        let delta = angularDelta(from: prev, to: cur)
        if abs(delta) > 180 { return false } // jumped too much, skip
        if delta > 0 {
            // Moving forward
            if prev <= target && cur > target { return true }
            // Wrap 359->0
            if prev > cur && (target >= prev || target < cur) { return true }
        } else {
            // Moving backward (retrograde)
            if prev >= target && cur < target { return true }
            if prev < cur && (target <= prev || target > cur) { return true }
        }
        return false
    }

    // Signed angular difference from a to b (-180 to 180)
    func angularDelta(from a: Double, to b: Double) -> Double {
        var d = b - a
        while d > 180  { d -= 360 }
        while d < -180 { d += 360 }
        return d
    }

    // Binary search for exact crossing moment
    func binarySearchCrossing(name: String, target: Double, low: Date, high: Date, iterations: Int) -> Date {
        var lo = low
        var hi = high
        for _ in 0..<iterations {
            let mid = Date(timeIntervalSince1970: (lo.timeIntervalSince1970 + hi.timeIntervalSince1970) / 2)
            let lonMid = planetLon(name: name, date: mid)
            let lonLo  = planetLon(name: name, date: lo)
            if crossesDegree(prev: lonLo, cur: lonMid, target: target) {
                hi = mid
            } else {
                lo = mid
            }
        }
        return Date(timeIntervalSince1970: (lo.timeIntervalSince1970 + hi.timeIntervalSince1970) / 2)
    }
}

// MARK: - Row
struct ArrivalRow: View {
    let arrival: DegreeArrival

    private let df: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "dd MMM yyyy  HH:mm"
        f.locale = Locale(identifier: "es_MX")
        return f
    }()

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(arrival.direction == "Retrógrado" ? Color.red.opacity(0.2) : Color.indigo.opacity(0.2))
                    .frame(width: 44, height: 44)
                Text(arrival.planetSymbol)
                    .font(.system(size: 22))
            }

            VStack(alignment: .leading, spacing: 3) {
                HStack {
                    Text(arrival.planetName)
                        .font(.subheadline).fontWeight(.semibold).foregroundColor(.white)
                    if arrival.direction == "Retrógrado" {
                        Text("℞").font(.caption).foregroundColor(.red)
                            .padding(.horizontal, 4).background(Color.red.opacity(0.15)).cornerRadius(4)
                    }
                }
                Text(arrival.direction)
                    .font(.caption2).foregroundColor(arrival.direction == "Retrógrado" ? .red : .green)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 3) {
                Text(df.string(from: arrival.date))
                    .font(.system(.caption, design: .monospaced))
                    .foregroundColor(.yellow)
                Text(String(format: "%.3f°", arrival.exactLongitude))
                    .font(.caption2).foregroundColor(.gray)
            }
        }
        .padding(.horizontal, 14).padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.05))
                .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Color.white.opacity(0.08), lineWidth: 1))
        )
    }
}
