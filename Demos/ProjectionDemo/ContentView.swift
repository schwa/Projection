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
                NavigationLink("TeapotView") {
                    TeapotView()
                }
                NavigationLink("ExtrusionView") {
                    ExtrusionView()
                }
            }
        }
        
        
    }
}

#Preview {
    ContentView()
}