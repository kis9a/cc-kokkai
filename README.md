# cc-kokkai

A Vim plugin that simulates parliamentary debates using AI. Three AI sessions (ruling party, opposition, and speaker) engage in heated discussions on any given topic.

> A fun plugin built with [aistream.vim](https://github.com/kis9a/aistream.vim).  
> Not very practical — forcing "for/against" positions means the AI will defend even incorrect stances, resulting in sophistry.  
> [aistream.vim](https://github.com/kis9a/aistream.vim) を用いた遊びプラグイン  
> 実用性は低い、特に「賛成/反対」を強制すると、正しくない立場でも無理やり擁護するから詭弁になる所。

## Demo

![DEMO](./demo/demo.gif)

**:Kokkai -r 2 -pro "論調: 保守" -con "論調: 革新" -judge "派閥: 中立" "無人島に持って行くなら、たけのこの里 OR きのこの山"**

Three panes are automatically arranged, with the ruling party (for), opposition (against), and speaker debating round by round.

## Requirements

- Vim 8.0+ or Neovim 0.5+
- [aistream.vim](https://github.com/kis9a/aistream.vim) plugin
- Claude Code CLI

## Installation

Add with your plugin manager:

```vim
" vim-plug
Plug 'kis9a/cc-kokkai'
```

## Usage

### Commands

```vim
" Start a debate
:Kokkai {topic}

" With options
:Kokkai -r 5 -pro "Tetsuya" -con "Shibuya gal" Should breakfast be bread or rice?
```

### Flags

| Flag | Description |
|------|-------------|
| `-r N` | Number of rounds |
| `-pro PROMPT` | Custom prompt for the ruling party (persona, tone, constraints, etc.) |
| `-con PROMPT` | Custom prompt for the opposition |
| `-judge PROMPT` | Custom prompt for the speaker |

### Examples

```vim
" Custom characters for 4 rounds
:Kokkai -r 4 -pro "Old-school politician" -con "Gen-Z newcomer" -judge "Strict former judge" The right to stay in bed

" Custom prompts (freely specify output format, constraints, etc.)
:Kokkai -pro "List exactly 3 points in bullet form" -judge "Score logic, specificity, and persuasiveness out of 10 each" AI pros and cons

" Debate in English
:let g:cc_kokkai_lang = 'en'
:Kokkai -r 3 Tabs vs Spaces
```

### Functions

| Function | Description |
|----------|-------------|
| `cc_kokkai#start({args})` | Start a debate with an argument string (programmatic use) |
| `cc_kokkai#stop()` | Stop the debate |
| `cc_kokkai#status()` | Show current status |

## Configuration

```vim
let g:cc_kokkai_max_rounds = 3    " Default number of rounds
let g:cc_kokkai_lang = 'ja'       " Language ('ja' or 'en')
let g:cc_kokkai_model = ''        " Model for aistream.vim
let g:cc_kokkai_max_turns = 1     " Max turns per AI call
let g:cc_kokkai_poll_ms = 500     " Polling interval (ms)
let g:cc_kokkai_persona_pro = ''  " Default prompt for ruling party
let g:cc_kokkai_persona_con = ''  " Default prompt for opposition
let g:cc_kokkai_persona_judge = '' " Default prompt for speaker
```

## Layout

When a debate starts, a new tab with 3 panes is created. Each pane shows "Preparing..." until AI output arrives.

```
┌──────────┬──────────┐
│  Ruling  │ Oppos.   │
│  (For)   │ (Against)│
├──────────┴──────────┤
│      Speaker        │
└─────────────────────┘
```

## Debate Flow

1. The ruling party delivers an opening statement in favor
2. The opposition delivers a rebuttal against
3. The speaker summarizes the round
4. From round 2 onward, each side rebuts based on the other's arguments
5. After the final round, the speaker delivers a final verdict

Each session maintains conversation history, so the debate deepens as rounds progress.

## How It Works

Each session outputs to a separate buffer via `aistream#run()`. Sessions are linked by reading response text from buffers with `getbufline()` and embedding it into the next session's prompt. Completion detection uses timer polling (`get_state() == 'idle'`).

```
pro → (wait) → get response → con's prompt → (wait) → get response → judge → …
```

## License

MIT
