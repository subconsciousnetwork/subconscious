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
        case forward(Content)
        case forwardFade(Content)
        case slideIn
        case fadeIn
        case back
        case pop
    }

    static func update(
        state: Self,
        action: Action
    ) -> Update<Self, Action> {
        switch action {
        case .forward(let content):
            var model = state
            model.isTopSlideComplete = false
            model.isTopVisible = true
            let panel = Panel(content: content)
            model.stack[panel.id] = panel
            let fx: Fx<Action> = Just(Action.slideIn)
                .eraseToAnyPublisher()
            return Update(state: model, fx: fx)
        case .forwardFade(let content):
            var model = state
            model.isTopSlideComplete = true
            model.isTopVisible = false
            let panel = Panel(content: content)
            model.stack[panel.id] = panel
            let fx: Fx<Action> = Just(Action.fadeIn)
                .eraseToAnyPublisher()
            return Update(state: model, fx: fx)
        case .slideIn:
            var model = state
            model.isTopSlideComplete = true
            model.isTopVisible = true
            return Update(state: model)
                .animation(.easeOut(duration: model.slideDuration))
        case .fadeIn:
            var model = state
            model.isTopSlideComplete = true
            model.isTopVisible = true
            return Update(state: model)
                .animation(.easeOut(duration: model.slideDuration))
        case .back:
            var model = state
            model.isTopSlideComplete = false

            let fx: Fx<Action> = Just(Action.pop)
                .delay(
                    for: .seconds(model.slideDuration),
                    scheduler: DispatchQueue.main
                )
                .eraseToAnyPublisher()

            return Update(state: model, fx: fx)
                .animation(.easeOut(duration: model.slideDuration))
        case .pop:
            var model = state
            if !model.stack.isEmpty {
                model.stack.removeLast()
            }
            model.isTopSlideComplete = true
            return Update(state: model)
        }
    }

    private(set) var isTopSlideComplete: Bool
    private(set) var isTopVisible: Bool
    var stack: OrderedDictionary<UUID, Panel>
    var slideDuration: Double = 0.25

    init(
        stack: [Content] = [],
        slideDuration: Double = 0.25
    ) {
        self.stack = OrderedDictionary(
            stack.map({ content in
                let panel = Panel(content: content)
                return (panel.id, panel)
            }),
            uniquingKeysWith: { l, r in r }
        )
        self.slideDuration = slideDuration
        self.isTopSlideComplete = true
        self.isTopVisible = true
    }
}

struct NavigationStackView<ContentView, Content>: View
where ContentView: View, Content: Identifiable, Content: Equatable {
    var store: ViewStore<
        NavigationStackModel<Content>,
        NavigationStackModel<Content>.Action
    >
    var panel: (Content) -> ContentView
    var snapRatio: CGFloat = 0.5
    @GestureState private var drag: CGSize = CGSize.zero

    var rest: ArraySlice<NavigationStackModel<Content>.Panel> {
        store.state.stack.values.suffix(2).dropLast()
    }

    var top: NavigationStackModel<Content>.Panel? {
        store.state.stack.values.last
    }

    func offsetYForTop(width: CGFloat) -> CGFloat {
        if store.state.isTopSlideComplete {
            return max(drag.width, 0)
        } else {
            return width
        }
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
            .shadow(color: Color.black.opacity(0.1), radius: 20, x: 0, y: 0)
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
                    .overlay(alignment: .leading) {
                        EdgeHandleView()
                            .zIndex(2)
                            .gesture(
                                DragGesture(minimumDistance: 0)
                                    .updating($drag) { value, state, t in
                                        state = value.translation
                                    }
                                    .onEnded { value in
                                        let snapDistance = (
                                            geometry.size.width *
                                            self.snapRatio
                                        )
                                        if
                                            abs(value.translation.width)
                                            > snapDistance
                                        {
                                            store.send(.back)
                                        }
                                    }
                            )
                    }
                    .opacity(
                        store.state.isTopVisible ? 1 : 0
                    )
                    .offset(
                        x: offsetYForTop(width: geometry.size.width)
                    )
                    .zIndex(3)
                    .animation(
                        .interactiveSpring(
                            response: 0.5,
                            dampingFraction: 0.86,
                            blendDuration: 0.25
                        ),
                        value: drag
                    )
                }
            }
        }
    }
}
