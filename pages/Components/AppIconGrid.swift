import SwiftUI

struct AppIconGrid: View {
    let options: [IconButtonOption]
    let columns: [GridItem]
    
    init(options: [IconButtonOption], columnsCount: Int = 4) {
        self.options = options
        self.columns = Array(repeating: GridItem(.flexible(), spacing: 16), count: columnsCount)
    }
    
    var body: some View {
        LazyVGrid(columns: columns, spacing: 24 ){
            ForEach(options) { option in
                Button {
                    option.action()
                } label: {
                    VStack(spacing: 8,){
                            if let imageName = option.imageName {
                                Image(imageName).resizable().scaledToFit().frame(width: 60,height: 60)
                                    .clipShape(Circle())
                            }
                        Text(option.title).font(.system(size: 12,weight: .medium)).foregroundColor(.primary)
                            .lineLimit(2)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: 80)
                    }
                }
            }.buttonStyle(PlainButtonStyle())
        }
    }
}


#Preview {
    AppIconGrid(options:      (0..<6).map  { index in
        IconButtonOption(
           title: "YouTube",
           color: .red,
           imageName: "youtube-logo",
           action: {
               print("YouTube \(index) selected")
           },
           searchEngine: .youtube
        )
    }
    )
        
}
