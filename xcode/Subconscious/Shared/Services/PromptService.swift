//
//  PromptService.swift
//  Subconscious
//
//  Created by Gordon Brander on 1/30/24.
//

import Foundation

actor PromptService {
    private let tracery = Tracery()
    private var grammar: Dictionary<String, Array<String>>

    init(grammar: Dictionary<String, Array<String>> = [:]) {
        self.grammar = grammar
    }

    func generate(start: String = "#start#") -> String {
        tracery.flatten(grammar: grammar, start: start)
    }
}

extension PromptService {
    static let prompts = [
        "start": [
            "#connect#",
            "#reflect#"
        ],
        "connect": [
            "What else is like this?",
            "What is the opposite?",
            "What are the underlying principles?",
            "How would someone else see this?",
            "What problem can this idea solve?",
            "Can you capture it in a metaphor?",
            "How would a child understand it?",
            "Can it be simplified?",
            "Is it complicated enough?",
            "What could be the consequences?",
            "What are the ethical implications?",
            "What happens if you change the context?",
            "What are the unintended effects?",
            "What would be a counter-argument?",
            "Why could this be wrong?",
            "Does this resemble a historical event?",
            "Does nature provide an example?",
            "Could you draw a diagram?",
            "Will this matter in a decade?",
            "What if the roles were reversed?",
            "Does this resonate with you personally?",
            "What would a child think?",
            "How can this be misinterpreted?",
            "What if the main assumption is wrong?",
            "What if time was not a factor?",
            "Can it be scaled up?",
            "What if you zoom out?",
            "What if you changed a key component?",
            "Who would disagree?",
            "Would it make sense in 100 years?",
            "What if you start from scratch?",
            "What would your hero think?",
            "What are the incentives?",
            "What does success look like?",
            "When is it relevant?",
            "Where can restrictions be eased?",
            "How can inconsistency become consistent?",
            "What if a vital connection was cut?",
            "What if desire was not a factor?",
            "What's outside the boundaries?",
            "Can it be extended?",
            "What comes before?",
            "What comes after?",
            "Could you entertain conflicting ideas?",
            "Is this surprising?",
            "What if the opposite were true?",
            "How do you relate to it?",
            "What if you looked at it backwards?",
            "What remains unsaid?",
            "What would an expert think?",
            "How does this inspire you?",
            "Is there another perspective?",
            "What does this build upon?",
            "Can you say it in one sentence?",
            "In what ways might this be true?",
            "What does this contradict?"
        ],
        "reflect": [
            "What was the best part of your day?",
            "What was the worst part of your day?",
            "What did you learn today?",
            "What are you grateful for today?",
            "What are you looking forward to tomorrow?",
            "What are you worried about?",
            "What are you excited about?",
            "What is something you want to change?",
            "What is something you want to improve?",
            "What is something you want to learn?",
            "What is something you want to do?",
            "What is something you want to make?",
            "What is something you want to achieve?",
            "What is something you want to build?",
            "What is something you want to try?",
            "What is something you want to start?",
            "What is something you want to stop?",
            "What is something you want to finish?",
            "What is something you want to change?",
            "What is something you want to improve?",
            "What is something you want to learn?",
            "What is something you want to do?",
            "What is something you want to make?",
            "What is something you want to achieve?",
            "What is something you want to build?",
            "What is something you want to try?",
            "What is something you want to start?",
            "What is something you want to stop?",
            "What is something you want to finish?",
            "What is something you want to change?",
            "What is something you want to improve?",
            "What is something you want to learn?",
            "What is something you want to do?",
            "What is something you want to make?",
            "What is something you want to achieve?",
            "What is something you want to build?",
        ]
    ]

    static let `default` = PromptService(grammar: prompts)
}
