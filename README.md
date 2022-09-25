# FastLove

Automatic texture atlas creation and spritebatch renderer, outperforming the inbuilt spritebatches.
It also supports viewport transforms.

Requires JIT, else it will perform bad. Like, really bad.

# Usage

```lua
--create renderer with a 512^2 canvas
local fastLove = require("fastLove")(512)

--draw a (static) texture (a canvas for example works, but will be rendered only once)
fastLove:add(texture, x, y, rot, sx, sy, ox, oy, sx, sy)

--full support for quads
fastLove:addQuad(texture, quad, x, y, rot, sx, sy, ox, oy, sx, sy)

--support for transformation, affects all newly added sprites
fastLove:origin()
fastLove:translate(x, y)
fastLove:scale(x, y)
fastLove:rotate(rot)

--don't forget to clear
fastLove:clear()

--resetting clears the atlas, useful on scene switch, or window mode change
fastLove:reset()

--manually embed a new sprite in the atlas (will be called automatically in draw)
fastLove:getSprite(texture)
```

# Benchmarks

Results massively depends on the scene, amount of transformations, screen coverage etc. But here are the results from the included ships example with 3000 ships:

* Love2d simple draw calls: `22 FPS`
* Love2d spritebatch: `175 FPS`
* FastLove: `362 FPS`

# Known issues

When changing the window mode or fullscreen, contents of canvases are cleared. That means, fastLoves canvas is also gone. Call `reset()` to fix.

# Credits

Example scene provided by chabull  
CC BY 3.0  
https://opengameart.org/content/ships-with-ripple-effect