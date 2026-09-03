# NIGHTSPLIT

Roblox co-op survival prototype built with Rojo.

## Current prototype

- Smooth walk/sprint acceleration
- Stamina drain, exhaustion, regen, and minimal HUD
- Contextual crouch/slide action
- Physical crouch via HipHeight lowering plus overhead clearance check
- Sprint-to-slide momentum with smooth deceleration
- Camera height/FOV feedback
- Keyboard, controller, and mobile ContextActionService bindings
- Hooks for custom crouch and slide animations

## Default controls

### Keyboard / mouse
- Sprint: Left Shift
- Crouch: C or Left Control
- Slide: C or Left Control while sprinting

### Controller
- Sprint: L3
- Crouch/Slide: B / Circle

### Mobile
- Sprint and Crouch/Slide touch buttons are generated automatically.

## Animation setup

A truly visible crouch/slide stance requires Roblox animation assets. Set these in `src/shared/MovementConfig.lua` after uploading R15 animations:

```lua
Config.CrouchAnimationId = 1234567890
Config.SlideAnimationId = 1234567890
```

Until those IDs are supplied, the controller still changes physical height, camera height, movement speed, and slide physics, but it cannot invent a custom limb pose.

## Rojo

From the repository folder:

```bash
rojo serve
```

Then connect the Rojo Studio plugin to the local server and sync the project into Roblox Studio.
