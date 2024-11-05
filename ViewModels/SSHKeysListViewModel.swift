import Foundation
import SwiftUI

class SSHKeysListViewModel: ObservableObject {
    @Published var sshKeys: [String] = []
    @Published var usernames: [String: String] = [:]
    @Published var emails: [String: String] = [:]
    @Published var connectionStatus: [String: Bool] = [:]
    @Published var statusMessages: [String: String] = [:]
    @Published var services: [String: String] = [:]
    
    func loadSSHKeys() {
        sshKeys.removeAll()
        usernames.removeAll()
        emails.removeAll()
        connectionStatus.removeAll()
        statusMessages.removeAll()
        
        let sshDirectory = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(".ssh")
        
        do {
            let files = try FileManager.default.contentsOfDirectory(atPath: sshDirectory.path)
            
            let privateKeys = files.filter { file in
                let filePath = sshDirectory.appendingPathComponent(file)
                let allowedKeys = ["id_rsa", "id_ecdsa", "id_ed25519"]
                return allowedKeys.contains(file) || (!file.hasSuffix(".pub") && file != "known_hosts" && file != "known_hosts.old" && file != ".DS_Store" && FileManager.default.isReadableFile(atPath: filePath.path))
            }
            
            for key in privateKeys {
                sshKeys.append(key)
                
                // Cargar configuración personalizada para cada llave desde un archivo JSON
                if let config = loadConfig(for: key) {
                    usernames[key] = config.username
                    emails[key] = config.email
                } else {
                    usernames[key] = "DefaultUserName_\(key)"
                    emails[key] = "\(key)@example.com"
                }
                
                connectionStatus[key] = false
                statusMessages[key] = ""
            }
        } catch {
            print("Error al cargar llaves SSH: \(error.localizedDescription)")
        }
        
        print("SSH Keys loaded:", sshKeys)
        print("Usernames loaded:", usernames)
        print("Emails loaded:", emails)
    }
    
    func testConnection(for key: String) {
        // Implementación del test de conexión para cada llave
        print("Probando conexión para la llave: \(key)")
        // Ejemplo de un comando SSH para verificar la conexión
        let sshDirectory = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(".ssh")
        let privateKeyPath = sshDirectory.appendingPathComponent(key)
        let command = "ssh -o StrictHostKeyChecking=no -i \(privateKeyPath.path) -T git@github.com"
        
        let success = executeShellCommand(command) != nil
        DispatchQueue.main.async {
            self.connectionStatus[key] = success
            self.statusMessages[key] = success ? "Conexión exitosa" : "Error de conexión"
        }
    }

    func applyGitConfigChanges(for key: String) {
        guard let username = usernames[key], let email = emails[key] else {
            print("Nombre de usuario o correo electrónico no definido para la llave \(key)")
            statusMessages[key] = "Nombre de usuario o correo electrónico no definido para la llave \(key)"
            return
        }
        
        saveConfig(for: key, username: username, email: email)
        
        DispatchQueue.main.async {
            self.statusMessages[key] = "Configuración guardada para la llave \(key)"
            print("Configuración guardada para la llave \(key)")
        }
    }
    
    func deleteSSHKey(named key: String) {
        let sshDirectory = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(".ssh")
        let privateKeyPath = sshDirectory.appendingPathComponent(key)
        let publicKeyPath = sshDirectory.appendingPathComponent("\(key).pub")
        let configPath = sshDirectory.appendingPathComponent("\(key)_config.json")
        
        do {
            if FileManager.default.fileExists(atPath: privateKeyPath.path) {
                try FileManager.default.removeItem(at: privateKeyPath)
                print("Archivo \(key) eliminado del sistema de archivos.")
            }
            
            if FileManager.default.fileExists(atPath: publicKeyPath.path) {
                try FileManager.default.removeItem(at: publicKeyPath)
                print("Archivo \(key).pub eliminado del sistema de archivos.")
            }
            
            if FileManager.default.fileExists(atPath: configPath.path) {
                try FileManager.default.removeItem(at: configPath)
                print("Archivo de configuración eliminado.")
            }
            
            sshKeys.removeAll { $0 == key }
            usernames.removeValue(forKey: key)
            emails.removeValue(forKey: key)
            connectionStatus.removeValue(forKey: key)
            statusMessages[key] = "Llave \(key) eliminada correctamente."
            
        } catch {
            print("Error al eliminar la llave \(key): \(error.localizedDescription)")
            statusMessages[key] = "Error al eliminar la llave \(key)."
        }
    }
    
    private func loadConfig(for key: String) -> Config? {
        let configPath = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(".ssh/\(key)_config.json")
        guard let data = try? Data(contentsOf: configPath) else { return nil }
        let decoder = JSONDecoder()
        return try? decoder.decode(Config.self, from: data)
    }
    
    private func saveConfig(for key: String, username: String, email: String) {
        let config = Config(username: username, email: email)
        let encoder = JSONEncoder()
        if let data = try? encoder.encode(config) {
            let configPath = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(".ssh/\(key)_config.json")
            try? data.write(to: configPath)
            print("Configuración guardada en \(configPath.path)")
        }
    }
    
    private func executeShellCommand(_ command: String) -> String? {
        let task = Process()
        let pipe = Pipe()
        
        task.launchPath = "/bin/zsh"
        task.arguments = ["-c", command]
        task.standardOutput = pipe
        task.standardError = pipe
        
        task.launch()
        
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        task.waitUntilExit()
        
        let output = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines)
        
        print("Salida del comando: \(output ?? "")")
        
        return output
    }
}

struct Config: Codable {
    let username: String
    let email: String
}
