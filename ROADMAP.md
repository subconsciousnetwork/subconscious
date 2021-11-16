# Subconscious Roadmap

## Purpose

**Subconscious is building the internet of ideas.**

Subconscious is your web3 notebook. We want to build a new kind of web-like ecosystem based on multiplayer social hypertext, like Twitter meets Wiki.

## Principles

**Own your data**: It's your second brain, not ours. Notes should last a lifetime. The only way to ensure this for you to retain ownership of your notes.

**Credible exit**: you must be able to usefully get your data out of Subconscious and into files, or other apps.

**Built on top of open protocols**: Think like TBL. Build Subconscious on general protocol primitives that will be useful for multiple tools and apps.

**Open-ended and evolvable**: When TBL launched the web it was just a small app for scientists to share papers, but it quickly evolved, becoming the networked app platform we have today. How? Any user or developer can extend the system in new directions. The result is [open-ended evolution](https://subconscious.substack.com/p/open-ended-tools-for-infinite-games). Build Subconscious from an [alphabet](https://subconscious.substack.com/p/provoking-emergence-with-alphabets) of pieces you can remix and evolve for new use-cases.

## Q1 2022 Alpha

Priority: Launch a simple single-player alpha, focused on "self-organizing ideas". Ideas self-organize through feedback loops that focus on creative divergence/convergence.

- Diverge: the home view of Subconscious is a feed that surfaces prompts and relationships generated from your notes.
- Converge: the core game loop of Subconscious is search-or-create. This nudges you toward capturing new ideas by adding to old notes, slowly growing knowledge artifacts from the bottom-up.

Our hypothesis: the best edge-of-the-wedge is a mobile app that solves for "self-organizing ideas", a different goal from Roam/Obsidian/Notion.

- Mobile: existing tools for thought skew desktop web, leaving mobile to Apple Notes, which does not do much to help you develop ideas.
- Self-organizing ideas: Roam, Obsidian and Notion are like RPGs focused on knowledge graph worldbuilding. Subconscious wants to focus on lazy knowledge gardening. Easy ambient capture + microinteractions to generate and develop ideas.

### Search-or-create

A game mechanic inspired by [Notational Velocity](https://notational.net/) and adapted for mobile. Type-ahead to search through existing notes. If nothing turns up, create a new note. New note body is populated with query. This mechanic closes a feedback loop in note-taking. New notes get folded into old ones, causing knowledge artifacts to grow from the bottom up.

Background thinking:

- [Knowledge gardening is recursive](https://subconscious.substack.com/p/knowledge-gardening-is-recursive)
- [Unconscious R&D](https://subconscious.substack.com/p/unconscious-r-and-d)
- [Search reveals useful dimensions in latent idea space](https://subconscious.substack.com/p/search-reveals-useful-dimensions)
- [Notes are conversations across time](https://subconscious.substack.com/p/notes-are-conversations-across-time)

### Generative feed

Algorithmic home feed view that surfaces generative prompts. The feed uses simple local-first algorithms to generate updates (recent notes and also prompts) from your notes. The design goal is spark new ideas and connections.

Tracking:

- [Implement generative feed #16](https://github.com/gordonbrander/subconscious/issues/16)

Backround thinking:

- [Building a second subconscious](https://subconscious.substack.com/p/second-subconscious)
- [Getting lost in the land of ideas](https://subconscious.substack.com/p/getting-lost-in-the-land-of-ideas)
- [Self-organizing ideas](https://subconscious.substack.com/p/self-organizing-ideas)
- [Unconscious R&D](https://subconscious.substack.com/p/unconscious-r-and-d)
- [Notes are conversations across time](https://subconscious.substack.com/p/notes-are-conversations-across-time)
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

### Sharesheet

Integrate with iOS sharesheet for easy note capture.

## Q? 2022 Multiplayer

Priorities: launch multiplayer version that supports open sync, public and private notes.

### Open sync

Cross-platform sync.

### Distributed cloud infrastructure

Create cloud infrastructure for sync (with future multiplayer support). Focus on building with general protocols that could be used by other apps and for other purposes.

### Publish notes

- Publish notes to [IPFS](https://ipfs.io/), the permanent web.
    - Server acts as IPFS gateway for notes
- Publish notes to HTTP

### Follow

- Follow public notes (RSS?)
- See updates in your feed

### Block editor

Modeless block editor (like Notion or Roam) with rich transcludes.

## Q? 2022 Subspaces

Priorties: upgrade multiplayer to support "Subspaces" which support multi-user team note-taking.

### Federated Subspaces

Background thinking:

- [Wiki as a commons](https://subconscious.substack.com/p/wiki-as-a-commons)
- [Dunbar-scale social](https://subconscious.substack.com/p/dunbar-scale-social)
- [Network intersubjectives](https://subconscious.substack.com/p/network-intersubjectives)

## Q? 2022 Subconscious DAO

### Coop ownership DAO

## Q? 2022 Subconscious Web3

### Subtitle - NFT DNS

### Subwallet

### Expanded subtokens

## Future Goals

### End-to-end encryption

Single player and multiplayer end-to-end encrypted private notes. Manage keys with wallet app.

### Cooperatively-owned infrastructure

Explore using a DAO to fund cooperatively owned server infrastructure for multiplayer and sync.

### Geists

End-user scripting for your notes via sandboxed bots.

### Mint note NFTs

Mint NFTs for notes, creating chains of provable authorship.

### Web clipper

Save plain text archives of all links within your Subconscious note corpus. This enables full-text search of links that you care about.

Background thinking:

- [Saving copies of everything is like low-budget p2p](https://subconscious.substack.com/p/saving-copies-of-everything-is-like)

### Email to note

Send emails to create new notes. This would enable things like subscribing to a Google Scholar alert to build an ongoing archive of all papers on a given topic.

Background thinking:

- [Everything talks email](https://subconscious.substack.com/p/everything-talks-email)