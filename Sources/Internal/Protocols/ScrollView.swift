//
//  ScrollView.swift
//  MijickPopupView
//
//  Created by 大江山岚 on 2025/2/18.
//

import UIKit

@MainActor public protocol MijickScrollViewGesture: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView)
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool)
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView)
}

open class MijickScrollViewGestureImpl: NSObject, MijickScrollViewGesture {
    
    open func scrollViewDidScroll(_ scrollView: UIScrollView) {
        PopupManager.shared.scrollViewOffset = scrollView.contentOffset
        print("scrollView.contentOffset: \(scrollView.contentOffset)")
        if scrollView.contentOffset.y < 0 || scrollView.contentOffset.x < 0 {
            scrollView.setContentOffset(.zero, animated: false)
        }
        if scrollView.contentOffset.y <= 0 || scrollView.contentOffset.x <= 0 {
            if PopupManager.shared.enable != true {
                PopupManager.shared.enable = true
            }
        } else {
            if PopupManager.shared.enable != false {
                PopupManager.shared.enable = false
            }
        }
    }
    
    open func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if PopupManager.shared.enable != true {
            PopupManager.shared.enable = true
        }
    }
    
    open func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        if scrollView.contentOffset.y > 0 || scrollView.contentOffset.x > 0 {
            if PopupManager.shared.enable != false {
                PopupManager.shared.enable = false
            }
        }
    }
    
}
