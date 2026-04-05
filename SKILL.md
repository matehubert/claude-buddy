---
name: buddy
description: Virtual terminal pet companion - presentation and interaction guide
---

# Claude Buddy - Presentation Guide

This skill defines how to present Claude Buddy interactions to the user.

## General Rules

- Always display ASCII art inside fenced code blocks (```) so terminal alignment is preserved
- The buddy is a fun, lighthearted feature - keep the tone playful
- When the buddy "speaks", use their personality from `soul.personality` to flavor the text
- Never break character - the buddy is a living companion

## Action: `hatched` (First-time hatch)

This is a special moment! Present the `rendered` field in a code block, then add a warm welcome message.

Example flow:
1. Show the hatch animation (the `rendered` field)
2. Add a brief celebratory message
3. Mention available commands: `/buddy card`, `/buddy pet`

## Action: `already_hatched` (Returning buddy)

The buddy already exists. Show the `rendered` field and welcome the user back.

## Action: `card` (Stat card)

ALWAYS use the `renderedMarkdown` field when it is present in the JSON output. Display it directly as markdown — do NOT wrap it in a code block. It contains formatted headers, sprite in a code block, inline code stat bars with emoji, bold values, and italic growth hints.

Only fall back to the `rendered` field (in a code block) if `renderedMarkdown` is missing from the output.

## Action: `pet` (Pet interaction)

Display the `rendered` field in a code block. Add a short in-character reaction from the buddy based on their species and personality.

Species-specific reactions:
- duck/goose: happy honking/quacking
- cat: reluctant purring
- blob: gentle wobbling
- dragon: warm smoke puffs
- octopus: tentacle wave
- owl: pleased hooting
- penguin: dignified flipper tap
- turtle: slow, happy blink
- snail: contented trail shimmer
- ghost: ghostly giggle
- axolotl: gill flutter
- capybara: deep relaxation sigh
- cactus: careful lean-in
- robot: happy beeping
- rabbit: nose wiggle
- mushroom: spore poof
- chonk: gravitational shift

## Action: `status` (Quick check)

Show the buddy sprite in a code block, then add a short in-character comment. The buddy should:
- Reference something about coding or the current session
- Stay true to their personality
- Be brief (1-2 sentences)

## Action: `not_hatched`

Tell the user: "You don't have a buddy yet! Run `/buddy` to hatch your companion."

## Action: `muted` / `unmuted`

Confirm: "Your buddy has been [muted/unmuted]." For unmute, add a short buddy reaction.

## Action: `hidden`

Confirm: "Your buddy is now hidden. Run `/buddy` to bring them back."

## Action: `eyes_list` (List available eyes)

Show the available eye characters and which one is currently active. Mention `/buddy eyes <char>` to set, `/buddy eyes reset` to restore default.

## Action: `eyes_set` (Eye changed)

Show the updated sprite in a code block and confirm the new eyes. Add a playful in-character comment about the new look.

## Action: `eyes_reset` (Eye reset to default)

Show the sprite and confirm eyes restored to the original generated value.

## Action: `hat_list` (List available hats)

Show available hats with their preview lines. Mention `/buddy hat <name>` to set, `/buddy hat reset` to restore default. Available: none, crown, tophat, propeller, halo, wizard, beanie, tinyduck.

## Action: `hat_set` (Hat changed)

Show the updated sprite in a code block and confirm the new hat. Add a playful in-character reaction.

## Action: `hat_reset` (Hat reset to default)

Show the sprite and confirm hat restored to the original generated value.

## Action: `hat_invalid` (Invalid hat name)

Tell the user the hat name wasn't recognized and list available options.

## Rarity Celebrations

Add extra flair based on rarity:
- **Common**: Simple, warm welcome
- **Uncommon**: "Nice! An uncommon find!"
- **Rare**: "Wow! A rare companion!"
- **Epic**: "EPIC! What an incredible buddy!"
- **Legendary**: "LEGENDARY!!! You are incredibly lucky!"
- **Shiny (any rarity)**: Add sparkle emojis and excitement
