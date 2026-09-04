# Request: survey the automations {{PROJECT}} implies

Written by `felix commission` for a session's model to act on. The engine
cannot run a skill (constitution invariant 2), so it writes this request and
reads back the answer file named at the end. Topology `{{TOPOLOGY}}`.

Run the skill:

    /claude-code-setup:claude-automation-recommender
    Project {{PROJECT}}, at {{ROOT}}. Felix already detected: {{CAPS}}
    Already declared, do not repeat these: {{DECLARED}}
    Recommend hooks, subagents, skills, plugins and MCP servers this stack
    implies that are not in that list. Read-only: Felix decides what to adopt.

Then write the answer file, exactly this shape, tab-separated, one row per
recommendation, at most forty rows:

    # topology {{TOPOLOGY}}
    <kind>	<name>	<source>	<capability>	<why>
    done	<count of rows above>

to:

    {{OUT}}

kind is one of plugin, mcp, hook, skill, subagent. name is the plugin or
server or skill name as the marketplace or registry spells it, no spaces.
source is a URL or `-`. capability is one of the capabilities Felix detected
or declared above, or `-`. why is one sentence. There is no risk column:
risk is not the model's to assign, and a row carrying one is malformed.

Nothing in this file is installed by being written here. A plugin row is
fetched at its pinned commit, read, tiered and corroborated by the engine
before anything is declared, and only a low tier installs; an mcp row is
never installed from a request; hook, skill and subagent rows are recorded
and reported, because Felix authors none of those.
