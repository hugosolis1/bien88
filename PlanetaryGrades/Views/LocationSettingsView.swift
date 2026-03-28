import SwiftUI

struct LocationSettingsView: View {
    @ObservedObject var vm: AstroViewModel
    @Environment(\.dismiss) var dismiss
    
    @State private var latText: String = ""
    @State private var lonText: String = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Ubicación Geográfica")) {
                    HStack {
                        Text("Latitud")
                        Spacer()
                        TextField("ej. 19.4326", text: $latText)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                    HStack {
                        Text("Longitud")
                        Spacer()
                        TextField("ej. -99.1332", text: $lonText)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                }
                
                Section(header: Text("Ciudades de Referencia")) {
                    cityButton("Ciudad de México", lat: 19.4326, lon: -99.1332)
                    cityButton("Madrid", lat: 40.4168, lon: -3.7038)
                    cityButton("Buenos Aires", lat: -34.6037, lon: -58.3816)
                    cityButton("Nueva York", lat: 40.7128, lon: -74.0060)
                    cityButton("Londres", lat: 51.5074, lon: -0.1278)
                    cityButton("París", lat: 48.8566, lon: 2.3522)
                }
                
                Section {
                    Button("Aplicar") {
                        if let lat = Double(latText), let lon = Double(lonText) {
                            vm.latitude = lat
                            vm.longitude = lon
                            vm.compute()
                        }
                        dismiss()
                    }
                    .foregroundColor(.accentColor)
                }
            }
            .navigationTitle("Configuración")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cerrar") { dismiss() }
                }
            }
            .onAppear {
                latText = String(format: "%.4f", vm.latitude)
                lonText = String(format: "%.4f", vm.longitude)
            }
        }
    }
    
    func cityButton(_ name: String, lat: Double, lon: Double) -> some View {
        Button(action: {
            vm.latitude = lat
            vm.longitude = lon
            latText = String(format: "%.4f", lat)
            lonText = String(format: "%.4f", lon)
            vm.compute()
            dismiss()
        }) {
            HStack {
                Text(name)
                Spacer()
                Text("\(String(format: "%.2f", lat))°, \(String(format: "%.2f", lon))°")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
        .foregroundColor(.primary)
    }
}
