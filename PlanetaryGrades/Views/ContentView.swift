import SwiftUI

struct ContentView: View {
    @StateObject var vm = AstroViewModel()
    @State var showSettings = false
    @State var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            PlanetListTab(vm: vm, showSettings: $showSettings)
                .tabItem { Label("Posiciones", systemImage: "globe") }
                .tag(0)

            NavigationView { DegreeFinderView() }
                .tabItem { Label("Buscador °", systemImage: "magnifyingglass.circle") }
                .tag(1)

            NavigationView { GannSquareView() }
                .tabItem { Label("Gann 9", systemImage: "squareshape.split.3x3") }
                .tag(2)
        }
        .preferredColorScheme(.dark)
        .accentColor(.yellow)
    }
}

// MARK: - Planet List Tab
struct PlanetListTab: View {
    @ObservedObject var vm: AstroViewModel
    @Binding var showSettings: Bool
    @State private var selectedPlanet: PlanetPosition? = nil

    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(
                    colors: [Color(red: 0.07, green: 0.02, blue: 0.13),
                             Color(red: 0.00, green: 0.01, blue: 0.10)],
                    startPoint: .top, endPoint: .bottom
                ).ignoresSafeArea()

                VStack(spacing: 0) {
                    VStack(spacing: 12) {
                        DatePicker("Fecha", selection: $vm.selectedDate,
                                   displayedComponents: [.date, .hourAndMinute])
                            .datePickerStyle(.compact)
                            .colorScheme(.dark)
                            .padding(.horizontal)

                        Picker("Perspectiva", selection: $vm.isGeocentric) {
                            Text("Geocéntrico").tag(true)
                            Text("Heliocéntrico").tag(false)
                        }
                        .pickerStyle(.segmented)
                        .padding(.horizontal)

                        Button(action: { vm.compute() }) {
                            HStack {
                                Image(systemName: "sparkles")
                                Text("Calcular Posiciones").fontWeight(.semibold)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color.indigo)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }
                        .padding(.horizontal)
                    }
                    .padding(.top, 12).padding(.bottom, 8)
                    .background(Color.black.opacity(0.3))

                    if vm.isLoading {
                        Spacer()
                        ProgressView("Calculando...").foregroundColor(.white)
                        Spacer()
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 8) {
                                SectionHeader(title: "Ángulos de la Carta")
                                ForEach([vm.ascendantPosition, vm.midheavenPosition,
                                         vm.descendantPosition, vm.imumCoeliPosition]) { p in
                                    PlanetRow(planet: p, isAngle: true)
                                        .onTapGesture { selectedPlanet = p }
                                }

                                SectionHeader(title: "Planetas")
                                ForEach(vm.planets) { p in
                                    PlanetRow(planet: p, isAngle: false)
                                        .onTapGesture { selectedPlanet = p }
                                }
                            }
                            .padding()
                        }
                    }
                }
            }
            .navigationTitle("Grados Planetarios")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { showSettings.toggle() } label: {
                        Image(systemName: "location.circle")
                    }
                }
            }
            .sheet(isPresented: $showSettings) { LocationSettingsView(vm: vm) }
            .sheet(item: $selectedPlanet) { planet in PlanetDetailView(planet: planet) }
        }
        .onChange(of: vm.selectedDate) { _ in vm.compute() }
        .onChange(of: vm.isGeocentric) { _ in vm.compute() }
    }
}

// MARK: - Shared sub-views

struct SectionHeader: View {
    let title: String
    var body: some View {
        HStack {
            Text(title.uppercased())
                .font(.caption).fontWeight(.bold)
                .foregroundColor(.yellow.opacity(0.8)).tracking(2)
            Spacer()
        }
        .padding(.top, 8).padding(.bottom, 2)
    }
}

struct PlanetRow: View {
    let planet: PlanetPosition
    let isAngle: Bool

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle().fill(symbolColor.opacity(0.2)).frame(width: 40, height: 40)
                Text(planet.symbol).font(.system(size: 20)).foregroundColor(symbolColor)
            }

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(planet.name)
                        .font(.system(.subheadline)).fontWeight(.medium).foregroundColor(.white)
                    if planet.isRetrograde {
                        Text("℞").font(.caption).foregroundColor(.red)
                            .padding(.horizontal, 4).padding(.vertical, 1)
                            .background(Color.red.opacity(0.2)).cornerRadius(4)
                    }
                }
                Text(planet.sign.rawValue).font(.caption).foregroundColor(.gray)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                HStack(spacing: 2) {
                    Text(planet.sign.glyph).font(.title3).foregroundColor(signColor(planet.sign))
                    Text("\(Int(planet.degreeInSign))°\(Int(planet.minuteInSign))'\(Int(planet.secondInSign))\"")
                        .font(.system(.subheadline, design: .monospaced))
                        .foregroundColor(.white).fontWeight(.semibold)
                }
                if !isAngle && planet.distance > 0 {
                    Text(String(format: "%.3f AU", planet.distance))
                        .font(.caption2).foregroundColor(.gray)
                }
            }

            Image(systemName: "chevron.right").font(.caption2).foregroundColor(.gray.opacity(0.5))
        }
        .padding(.horizontal, 14).padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(isAngle ? 0.07 : 0.05))
                .overlay(RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(Color.white.opacity(0.08), lineWidth: 1))
        )
        .contentShape(Rectangle())
    }

    var symbolColor: Color {
        if isAngle { return .yellow }
        switch planet.name {
        case "Sol":      return .yellow
        case "Luna":     return .white
        case "Mercurio": return .mint
        case "Venus":    return .pink
        case "Marte":    return .red
        case "Júpiter":  return .orange
        case "Saturno":  return Color(red: 0.7, green: 0.5, blue: 0.2)
        case "Urano":    return .cyan
        case "Neptuno":  return .blue
        case "Plutón":   return .purple
        case "Nodo Norte", "Nodo Sur": return .green
        default: return .gray
        }
    }

    func signColor(_ sign: ZodiacSign) -> Color {
        switch sign {
        case .aries, .leo, .sagittarius:    return .red
        case .taurus, .virgo, .capricorn:   return .green
        case .gemini, .libra, .aquarius:    return .yellow
        case .cancer, .scorpio, .pisces:    return .blue
        }
    }
}
