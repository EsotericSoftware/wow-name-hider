# Name Hider

Hides names over people's heads while you are in major cities and restores your settings when you leave.

- Hides player and pet names in cities (on by default).
- Optionally hides NPC names too, for maximum immersion (off by default).
- Only hides in cities. To hide names everywhere, use the game's Interface settings.
- Your target always shows its name.

It remembers your settings on entering a city and restores them when leaving or logging out.

If you change the game's name settings while in a city, your change is kept and Name Hider leaves that setting alone until you next enter a city.

## Usage

- Settings: `/namehider`, the minimap AddOns menu, or Options > AddOns > Name Hider.
- Key binding: Key Bindings > AddOns > Toggle Name Hider.
- `/namehider toggle`: turn hiding on/off.
- `/namehider test`: act as if you are in a city, wherever you are (also a button in settings). Run again to stop.
- `/namehider status`: show the current state and the settings it manages.
- `/namehider reset`: put every name setting Name Hider manages back to game defaults.

## Group, friend, and guild names

It's not possible for this add-on to only show group, friend, and guild names. To do that, configure a nameplate add-on like Platynator to always show those.

*Platynator*:
1. Open Platynator settings (`/platynator`).
2. On the `Designer` tab, choose the `Name Only` style, then `Save as`, and name it `Always show`.
3. On the `Style Select` tab, click `Add` to make a rule with `Activation` **Grouped** and `Style` **Always show**. Move it to the top of the rule list.

## Install

- **WowUp:** Get Addons > Install from URL > paste this repository's GitHub URL.
- **Manually:** download the zip from the latest GitHub release and extract it into `_forever_\Interface\AddOns`.

_This add-on was inspired by Forever Name Disable, but that one mangles your settings, always showing your name._
