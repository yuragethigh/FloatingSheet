//
//  ContentViewSheet.swift
//  FloatingSheet
//
//  Created by Yuriy on 26.07.2024.
//

import SwiftUI

extension View {
    func readFrame(_ binding: Binding<CGRect>)-> some View {
        background(GeometryReader { g in
            Color.clear
                .preference(key: FramePreferenceKey.self, value: g.frame(in: .global))
                .onPreferenceChange(FramePreferenceKey.self) { frame in
                    DispatchQueue.main.async {
                        binding.wrappedValue = frame

                    }
                }
        })
    }
}

private struct FramePreferenceKey: PreferenceKey {
    static var defaultValue = CGRect.zero
    
    static func reduce(value: inout CGRect, nextValue: () -> CGRect) {
        value = nextValue()
    }
}


struct ScrollViewModifier<ScrollContent: View, HeaderContent: View>: ViewModifier {
    @State private var contentOffset: CGFloat = .zero
    @State private var headerRect: CGRect = .zero
    @Binding var currentState: Int
    @Binding var updateContent: Bool
    let thresholds: [CGFloat]
    let backgroundColor: Color
    let cornerRadius: CGFloat
    let scrollContent: ScrollContent
    let headerContent: HeaderContent
    
    init(
        currentState: Binding<Int>,
        updateContent: Binding<Bool>,
        thresholds: [CGFloat],
        backgroundColor: Color,
        cornerRadius: CGFloat,
        @ViewBuilder scrollContent: () -> ScrollContent,
        @ViewBuilder headerContent: () -> HeaderContent
    ) {
        self._currentState = currentState
        self._updateContent = updateContent
        self.thresholds = thresholds
        self.backgroundColor = backgroundColor
        self.cornerRadius = cornerRadius
        self.scrollContent = scrollContent()
        self.headerContent = headerContent()
    }
    
    func body(content: Content) -> some View {
        
        ZStack(alignment: .bottom) {
            
            content
            
            GeometryReader { proxy in
                
                ScrollViewWrapper(
                    thresholds: thresholds,
                    proxy: proxy,
                    currentIndex: $currentState,
                    contentOffset: $contentOffset,
                    updateContent: $updateContent,
                    headerRect: $headerRect
                ) {
                    scrollContent
                }
                
                .frame(
                    height: thresholds[currentState] + contentOffset
                )
                .background(
                    backgroundColor
                )
                .overlay(
                    headerContent
                        .readFrame($headerRect)
                        .allowsHitTesting(false)
                    ,alignment: .top
                )
                .cornerRadius(
                    cornerRadius,
                    corners: [.topLeft, .topRight]
                )
                .animation(
                    .spring(duration: 0.25, bounce: 0.25),
                    value: contentOffset
                )
                .animation(
                    .spring(duration: 0.25, bounce: 0.25),
                    value: currentState
                )
                .frame(
                    maxHeight: .infinity,
                    alignment: .bottom
                )
            }
        }
        
    }
}

extension View {
    func scrollViewWrapper<ScrollContent: View, HeaderContent: View>(
        currentState: Binding<Int>,
        updateContent: Binding<Bool>,
        thresholds: [CGFloat],
        backgroundColor: Color,
        cornerRadius: CGFloat,
        @ViewBuilder scrollContent: @escaping () -> ScrollContent,
        @ViewBuilder headerContent: @escaping () -> HeaderContent
    ) -> some View {
        self.modifier(
            ScrollViewModifier(
                currentState: currentState,
                updateContent: updateContent,
                thresholds: thresholds,
                backgroundColor: backgroundColor,
                cornerRadius: cornerRadius,
                scrollContent: scrollContent,
                headerContent: headerContent
            )
        )
    }
}




struct MainView: View {
    @Environment(\.safeAreaInsets) private var safeAreaInsets
    @State private var currentState: Int = 0
    @State private var contentOffset: CGFloat = .zero
    @State private var show = false
    
    var body: some View {
        VStack {
            TabView {
                Color.red
                    .scrollViewWrapper(
                        currentState: $currentState,
                        updateContent: $show,
                        thresholds: [
                            150,
                            400,
                            750
                        ],
                        backgroundColor: .blue.opacity(0.4),
                        cornerRadius: 25
                    ) {
                        if show {
                            LazyVStack {
                                ForEach(1...300, id: \.self) { y in
                                    Rectangle()
                                        .fill(.gray)
                                        .padding()
                                        .overlay(
                                            Text("\(y)")
                                        )
                                }
                            }
                        }
                        
                    } headerContent: {
                        Capsule()
                            .fill(.white)
                            .frame(width: 40, height: 5)
                            .padding(.vertical, 10)
                            .frame(maxWidth: .infinity)
                            .background(Color.black)
                           
                    }
                
                Color.pink
            }
            .onAppear{
                print(safeAreaInsets.bottom)

                DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                    show = true
                }
            }
        }
    }
}

#Preview {
    MainView()
}


