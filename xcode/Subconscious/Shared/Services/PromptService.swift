//
//  PromptService.swift
//  Subconscious
//
//  Created by Gordon Brander on 1/30/24.
//

import SwiftUI

actor PromptService {
    private let tracery: Tracery
    private let grammar: Grammar
    private var router: PromptRouter

    init(grammar: Dictionary<String, Array<String>> = [:]) {
        let tracery = Tracery()

        var classifier = PromptClassifier()
        classifier.classifier(
            RegexClassifier(/journal|diary/) { matches, input in
                [PromptClassification(tag: .journal, weight: 0.6)]
            }
        )
        classifier.classifier(
            RegexClassifier(/me|myself|I am|my/) { matches, input in
                [PromptClassification(tag: .journal, weight: 0.6)]
            }
        )
        classifier.classifier(
            RegexClassifier(/todo/) { matches, input in
                [PromptClassification(tag: .project, weight: 0.2 * CGFloat(matches.count))]
            }
        )
        classifier.classifier(
            RegexClassifier(/\?\s/) { matches, input in
                [PromptClassification(tag: .question, weight: 0.5 * CGFloat(matches.count))]
            }
        )
        classifier.classifier(
            RegexClassifier(/(\b\d{1,2}\D{0,3}\b(?:Jan(?:uary)?|Feb(?:ruary)?|Mar(?:ch)?|Apr(?:il)?|May|Jun(?:e)?|Jul(?:y)?|Aug(?:ust)?|Sep(?:tember)?|Oct(?:ober)?|Nov(?:ember)?|Dec(?:ember)?)\D{0,3}\b\d{2,4})|(\b\d{4}-\d{1,2}-\d{1,2}\b)|(\b\d{1,2}-\d{1,2}-\d{2,4}\b)|(\b\d{1,2}\/\d{1,2}\/\d{2,4}\b)/) { matches, input in
                
                if matches.count == 1 {
                    return [
                        PromptClassification(tag: .journal, weight: 0.5),
                        PromptClassification(tag: .date, weight: 0.2)
                    ]
                }
                
                return [
                    PromptClassification(tag: .date, weight: 0.2 * CGFloat(matches.count)),
                    PromptClassification(tag: .list, weight: 0.1 * CGFloat(matches.count)),
                ]
            }
        )
        classifier.classifier(KeywordClassifier() { keywords, input in
            keywords.map { k in
                PromptClassification(tag: .noun(k), weight: 1)
            }
        })
        classifier.classifier(
            SubtextClassifier() { dom, input in
                [
                    PromptClassification(
                        tag: .link,
                        weight: CGFloat(dom.slashlinks.count) * 0.3
                    ),
                    PromptClassification(
                        tag: .list,
                        weight: CGFloat(dom.blocks.filter({ block in
                            switch block {
                            case .list:
                                return true
                            default:
                                return false
                            }
                        }).count) * 0.2
                    ),
                    PromptClassification(
                        tag: .quote,
                        weight: CGFloat(dom.blocks.filter({ block in
                            switch block {
                            case .quote:
                                return true
                            default:
                                return false
                            }
                        }).count) * 0.6
                    ),
                    PromptClassification(
                        tag: .heading,
                        weight: CGFloat(dom.blocks.filter({ block in
                            switch block {
                            case .heading:
                                return true
                            default:
                                return false
                            }
                        }).isEmpty ? 0 : 1)
                    )
                ]
            }
        )

        var router = PromptRouter(classifier: classifier)
        // Journal route
        router.route(
            PromptRoute { request in
                guard request.classifications.contains(
                    where: { classification in
                        switch classification.tag {
                        case .journal:
                            return classification.weight > 0.5
                        default:
                            return false
                        }
                    }
                ) else {
                    return nil
                }
                return tracery.flatten(
                    grammar: grammar,
                    start: "#reflect#"
                )
            }
        )

        self.router = router
        self.tracery = tracery
        self.grammar = grammar
    }

    func generate(start: String = "#start#") async -> String {
        tracery.flatten(grammar: grammar, start: start)
    }
    
    /// Generate a prompt given an input string
    func generate(input: String) async -> String {
        guard let result = await router.process(input) else {
            return await generate()
        }
        return result

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
            "What does this contradict?",
            "What does this support?",
            "Can you combine this with another idea to make something new?",
            "What questions does this trigger?",
            "How does this change my understanding?",
            "Can you make a connection to #domains#?",
            "Can you make an analogy to #domains#?"
        ],
        "domains": [
            "nature",
            "ecosystems",
            "science",
            "art",
            "economics",
            "physics",
            "music",
            "history",
            "dance",
            "theater",
            "literature",
            "architecture",
            "psychology",
            "philosophy",
            "engineering",
            "fashion",
            "cooking",
            "mythology",
            "folklore",
            "magic"
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

struct PromptService_Previews: PreviewProvider {
    struct PromptPreviewView: View {
        let prompt = PromptService.default
        @State private var prompts: [String] = []

        private func regeneratePrompts() async {
            var prompts: [String] = []
            prompts.append(await prompt.generate(input: "journal"))
            prompts.append(await prompt.generate(input: "dear diary"))
            prompts.append(await prompt.generate(input: "I am writing in my journal"))
            prompts.append(await prompt.generate(input: "no match"))
            prompts.append(await prompt.generate(input: "I am writing in my journal"))
            prompts.append(await prompt.generate(input: "I am writing in my journal and @ben/link @gordon/link I have links!"))
            prompts.append(await prompt.generate(input:
                """
                - test
                - one
                - two
                - three
                """
            ))
            prompts.append(await prompt.generate())
            prompts.append(await prompt.generate())
            prompts.append(await prompt.generate())
            prompts.append(await prompt.generate())
            prompts.append(await prompt.generate())
            prompts.append(await prompt.generate())
            prompts.append(await prompt.generate())
            prompts.append(await prompt.generate())
            prompts.append(await prompt.generate())
            prompts.append(await prompt.generate())
            prompts.append(await prompt.generate())
            prompts.append(await prompt.generate())
            prompts.append(await prompt.generate())
            prompts.append(await prompt.generate())
            prompts.append(await prompt.generate())
            prompts.append(await prompt.generate())
            self.prompts = prompts
        }

        var body: some View {
            VStack(alignment: .leading) {
                ForEach(prompts, id: \.self) { prompt in
                    HStack {
                        Text(prompt)
                        Spacer()
                    }
                }
                Button(
                    action: {
                        Task {
                            await regeneratePrompts()
                        }
                    },
                    label: {
                        Text("Generate")
                    }
                )
                .buttonStyle(.borderedProminent)
            }
            .padding()
            .task {
                await regeneratePrompts()
            }
        }
    }

    static var previews: some View {
        PromptPreviewView()
    }
}
