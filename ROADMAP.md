# Subconscious Roadmap

## Purpose

**Subconscious is building the internet of ideas.**

Subconscious is your web3 notebook. We want to build a new kind of web-like ecosystem based on multiplayer social hypertext, like Twitter meets Wiki.

## Principles

**You own your data**: It's your second brain, not ours. Notes should last a lifetime. The only way to ensure this for you to retain ownership of your notes.

**Credible exit**: you must be able to usefully get your data out of Subconscious and into files, or other apps.

**Built on top of open protocols**: Like the web, Subconscious aims to build on top of general protocol primitives. New tools and apps (even competitors) should be able to usefully use the same markup and protocols that Subconscious uses.

**Open-ended**: Like the web, Subconscious aims to support open-ended evolution. When TBL launched the web it was just a small app for scientists to share papers, but it quickly evolved, becoming the networked app platform we have today. How? Permissionless innovation. Any user or developer can extend the system in new directions. The result is open-ended evolution.

## Q1 2022 Alpha

Priority: Launch a simple single-player alpha, focused on "self-organizing ideas". Ideas self-organize through feedback loops that focus on creative divergence/convergence.

- Diverge: the home view of Subconscious is a feed that surfaces prompts and relationships generated from your notes.
- Converge: the core game loop of Subconscious is search-or-create. This nudges you toward capturing new ideas by adding to old notes, slowly growing knowledge artifacts from the bottom-up.

Our hypothesis: the best edge-of-the-wedge is a mobile app that solves for "self-organizing ideas", a different goal from Roam/Obsidian/Notion.

- Mobile: existing tools for thought skew desktop web, leaving mobile to Apple Notes, which does not do much to help you develop ideas.
- Self-organizing ideas: Roam, Obsidian and Notion are like RPGs focused on knowledge graph worldbuilding. Subconscious wants to focus on lazy knowledge gardening. Easy ambient capture + microinteractions to generate and develop ideas.

### Search-or-create flow

A game mechanic inspired by [Notational Velocity](https://notational.net/) and adapted for mobile. Type-ahead to search through existing notes. If nothing turns up, create a new note. New note body is populated with query. This mechanic closes a feedback loop in note-taking. New notes get folded into old ones, causing knowledge artifacts to grow from the bottom up.

Background thinking:

- [Knowledge gardening is recursive](https://subconscious.substack.com/p/knowledge-gardening-is-recursive)
- [Unconscious R&D](https://subconscious.substack.com/p/unconscious-r-and-d)
- [Search reveals useful dimensions in latent idea space](https://subconscious.substack.com/p/search-reveals-useful-dimensions)

### Generative home feed

Algorithmic home feed view that surfaces generative prompts. The feed uses simple local-first algorithms to generate updates (recent notes and also prompts) from your notes. The design goal is spark new ideas and connections.

Backround thinking:

- [Building a second subconscious](https://subconscious.substack.com/p/second-subconscious)
- [Getting lost in the land of ideas](https://subconscious.substack.com/p/getting-lost-in-the-land-of-ideas)
- [Self-organizing ideas](https://subconscious.substack.com/p/self-organizing-ideas)
- [Unconscious R&D](https://subconscious.substack.com/p/unconscious-r-and-d)
- [Outward notes, inward notes](https://subconscious.substack.com/p/outward-notes-inward-notes)
- [The Knowledge Ecology](https://subconscious.substack.com/p/the-knowledge-ecology)

### Subtext

Project URL: https://github.com/gordonbrander/subtext

Develop a simple plain-text markup language for note-taking. Support programmatic decomposition. Make it easy to implement so other tools and apps can choose to interoperate.

Background thinking:

- [Subtext README](https://github.com/gordonbrander/subtext/blob/main/README.md)
- [Subtext: markup for note-taking](https://subconscious.substack.com/p/subtext-markup-for-note-taking)
- [Thought legos](https://subconscious.substack.com/p/thought-legos)
- [Hypertext montage](https://subconscious.substack.com/p/hypertext-montage)
- [Self-organizing ideas](https://subconscious.substack.com/p/self-organizing-ideas)
- [Concept refactoring](https://subconscious.substack.com/p/concept-refactoring)


### Live-rendered markup

Live-render Subtext markup as you type. No separation between "view mode" and "edit mode". Link URLs and slashlinks, format headings, quotes, and lists.

Background thinking:

- [Slashlinks](https://subconscious.substack.com/p/slashlinks)

### Backlinks

List backlinks and related notes below note.

Background thinking:

- [Slashlinks](https://subconscious.substack.com/p/slashlinks)

### Link suggestions

Suggest links from existing pages and frequent searches while writing notes. This closes feedback loops between past, present, and future notes.

Background thinking:

- [Search reveals useful dimensions in latent idea space](https://subconscious.substack.com/p/search-reveals-useful-dimensions)
- [Outward notes, inward notes](https://subconscious.substack.com/p/outward-notes-inward-notes)
- [Slashlinks](https://subconscious.substack.com/p/slashlinks)

### Save to files

Save note content to Subtext files. Lean on integrated iOS files support until we develop an open sync system. This gives users credible exit.

Background thinking:

- [Composability with other tools](https://subconscious.substack.com/p/composability-with-other-tools)

## Q? 2022 Multiplayer

Priorities: launch multiplayer version that supports open sync, public and private notes.

### Open sync

### Distributed cloud infrastructure

### Block editor

## Q? 2022 Subspaces

Priorties: upgrade multiplayer to support "Subspaces" which support multi-user team note-taking.

Background thinking:

- [Wiki as a commons](https://subconscious.substack.com/p/wiki-as-a-commons)

## Future Goals

### Cooperatively-owned infrastructure 

### Geists

End-user scripting for your notes via sandboxed bots.