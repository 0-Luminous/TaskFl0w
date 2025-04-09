//
//  ToDoRouter.swift
//  ToDoList
//
//  Created by Yan on 19/3/25.
//
import SwiftUI
import UIKit

class ToDoRouter: ToDoRouterProtocol {
    // Определяем ассоциированный тип для протокола
    typealias ContentView = TaskListView
    
    static func createModule(selectedCategory: TaskCategoryModel? = nil) -> TaskListView {
        let viewModel = ListViewModel(selectedCategory: selectedCategory)
        let view = TaskListView(viewModel: viewModel, selectedCategory: selectedCategory)
        let interactor = ToDoInteractor()
        let router = ToDoRouter()
        let presenter = ToDoPresenter(view: viewModel)

        viewModel.presenter = presenter
        presenter.interactor = interactor
        presenter.router = router
        interactor.presenter = presenter

        print("🚀 Router: Инициализация модуля и загрузка данных")
        presenter.viewDidLoad()

        return view
    }

    func shareItem(_ item: ToDoItem) {
        let textToShare = "\(item.title)\n\(item.content)"
        let activityVC = UIActivityViewController(
            activityItems: [textToShare],
            applicationActivities: nil
        )

        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
            let window = windowScene.windows.first,
            let rootVC = window.rootViewController
        {
            rootVC.present(activityVC, animated: true)
        }
    }
}
