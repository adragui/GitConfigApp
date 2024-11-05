import SwiftUI

struct SSHKeyRowView: View {
    let key: String
    var isConnectionSuccessful: Bool?
    let onTestConnection: () -> Void
    let onDeleteKey: () -> Void

    var body: some View {
        if !key.hasSuffix(".json") {  // Solo mostrar si el archivo no es .json
            GroupBox(label: Label("Llave: \(cleanKeyName(key))", systemImage: "key.fill")) {
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Button(action: {
                            onTestConnection()
                        }) {
                            HStack {
                                Text("Probar Conexión")
                                if let connectionResult = isConnectionSuccessful {
                                    Image(systemName: connectionResult ? "checkmark.circle.fill" : "xmark.circle.fill")
                                        .foregroundColor(connectionResult ? .green : .red)
                                }
                            }
                        }
                        .buttonStyle(BorderedProminentButtonStyle())
                        .tint(.blue)

                        Button(action: {
                            onDeleteKey()
                        }) {
                            Text("Eliminar Llave")
                        }
                        .buttonStyle(BorderedProminentButtonStyle())
                        .tint(.red)
                    }
                }
                .padding()
            }
            .background(Color.white)
            .cornerRadius(15)
            .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
        }
    }
    
    private func cleanKeyName(_ key: String) -> String {
        // Eliminar solo la extensión .json si está presente
        return key.hasSuffix(".json") ? String(key.dropLast(5)) : key
    }
}
