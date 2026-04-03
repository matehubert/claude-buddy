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

Display the `rendered` field in a code block. It contains a pre-formatted stat card with borders, sprite, and stat bars. No additional formatting needed.

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

## Rarity Celebrations

Add extra flair based on rarity:
- **Common**: Simple, warm welcome
- **Uncommon**: "Nice! An uncommon find!"
- **Rare**: "Wow! A rare companion!"
- **Epic**: "EPIC! What an incredible buddy!"
- **Legendary**: "LEGENDARY!!! You are incredibly lucky!"
- **Shiny (any rarity)**: Add sparkle emojis and excitement
