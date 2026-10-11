# Decisions:

Write Minimal Code, NEVER design ahead
- If something can be done with a variable, don't introduce a new module
- Code can be changed so frequently, that designing a module can be a waste of time.
- I don't need sophisticated code at the first run. I want it to start running immediately.
- I only redesign interfaces when I'm annoyed by the code, which indicates, something is unlikely to change anymore. Before that, keep things ugly.

Composition Over Inheritence
- prefering A has B over A is B
- do inheritence only when it is unavoidable
