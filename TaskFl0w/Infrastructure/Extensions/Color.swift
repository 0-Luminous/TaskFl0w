//
//  Color.swift
//  TaskFl0w
//
//  Created by Yan on 24/12/24.
//
import SwiftUI
import UIKit

extension Color {
    init?(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")

        var rgb: UInt64 = 0
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 1.0

        let length = hexSanitized.count

        guard Scanner(string: hexSanitized).scanHexInt64(&rgb) else { return nil }

        if length == 6 {
            r = CGFloat((rgb & 0xFF0000) >> 16) / 255.0
            g = CGFloat((rgb & 0x00FF00) >> 8)  / 255.0
            b = CGFloat(rgb & 0x0000FF)        / 255.0
        } else if length == 8 {
            r = CGFloat((rgb & 0xFF000000) >> 24) / 255.0
            g = CGFloat((rgb & 0x00FF0000) >> 16) / 255.0
            b = CGFloat((rgb & 0x0000FF00) >> 8)  / 255.0
            a = CGFloat(rgb & 0x000000FF)         / 255.0
        } else {
            return nil
        }

        self.init(red: r, green: g, blue: b, opacity: a)
    }
    
    func toHex() -> String {
        guard let components = UIColor(self).cgColor.components else { return "" }
        
        let r = Float(components[0])
        let g = Float(components[1])
        let b = Float(components[2])
        let a = components.count >= 4 ? Float(components[3]) : Float(1.0)
        
        if a != Float(1.0) {
            return String(format: "%02lX%02lX%02lX%02lX",
                        lroundf(r * 255),
                        lroundf(g * 255),
                        lroundf(b * 255),
                        lroundf(a * 255))
        }
        
        return String(format: "%02lX%02lX%02lX",
                    lroundf(r * 255),
                    lroundf(g * 255),
                    lroundf(b * 255))
    }
}

