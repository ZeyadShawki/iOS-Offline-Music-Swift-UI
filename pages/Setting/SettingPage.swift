//
//  aboutme
//
//  Created by zeyad Shawki on 06/12/2025.
//

import Foundation
import SwiftUI

struct SettingPage : View {
    @EnvironmentObject var appRouter: AppRouter

    var body: some View {
        NavigationStack(path: $appRouter.settingsPath) {
            VStack {
                Text("hello")
            }
            .navigationDestination(for: SettingsRoute.self) { route in
                switch route {
                default:
                    EmptyView()
                }
            }
        }
    }
}
