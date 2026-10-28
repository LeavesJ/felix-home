When agents made typing free, they exposed something about engineering that was always true.

Karpathy coined "vibe coding" for building without really looking at the code. Boris Cherny, who leads Claude Code, says Claude wrote every line of the 259 pull requests he landed in one month. The same kind of model is behind a weekend toy and behind a codebase a lot of people depend on. So the difference between vibe coding and engineering can't be who types. I think it's what the work is held to.

Vibe coding holds code to the prompt and to whatever a run shows. Engineering holds it to more:
• everything the change owes, including what nobody asked for
• a check written by someone other than the author, and seen to fail
• a record that outlives the session, so the next change answers to the same standard
• a person who answers for the result for as long as anyone depends on it

The first is the hardest, and it's where I started. A model once shipped a deployment for me with every test green and no rate limiting. I hadn't noticed either. The same omission then got past my own first design for catching things like it, and past a checklist written by hand. A list written by anyone drops things. So what a project owes has to come from the project itself: what it exposes, what it depends on, and how mature it is, because a prototype and a production service owe very different things.

The second rules out the obvious shortcut, which is asking the model whether it's done. A model's verdict on its own work isn't evidence, since it shares the blind spot that produced the work. Models are good at proposing what might be owed and at narrowing a rule. The final say belongs to a check that runs the same way every time.

That's the theory behind Felix, which I'm building first on Claude Code. The split is easy to state: the person decides what gets built, and Felix owns how it gets held to engineering. Which model does the typing becomes a detail. Felix keeps the standing record of what each project owes, who checked it, and what is allowed to land.

It also changes what I measure. Pass rate is easy to raise by checking less. I count how often a person has to step in and do the tool's job.

What I'm least sure of is the edge of that first item. Some obligations fall into classes a machine can recognize from a project's shape. Others belong to no class, and nobody states them until they bite. I don't know yet how much of engineering lives in the second group, or whether anything but a person with a stake can find it.

If you build with agents or review their work, I'd like to hear where you'd draw that line.
