import Foundation

// MARK: - Astronomical Constants
struct AstroConstants {
    static let J2000: Double = 2451545.0
    static let DEG_TO_RAD: Double = .pi / 180.0
    static let RAD_TO_DEG: Double = 180.0 / .pi
    static let ARCSEC_TO_DEG: Double = 1.0 / 3600.0
}

// MARK: - Planet Data Model
struct PlanetPosition: Identifiable {
    let id = UUID()
    let name: String
    let symbol: String
    let longitude: Double      // ecliptic longitude degrees 0-360
    let latitude: Double       // ecliptic latitude degrees
    let distance: Double       // AU
    let speed: Double          // degrees/day (negative = retrograde)
    let sign: ZodiacSign
    let degreeInSign: Double
    let minuteInSign: Double
    let secondInSign: Double
    var isRetrograde: Bool { speed < 0 }
    
    var formattedPosition: String {
        let d = Int(degreeInSign)
        let m = Int(minuteInSign)
        let s = Int(secondInSign)
        return "\(d)°\(m)'\(s)\" \(sign.rawValue)"
    }
    
    var decimalDegreeInSign: Double { degreeInSign + minuteInSign / 60.0 + secondInSign / 3600.0 }
}

// MARK: - Zodiac
enum ZodiacSign: String, CaseIterable {
    case aries = "♈ Aries"
    case taurus = "♉ Tauro"
    case gemini = "♊ Géminis"
    case cancer = "♋ Cáncer"
    case leo = "♌ Leo"
    case virgo = "♍ Virgo"
    case libra = "♎ Libra"
    case scorpio = "♏ Escorpio"
    case sagittarius = "♐ Sagitario"
    case capricorn = "♑ Capricornio"
    case aquarius = "♒ Acuario"
    case pisces = "♓ Piscis"
    
    var glyph: String {
        switch self {
        case .aries: return "♈"
        case .taurus: return "♉"
        case .gemini: return "♊"
        case .cancer: return "♋"
        case .leo: return "♌"
        case .virgo: return "♍"
        case .libra: return "♎"
        case .scorpio: return "♏"
        case .sagittarius: return "♐"
        case .capricorn: return "♑"
        case .aquarius: return "♒"
        case .pisces: return "♓"
        }
    }
    
    static func from(longitude: Double) -> ZodiacSign {
        let norm = longitude.truncatingRemainder(dividingBy: 360)
        let pos = norm < 0 ? norm + 360 : norm
        let idx = Int(pos / 30.0) % 12
        return ZodiacSign.allCases[idx]
    }
}

// MARK: - Chart Angles
struct ChartAngles {
    let ascendant: Double
    let descendant: Double
    let midheaven: Double
    let imumCoeli: Double
    let northNode: Double
    let southNode: Double
}

// MARK: - Astronomical Engine
class AstronomicalEngine {
    
    // Convert calendar date to Julian Day Number
    static func julianDay(date: Date) -> Double {
        let cal = Calendar(identifier: .gregorian)
        let comps = cal.dateComponents([.year, .month, .day, .hour, .minute, .second], from: date)
        
        let Y = Double(comps.year ?? 2000)
        let M = Double(comps.month ?? 1)
        let D = Double(comps.day ?? 1)
        let h = Double(comps.hour ?? 12)
        let m = Double(comps.minute ?? 0)
        let s = Double(comps.second ?? 0)
        
        let dayFraction = D + h/24.0 + m/1440.0 + s/86400.0
        
        var jY = Y
        var jM = M
        if M <= 2 { jY -= 1; jM += 12 }
        
        let A = Int(jY / 100)
        let B = 2 - A + Int(A / 4)
        
        return Double(Int(365.25 * (jY + 4716))) + Double(Int(30.6001 * (jM + 1))) + dayFraction + Double(B) - 1524.5
    }
    
    // Julian centuries from J2000
    static func T(jd: Double) -> Double {
        return (jd - AstroConstants.J2000) / 36525.0
    }
    
    // Normalize angle to 0-360
    static func norm360(_ angle: Double) -> Double {
        var a = angle.truncatingRemainder(dividingBy: 360)
        if a < 0 { a += 360 }
        return a
    }
    
    // Convert decimal degrees to DMS
    static func toDMS(degrees: Double) -> (d: Double, m: Double, s: Double) {
        let total = abs(degrees)
        let d = floor(total)
        let mFrac = (total - d) * 60
        let m = floor(mFrac)
        let s = (mFrac - m) * 60
        return (d, m, s)
    }
    
    // MARK: - Sun (geometric mean, full VSOP87 simplified)
    static func sunLongitude(T: Double) -> Double {
        let L0 = norm360(280.46646 + 36000.76983 * T + 0.0003032 * T * T)
        let M = norm360(357.52911 + 35999.05029 * T - 0.0001537 * T * T) * AstroConstants.DEG_TO_RAD
        let e = 0.016708634 - 0.000042037 * T
        
        let C = (1.914602 - 0.004817 * T - 0.000014 * T * T) * sin(M)
              + (0.019993 - 0.000101 * T) * sin(2 * M)
              + 0.000289 * sin(3 * M)
        
        let sunLon = L0 + C
        // Apparent longitude (aberration)
        let omega = (125.04 - 1934.136 * T) * AstroConstants.DEG_TO_RAD
        let apparent = sunLon - 0.00569 - 0.00478 * sin(omega)
        return norm360(apparent)
    }
    
    // MARK: - Moon (full ELP2000-82 truncated)
    static func moonLongitude(T: Double) -> (lon: Double, lat: Double, dist: Double) {
        let D  = norm360(297.85036 + 445267.111480 * T - 0.0019142 * T*T) * AstroConstants.DEG_TO_RAD
        let M  = norm360(357.52772 + 35999.050340 * T - 0.0001603 * T*T) * AstroConstants.DEG_TO_RAD
        let Mp = norm360(134.96298 + 477198.867398 * T + 0.0086972 * T*T) * AstroConstants.DEG_TO_RAD
        let F  = norm360(93.27191  + 483202.017538 * T - 0.0036825 * T*T) * AstroConstants.DEG_TO_RAD
        
        // Longitude terms (degrees * 10^-4)
        var sumL: Double = 0
        let lTerms: [(Double, Double, Double, Double, Double)] = [
            (0,0,1,0,  6288774),
            (2,0,-1,0, 1274027),
            (2,0,0,0,   658314),
            (0,0,2,0,   213618),
            (0,1,0,0,  -185116),
            (0,0,0,2,  -114332),
            (2,0,-2,0,   58793),
            (2,-1,-1,0,  57066),
            (2,0,1,0,    53322),
            (2,-1,0,0,   45758),
            (0,1,-1,0,  -40923),
            (1,0,0,0,   -34720),
            (0,1,1,0,   -30383),
            (2,0,0,-2,   15327),
            (0,0,1,2,   -12528),
            (0,0,1,-2,   10980),
            (4,0,-1,0,   10675),
            (0,0,3,0,    10034),
            (4,0,-2,0,    8548),
            (2,1,-1,0,   -7888)
        ]
        for t in lTerms {
            let arg = t.0*D + t.1*M + t.2*Mp + t.3*F
            sumL += t.4 * sin(arg)
        }
        
        // Latitude terms
        var sumB: Double = 0
        let bTerms: [(Double, Double, Double, Double, Double)] = [
            (0,0,0,1,  5128122),
            (0,0,1,1,   280602),
            (0,0,1,-1,  277693),
            (2,0,0,-1,  173237),
            (2,0,-1,1,   55413),
            (2,0,-1,-1,  46271),
            (2,0,0,1,   32573),
            (0,0,2,1,   17198),
            (2,0,1,-1,   9266),
            (0,0,2,-1,   8822)
        ]
        for t in bTerms {
            let arg = t.0*D + t.1*M + t.2*Mp + t.3*F
            sumB += t.4 * sin(arg)
        }
        
        // Distance terms
        var sumR: Double = 0
        let rTerms: [(Double, Double, Double, Double, Double)] = [
            (0,0,1,0,  -20905355),
            (2,0,-1,0,  -3699111),
            (2,0,0,0,   -2955968),
            (0,0,2,0,    -569925),
            (0,1,0,0,     48888),
            (0,0,0,2,    -3149),
            (2,0,-2,0,   246158),
            (2,-1,-1,0, -152138),
            (2,0,1,0,   -170733),
            (2,-1,0,0,  -204586)
        ]
        for t in rTerms {
            let arg = t.0*D + t.1*M + t.2*Mp + t.3*F
            sumR += t.4 * cos(arg)
        }
        
        let L1 = norm360(218.3164477 + 481267.88123421 * T)
        let lon = norm360(L1 + sumL / 1000000.0)
        let lat = sumB / 1000000.0
        let dist = (385000.56 + sumR / 1000.0) / 149597870.7 // AU
        
        return (lon, lat, dist)
    }
    
    // MARK: - Outer planets using truncated VSOP87
    // Mercury
    static func mercuryLongitude(T: Double) -> (lon: Double, lat: Double, dist: Double, speed: Double) {
        let L = norm360(252.250906 + 149474.0722491 * T + 0.0003035 * T*T)
        let a = 0.387098310
        let e = 0.20563175 + 0.000020407 * T
        let M = norm360(174.791086 + 149472.515654 * T) * AstroConstants.DEG_TO_RAD
        let v = trueAnomaly(M: M, e: e)
        let r = a * (1 - e*e) / (1 + e * cos(v))
        let lon = norm360(L + (v - M) * AstroConstants.RAD_TO_DEG)
        return (lon, 0, r, 4.09)
    }
    
    // Venus
    static func venusLongitude(T: Double) -> (lon: Double, lat: Double, dist: Double, speed: Double) {
        let L = norm360(181.979801 + 58519.2130302 * T + 0.00031014 * T*T)
        let a = 0.723329820
        let e = 0.00677188 - 0.000047766 * T
        let M = norm360(50.416009 + 58517.803876 * T) * AstroConstants.DEG_TO_RAD
        let v = trueAnomaly(M: M, e: e)
        let r = a * (1 - e*e) / (1 + e * cos(v))
        let lon = norm360(L + (v - M) * AstroConstants.RAD_TO_DEG)
        return (lon, 0, r, 1.60)
    }
    
    // Mars
    static func marsLongitude(T: Double) -> (lon: Double, lat: Double, dist: Double, speed: Double) {
        let L = norm360(355.433275 + 19141.6964746 * T + 0.00031052 * T*T)
        let a = 1.523679342
        let e = 0.09340062 + 0.000090483 * T
        let M = norm360(19.373481 + 19140.2993313 * T) * AstroConstants.DEG_TO_RAD
        let v = trueAnomaly(M: M, e: e)
        let r = a * (1 - e*e) / (1 + e * cos(v))
        let lon = norm360(L + (v - M) * AstroConstants.RAD_TO_DEG)
        return (lon, 0, r, 0.524)
    }
    
    // Jupiter
    static func jupiterLongitude(T: Double) -> (lon: Double, lat: Double, dist: Double, speed: Double) {
        let L = norm360(34.351519 + 3036.3027748 * T + 0.00022330 * T*T)
        let a = 5.202603191 + 0.0000001913 * T
        let e = 0.04849485 + 0.000163244 * T
        let M = norm360(20.9240022 + 3034.9056606 * T) * AstroConstants.DEG_TO_RAD
        let v = trueAnomaly(M: M, e: e)
        let r = a * (1 - e*e) / (1 + e * cos(v))
        let lon = norm360(L + (v - M) * AstroConstants.RAD_TO_DEG)
        return (lon, 0, r, 0.0831)
    }
    
    // Saturn
    static func saturnLongitude(T: Double) -> (lon: Double, lat: Double, dist: Double, speed: Double) {
        let L = norm360(50.077444 + 1223.5110686 * T + 0.00051908 * T*T)
        let a = 9.554909596 - 0.0000021389 * T
        let e = 0.05550862 - 0.000346818 * T
        let M = norm360(317.020831 + 1222.1134582 * T) * AstroConstants.DEG_TO_RAD
        let v = trueAnomaly(M: M, e: e)
        let r = a * (1 - e*e) / (1 + e * cos(v))
        let lon = norm360(L + (v - M) * AstroConstants.RAD_TO_DEG)
        return (lon, 0, r, 0.0335)
    }
    
    // Uranus
    static func uranusLongitude(T: Double) -> (lon: Double, lat: Double, dist: Double, speed: Double) {
        let L = norm360(314.055005 + 429.8640561 * T + 0.00030390 * T*T)
        let a = 19.218446062 - 0.0000000372 * T
        let e = 0.04629590 - 0.000027337 * T
        let M = norm360(142.5905632 + 428.4603567 * T) * AstroConstants.DEG_TO_RAD
        let v = trueAnomaly(M: M, e: e)
        let r = a * (1 - e*e) / (1 + e * cos(v))
        let lon = norm360(L + (v - M) * AstroConstants.RAD_TO_DEG)
        return (lon, 0, r, 0.01176)
    }
    
    // Neptune
    static func neptuneLongitude(T: Double) -> (lon: Double, lat: Double, dist: Double, speed: Double) {
        let L = norm360(304.348665 + 219.8833092 * T + 0.00030882 * T*T)
        let a = 30.110386869 - 0.0000001663 * T
        let e = 0.00898809 + 0.000006408 * T
        let M = norm360(256.2281046 + 218.4862002 * T) * AstroConstants.DEG_TO_RAD
        let v = trueAnomaly(M: M, e: e)
        let r = a * (1 - e*e) / (1 + e * cos(v))
        let lon = norm360(L + (v - M) * AstroConstants.RAD_TO_DEG)
        return (lon, 0, r, 0.006)
    }
    
    // Pluto (simplified)
    static func plutoLongitude(T: Double) -> (lon: Double, lat: Double, dist: Double, speed: Double) {
        let lon = norm360(238.9508 + 144.9600 * T)
        return (lon, -17.0, 39.543, 0.004)
    }
    
    // True anomaly from mean anomaly (Kepler equation solver)
    static func trueAnomaly(M: Double, e: Double) -> Double {
        var E = M
        for _ in 0..<50 {
            let dE = (M - E + e * sin(E)) / (1 - e * cos(E))
            E += dE
            if abs(dE) < 1e-10 { break }
        }
        let sinV = sqrt(1 - e*e) * sin(E) / (1 - e * cos(E))
        let cosV = (cos(E) - e) / (1 - e * cos(E))
        return atan2(sinV, cosV)
    }
    
    // MARK: - Geocentric conversion
    static func toGeocentric(helioLon: Double, helioLat: Double, helioDist: Double,
                              sunLon: Double, sunDist: Double) -> (lon: Double, lat: Double, dist: Double) {
        let lon1 = helioLon * AstroConstants.DEG_TO_RAD
        let lat1 = helioLat * AstroConstants.DEG_TO_RAD
        let sLon = sunLon * AstroConstants.DEG_TO_RAD
        
        let x = helioDist * cos(lat1) * cos(lon1) - sunDist * cos(sLon)
        let y = helioDist * cos(lat1) * sin(lon1) - sunDist * sin(sLon)
        let z = helioDist * sin(lat1)
        
        let dist = sqrt(x*x + y*y + z*z)
        let lon = norm360(atan2(y, x) * AstroConstants.RAD_TO_DEG)
        let lat = atan2(z, sqrt(x*x + y*y)) * AstroConstants.RAD_TO_DEG
        
        return (lon, lat, dist)
    }
    
    // MARK: - Lunar Nodes
    static func lunarNodes(T: Double) -> (north: Double, south: Double) {
        let omega = norm360(125.0445479 - 1934.1362608 * T + 0.0020754 * T*T + T*T*T/467441.0)
        return (omega, norm360(omega + 180))
    }
    
    // MARK: - Obliquity of Ecliptic
    static func obliquity(T: Double) -> Double {
        return 23.4392911 - 0.0130042 * T - 0.00000164 * T*T + 0.000000504 * T*T*T
    }
    
    // MARK: - GMST (Greenwich Mean Sidereal Time)
    static func gmst(jd: Double) -> Double {
        let T = (jd - AstroConstants.J2000) / 36525.0
        let gmst0 = 280.46061837 + 360.98564736629 * (jd - AstroConstants.J2000)
                  + 0.000387933 * T*T - T*T*T / 38710000.0
        return norm360(gmst0)
    }
    
    // MARK: - Local Sidereal Time
    static func lst(jd: Double, longitude: Double) -> Double {
        return norm360(gmst(jd: jd) + longitude)
    }
    
    // MARK: - Ascendant calculation
    static func ascendant(obliquity: Double, lst: Double, latitude: Double) -> Double {
        let E = obliquity * AstroConstants.DEG_TO_RAD
        let T = lst * AstroConstants.DEG_TO_RAD
        let L = latitude * AstroConstants.DEG_TO_RAD
        
        let y = -cos(T)
        let x = sin(E) * tan(L) + cos(E) * sin(T)
        var asc = atan2(y, x) * AstroConstants.RAD_TO_DEG
        if asc < 0 { asc += 360 }
        return norm360(asc)
    }
    
    // MARK: - Midheaven
    static func midheaven(obliquity: Double, lst: Double) -> Double {
        let E = obliquity * AstroConstants.DEG_TO_RAD
        let T = lst * AstroConstants.DEG_TO_RAD
        let mc = atan2(sin(T), cos(T) * cos(E) - tan(0) * sin(E)) * AstroConstants.RAD_TO_DEG
        return norm360(mc)
    }
    
    // MARK: - Main compute function
    static func computePositions(date: Date, isGeocentric: Bool,
                                  latitude: Double = 19.4326,
                                  longitude: Double = -99.1332) -> ([PlanetPosition], ChartAngles) {
        let jd = julianDay(date: date)
        let t = T(jd: jd)
        
        let sunLon = sunLongitude(T: t)
        // Sun distance approx
        let Me = norm360(357.52911 + 35999.05029 * t) * AstroConstants.DEG_TO_RAD
        let sunDist = 1.000001018 * (1 - 0.016708634 * 0.016708634) / (1 + 0.016708634 * cos(Me))
        
        let obliq = obliquity(T: t)
        let lstDeg = lst(jd: jd, longitude: longitude)
        let asc = ascendant(obliquity: obliq, lst: lstDeg, latitude: latitude)
        let mc = midheaven(obliquity: obliq, lst: lstDeg)
        let nodes = lunarNodes(T: t)
        
        func makePlanet(name: String, symbol: String, hLon: Double, hLat: Double, hDist: Double, hSpeed: Double) -> PlanetPosition {
            var lon: Double
            var lat: Double
            var dist: Double
            var speed: Double = hSpeed
            
            if isGeocentric {
                let geo = toGeocentric(helioLon: hLon, helioLat: hLat, helioDist: hDist,
                                       sunLon: sunLon, sunDist: sunDist)
                lon = geo.lon
                lat = geo.lat
                dist = geo.dist
                // Rough retrograde: if geo longitude < helio, retrograde
                speed = (geo.lon - hLon > 180 || geo.lon - hLon < -180) ? -hSpeed * 0.3 : hSpeed
            } else {
                lon = hLon
                lat = hLat
                dist = hDist
            }
            
            let sign = ZodiacSign.from(longitude: lon)
            let degInSign = lon.truncatingRemainder(dividingBy: 30)
            let dms = toDMS(degrees: degInSign)
            return PlanetPosition(name: name, symbol: symbol,
                                  longitude: lon, latitude: lat, distance: dist, speed: speed,
                                  sign: sign, degreeInSign: dms.d, minuteInSign: dms.m, secondInSign: dms.s)
        }
        
        // Sun (geocentric always)
        let sunDms = toDMS(degrees: sunLon.truncatingRemainder(dividingBy: 30))
        let sunSign = ZodiacSign.from(longitude: sunLon)
        let sunPos = PlanetPosition(name: "Sol", symbol: "☉", longitude: sunLon,
                                    latitude: 0, distance: sunDist, speed: 0.9856,
                                    sign: sunSign, degreeInSign: sunDms.d, minuteInSign: sunDms.m, secondInSign: sunDms.s)
        
        // Moon
        let moonData = moonLongitude(T: t)
        let moonLon = isGeocentric ? moonData.lon : moonData.lon
        let moonSign = ZodiacSign.from(longitude: moonLon)
        let moonDms = toDMS(degrees: moonLon.truncatingRemainder(dividingBy: 30))
        let moonPos = PlanetPosition(name: "Luna", symbol: "☽", longitude: moonLon,
                                     latitude: moonData.lat, distance: moonData.dist * 149597870.7 / 1.0,
                                     speed: 13.17, sign: moonSign,
                                     degreeInSign: moonDms.d, minuteInSign: moonDms.m, secondInSign: moonDms.s)
        
        let merc = mercuryLongitude(T: t)
        let ven  = venusLongitude(T: t)
        let mars = marsLongitude(T: t)
        let jup  = jupiterLongitude(T: t)
        let sat  = saturnLongitude(T: t)
        let ura  = uranusLongitude(T: t)
        let nep  = neptuneLongitude(T: t)
        let plu  = plutoLongitude(T: t)
        
        var planets: [PlanetPosition] = [
            sunPos,
            moonPos,
            makePlanet(name: "Mercurio", symbol: "☿", hLon: merc.lon, hLat: merc.lat, hDist: merc.dist, hSpeed: merc.speed),
            makePlanet(name: "Venus",    symbol: "♀", hLon: ven.lon,  hLat: ven.lat,  hDist: ven.dist,  hSpeed: ven.speed),
            makePlanet(name: "Marte",    symbol: "♂", hLon: mars.lon, hLat: mars.lat, hDist: mars.dist, hSpeed: mars.speed),
            makePlanet(name: "Júpiter",  symbol: "♃", hLon: jup.lon,  hLat: jup.lat,  hDist: jup.dist,  hSpeed: jup.speed),
            makePlanet(name: "Saturno",  symbol: "♄", hLon: sat.lon,  hLat: sat.lat,  hDist: sat.dist,  hSpeed: sat.speed),
            makePlanet(name: "Urano",    symbol: "♅", hLon: ura.lon,  hLat: ura.lat,  hDist: ura.dist,  hSpeed: ura.speed),
            makePlanet(name: "Neptuno",  symbol: "♆", hLon: nep.lon,  hLat: nep.lat,  hDist: nep.dist,  hSpeed: nep.speed),
            makePlanet(name: "Plutón",   symbol: "♇", hLon: plu.lon,  hLat: plu.lat,  hDist: plu.dist,  hSpeed: plu.speed),
        ]
        
        // Add Nodo Norte/Sur
        let nnDms = toDMS(degrees: nodes.north.truncatingRemainder(dividingBy: 30))
        let nnPos = PlanetPosition(name: "Nodo Norte", symbol: "☊",
                                   longitude: nodes.north, latitude: 0, distance: 0, speed: -0.053,
                                   sign: ZodiacSign.from(longitude: nodes.north),
                                   degreeInSign: nnDms.d, minuteInSign: nnDms.m, secondInSign: nnDms.s)
        let snDms = toDMS(degrees: nodes.south.truncatingRemainder(dividingBy: 30))
        let snPos = PlanetPosition(name: "Nodo Sur", symbol: "☋",
                                   longitude: nodes.south, latitude: 0, distance: 0, speed: -0.053,
                                   sign: ZodiacSign.from(longitude: nodes.south),
                                   degreeInSign: snDms.d, minuteInSign: snDms.m, secondInSign: snDms.s)
        planets.append(nnPos)
        planets.append(snPos)
        
        let angles = ChartAngles(
            ascendant: asc,
            descendant: norm360(asc + 180),
            midheaven: mc,
            imumCoeli: norm360(mc + 180),
            northNode: nodes.north,
            southNode: nodes.south
        )
        
        return (planets, angles)
    }
}
