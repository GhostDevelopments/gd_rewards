# Daily Character Rewards

A Qbox / ox_inventory daily reward menu with separate male and female collections. Each eligible character can claim items from their collection once every 24 hours. Claims are persisted by citizen ID in MySQL.

## Configuration

Edit `config.lua` to change:

- Commands and cooldown duration
- Reward labels, descriptions, item names, and amounts
- Item image URLs (the defaults use ox_inventory images)
- Male and female reward collections

The configured item names must exist in ox_inventory. For custom images, replace an item's `image` value with a valid NUI or web image URL.

## Commands

- `/malerewards` opens the male collection for characters with gender `0`.
- `/femalerewards` opens the female collection for characters with gender `1`.

The server validates gender, inventory capacity, item selection, and cooldown; client values are not trusted.
