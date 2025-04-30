//
//  TaskFlowWidgetsLiveActivity.swift
//  TaskFlowWidgets
//
//  Created by Yan on 30/4/25.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct TaskFlowWidgetsAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic stateful properties about your activity go here!
        var emoji: String
    }

    // Fixed non-changing properties about your activity go here!
    var name: String
}

struct TaskFlowWidgetsLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: TaskFlowWidgetsAttributes.self) { context in
            // Lock screen/banner UI goes here
            VStack {
                Text("Hello \(context.state.emoji)")
            }
            .activityBackgroundTint(Color.cyan)
            .activitySystemActionForegroundColor(Color.black)

        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI goes here.  Compose the expanded UI through
                // various regions, like leading/trailing/center/bottom
                DynamicIslandExpandedRegion(.leading) {
                    Text("Leading")
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text("Trailing")
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text("Bottom \(context.state.emoji)")
                    // more content
                }
            } compactLeading: {
                Text("L")
            } compactTrailing: {
                Text("T \(context.state.emoji)")
            } minimal: {
                Text(context.state.emoji)
            }
            .widgetURL(URL(string: "http://www.apple.com"))
            .keylineTint(Color.red)
        }
    }
}

extension TaskFlowWidgetsAttributes {
    fileprivate static var preview: TaskFlowWidgetsAttributes {
        TaskFlowWidgetsAttributes(name: "World")
    }
}

extension TaskFlowWidgetsAttributes.ContentState {
    fileprivate static var smiley: TaskFlowWidgetsAttributes.ContentState {
        TaskFlowWidgetsAttributes.ContentState(emoji: "😀")
     }
     
     fileprivate static var starEyes: TaskFlowWidgetsAttributes.ContentState {
         TaskFlowWidgetsAttributes.ContentState(emoji: "🤩")
     }
}

#Preview("Notification", as: .content, using: TaskFlowWidgetsAttributes.preview) {
   TaskFlowWidgetsLiveActivity()
} contentStates: {
    TaskFlowWidgetsAttributes.ContentState.smiley
    TaskFlowWidgetsAttributes.ContentState.starEyes
}
