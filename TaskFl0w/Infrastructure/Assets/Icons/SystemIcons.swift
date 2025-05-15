//
//  SystemIcons.swift
//  TaskFl0w
//
//  Created by Yan on 24/12/24.
//

import Foundation

public enum SystemIcons {
    // Все доступные иконки
    public static let available: [String] = [
        workAndEducation, homeAndFamily, creativityAndHobbies, 
        shoppingAndFinance, travelAndTransport, timeAndPlanning, 
        communicationAndTech, toolsAndSettings
    ].flatMap { $0 }
    
    // Работа, Учёба, Бизнес
    public static let workAndEducation: [String] = [
        "briefcase.fill", "case.fill", "chart.bar.fill", "doc.text.fill", 
        "doc.fill", "folder.fill", "list.bullet", "paperplane.fill", 
        "archivebox.fill", "graduationcap.fill", "doc.text.magnifyingglass", 
        "link", "command", "keyboard", "printer.fill"
    ]
    
    // Дом, Семья, Личное
    public static let homeAndFamily: [String] = [
        "house.fill", "person.fill", "person.2.fill", "sofa.fill", 
        "washer.fill", "bed.double.fill", "fanblades.fill", "refrigerator.fill", 
        "lamp.table.fill", "heart.fill", "heart.circle.fill", "heart.text.square.fill", 
        "bandage.fill", "pills.fill", "stethoscope", "cross.fill", 
        "lungs.fill", "drop.fill"
    ]
    
    // Творчество, Развлечения, Хобби
    public static let creativityAndHobbies: [String] = [
        "paintbrush.fill", "paintpalette.fill", "camera.fill", "photo.fill", 
        "camera.aperture", "music.note", "music.mic", "video.fill", 
        "mic.fill", "speaker.fill", "theatermasks.fill", "popcorn.fill", 
        "film.fill", "ticket.fill", "gamecontroller.fill", "gamecontroller.circle.fill", 
        "headphones", "wand.and.stars.inverse", "sparkle.magnifyingglass", 
        "sparkles", "puzzlepiece.fill"
    ]
    
    // Покупки, Деньги, Подарки
    public static let shoppingAndFinance: [String] = [
        "cart.fill", "cart.circle.fill", "gift.fill", "giftcard.fill", 
        "bag.fill", "scissors", "tag.fill", "wallet.pass", 
        "wallet.pass.fill", "dollarsign.circle.fill", "creditcard.fill", 
        "banknote.fill", "bitcoinsign.circle.fill", "plus"
    ]
    
    // Путешествия, Локации, Транспорт
    public static let travelAndTransport: [String] = [
        "location.fill", "map.fill", "pin.fill", "safari.fill", 
        "globe", "airplane", "car.fill", "tram.fill", 
        "bicycle", "fuelpump.fill", "ferry.fill", "bus.fill", 
        "scooter", "signpost.right.fill", "mappin.and.ellipse", "parkingsign.circle.fill", 
        "cloud.fill", "cloud.rain.fill", "sun.max.fill", "moon.fill", 
        "snow", "flame.fill", "bolt.fill"
    ]
    
    // Время, Планирование, Заметки
    public static let timeAndPlanning: [String] = [
        "calendar", "clock.fill", "stopwatch.fill", "timer", 
        "gauge", "speedometer", "bookmark.fill", "flag.fill", 
        "note.text", "doc.text.fill", "folder.fill", "tray.fill", 
        "archivebox.fill"
    ]
    
    // Связь, Технологии, Соцсети
    public static let communicationAndTech: [String] = [
        "phone.fill", "phone.arrow.up.right.fill", "message.fill", "bubble.left.and.bubble.right.fill", 
        "bubble.left.fill", "quote.bubble.fill", "envelope.fill", "apps.iphone", 
        "iphone", "ipad", "laptopcomputer", "display", 
        "tv.fill", "network", "wifi", "antenna.radiowaves.left.and.right", 
        "antenna.radiowaves.left.and.right.circle.fill", "battery.100"
    ]
    
    // Инструменты, Настройки, Безопасность
    public static let toolsAndSettings: [String] = [
        "hammer.fill", "wrench.fill", "xmark", "circle.fill", 
        "square.fill", "triangle.fill", "diamond.fill", "gearshape.fill", 
        "gear.circle.fill", "lock.shield.fill", "key.fill", "magnifyingglass.circle.fill", 
        "shield.fill"
    ]
} 