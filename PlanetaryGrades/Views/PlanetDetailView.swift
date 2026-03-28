import SwiftUI

struct PlanetDetailView: View {
    let planet: PlanetPosition
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(
                    colors: [Color(red: 0.05, green: 0.02, blue: 0.15),
                             Color(red: 0.00, green: 0.01, blue: 0.10)],
                    startPoint: .top, endPoint: .bottom
                ).ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        // Header
                        VStack(spacing: 8) {
                            Text(planet.symbol)
                                .font(.system(size: 64))
                            Text(planet.name)
                                .font(.system(.title, design: .serif))
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                            Text(planet.sign.rawValue)
                                .font(.subheadline)
                                .foregroundColor(.yellow.opacity(0.8))
                        }
                        .padding(.top, 8)

                        // Cards grid
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                            DetailCard(title: "Posición en Signo",
                                       value: "\(Int(planet.degreeInSign))°\(Int(planet.minuteInSign))'\(Int(planet.secondInSign))\"",
                                       subtitle: planet.sign.rawValue,
                                       icon: "location.north.circle")

                            DetailCard(title: "Longitud Eclíptica",
                                       value: String(format: "%.4f°", planet.longitude),
                                       subtitle: "0° – 360°",
                                       icon: "circle.dashed")

                            DetailCard(title: "Grado en Signo",
                                       value: String(format: "%.6f°", planet.decimalDegreeInSign),
                                       subtitle: "Decimal",
                                       icon: "number.circle")

                            DetailCard(title: "Latitud Eclíptica",
                                       value: String(format: "%+.4f°", planet.latitude),
                                       subtitle: planet.latitude >= 0 ? "Norte eclíptica" : "Sur eclíptica",
                                       icon: "arrow.up.and.down.circle")

                            if planet.distance > 0 {
                                DetailCard(title: "Distancia",
                                           value: String(format: "%.6f AU", planet.distance),
                                           subtitle: String(format: "%.2f M km", planet.distance * 149.598),
                                           icon: "ruler")
                            }

                            DetailCard(title: "Velocidad",
                                       value: String(format: "%+.4f°/día", planet.speed),
                                       subtitle: planet.isRetrograde ? "⬅ Retrógrado" : "➡ Directo",
                                       icon: "gauge.with.needle")
                        }
                        .padding(.horizontal)

                        // Zodiac wheel position bar
                        ZodiacPositionBar(longitude: planet.longitude)
                            .padding(.horizontal)

                        // Extra info
                        VStack(alignment: .leading, spacing: 10) {
                            InfoRow(label: "Signo",         value: planet.sign.rawValue)
                            InfoRow(label: "Elemento",      value: element(for: planet.sign))
                            InfoRow(label: "Modalidad",     value: modality(for: planet.sign))
                            InfoRow(label: "Grado absoluto",value: String(format: "%.4f° / 360°", planet.longitude))
                            InfoRow(label: "Grado circular",value: circularDeg(planet.longitude))
                            InfoRow(label: "Estado",        value: planet.isRetrograde ? "Retrógrado ℞" : "Directo")
                        }
                        .padding()
                        .background(RoundedRectangle(cornerRadius: 14).fill(Color.white.opacity(0.05)))
                        .padding(.horizontal)
                    }
                    .padding(.bottom, 30)
                }
            }
            .navigationTitle("Detalle — \(planet.name)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cerrar") { dismiss() }
                        .foregroundColor(.yellow)
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    func element(for sign: ZodiacSign) -> String {
        switch sign {
        case .aries, .leo, .sagittarius:          return "🔥 Fuego"
        case .taurus, .virgo, .capricorn:         return "🌍 Tierra"
        case .gemini, .libra, .aquarius:          return "💨 Aire"
        case .cancer, .scorpio, .pisces:          return "💧 Agua"
        }
    }

    func modality(for sign: ZodiacSign) -> String {
        switch sign {
        case .aries, .cancer, .libra, .capricorn:          return "Cardinal"
        case .taurus, .leo, .scorpio, .aquarius:           return "Fijo"
        case .gemini, .virgo, .sagittarius, .pisces:       return "Mutable"
        }
    }

    func circularDeg(_ lon: Double) -> String {
        let sign = Int(lon / 30)
        let deg = Int(lon) % 30
        let min = Int((lon - Double(Int(lon))) * 60)
        return "\(ZodiacSign.allCases[sign].glyph) \(deg)°\(min)'"
    }
}

// MARK: - Sub-views

struct DetailCard: View {
    let title: String
    let value: String
    let subtitle: String
    let icon: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundColor(.yellow.opacity(0.7))
                Text(title)
                    .font(.caption2)
                    .foregroundColor(.gray)
            }
            Text(value)
                .font(.system(.subheadline, design: .monospaced))
                .fontWeight(.bold)
                .foregroundColor(.white)
                .minimumScaleFactor(0.6)
            Text(subtitle)
                .font(.caption2)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.07)))
    }
}

struct InfoRow: View {
    let label: String
    let value: String
    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.gray)
            Spacer()
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.white)
        }
    }
}

struct ZodiacPositionBar: View {
    let longitude: Double
    private let signs = ZodiacSign.allCases

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Posición en la Eclíptica")
                .font(.caption)
                .foregroundColor(.gray)
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    // Colored zodiac segments
                    HStack(spacing: 0) {
                        ForEach(0..<12) { i in
                            Rectangle()
                                .fill(segColor(i).opacity(0.35))
                                .frame(width: geo.size.width / 12)
                        }
                    }
                    .cornerRadius(6)

                    // Sign glyphs
                    HStack(spacing: 0) {
                        ForEach(0..<12) { i in
                            Text(signs[i].glyph)
                                .font(.system(size: 9))
                                .frame(width: geo.size.width / 12)
                        }
                    }

                    // Position needle
                    let x = CGFloat(longitude / 360.0) * geo.size.width
                    Rectangle()
                        .fill(Color.yellow)
                        .frame(width: 2, height: 28)
                        .offset(x: x - 1)

                    Triangle()
                        .fill(Color.yellow)
                        .frame(width: 8, height: 6)
                        .offset(x: x - 4, y: -14)
                }
            }
            .frame(height: 28)

            Text(String(format: "%.2f° de 360°", longitude))
                .font(.caption2)
                .foregroundColor(.yellow)
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.06)))
    }

    func segColor(_ i: Int) -> Color {
        switch i % 4 {
        case 0: return .red
        case 1: return .green
        case 2: return .yellow
        default: return .blue
        }
    }
}

struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        Path { p in
            p.move(to: CGPoint(x: rect.midX, y: rect.minY))
            p.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
            p.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
            p.closeSubpath()
        }
    }
}
