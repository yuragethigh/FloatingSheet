//
//  ScrollViewWrapper.swift
//  FloatingSheet
//
//  Created by Yuriy on 26.07.2024.
//

import SwiftUI
import SnapKit

public struct ScrollViewWrapper<Content: View>: UIViewRepresentable {
    
    private let thresholds: [CGFloat]
    private let proxy: GeometryProxy
    @Binding var currentIndex: Int
    @Binding var contentOffset: CGFloat
    @Binding var updateContent: Bool
    @Binding var headerRect: CGRect
    
    let content: () -> Content
    
    init(
        thresholds: [CGFloat],
        proxy: GeometryProxy,
        currentIndex: Binding<Int>,
        contentOffset: Binding<CGFloat>,
        updateContent: Binding<Bool>,
        headerRect: Binding<CGRect>,
        @ViewBuilder _ content: @escaping () -> Content
    ) {
        self.thresholds = thresholds
        self.proxy = proxy
        self._currentIndex = currentIndex
        self._contentOffset = contentOffset
        self._updateContent = updateContent
        self._headerRect = headerRect
        self.content = content
    }
    
    public func makeUIView(context: UIViewRepresentableContext<ScrollViewWrapper>) -> UIScrollView {
        let sv = UIScrollView()
        sv.backgroundColor = .clear
        sv.alwaysBounceVertical = true
        sv.showsVerticalScrollIndicator = false
        sv.delegate = context.coordinator
        
        layoutContent(sv)

        return sv
    }

    public func updateUIView(_ sv: UIScrollView, context: UIViewRepresentableContext<ScrollViewWrapper>) {
        if updateContent {
            layoutContent(sv)
            updateContent = false
        }
    }
    
    private func layoutContent(_ sv: UIScrollView) {
        let controller = UIHostingController(rootView: content())
        controller.view.backgroundColor = .clear
        
        sv.addSubview(controller.view)
        controller.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            controller.view.leadingAnchor.constraint(equalTo: sv.leadingAnchor),
            controller.view.trailingAnchor.constraint(equalTo: sv.trailingAnchor),
            controller.view.topAnchor.constraint(equalTo: sv.topAnchor, constant: headerRect.height),
            controller.view.bottomAnchor.constraint(equalTo: sv.bottomAnchor),
            controller.view.widthAnchor.constraint(equalTo: sv.widthAnchor)
        ])
    }
    
    public func makeCoordinator() -> Coordinator {
        Coordinator(
            thresholds: thresholds,
            proxy: proxy,
            currentIndex: $currentIndex,
            contentOffset: $contentOffset
        )
    }
    
    public final class Coordinator: NSObject, UIScrollViewDelegate {
        var height: CGFloat = 0.0
        let thresholds: [CGFloat]
        let proxy: GeometryProxy
        @Binding var currentIndex: Int
        @Binding var contentOffset: CGFloat
        
        init(
            thresholds: [CGFloat],
            proxy: GeometryProxy,
            currentIndex: Binding<Int>,
            contentOffset: Binding<CGFloat>
        ){
            self.thresholds = thresholds
            self.proxy = proxy
            self._currentIndex = currentIndex
            self._contentOffset = contentOffset
        }
        
        private enum DragState {
            case drag, scroll, bounce
        }
        
        private var dragState: DragState = .drag
        private var decelerate: Bool = true
        
        
        public func scrollViewDidScroll(_ scrollView: UIScrollView) {
            let yOffset = scrollView.contentOffset.y
            
            guard let viewHeight = thresholds.last else { return }
            let getSizeY = thresholds[currentIndex] + contentOffset

            switch dragState {
            case .drag:
                
                if getSizeY >= viewHeight {
                    currentIndex = thresholds.count - 1
                    contentOffset = 0
                    dragState = .scroll
                    scrollView.setContentOffset(CGPoint.zero, animated: false)
                   
                } else {
                    contentOffset += yOffset
                    scrollView.contentOffset.y = 0
                }
                
            case .scroll:
                
                if yOffset < 0 {
                    contentOffset += yOffset
                    dragState = .drag
                    scrollView.contentOffset.y = 0
                } else if decelerate {
                    dragState = .bounce
                }
                
            case .bounce:
                decelerate = false
                if yOffset == 0 {
                    self.dragState = .scroll
                }
            }
            
        }
        
        private func switchSize(_ scrollView: UIScrollView) {
            let currentY = thresholds[currentIndex] + contentOffset
            
            let nearestIndex = thresholds.enumerated().min(by: { abs($0.element - currentY) < abs($1.element - currentY) })?.offset ?? currentIndex
            
            contentOffset = 0
            currentIndex = nearestIndex
        }
        
        public func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
            switchSize(scrollView)
            if dragState != .bounce {
                self.decelerate = decelerate
            }
        }
        
        public func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
            
            let thresholdVelocity = 1.3
            
            guard dragState == .drag else {
                return
            }
            
            if currentIndex != thresholds.count - 1 {
                targetContentOffset.pointee.y = 0
            }
            
            if velocity.y > thresholdVelocity {
                currentIndex += 1
            } else if velocity.y < -thresholdVelocity {
                currentIndex -= 1
            }
        }
    }
}

#Preview{
    MainView()
}

