import SwiftUI
import Foundation

class SSHKeyGeneratorViewModel: ObservableObject {
    @Published var email = ""
    @Published var username = ""
    @Published var service = ""
    @Published var tag = ""
    @Published var keyType = "RSA"
    @Published var generatedKey = ""
    
    let services = ["GitHub", "GitLab", "Bitbucket", "Otros"]
    let keyTypes = ["RSA", "ED25519", "ECDSA"]
    
    func generateSSHKey() {
        // Directorio para almacenar la llave
        let sshDirectory = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(".ssh")
        
        // Crear el directorio .ssh si no existe
        if !FileManager.default.fileExists(atPath: sshDirectory.path) {
            do {
                try FileManager.default.createDirectory(at: sshDirectory, withIntermediateDirectories: true, attributes: nil)
            } catch {
                DispatchQueue.main.async {
                    self.generatedKey = "Error al crear el directorio .ssh: \(error.localizedDescription)"
                }
                return
            }
        }
        
        // Ruta completa para la llave SSH
        let sshKeyPath = sshDirectory.appendingPathComponent("\(tag)_\(service)").path
        let command = "ssh-keygen -t \(keyType.lowercased()) -C \"\(email)\" -f \(sshKeyPath) -N \"\""
        
        let task = Process()
        task.launchPath = "/bin/zsh"
        task.arguments = ["-c", command]
        
        let pipe = Pipe()
        task.standardOutput = pipe
        task.launch()
        task.waitUntilExit()
        
        // Verificar si se generó correctamente la llave
        let pubKeyPath = "\(sshKeyPath).pub"
        if FileManager.default.fileExists(atPath: pubKeyPath) {
            if let pubKey = try? String(contentsOfFile: pubKeyPath, encoding: .utf8) {
                DispatchQueue.main.async {
                    self.generatedKey = pubKey
                }
                
                // Guarda `user.name` y `user.email` asociados a la llave
                saveConfig(username: username, email: email, keyName: "\(tag)_\(service)")
            }
        } else {
            DispatchQueue.main.async {
                self.generatedKey = "Error al generar la llave SSH."
            }
        }
    }
    
    private func saveConfig(username: String, email: String, keyName: String) {
        // Guarda la configuración de user.name y user.email en un archivo JSON
        let config = SSHKeyConfig(username: username, email: email)
        let encoder = JSONEncoder()
        if let data = try? encoder.encode(config) {
            let configPath = FileManager.default.homeDirectoryForCurrentUser
                .appendingPathComponent(".ssh/\(keyName)_config.json")
            try? data.write(to: configPath)
            print("Configuración guardada para la llave \(keyName)")
        }
    }
    
    func copyToClipboard() {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(generatedKey, forType: .string)
    }
}

struct SSHKeyConfig: Codable {
    let username: String
    let email: String
}
