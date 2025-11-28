# Design System

## Philosophy
Modern, flat, clean. No gradients except on homepage, shadows should be very subtle or none. Let whitespace breathe. Use color sparingly but intentionally.

## Colors
- **Base/Neutral**: Use for backgrounds, text, borders (grays, slate)
- **Primary**: Main actions, CTAs, links (use sparingly for impact)
- **Secondary**: Supporting actions
- **Accent**: Highlights, badges, notifications (use sparingly)

Keep the UI mostly neutral. Color should draw attention, not overwhelm.

## Buttons & Interactive Elements
- **Fully rounded** (pill-shaped): `rounded-full`
- Semibold font weight: `font-semibold`
- Flat design, no shadows or gradients
- Subtle hover: darken with `hover:brightness-90` or background shade change. No jumping effect on hover.
- Icon buttons: square with rounded corners, use when action is clear (edit, delete, copy)
- **Always add `cursor-pointer`** to clickable elements (buttons, icon buttons, clickable divs)

## Cards
- Rounded corners: `rounded-2xl`
- Subtle gray border or very light shadow: `border border-base-200`
- Consistent padding: `p-4`
- No heavy shadows

## Typography
- Limited font weights: regular (400), medium (500), semibold (600)
- Don't over-bold things

## Spacing
- Consistent scale (4, 8, 12, 16, 24, 32, 48)
- Let sections breathe
- Don't cram elements together

## Icons
- Consistent stroke width
- Use raw SVG
- Size: 20px (w-5 h-5) for inline, 24px (w-6 h-6) for standalone

## Don'ts
- No gradients except on homepage
- No heavy drop shadows
- No animations beyond subtle hovers/transitions
- No rounded-md buttons (either square-ish or fully round)
- Don't use primary color for everything

---

## Components

### Tabs (Segmented Control / Pill Tabs)

A pill-shaped segmented navigation - a row of rounded links inside a gray pill container. The active tab "pops" with a white background and subtle shadow, creating a floating card effect. Clean, minimal, iOS-inspired.

**Example:**
```erb
<div class="inline-flex bg-base-200 rounded-full p-1">
  <%= link_to "Active", "#", class: "px-6 py-3 text-sm font-medium rounded-full text-center transition-all bg-white text-base-content shadow-sm" %>
  <%= link_to "Inactive", "#", class: "px-6 py-3 text-sm font-medium rounded-full text-center transition-all text-base-content/70 hover:text-base-content" %>
  <%= link_to "Inactive", "#", class: "px-6 py-3 text-sm font-medium rounded-full text-center transition-all text-base-content/70 hover:text-base-content" %>
</div>
```

### Buttons

**Primary** - filled, for CTAs and main actions.
```erb
<%= link_to "Sign up", "#", class: "px-4 py-2 text-sm font-semibold rounded-full bg-primary text-primary-content border-2 border-primary hover:brightness-90 transition-all" %>
```

**Secondary** - outline, for supporting actions.
```erb
<%= link_to "Log in", "#", class: "px-4 py-2 text-sm font-semibold rounded-full text-primary border-2 border-base-300 hover:border-base-400 hover:bg-base-200 transition-all" %>
```