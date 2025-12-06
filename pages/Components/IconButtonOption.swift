import SwiftUI

struct IconButtonOption: Identifiable , Equatable ,Hashable{
    let id = UUID()
    let title: String
    let color: Color?
    let imageName: String?
    let action: () -> Void
    
    static func == (lhs: IconButtonOption, rhs: IconButtonOption) -> Bool {
          return lhs.id == rhs.id &&
                 lhs.title == rhs.title &&
                 lhs.color == rhs.color &&
                 lhs.imageName == rhs.imageName
          // Note: action closure is not compared
      }
    func hash(into hasher: inout Hasher) {
         hasher.combine(id)
         hasher.combine(title)
         hasher.combine(color)
         hasher.combine(imageName)
         // Note: action closure is not hashed
     }
}
