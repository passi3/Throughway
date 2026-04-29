//
//  LoginView.swift
//  Throughway
//
//  Created by passi on 4/26/26.
//

import SwiftUI

struct LoginView: View {
    
    enum LoginField {
        case email, password
    }
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: 36)
            
        }
    }
}

private extension LoginView {
    
    var headerSection: some View {
        VStack(spacing: 8) {
            Text("Throughway")
                .font(.Paperlogy.title1)
                .fontWeight(.bold)
                .foregroundStyle(Color.blackSeafoam)
        }
    }
}

#Preview {
    LoginView()
}
