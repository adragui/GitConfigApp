import SwiftUI

struct SSHKeyGeneratorView: View {
    @ObservedObject var viewModel: SSHKeyGeneratorViewModel
    
    var body: some View {
        VStack {
            Text("Generar Nueva Llave SSH")
                .font(.system(size: 30, weight: .bold, design: .rounded))
                .padding(.bottom, 20)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 30)
            
            ScrollView {
                VStack(spacing: 25) {
                    GroupBox(label: Label("Información de la Llave", systemImage: "person.fill")) {
                        VStack(spacing: 15) {
                            TextField("Nombre de usuario", text: $viewModel.username)
                                .padding()
                                .background(Color(NSColor.windowBackgroundColor).opacity(0.2))
                                .cornerRadius(12)
                            
                            TextField("Correo electrónico", text: $viewModel.email)
                                .padding()
                                .background(Color(NSColor.windowBackgroundColor).opacity(0.2))
                                .cornerRadius(12)
                            
                            TextField("Etiqueta para la llave (opcional)", text: $viewModel.tag)
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

                    GroupBox(label: Label("Configuración de la Llave", systemImage: "lock.shield.fill")) {
                        VStack(spacing: 15) {
                            Picker("Tipo de seguridad", selection: $viewModel.keyType) {
                                ForEach(viewModel.keyTypes, id: \.self) { type in
                                    Text(type).tag(type)
                                }
                            }
                            .pickerStyle(SegmentedPickerStyle())
                            .padding(.horizontal)

                            Picker("Servicio", selection: $viewModel.service) {
                                ForEach(viewModel.services, id: \.self) { service in
                                    Text(service).tag(service)
                                }
                            }
                            .pickerStyle(MenuPickerStyle())
                            .padding(.horizontal)
                        }
                        .padding()
                    }
                    .background(Color.white)
                    .cornerRadius(15)
                    .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
                    .padding(.horizontal, 20)
                    
                    Button(action: {
                        viewModel.generateSSHKey()
                    }) {
                        Text("Generar Llave")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(LinearGradient(gradient: Gradient(colors: [Color.green, Color.blue]), startPoint: .leading, endPoint: .trailing))
                            .cornerRadius(12)
                            .shadow(color: Color.green.opacity(0.3), radius: 8, x: 0, y: 4)
                    }
                    .padding(.horizontal, 20)

                    if !viewModel.generatedKey.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Llave generada con éxito:")
                                .font(.headline)
                                .padding(.top)
                            Text(viewModel.generatedKey)
                                .font(.system(.body, design: .monospaced))
                                .padding()
                                .background(Color(NSColor.windowBackgroundColor).opacity(0.2))
                                .cornerRadius(12)
                                .padding(.horizontal, 20)
                            
                            Button(action: {
                                viewModel.copyToClipboard()
                            }) {
                                Text("Copiar al Portapapeles")
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.orange)
                                    .foregroundColor(.white)
                                    .cornerRadius(12)
                                    .shadow(color: Color.orange.opacity(0.3), radius: 8, x: 0, y: 4)
                            }
                            .padding(.horizontal, 20)
                        }
                        .padding(.top, 20)
                    }
                }
                .padding(.vertical)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(NSColor.windowBackgroundColor).edgesIgnoringSafeArea(.all))
        }
    }
}
