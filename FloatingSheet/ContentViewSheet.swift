//
//  ContentViewSheet.swift
//  FloatingSheet
//
//  Created by Yuriy on 26.07.2024.
//

import SwiftUI

struct ContentViewSheet: View {
    @State private var contentOffset: CGPoint = .zero
    @StateObject private var vm = BottomSheetVM()
    
    var body: some View {
        
        GeometryReader {
            let safeAreaB = $0.safeAreaInsets.bottom
            
            
            ZStack(alignment: .bottom) {
                Color.purple
                
                    
                ScrollViewWrapper(
                    contentOffset: $contentOffset,
                    vm: vm
                ) {
                    Content()
                }
                .frame(height: vm.getSizeY() + safeAreaB)
                .background(Color.blue)
                .cornerRadius(20)
                .animation(.spring(duration: 0.2), value: vm.getSizeY())
            }
        }
        .ignoresSafeArea(edges: .bottom)
    }
    
    
    @ViewBuilder
    private func Content() -> some View {
        LazyVStack {
            ForEach(1...100, id: \.self) { _ in
                Rectangle()
                    .padding()
            }
        }
    }
}

#Preview {
    ContentViewSheet()
}
