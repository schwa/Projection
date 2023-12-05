import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationView {
            List {
                NavigationLink("(Bare) SoftwareRendererView") {
                    SoftwareRendererView() { _, _, _ in
                    }
                }
                NavigationLink("BoxesView") {
                    BoxesView()
                }
                NavigationLink("MeshView") {
                    MeshView()
                }
                NavigationLink("ExtrusionView") {
                    ExtrusionView()
                }
                NavigationLink("RevolveView") {
                    RevolveView()
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
