# vis-restree

A small [vis](https://github.com/martanne/vis) plugin for [restree](https://github.com/kamil-koziol/restree).

Adds:

```text
:restree
:restree --jq
:restree --headers
:restree --jq --headers
```

The response is opened in a new vertical split. `--jq` formats the body with `jq`, while `--headers` shows the response headers.

## Setup

Load the plugin from your `visrc`:

```lua
require('vis-restree')
```

Optional keybindings:

```lua
vis:map(vis.modes.NORMAL, '\\rr', ':restree<Enter>')
vis:map(vis.modes.NORMAL, '\\rj', ':restree --jq<Enter>')
vis:map(vis.modes.NORMAL, '\\rh', ':restree --headers<Enter>')
vis:map(vis.modes.NORMAL, '\\ra', ':restree --jq --headers<Enter>')
```

Requires [`restree`](https://github.com/kamil-koziol/restree) and `jq` for `--jq`.

