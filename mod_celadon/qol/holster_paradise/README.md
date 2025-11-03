# Holster Paradise (Celadon QoL Sub-module)

ID: CELADON_HOLSTER_PARADISE

Paradise 220-style holster system with hotkeys and intent-based weapon draw.

## Core Code Changes

- ADD `code/__DEFINES/keybinding.dm`: `COMSIG_KB_HUMAN_HOLSTER_DOWN`
- REMOVE `code/modules/clothing/under/accessories.dm`: holster types
- REMOVE `code/datums/components/storage/concrete/pockets.dm`: holster storage

## Overrides

- `/mob/living/carbon/human/Initialize()` - signal registration
- `/mob/living/carbon/human/Destroy()` - signal cleanup

## Author

Mirag1993, 2025-09-11
