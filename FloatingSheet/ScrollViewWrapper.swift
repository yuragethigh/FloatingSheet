//
//  ScrollViewWrapper.swift
//  FloatingSheet
//
//  Created by Yuriy on 26.07.2024.
//

import SwiftUI
import SnapKit

public struct ScrollViewWrapper<Content: View>: UIViewRepresentable {
    
    @Binding var contentOffset: CGPoint
    @ObservedObject var vm: BottomSheetVM
    
    let content: () -> Content
    
     init(
        contentOffset: Binding<CGPoint>,
        vm: BottomSheetVM,
        @ViewBuilder _ content: @escaping () -> Content
    ) {
        self._contentOffset = contentOffset
        self.vm = vm
        self.content = content
    }
    
    public func makeUIView(context: UIViewRepresentableContext<ScrollViewWrapper>) -> UIScrollView {
        let sv = UIScrollView()
        sv.backgroundColor = .clear
        sv.delegate = context.coordinator
        let controller = UIHostingController(rootView: content())
        controller.view.backgroundColor = .clear
        sv.addSubview(controller.view)

        controller.view.snp.makeConstraints {
            $0.bottom.leading.top.trailing.equalToSuperview()
            $0.width.equalToSuperview()
            
        }

        return sv
    }

    public func updateUIView(_ uiView: UIScrollView, context: UIViewRepresentableContext<ScrollViewWrapper>) {

    }


    
    public func makeCoordinator() -> Coordinator {
        Coordinator(contentOffset: self._contentOffset, vm: vm)
    }
    
    public class Coordinator: NSObject, UIScrollViewDelegate {
        
        let contentOffset: Binding<CGPoint>
        var vm: BottomSheetVM
        
        init(
            contentOffset: Binding<CGPoint>,
            vm: BottomSheetVM
        ){
            self.contentOffset = contentOffset
            self.vm = vm
        }
        
        private enum DragState {
            case drag, scroll, bounce
        }
        
        private var dragState: DragState = .drag
        private var decelerate: Bool = true
        
        
        public func scrollViewDidScroll(_ scrollView: UIScrollView) {
            let yOffset = scrollView.contentOffset.y
            
            let viewHeight = UIScreen.main.bounds.height - UIScreen.topSafeArea
            
//            print("# viewHeight     - ", viewHeight)
//            print("# getsize Y      - ", vm.getSizeY())
//            print("# State          - ", vm.initialState)
//            print("# dragState      - ", dragState)
//            print("# decelerate     - ", decelerate)
            switch dragState {
            case .drag:
                
                if vm.getSizeY() >= viewHeight {
                    vm.initialState = .large
                    vm.contentOffset = 0
                    dragState = .scroll
                    scrollView.setContentOffset(CGPoint.zero, animated: false)
                } else {
                    vm.contentOffset += yOffset
                    scrollView.contentOffset.y = 0
                   
                }
                
            case .scroll:
                
                if yOffset < 0 {
                    vm.contentOffset += yOffset
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
            let height = UIScreen.main.bounds.height - UIScreen.topSafeArea
            let currentY = vm.getSizeY()
            print(vm.initialState)
            
            if currentY <= height * 0.35 {
                vm.contentOffset = 0
                vm.initialState = .small
                
            } else if currentY <= height * 0.8 {
                vm.contentOffset = 0
                vm.initialState = .middle
            } else {
                vm.contentOffset = 0
                vm.initialState = .large
            }
        }
        
        public func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
            switchSize(scrollView)
            if dragState != .bounce {
                self.decelerate = decelerate
                
            }
        }
        
        public func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
            print(velocity)
            let thresholdVelocity = 1.3
            
            guard dragState == .drag else { return }
            
            if vm.initialState != .large {
                targetContentOffset.pointee.y = 0
            }
            
            if velocity.y > thresholdVelocity {
                print(velocity)
                if vm.initialState == .small {
                    vm.initialState = .middle
                } else if vm.initialState == .middle {
                    vm.initialState = .large
                }
            } else if velocity.y < -thresholdVelocity {
                print(velocity)
                if vm.initialState == .large {
                    vm.initialState = .middle
                } else if vm.initialState == .middle {
                    vm.initialState = .small
                }
            }
            
        }
    }
}

#Preview{
    ContentViewSheet()
}

