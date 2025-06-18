//
//  CategoryEntity+Extension.swift
//  TaskFl0w
//
//  Created by Yan on 24/12/24.
//
import CoreData
import SwiftUI

extension CategoryEntity {
    var categoryModel: TaskCategoryModel {
        TaskCategoryModel(
            id: id ?? UUID(),
            rawValue: name ?? "",
            iconName: iconName ?? "",
            color: Color(hex: colorHex ?? "") ?? .blue
        )
    }
    
    static func from(_ model: TaskCategoryModel, context: NSManagedObjectContext) -> CategoryEntity {
        let entity = CategoryEntity(context: context)
        entity.id = model.id
        entity.name = model.rawValue
        entity.iconName = model.iconName
        entity.colorHex = model.color.toHex()
        return entity
    }
} 
