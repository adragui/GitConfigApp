import Foundation
import SwiftUI

class GitCloneViewModel: ObservableObject {
    @Published var repoURL: String = ""
    @Published var sshKeys: [String] = []
    @Published var selectedAccount: String = ""
    @Published var userNameOverride: String = ""  // Campo opcional para un user.name personalizado
    @Published var userEmailOverride: String = ""  // Campo opcional para un user.email personalizado
    @Published var connectionStatus: String = ""
    @Published var isConnectionSuccessful: Bool? = nil  // nil indica que aún no se ha probado
    
    // Referencia a SSHKeysListViewModel para acceder a `user.name` y `user.email` guardados
    private var sshKeysListViewModel: SSHKeysListViewModel
    
    init(sshKeysListViewModel: SSHKeysListViewModel) {
        self.sshKeysListViewModel = sshKeysListViewModel
        loadSSHKeys()  // Carga las llaves SSH al inicializar el modelo
    }
    
    func loadSSHKeys() {
        let sshDirectory = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(".ssh")
        
        do {
            let files = try FileManager.default.contentsOfDirectory(atPath: sshDirectory.path)
            sshKeys = files.filter { $0.hasSuffix(".pub") }.map { String($0.dropLast(4)) }
            print("SSH Keys Loaded: \(sshKeys)")  // Verificar que las llaves se cargan correctamente
        } catch {
            print("Error al cargar llaves SSH: \(error.localizedDescription)")
        }
    }
    
    func testConnection() {
        guard !selectedAccount.isEmpty else {
            connectionStatus = "Selecciona una cuenta."
            isConnectionSuccessful = false
            return
        }
        
        let sshDirectory = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(".ssh")
        let privateKeyPath = sshDirectory.appendingPathComponent(selectedAccount)
        
        // Determina el host del servicio basado en la URL (ej: github.com)
        guard let host = extractHost(from: repoURL) else {
            connectionStatus = "URL de repositorio no válida."
            isConnectionSuccessful = false
            return
        }
        
        let command = "ssh -o StrictHostKeyChecking=no -i \(privateKeyPath.path) -T git@\(host)"
        
        print("Ejecutando comando SSH para probar conexión: \(command)")
        
        let success = executeShellCommand(command)
        
        DispatchQueue.main.async {
            self.isConnectionSuccessful = success
            self.connectionStatus = success ? "Conexión exitosa con \(host)." : "Error de conexión con \(host). Verifica la llave SSH."
        }
    }
    
    func cloneRepository(to directory: URL) {
        guard !repoURL.isEmpty, !selectedAccount.isEmpty else {
            print("URL del repositorio o cuenta no seleccionada.")
            return
        }
        
        // Extraer el nombre del repositorio de la URL
        guard let repoName = URL(string: repoURL)?.lastPathComponent.replacingOccurrences(of: ".git", with: "") else {
            print("No se pudo extraer el nombre del repositorio.")
            return
        }
        
        let targetDirectory = directory.appendingPathComponent(repoName)
        
        let sshDirectory = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(".ssh")
        let privateKeyPath = sshDirectory.appendingPathComponent(selectedAccount)
        
        let command = "GIT_SSH_COMMAND='ssh -i \(privateKeyPath.path)' git clone \(repoURL) \(targetDirectory.path)"
        
        let success = executeShellCommand(command)
        
        DispatchQueue.main.async {
            if success {
                self.connectionStatus = "Clonación exitosa en \(targetDirectory.path)."
                print("Clonación exitosa en \(targetDirectory.path).")
                
                // Configurar `user.name` y `user.email` en el repositorio clonado
                self.setLocalGitConfig(for: targetDirectory)
            } else {
                self.connectionStatus = "Error al clonar el repositorio. Verifica la URL y la llave SSH."
                print("Error al clonar el repositorio.")
            }
        }
    }
    
    private func setLocalGitConfig(for directory: URL) {
        // Verificar si se proporcionaron valores personalizados o si se deben usar los valores por defecto
        let username = userNameOverride.isEmpty ? (sshKeysListViewModel.usernames[selectedAccount] ?? "") : userNameOverride
        let email = userEmailOverride.isEmpty ? (sshKeysListViewModel.emails[selectedAccount] ?? "") : userEmailOverride
        
        guard !username.isEmpty, !email.isEmpty else {
            print("Nombre de usuario o correo electrónico no definido para la llave \(selectedAccount).")
            return
        }
        
        // Comando para establecer user.name a nivel de repositorio
        let setNameCommand = "cd \(directory.path) && git config user.name '\(username)'"
        let nameSuccess = executeShellCommand(setNameCommand)
        print("Ejecutando comando: \(setNameCommand)")
        
        // Comando para establecer user.email a nivel de repositorio
        let setEmailCommand = "cd \(directory.path) && git config user.email '\(email)'"
        let emailSuccess = executeShellCommand(setEmailCommand)
        print("Ejecutando comando: \(setEmailCommand)")
        
        if nameSuccess && emailSuccess {
            print("Configuración de Git para user.name y user.email aplicada localmente en \(directory.path)")
        } else {
            print("Error al aplicar la configuración de Git local en \(directory.path)")
        }
    }
    
    private func extractHost(from url: String) -> String? {
        if let range = url.range(of: "git@"), let endRange = url.range(of: ":") {
            return String(url[range.upperBound..<endRange.lowerBound])
        }
        return nil
    }
    
    private func executeShellCommand(_ command: String) -> Bool {
        let task = Process()
        let pipe = Pipe()
        
        task.launchPath = "/bin/zsh"
        task.arguments = ["-c", command]
        task.standardOutput = pipe
        task.standardError = pipe
        
        task.launch()
        
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        task.waitUntilExit()
        
        let output = String(data: data, encoding: .utf8) ?? ""
        
        print("Salida del comando SSH: \(output)")
        
        // Detecta el mensaje de autenticación exitosa
        if output.contains("successfully authenticated") {
            print("Autenticación SSH exitosa detectada en la salida.")
            return true
        } else {
            return task.terminationStatus == 0
        }
    }
}
