# Ridge Runner 🥕⛏️

A tiny idle/incremental game about shanking zombie wolves with carrots, and hoarding gold like a very determined goblin.

![Demo](./demo.gif)
![Cart](/ridgerunner.p8.png)

## About

Watch your little bun auto-battle through endless waves, or take a break from fighting to bonk rocks in the mines. Hire miners to make money while you do literally nothing. Upgrade your stats until the numbers get silly, then prestige and do it all over again.

How far can you run the ridge?

## Features

- Auto-battling bunny warrior
- Mining minigame with destructible blocks
- Hire miners for passive income
- Prestige system for endless replayability
- 3 save slots
- Chill parallax mountain vibes

## Play

You can play Ridge Runner on [itch.io](https://coldglassomilk.itch.io/ridge-runner) the [Lexaloffle BBS](https://www.lexaloffle.com/bbs/?tid=153735) or download the cart and run it in PICO-8.

## A Personal Milestone

This is my first completed game. I've spent 20 years fascinated by game development — reading, learning, tinkering — without ever actually finishing something. This little cart is me finally breaking that cycle. It's not going to blow anyone's mind, but it's done, it's mine, and I'm proud of it.

My goal was simply to complete something, and I did. Hoping to keep making these little games and getting better with each one.

## Technical Notes

Running at exactly 8192/8192 tokens — every byte accounted for. Under the hood:

- Scene manager with push/pop overlays
- State machine for managing game states
- Input context stacking
- Tweening system with multiple easing functions
- Bignum support for exponential gold scaling
- Flexible menu system with nested submenus
- Save/load system with 3 persistent slots

Built as a reusable foundation — feel free to poke around and use any of these systems for your own projects.

## File Structure

```
├── ridgerunner.p8           # main cartridge
└── src/
    ├── main.lua             # entry point
    ├── common/
    │   └── mountains.lua    # parallax background
    ├── system/
    │   ├── app.lua          # app configuration
    │   ├── bignum.lua       # large number handling
    │   ├── input.lua        # input management
    │   ├── menu.lua         # menu system
    │   ├── message_bus.lua  # event system
    │   ├── scene.lua        # scene management
    │   ├── slot.lua         # save/load system
    │   ├── state.lua        # state machine
    │   └── tween.lua        # animation tweening
    └── scenes/
        ├── gamescene.lua    # main battle/upgrade loop
        ├── minescene.lua    # mining minigame
        ├── prestigescene.lua# prestige confirmation
        └── titlescene.lua   # title screen & menus
```

## License

Released under the MIT Open Source License.

## Feedback

If you spot token optimizations I missed, let me know. Might squeeze in a few more features if this little bun finds an audience. 🐰
