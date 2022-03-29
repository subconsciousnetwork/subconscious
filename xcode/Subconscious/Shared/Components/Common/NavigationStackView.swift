//
//  NavigationStackView.swift
//  Subconscious (iOS)
//
//  Created by Gordon Brander on 3/28/22.
//

import SwiftUI
import ObservableStore
import Combine
import OrderedCollections

/// Model
struct NavigationStackModel<Content>: Equatable
where Content: Equatable
{
    struct Panel: Identifiable, Equatable {
        /// UUID for panel (this is a view ID, distinct from model ID)
        var id = UUID()
        /// Panel content model
        var content: Content
    }

    enum Action {
        case drag(drag: CGFloat, width: CGFloat)
        case dragEnd(drag: CGFloat, width: CGFloat)
        case forward(Content)
        case forwardFade(Content)
        case slideIn
        case fadeIn
        case back
        case pop
    }

    static func back(
        state: Self
    ) -> Update<Self, Action> {
        let fx: Fx<Action> = Just(Action.pop)
            .delay(
                for: .seconds(state.animationDuration),
                scheduler: DispatchQueue.main
            )
            .eraseToAnyPublisher()

        var model = state
        model.dragRatio = 1

        return Update(state: model, fx: fx)
    }

    static func update(
        state: Self,
        action: Action
    ) -> Update<Self, Action> {
        switch action {
        case .forward(let content):
            var model = state
            model.dragRatio = 1
            model.isTopVisible = true
            let panel = Panel(content: content)
            model.stack[panel.id] = panel
            let fx: Fx<Action> = Just(Action.slideIn)
                .eraseToAnyPublisher()
            return Update(state: model, fx: fx)
        case .forwardFade(let content):
            var model = state
            model.dragRatio = 0
            model.isTopVisible = false
            let panel = Panel(content: content)
            model.stack[panel.id] = panel
            let fx: Fx<Action> = Just(Action.fadeIn)
                .eraseToAnyPublisher()
            return Update(state: model, fx: fx)
        case .slideIn:
            var model = state
            model.dragRatio = 0
            model.isTopVisible = true
            return Update(state: model)
        case .fadeIn:
            var model = state
            model.dragRatio = 0
            model.isTopVisible = true
            return Update(state: model)
                .animation(.easeOutCubic(duration: model.animationDuration))
        case .back:
            return back(state: state)
        case .pop:
            var model = state
            if !model.stack.isEmpty {
                model.stack.removeLast()
            }
            model.dragRatio = 0
            return Update(state: model)
        case .drag(let drag, let width):
            var model = state
            model.dragRatio = drag / width
            return Update(state: model)
        case .dragEnd(let drag, let width):
            let ratio = drag / width
            if ratio > state.dragSnapRatio {
                return back(state: state)
            } else {
                var model = state
                model.dragRatio = 0
                return Update(state: model)
            }
        }
    }

    private(set) var dragRatio: CGFloat
    private(set) var dragSnapRatio: CGFloat
    private(set) var isTopVisible: Bool
    var stack: OrderedDictionary<UUID, Panel>
    var animationDuration: Double

    init(
        stack: [Content] = [],
        animationDuration: Double = 0.5
    ) {
        self.stack = OrderedDictionary(
            stack.map({ content in
                let panel = Panel(content: content)
                return (panel.id, panel)
            }),
            uniquingKeysWith: { l, r in r }
        )
        self.animationDuration = animationDuration
        self.dragRatio = 0
        self.dragSnapRatio = 0.3
        self.isTopVisible = true
    }
}

struct NavigationStackView<ContentView, Content>: View
where ContentView: View, Content: Equatable {
    var store: ViewStore<
        NavigationStackModel<Content>,
        NavigationStackModel<Content>.Action
    >
    var panel: (Content) -> ContentView

    var rest: ArraySlice<NavigationStackModel<Content>.Panel> {
        store.state.stack.values.suffix(2).dropLast()
    }

    var top: NavigationStackModel<Content>.Panel? {
        store.state.stack.values.last
    }

    func offsetXForTop(width: CGFloat) -> CGFloat {
        max(store.state.dragRatio * width, 0)
    }

    struct EdgeHandleView: View {
        var body: some View {
            Color.clear
                .frame(width: 44)
                .contentShape(Rectangle())
        }
    }

    struct PanelView: View {
        var content: ContentView
        var size: CGSize

        var body: some View {
            VStack {
                content
            }
            .frame(
                width: size.width,
                height: size.height
            )
            .background(.background)
        }
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(rest) { panel in
                    PanelView(
                        content: self.panel(panel.content),
                        size: geometry.size
                    )
                    .id("NavigationStackView/Panel/\(panel.id)")
                    .zIndex(1)
                }
                if let panel = top {
                    PanelView(
                        content: self.panel(panel.content),
                        size: geometry.size
                    )
                    .id("NavigationStackView/Panel/\(panel.id)")
//                    .overlay(alignment: .leading) {
//                        EdgeHandleView()
//                            .gesture(
//                                DragGesture(minimumDistance: 0)
//                                    .updating($drag) { value, state, t in
//                                        state = value.translation
//                                    }
//                                    .onEnded { value in
//                                        let snapDistance = (
//                                            geometry.size.width *
//                                            self.snapRatio
//                                        )
//                                        if
//                                            abs(value.translation.width)
//                                            > snapDistance
//                                        {
//                                            store.send(.back)
//                                        }
//                                    }
//                            )
//                    }
                    .opacity(
                        store.state.isTopVisible ? 1 : 0
                    )
                    .offset(
                        x: offsetXForTop(width: geometry.size.width)
                    )
                    .zIndex(3)
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged({ value in
                                store.send(
                                    .drag(
                                        drag: value.translation.width,
                                        width: geometry.size.width
                                    )
                                )
                            })
                            .onEnded { value in
                                store.send(
                                    .dragEnd(
                                        drag: value.translation.width,
                                        width: geometry.size.width
                                    )
                                )
                            }
                    )
                    .animation(
                        .interpolatingSpring(mass: 0.01, stiffness: 3, damping: 1),
                        value: store.state.dragRatio
                    )
                }
            }
        }
    }
}
