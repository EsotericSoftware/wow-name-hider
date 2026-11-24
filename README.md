# Name Hider

A World of Warcraft: Forever add-on that hides names over people's heads while you are in a major city or sanctuary, and puts your name settings back exactly as they were when you leave.

- Hides player names, and pet/minion/guardian/totem names, in cities (both on by default).
- Optionally hides NPC and critter names too, for maximum immersion (off by default).
- Only acts in cities. To hide names everywhere, use the game's own Interface options.
- Your target always shows its name.

## Your settings are safe

Name Hider only borrows the game's own name settings while you are in a city:

- It remembers your settings on entering a city and restores them on leaving, on logout, and when you turn it off.
- If you change a name setting in the game's options while in a city, your change is kept and Name Hider leaves that setting alone until you next enter a city.
- Removing the add-on leaves your settings as you had them. The one exception is a game crash while in a city; run `/namehider reset` (or re-enter and leave a city) to fix that.

## Usage

- Settings: `/namehider`, the minimap AddOns menu, or Options > AddOns > Name Hider.
- Key binding: Key Bindings > AddOns > Toggle Name Hider.
- `/namehider toggle`: turn hiding on/off.
- `/namehider status`: show the current state and the settings it manages.
- `/namehider reset`: put every name setting Name Hider manages back to game defaults.

## Party members' names (Platynator)

The game has a single setting for all friendly player names, so Name Hider can't keep party members visible by itself. Every nameplate add-on asks the game whether to show a name. If you use Platynator, you can make it always show names of your group:

1. Open Platynator settings (`/platynator`).
2. Make a copy of the **Name Only** style, and in its name text untick **Show when WoW does**.
3. In style selection, add a rule with **Grouped** + **Cannot Attack** that uses your new style, and move it above the existing **Cannot Attack** rule.

## Coming from NameDisable

Disable or uninstall NameDisable first; both change the same settings. NameDisable could leave some settings changed (including forcing your own name on), so run `/namehider reset` once outside a city, then check Options > Interface > Names.

## Install

- **WowUp:** Get Addons > Install from URL > paste this repository's GitHub URL.
- **Manually:** download the zip from the latest GitHub release and extract it into `_forever_\Interface\AddOns`.
