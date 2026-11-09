# Semantic colors

The color catalog follows the Semantic Tokens tables in the base repository's
`14 DESIGNmd/DESIGN.md`. Asset names keep the project's `color-` prefix, use
lowercase, and replace spaces with hyphens (for example, `Blue1` becomes
`color-blue1` and `05 MA - 0005` becomes `color-05-ma-0005`). Use the named
semantic asset for its role, even when another role currently has the same RGBA
value. The catalog stores the resolved light and dark values, including
opacity; no separate primitive palette is needed.

These older assets retain their original values for existing screens:

| Existing asset | DESIGN.md equivalent for new uses |
| --- | --- |
| `color-brand-blue-2` | `color-blue2` |
| `color-text-60` | `color-text2` |
| `color-legacy-dialog` | `color-dialog` |
| `color-legacy-transparent` | `color-transparent` |

Use `MarketColor.resolve` for red/green colors that follow the market direction
preference. The alternate demo pairs stay separate: `color-utility2-red` has
the same color as `color-red`, but swaps with `color-utility2-green`.
