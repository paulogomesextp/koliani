# Shadowblade Hero — Godot 4 asset

## Included

- `shadowblade_hero_atlas.png`: transparent PNG atlas, 8 columns × 128×160-pixel cells.
- `shadowblade_hero_frames.tres`: ready-made `SpriteFrames` resource for Godot 4.
- `hero_character.tscn` and `hero_character.gd`: a basic playable `CharacterBody2D` prefab and controller.

Animations: `idle` (4), `run` (6), `jump` (7), `attack` (6), `crouch` (3), `wall_slide` (3), and `double_jump` (5).

## Install

1. Copy every included file into the same `res://assets/` directory of your Godot project.
2. Select the PNG in the FileSystem dock and set **Filter = Nearest** and **Mipmaps = Off**, then reimport.
3. Drag `hero_character.tscn` into your level (or instantiate it as a child scene). It uses the `ui_left`, `ui_right`, `ui_down`, and `ui_accept` inputs that Godot creates by default.
4. The controller supplies left/right movement, jump/double jump, crouch, and an attack trigger. Adjust the exported `speed`, `jump_velocity`, and `gravity` values from the Inspector to match your level.

The atlas came from the frames in the image supplied in this chat. It was separated from its dark concept-board backdrop; because the original was a rendered presentation image rather than source sprite pixels, inspect each frame in-game and touch up any edge pixels if you need production-perfect cleanup.
