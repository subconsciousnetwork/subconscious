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
            RegexClassifier(/for me|by me|with me|myself|I am|I need|I want|I should|will I|can I|could I|would I|I feel|I think|I believe|I hope|I wish|I regret|I wonder|I'm trying|I'm hoping|I'm feeling|I've been|I've felt|I've thought|I plan|I'm planning|I've decided|I'm considering|I'm reflecting|reflecting on|thinking about|pondering|contemplating|dreaming of|aspiring to|goals for|my goals|my aspirations|my dreams|my fears|my hopes|my challenges|my successes|my failures|learning from|growing from|my journey|my path|my experiences|my reflections|personal growth|self-improvement|self-discovery|self-reflection|self-awareness|understanding myself|exploring my|navigating my|confronting my|embracing my|my mental health|my well-being|my happiness|my sadness|my anger|my frustration|my joy|my gratitude|grateful for|thankful for|appreciative of|looking forward to/) { matches, input in
                [PromptClassification(tag: .journal, weight: CGFloat(matches.count) * 0.1)]
            }
        )
        classifier.classifier(
            RegexClassifier(/might be|what if|I wonder|then just|this can be|this might be|this could be|this means|this implies|it follows that|another way|possibly|potentially|imagine if|suppose that|assuming that|if we consider|it's conceivable|it's possible|could it be|is it possible|there's a chance|the idea of|the concept of|the possibility of|one possibility is|to speculate|in theory|theoretically|hypothetically|let's assume|for the sake of argument|what about|how about|could we|would it be|might we consider|exploring the idea|investigating the \w|pondering the \w|contemplating the \w|envisaging|forecasting|predicting|the future of|the potential for|the prospects of|speculating about|daydreaming about|dreaming of|fantasizing about|envisioning|reimagining|rethinking|questioning the|challenging the \w|redefining|redesigning|reconsidering|reconceptualizing/) { matches, input in
                [PromptClassification(tag: .idea, weight: CGFloat(matches.count) * 0.1)]
            }
        )
        classifier.classifier(
            RegexClassifier(/in fact|indeed|it's possible|perhaps|imagine that|we can think|one can think|most \w+ have|but this is|instead|this is why|this is often|more useful than|aren't always|can never|nevertheless|however|on the other hand|\w+ is a \w+|once an \w+|are how we|this means|this implies|it follows that|to illustrate|for example|for instance|consider the case|in contrast|despite|although|given that|assuming that|if we assume|leads us to believe|suggests that|points to|evidence suggests|studies show|research indicates|it could be argued|it is argued|it is believed|one might argue|one might consider|the fact that|it is clear that|it is evident that|therefore|thus|as a result|consequently|which means|which implies|which suggests|suggesting/) { matches, input in
                [PromptClassification(tag: .argument, weight: CGFloat(matches.count) * 0.1)]
            }
        )
        classifier.classifier(
            RegexClassifier(/media|digital media|social media|art|visual art|digital art|twitter|instagram|bluesky|facebook|snapchat|tiktok|linkedin|book|ebook|audiobook|novel|magazine|newspaper|movie|film|documentary|series|miniseries|music|album|EP|single|song|playlist|mixtape|article|editorial|op-ed|letter|essay|report|thesis|image|painting|illustration|drawing|photo|photography|picture|graphic|infographic|performance|concert|festival|show|live performance|youtube|vimeo|twitch|video|livestream|streaming|netflix|hulu|amazon prime|disney|cinema|ballet|opera|theatre|musical|play|television|tv|cable tv|satellite tv|journalism|news|broadcast|podcast|vlog|webinar|forum|blog|vlogging|streaming service|media platform|content creation|multimedia|animation|anime|manga|graphic novel|comic|comic book|video game|gaming|esports|virtual reality|vr|augmented reality|ar|interactive media|digital content/) { matches, input in
                [PromptClassification(tag: .media, weight: CGFloat(matches.count) * 0.1)]
            }
        )
        classifier.classifier(
            RegexClassifier(/\b(project|todo|to do|next up|next steps|action items|priorities|planned tasks|upcoming tasks|task list|agenda|schedule|work plan|project plan|milestone|goals for|objective|deliverable|due date|deadline)\b/) { matches, input in
                [PromptClassification(tag: .project, weight: 0.4 * CGFloat(matches.count))]
            }
        )
        classifier.classifier(
            RegexClassifier(/\b(goal|code|repository|repo|branch|merge|pull request|campaign|strategy|planning|research|study|analysis|data|survey|publication|paper|article|experiment|testing|prototype|issue|bug|fix|solution|meeting|agenda|minutes|discussion|publish|deploy|release|version|update|upgrade|implementation|execution|evaluation|assessment|review|feedback|collaboration|partnership|team|group|workshop|seminar|conference|symposium|webinar|presentation|speaker|audience|networking|outcome|result|impact|progress|update|status|tracking|report|dashboard|KPI|metric|benchmark|performance|efficiency|productivity|optimization|innovation|development|design|architecture|engineering|user experience|UX|user interface|UI|customer|client|stakeholder|vendor|supplier|contract|proposal|budget|cost|expense|funding|grant|resource|allocation|scheduling|timeline|roadmap|framework|methodology|approach|technique|tool|software|platform|application|app|system|infrastructure|hardware|equipment|material|supply|logistics|procurement|operation|process|workflow|procedure|guideline|policy|compliance|regulation|standard|quality|safety|security|privacy|confidentiality|intellectual property|copyright|patent|trademark|license|authorization|certification|accreditation|validation|verification)\b/) { matches, input in
                [PromptClassification(tag: .project, weight: 0.2 * CGFloat(matches.count))]
            }
        )
        classifier.classifier(
            RegexClassifier(/\?\s/) { matches, input in
                [PromptClassification(tag: .question, weight: 0.6 * CGFloat(matches.count))]
            }
        )
        classifier.classifier(
            RegexClassifier(/".+"|\'.+\'|“.+”/) { matches, input in
                [PromptClassification(tag: .quote, weight: 0.6 * CGFloat(matches.count))]
            }
        )
        classifier.classifier(
            RegexClassifier(/(\b\d{1,2}\D{0,3}\b(?:Jan(?:uary)?|Feb(?:ruary)?|Mar(?:ch)?|Apr(?:il)?|May|Jun(?:e)?|Jul(?:y)?|Aug(?:ust)?|Sep(?:tember)?|Oct(?:ober)?|Nov(?:ember)?|Dec(?:ember)?)\D{0,3}\b\d{2,4})|(\b\d{4}-\d{1,2}-\d{1,2}\b)|(\b\d{1,2}-\d{1,2}-\d{2,4}\b)|(\b\d{1,2}\/\d{1,2}\/\d{2,4}\b)/) { matches, input in
                
                if matches.count == 1 {
                    return [
                        PromptClassification(tag: .journal, weight: 0.6),
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
                            return classification.weight > 0.8
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
        
        router.route(
            PromptRoute { request in
                guard request.classifications.contains(
                    where: { classification in
                        switch classification.tag {
                        case .idea:
                            return classification.weight > 0.8
                        case .argument:
                            return classification.weight > 0.8
                        default:
                            return false
                        }
                    }
                ) else {
                    return nil
                }
                
                return tracery.flatten(
                    grammar: grammar,
                    start: "#connect#"
                )
            }
        )
        
        router.route(
            PromptRoute { request in
                guard request.classifications.contains(
                    where: { classification in
                        switch classification.tag {
                        case .quote:
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
                    start: "#quote#"
                )
            }
        )
       
        router.route(
            PromptRoute { request in
                guard request.classifications.contains(
                    where: { classification in
                        switch classification.tag {
                        case .question:
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
                    start: "#question#"
                )
            }
        )
        
        router.route(
            PromptRoute { request in
                guard request.classifications.contains(
                    where: { classification in
                        switch classification.tag {
                        case .project:
                            return classification.weight > 1.0
                        default:
                            return false
                        }
                    }
                ) else {
                    return nil
                }
                
                return tracery.flatten(
                    grammar: grammar,
                    start: "#work#"
                )
            }
        )
        
        router.route(
            PromptRoute { request in
                guard request.classifications.contains(
                    where: { classification in
                        switch classification.tag {
                        case .media:
                            return classification.weight > 1.0
                        default:
                            return false
                        }
                    }
                ) else {
                    return nil
                }
                
                return tracery.flatten(
                    grammar: grammar,
                    start: "#media#"
                )
            }
        )
        
        router.route(
            PromptRoute { request in
                return tracery.flatten(
                    grammar: grammar,
                    start: "#start#"
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
            "#connect#"
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
            "Who does this remind you of?",
            "What are your prioties?",
            "What are you avoiding?",
            "When did you last laugh?",
            "What are you proud of?",
            "What makes you nostalgic?"
        ],
        "work": [
            "What are the unknowns?",
            "Can you mitigate risks?",
            "What is the next step?",
            "What are the key milestones?",
            "Who are the stakeholders involved?",
            "What resources are required?",
            "How can you measure success?",
            "What are the potential bottlenecks?",
            "Who can provide expert insights?",
            "What is the deadline?",
            "How does this align with goals?",
            "What are the dependencies?",
            "Can this process be optimized?",
            "What feedback has been received?",
            "How can teamwork be improved?",
            "What are the cost implications?",
            "Is there a plan B?",
            "What training is needed?",
            "How can communication be enhanced?",
            "What are the competitive advantages?",
            "Are there regulatory considerations?",
            "What technological tools can help?",
            "How can we track progress?",
            "What are the scalability options?",
            "How can we ensure quality?",
            "What are the project risks?",
            "Can we automate any steps?",
            "What lessons have been learned?"
        ],
        "quote": [
            "Who else would say this?",
            "Does this remind you of anyone?",
            "What if you took this literally?",
            "What's the underlying message?",
            "How does this apply today?",
            "Can you find a counterquote?",
            "What's the historical context?",
            "How would you paraphrase this?",
            "What examples embody this?",
            "What's the opposite viewpoint?",
            "How does this inspire you?",
            "What are the limitations?",
            "How can this be misunderstood?",
            "What would your critique be?",
            "Where can this be applied?",
            "What emotions does this evoke?",
            "How can this change behavior?",
            "What's the most controversial aspect?",
            "How is this universally relevant?",
            "Does this remind you of a personal story?",
            "Can this be simplified further?",
            "What does this ignore?",
            "How would a skeptic respond?",
            "What assumptions does this make?",
            "What are the implications?",
            "How can this be expanded?",
            "What questions does this raise?",
            "How does this challenge you?"
        ],
        "question": [
            "Is there more than one answer?",
            "When should you ask this?",
            "Who could answer best?",
            "How can you validate your answer?",
            "What assumptions are being made?",
            "Why is this question important?",
            "What context is necessary?",
            "How does this question evolve?",
            "What's the underlying problem?",
            "Can you ask it differently?",
            "What evidence supports your view?",
            "Who else has asked this?",
            "What if the roles were reversed?",
            "How would experts disagree?",
            "What are the possible consequences?",
            "Can this question be broken down?",
            "What biases might affect answers?",
            "How can this lead to action?",
            "What similar questions exist?",
            "How does time affect the answer?",
            "What do different cultures say?",
            "How can technology provide solutions?",
            "What if your initial answer is wrong?",
            "How does this question connect to others?",
            "What does this reveal about you?",
            "Can history offer insights?",
            "What are the ethical considerations?",
            "How does this question inspire creativity?",
            "What future questions does this prompt?"
        ],
        "media": [
            "How does this make you feel?",
            "What is the main aesthetic?",
            "Does this bring back a memory?",
            "What themes are explored?",
            "Who is the target audience?",
            "What's the cultural significance?",
            "What motifs are repeated?",
            "How does this challenge norms?",
            "What is the narrative?",
            "What symbolism is used?",
            "How is contrast used?",
            "What era is reflected?",
            "What are the colors?",
            "Who is the main character?",
            "What's unique about the style?",
            "What the relationships?",
            "What role does setting play?",
            "How is tension created?",
            "What questions does it raise?",
            "Where is the conflict?",
            "What genre is it?"
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
