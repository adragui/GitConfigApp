import SwiftUI

struct SSHKeysListView: View {
    @ObservedObject var viewModel: SSHKeysListViewModel
    
    var body: some View {
        ZStack {
            // Fondo principal de toda la vista
            Color(NSColor.windowBackgroundColor)
                .edgesIgnoringSafeArea(.all)  // Asegura que cubra toda el área
            
            VStack(alignment: .leading, spacing: 20) {
                Text("Llaves SSH Generadas")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .padding(.horizontal, 20)
                
                ScrollView {
                    VStack(spacing: 15) {
                        ForEach(viewModel.sshKeys, id: \.self) { key in
                            SSHKeyRowView(
                                key: key,
                                isConnectionSuccessful: viewModel.connectionStatus[key],
                                onTestConnection: {
                                    viewModel.testConnection(for: key)
                                },
                                onDeleteKey: {
                                    viewModel.deleteSSHKey(named: key)
                                }
                            )
                            .padding(.horizontal, 20)
                        }
                    }
                    .padding(.vertical)
                }
                .onAppear {
                    viewModel.loadSSHKeys()
                }
            }
            .padding()
        }
    }
}
