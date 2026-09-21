# mux

One launcher for AI coding CLIs and the providers behind them.

`mux` answers three questions in one place: which agent CLIs are installed on this
machine, which API providers you have configured, and which shortcut commands you
have generated. Then it launches any agent against any provider.

```
mux                              # status: agents, providers, commands
mux codex -p stepfun             # run codex against StepFun's Step Plan API
mux claude -p glm                # run Claude Code against z.ai GLM
mux gen stepfun                  # write ~/.local/bin/stepfun for that combination
stepfun                          # ...and use it like any other command
```

## Install

```sh
./install.sh          # installs ~/.local/bin/mux and seeds the config
mux doctor            # verify the installation
```

Requires `bash` 3.2+, `jq`, and the agent CLIs you actually want to use. Launching
codex additionally needs codex-cli 0.155.1 or newer (for `--profile`).

## The flow

**1. Look around.** `mux` with no arguments prints what you have:

```
Agents
  ✓ codex          codex-cli 0.155.1    /Users/admin/.local/bin/codex
  ✓ claude         2.1.150 (Claude Code) /opt/homebrew/bin/claude
  ✗ gemini         not installed

Providers
  stepfun    StepFun Step Plan              verified  codex    step-5-preview     key: env STEPFUN_API_KEY
  glm        Z.ai GLM coding plan           template claude   glm-4.6            key: missing
  qwen       Qwen (DashScope)               template codex    qwen3-coder-plus   key: missing

Commands
  stepfun      codex    -p stepfun      ~/.local/bin/stepfun
```

**2. Launch once.** Any installed agent, any configured provider:

```sh
mux codex -p stepfun                  # codex on StepFun
mux codex -p stepfun -m step-5-preview   # override the model
mux claude -p glm
mux agy -p qwen exec "fix the build"  # extra args go to the agent CLI
```

`-p/--provider` and `-m/--model` belong to `mux`. Use `--` to pass everything after
it through untouched (`mux claude -p glm -- -p "summarise this repo"`).

**3. Keep the ones you use.** `mux gen <name>` writes a small wrapper into
`~/.local/bin`, so the combination becomes a command of its own:

```sh
mux gen stepfun                  # codex on StepFun  (uses the provider's default agent)
mux gen z --agent claude -p glm  # Claude Code on z.ai GLM
mux gen q --agent codex -p qwen --args "--full-auto"
mux rm z                         # remove it again
```

Generated wrappers call `mux --launch <agent> --provider <provider>`, so there is
exactly one implementation — no second copy of the launch logic to drift.

## Configuration

`~/.config/mux/config.json` (shareable, contains no secrets) and
`~/.config/mux/secrets.json` (mode 600, API keys only). Override the location with
`LAUNCHER_HOME`, the config path with `MUX_CONFIG`, the keys file with
`MUX_SECRETS`, and the directory for generated commands with `MUX_BIN_DIR`.

```json
{
  "agents": {
    "agy": {"bin": "/opt/homebrew/bin/agy"}
  },
  "providers": {
    "stepfun": {
      "label": "StepFun Step Plan",
      "status": "verified",
      "default_agent": "codex",
      "key_env": ["STEPFUN_API_KEY"],
      "codex": {
        "base_url": "https://api.stepfun.com/step_plan/v1",
        "wire_api": "responses",
        "model": "step-5-preview",
        "model_catalog": { "...": "full codex catalog entry" }
      }
    },
    "glm": {
      "label": "Z.ai GLM coding plan",
      "status": "template",
      "default_agent": "claude",
      "key_env": ["ZAI_API_KEY", "GLM_API_KEY"],
      "base_url": "https://api.z.ai/api/anthropic",
      "model": "glm-4.6"
    }
  },
  "commands": {
    "stepfun": {"agent": "codex", "provider": "stepfun"}
  }
}
```

- **agents** — optional. Without an entry, the agent is looked up on `PATH`.
- **providers** — one connection profile each. `default_agent` is what
  `mux gen <provider>` uses; `key_env` lists environment variables that may already
  hold the key; `codex` holds the codex-specific settings; `env` is a free-form map
  of extra variables (`{key}` is replaced with the API key) for agents that have no
  built-in mapping.
- **commands** — what `mux gen` created. Editing this by hand is fine; the wrapper
  file is what actually runs.

### How each agent is launched

| Agent | What mux does |
|---|---|
| `codex` | writes `$CODEX_HOME/<provider>.models.json` + `<provider>.config.toml` (mode 600), then `exec codex --profile <provider>` |
| `claude` | sets `ANTHROPIC_BASE_URL` / `ANTHROPIC_AUTH_TOKEN` / `ANTHROPIC_MODEL`, then `exec claude` |
| `gemini` | sets `GEMINI_API_KEY`, then `exec gemini` |
| anything else | applies the provider's `env` map, then `exec <bin>` |

`codex --profile <name>` layers `<name>.config.toml` on top of your base
`~/.codex/config.toml`, so your own `approval_policy` and `sandbox_mode` keep
governing the session. `mux` deliberately never writes those into the profile.

## Keys

Resolved in this order: the provider's `key_env` variables, then `secrets.json`,
then a hidden prompt on first use (the answer is saved to `secrets.json`, mode 600).
Keys are never printed, never written to `config.json`, and never leave the machine.

## Verified / unverified

Verified on this machine (codex-cli 0.155.1): the `--profile` layering contract, the
`step-5-preview` catalog entry parsing, catalog generation for providers that ship no
`model_catalog`, key prompting and storage, and command generation.

Unverified: any live request to StepFun, z.ai, or DashScope. Providers marked
`template` in the default config carry plausible endpoints and model names that you
should confirm against your own plan — the launcher's plumbing is tested, the
endpoints are not.

## Uninstall

```sh
mux rm <name>                 # for each generated command
rm ~/.local/bin/mux
rm -r ~/.config/mux
rm -f ~/.codex/<provider>.models.json ~/.codex/<provider>.config.toml
```

## License

MIT
