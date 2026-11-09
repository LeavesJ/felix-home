### 0ft. 2026-11-06 to 11-07: the founder's decisions in the trust-plane revisit

This section records decisions the founder made in conversation during the trust-plane revisit, from the evening of 11-06 to the early hours of 11-07. It changes no code. Under direction point 3 they bind from this section until a fold brings them into `docs/direction.md`; that fold is the draft stacked on #489, as rows 42 to 47.

The working papers sit in the memory root under `designs/2026-11-06-trust-plane-revisit/`: the brief, sketches 1 and 2, and design drafts 2 and 3, each with its PDF. The language re-measure is under `audits/2026-11-06-language-remeasure/`. None of them is direction.

**Decided by the founder.** These are the decisions made so far, listed in the order the conversation reached them, which says nothing about their weight.

1. **Order (11-06): capability intake first, then the trust plane, before large capability builds.** "wrap up intake for capabiility, but later revisit and work on trust plane again bc like we both flagged, trust problem must be settled bc the probelm will propogate to future capability build...which WILL be large engineering work."
   - Lane slice 1 (#484) lands first.
   - Slice 2 and later capability builds wait for the revisit.
   - On 11-07 he added that the capability plane gets its own design later: "It's a part that we're going to design later ... Again, this is still a trust plane redesign."
2. **Felix becomes infrastructure (11-06).** "At the scale that we're running right now, come on, I cannot live off of a local tool."
   - The authority that approves landing runs hosted, off the developer's machine.
   - felix-home moves to the Daimonion org later, after the IP assignment: "at the end, Felix, well, in the future, move to Daimonion". No date is set, and the repository does not move without his go-ahead.
3. **The same machine rigor for every change (11-06).**
   - He rejected giving a task less rigor because it is simple, calling that a "circular argument that, because a task is simple, we are expecting and anticipating less engineering rigor ... We should not go easy on this". In his words, "Same machine rigor should be the baseline anyway".
   - He also rejected buying rigor with process: "Rigor is currently bought with process. And that is terrible." The aim: "Always find the smartest algorithm, right? Not find the longest, not the hardest, the smartest algorithm."
4. **Designs answer to directions, and the directions are an open list (11-06).** So far: speed, accuracy, efficiency, security, commercial viability and autonomy. "When I list several things, that does not mean that it's everything. I'm just giving you a direction ... Everything I say is a direction."
   - **Limits:** designs stay within the token and compute budgets real users have: "not everyone has like infinite amount of tokens for like a parallel 100 workers check ... Keep the human constraint in mind".
   - **Latency:** no design may put it at risk: "we should not have even thought about the idea of a 21.5 hours check".
   - **Commercial viability:** "Why would they be using a product that would spike their API keys by 20%? While also paying me the fee."
5. **Open sets stay open (11-07).** An example he gives illustrates a set and is not the set: "there's a reason why every time when I talk with you, I kept saying et cetera, and I kept saying things like this is only an example. Because I don't want you to finalize things."
   - Rate limiting was "the obvious meme factor", while "engineering complexity is a lot more than rate limiting".
   - A count is not the space either: "Just because in one of our project ... we had 22 does that mean everything?"
   - This holds for specs, designs, direction, pitches and memory: "this is a persistent pattern in how you settle things, write specs, give directions. Make pitches, etc. And I don't want to see this pattern again."
6. **Everything serves the product, and direction holds the newest decisions (11-07).** "Everything serves for the sake of the product."
   - Designs are judged against what Felix is, meaning direction §1 and the pitch where it still agrees with direction. They are not judged against a new thesis.
   - Earlier pitch material that no longer fits current direction is set aside: "If you think that doesn't sound right to our current direction, don't take that into account."
   - "direction markdown should always be updated. It should always contain our newest decision. And let's keep it that way."

**Still open:**
- **Landing versus release.** Should landing and releasing be separate, with release only after deep checks pass? "I cannot answer question two to you yet ... We have to run that perhaps natively."
- **The language.** Row 6 (the engine stays bash, rows first) stands. The 11-06 re-measure reopened the question, and design draft 3 places a Rust spike before it is asked.
- **The trust-plane design itself.** Draft 3 is with the founder and an external reviewer. Nothing in it is decided.
