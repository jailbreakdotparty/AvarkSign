import SwiftUI

struct LogView: View {
    var body: some View {
        GeometryReader { geometry in
            ScrollViewReader { proxy in
                ScrollView(showsIndicators: false) {
                    Text(appLogs)
                        .font(.system(size: 10, weight: .regular, design: .monospaced))
                        .multilineTextAlignment(.leading)
                    Spacer()
                        .id(0)
                }
                .onAppear {
                    DispatchQueue.main.async {
                        proxy.scrollTo(0)
                    }
                    // Redirect
                    // print("Redirecting stdout")
//                    setvbuf(stdout, nil, _IONBF, 0)
//                    dup2(pipe.fileHandleForWriting.fileDescriptor, STDOUT_FILENO)
                }
                .contextMenu {
                    Button {
                        UIPasteboard.general.string = appLogs
                    } label: {
                        Label("Copy Output", systemImage: "doc.on.doc")
                    }
                }
            }
        }
    }
}

struct LogSheetView: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            VStack {
                List {
                    LogView()
                        .frame(maxWidth: .infinity)
                        .frame(height: 500)
                }
            }
            .navigationTitle("Logs")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing, content: {
                    Button(action: {
                        dismiss()
                    }, label: {
                        AvarkCloseButton()
                    })
                })
            }
        }
    }
}
