//
//  BottomSheetVM.swift
//  FloatingSheet
//
//  Created by Yuriy on 26.07.2024.
//

import SwiftUI

final class BottomSheetVM: ObservableObject {
    
    @Published var initialState: Size = .small
    @Published var contentOffset: CGFloat = .zero
    
    func getSizeY() -> CGFloat {
        
        return initialState.sizeY + contentOffset
    }
    
    enum Size {
        case small, middle, large
        
        var sizeY: CGFloat {
            switch self {
            case .small:
                150
            case .middle:
                (UIScreen.main.bounds.height * 0.6) - UIScreen.topSafeArea
            case .large:
                UIScreen.main.bounds.height - UIScreen.topSafeArea
            }
        }
    }
}
