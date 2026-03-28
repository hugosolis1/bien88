import SwiftUI
import Combine

class AstroViewModel: ObservableObject {
    @Published var selectedDate: Date = Date()
    @Published var isGeocentric: Bool = true
    @Published var latitude: Double = 19.4326   // default CDMX
    @Published var longitude: Double = -99.1332
    @Published var planets: [PlanetPosition] = []
    @Published var angles: ChartAngles = ChartAngles(ascendant: 0, descendant: 180, midheaven: 90, imumCoeli: 270, northNode: 0, southNode: 180)
    @Published var isLoading: Bool = false
    
    init() {
        compute()
    }
    
    func compute() {
        isLoading = true
        DispatchQueue.global(qos: .userInitiated).async {
            let result = AstronomicalEngine.computePositions(
                date: self.selectedDate,
                isGeocentric: self.isGeocentric,
                latitude: self.latitude,
                longitude: self.longitude
            )
            DispatchQueue.main.async {
                self.planets = result.0
                self.angles = result.1
                self.isLoading = false
            }
        }
    }
    
    func anglePosition(name: String, symbol: String, lon: Double) -> PlanetPosition {
        let sign = ZodiacSign.from(longitude: lon)
        let deg = lon.truncatingRemainder(dividingBy: 30)
        let dms = AstronomicalEngine.toDMS(degrees: deg)
        return PlanetPosition(name: name, symbol: symbol,
                              longitude: lon, latitude: 0, distance: 0, speed: 0,
                              sign: sign, degreeInSign: dms.d, minuteInSign: dms.m, secondInSign: dms.s)
    }
    
    var ascendantPosition: PlanetPosition {
        anglePosition(name: "Ascendente", symbol: "AC", lon: angles.ascendant)
    }
    var descendantPosition: PlanetPosition {
        anglePosition(name: "Descendente", symbol: "DC", lon: angles.descendant)
    }
    var midheavenPosition: PlanetPosition {
        anglePosition(name: "Medio Cielo", symbol: "MC", lon: angles.midheaven)
    }
    var imumCoeliPosition: PlanetPosition {
        anglePosition(name: "Fondo Cielo", symbol: "IC", lon: angles.imumCoeli)
    }
    
    var allPositions: [PlanetPosition] {
        planets + [ascendantPosition, descendantPosition, midheavenPosition, imumCoeliPosition]
    }
}
