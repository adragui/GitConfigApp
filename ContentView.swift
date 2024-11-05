import SwiftUI

struct ContentView: View {
    // Inicializa cada ViewModel necesario para cada vista
    @StateObject private var sshKeyGeneratorViewModel = SSHKeyGeneratorViewModel()
    @StateObject private var sshKeysListViewModel = SSHKeysListViewModel()

    var body: some View {
        TabView {
            SSHKeyGeneratorView(viewModel: sshKeyGeneratorViewModel)
                .tabItem {
                    Label("Generar Llave", systemImage: "key.fill")
                }
            
            GitCloneView(sshKeysListViewModel: sshKeysListViewModel)
                .tabItem {
                    Label("Clonar Repo", systemImage: "arrow.down.circle.fill")
                }
            
            SSHKeysListView(viewModel: sshKeysListViewModel)
                .tabItem {
                    Label("Mis Llaves", systemImage: "list.bullet")
                }
        }
        .accentColor(.blue) // Color de acento para las pestañas seleccionadas
    }
}
