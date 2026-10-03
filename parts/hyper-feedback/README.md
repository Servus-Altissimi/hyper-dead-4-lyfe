# Hyper Feedback

The HUD. The server hides the stock survivor panels and draws its own through a per-player channel: it sets each client's `name2` cvar through `point_clientcommand`, and materials in `resource/ui/hud/itempickup.res` decode it with proxies.

- Message = tag * 1e6 + payload; at most 20 messages a second per client, all tags in one queue. Tags carry hit marks, damage arcs, stamina and HYPER, the boss bar, break free progress, cues, the kill feed, health digits, the live chain, the campaign stats, the team and Fort's scrap, cost and wave rows.
- The look: amber 255 176 60, bone 225 215 195, blood 215 45 35, Poppins Bold, no text.
- Fort modes (`hd4lfort`, `hd4lfreebuild`) look stock: stock panels, crosshair and kill feed; only Fort's scrap, cost and wave rows are drawn. The dot crosshair shows only when tag 1 carries its bit.
- `python3 -m tools assets hud` regenerates the textures, panel materials, `itempickup.res` and `clientscheme.res` (`tools/assets/hud/`); `art/hud` holds the HUD shapes as SVGs drawn in screen space (1024x512; states toggle by element id) and `art/icons` the icons.

**Modes:** `hd4l`, `hd4lversus`, `hd4lsurvival`, `hd4lfort`, `hd4lfreebuild`

**Code:** `addon/scripts/vscripts/hyper_feedback.nut`. Knobs sit at the top of each script.
