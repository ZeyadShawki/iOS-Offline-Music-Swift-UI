import SwiftUI

struct ReusableTextField: View {
    @Binding var text: String
    var placeHolder: String
    var title: String? = nil
    var isSecure: Bool = false
    var keyboardType: UIKeyboardType = .default
    var buttonOptions: [IconButtonOption]? = []
    @State private var selectedOption: IconButtonOption? = nil
   
    init(text:  Binding<String>, placeHolder: String, title: String? = nil, isSecure: Bool = false, keyboardType: UIKeyboardType = .default, buttonOptions: [IconButtonOption]? = nil, selectedOption: IconButtonOption? = nil) {
        self._text = text
        self.placeHolder = placeHolder
        self.title = title
        self.isSecure = isSecure
        self.keyboardType = keyboardType
        self.buttonOptions = buttonOptions
        self.selectedOption = buttonOptions?.first ?? selectedOption
    }
    
    var body : some View {
        VStack(alignment: .leading,spacing: 8) {
            if let title = title {
                Text(title).font(.caption).foregroundColor(.gray)
            }
            
            HStack {
                if buttonOptions != nil && !buttonOptions!.isEmpty {
                    Menu {
                        ForEach(buttonOptions!) { option in
                            Button {
                                selectedOption = option
                                option.action()
                            } label: {
                                HStack {
                                    if let imageName = option.imageName {
                                        Image(imageName).resizable().scaledToFit().frame(width: 20,height: 20)
                                    }
                                    Text(option.title)
                                        .foregroundColor(option.color ?? .primary)
                                }
                            }
                        }
                    } label: {
                        pickerLabel
                    }
                    .frame(width: 50, height: 30)
                    .padding(.leading, 8).onAppear {
                        if selectedOption == nil {
                            selectedOption = buttonOptions?.first
                        }
                    }
                }
                
                if isSecure {
                    SecureField(placeHolder,text: $text).keyboardType(keyboardType)
                }else{
                    TextField(placeHolder,text: $text).keyboardType(keyboardType)
                }
                
            }
            .padding().background(Color(.systemGray6).cornerRadius(30)).overlay(
                RoundedRectangle(cornerRadius: 30).stroke(Color(.gray),lineWidth: 1)
            )
            
        }
    }
    
    @ViewBuilder
    private var pickerLabel: some View {
        HStack(spacing: 4) {
            if let imageName = selectedOption?.imageName {
                Image(imageName)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: 20, maxHeight: 20)
            }
            Image(systemName: "chevron.down")
                .foregroundColor(.secondary)
                .font(.system(size: 10))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
    
#Preview {
ReusableTextField(
    text: .constant(""),
    placeHolder: "Search or enter web address",
    title: nil,
    buttonOptions: [
        IconButtonOption(
            title: "YouTube",
            color: .red,
            imageName: "youtube-logo", // Your asset image name
            action: {
                print("YouTube option selected")
            }
        ),
        IconButtonOption(
            title: "Google",
            color: nil,
            imageName: "google-logo",
            action: {
                print("Google option selected")
            }
        )
    ]
)
}
