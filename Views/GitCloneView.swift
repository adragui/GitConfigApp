import SwiftUI

struct GitCloneView: View {
    @ObservedObject var sshKeysListViewModel: SSHKeysListViewModel
    @StateObject private var viewModel: GitCloneViewModel

    init(sshKeysListViewModel: SSHKeysListViewModel) {
        self.sshKeysListViewModel = sshKeysListViewModel
        _viewModel = StateObject(wrappedValue: GitCloneViewModel(sshKeysListViewModel: sshKeysListViewModel))
    }

    var body: some View {
        VStack {
            Text("Clonar Repositorio")
                .font(.system(size: 30, weight: .bold, design: .rounded))
                .padding(.bottom, 20)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 30)
            
            ScrollView {
                VStack(spacing: 25) {
                    GroupBox(label: Label("Información del Repositorio", systemImage: "link")) {
                        VStack(spacing: 15) {
                            TextField("URL del repositorio", text: $viewModel.repoURL)
                                .padding()
                                .background(Color(NSColor.windowBackgroundColor).opacity(0.2))
                                .cornerRadius(12)
                            
                            Picker("Selecciona la cuenta", selection: $viewModel.selectedAccount) {
                                ForEach(viewModel.sshKeys, id: \.self) { key in
                                    Text(key).tag(key)
                                }
                            }
                            .pickerStyle(MenuPickerStyle())
                            .padding()
                            .background(Color(NSColor.windowBackgroundColor).opacity(0.2))
                            .cornerRadius(12)
                        }
                        .padding()
                    }
                    .background(Color.white)
                    .cornerRadius(15)
                    .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
                    .padding(.horizontal, 20)

                    GroupBox(label: Label("Configuración de Git", systemImage: "person.fill")) {
                        VStack(spacing: 15) {
                            TextField("user.name (opcional)", text: $viewModel.userNameOverride)
                                .padding()
                                .background(Color(NSColor.windowBackgroundColor).opacity(0.2))
                                .cornerRadius(12)
                            
                            TextField("user.email (opcional)", text: $viewModel.userEmailOverride)
                                .padding()
                                .background(Color(NSColor.windowBackgroundColor).opacity(0.2))
                                .cornerRadius(12)
                        }
                        .padding()
                    }
                    .background(Color.white)
                    .cornerRadius(15)
                    .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
                    .padding(.horizontal, 20)

                    Button(action: {
                        viewModel.testConnection()
                    }) {
                        Text("Probar Conexión")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.blue)
                            .cornerRadius(12)
                            .shadow(color: Color.blue.opacity(0.3), radius: 8, x: 0, y: 4)
                    }
                    .padding(.horizontal, 20)

                    if let isConnectionSuccessful = viewModel.isConnectionSuccessful {
                        Image(systemName: isConnectionSuccessful ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .foregroundColor(isConnectionSuccessful ? .green : .red)
                            .font(.largeTitle)
                            .padding(.top, 5)
                    }

                    Text(viewModel.connectionStatus)
                        .foregroundColor(.red)
                        .font(.subheadline)
                        .padding(.top, 5)

                    Button(action: {
                        let panel = NSOpenPanel()
                        panel.canChooseDirectories = true
                        panel.canCreateDirectories = true
                        panel.allowsMultipleSelection = false
                        panel.begin { response in
                            if response == .OK, let url = panel.urls.first {
                                viewModel.cloneRepository(to: url)
                            }
                        }
                    }) {
                        Text("Clonar Repositorio")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(LinearGradient(gradient: Gradient(colors: [Color.green, Color.blue]), startPoint: .leading, endPoint: .trailing))
                            .cornerRadius(12)
                            .shadow(color: Color.green.opacity(0.3), radius: 8, x: 0, y: 4)
                    }
                    .padding(.horizontal, 20)
                }
                .padding(.vertical)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(NSColor.windowBackgroundColor).edgesIgnoringSafeArea(.all))
        }
    }
}
