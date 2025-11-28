# Design System

## Philosophy
Modern, flat, clean. No gradients except on homepage, shadows should be very subtle or none. Let whitespace breathe. Use color sparingly but intentionally.

## Tech Stack
- **Tailwind CSS v4** (via tailwindcss-rails 4.4.0)
- **DaisyUI v5** (Tailwind plugin for semantic color tokens)
- **OKLCH color format** for all custom colors

## Colors

### DaisyUI Base Tokens

Use DaisyUI base tokens for all neutral colors. This enables easy light/dark theme switching by only changing CSS custom properties in `application.css`.

**Surface colors** (DaisyUI built-in):
| Token | Role | Light theme |
|-------|------|-------------|
| `base-100` | Primary surface (cards, navbar, footer) | white |
| `base-200` | Page background, hover states | light gray |
| `base-300` | All borders and dividers | gray |
| `base-content` | Primary text | dark gray |

**Extended text scale** (defined in `application.css`):
| Token | Role | Usage |
|-------|------|-------|
| `base-400` | Very muted | Placeholders, timestamps, hints |
| `base-500` | Muted | Secondary text, icons, footer |
| `base-600` | Slightly muted | Form labels |
| `base-700` | — | Reserved |
| `base-800` | — | Reserved |
| `base-900` | — | Reserved |

### Semantic Colors

Use DaisyUI semantic tokens for branded/status colors:
| Token | Usage |
|-------|-------|
| `primary` / `primary-content` | Main actions, CTAs, links |
| `secondary` / `secondary-content` | Supporting actions |
| `accent` / `accent-content` | Highlights, badges |
| `error` / `error-content` | Errors, destructive actions |
| `warning` / `warning-content` | Warnings |
| `success` / `success-content` | Success states |

### Color Rules

1. **No hardcoded Tailwind colors** - Use base tokens, not `gray-500`, `white`, etc.
2. **No opacity modifiers** - Use the base scale instead
   - Bad: `text-base-content/70`
   - Good: `text-base-500`
3. **Error states**: `bg-base-200` + `border-error` + `text-error`
4. **Primary link hover**: Use `hover:brightness-75` not `hover:text-primary/80`

Keep the UI mostly neutral. Color should draw attention, not overwhelm.

---

## Components

### Buttons

**Primary** - filled, for main CTAs (Sign in, Create account, Submit)
```erb
<%= f.submit "Sign in", class: "w-full px-4 py-2.5 text-base font-semibold rounded-full bg-primary text-primary-content border-2 border-primary hover:brightness-90 transition-all cursor-pointer" %>
```

**Secondary** - outline, for supporting actions (Log in, Cancel)
```erb
<%= link_to "Log in", "#", class: "px-4 py-2 text-sm font-semibold rounded-full text-primary border-2 border-base-300 hover:border-base-400 transition-all cursor-pointer" %>
```

**Ghost** - text only, for tertiary actions (Log out)
```erb
<%= button_to "Log out", "#", class: "px-4 py-2 text-sm font-medium rounded-full text-base-500 hover:text-base-content hover:bg-base-200 transition-all cursor-pointer" %>
```

### Cards

```erb
<div class="bg-base-100 border border-base-300 rounded-2xl p-6 sm:p-8">
  <!-- content -->
</div>
```

- Rounded corners: `rounded-2xl`
- Padding: `p-6 sm:p-8` for forms (responsive), `p-4` for compact
- No shadows

### Form Inputs

```erb
<%= f.email_field :email,
    placeholder: "you@example.com",
    class: "w-full px-4 py-2.5 text-sm rounded-full border border-base-300 bg-base-100 text-base-content placeholder:text-base-400 focus:outline-none focus:border-primary focus:ring-1 focus:ring-primary transition-colors" %>
```

### Form Labels

```erb
<%= f.label :email, class: "block text-sm font-medium text-base-600 mb-1.5" %>
```

### Checkboxes

```erb
<%= f.check_box :remember_me, class: "checkbox checkbox-sm cursor-pointer" %>
```
- Keep neutral (no `checkbox-primary`)

### Links

**Primary link** (inline):
```erb
<%= link_to "Sign up", "#", class: "text-primary underline hover:brightness-75 transition-colors" %>
```

**Muted link** (footer, secondary nav):
```erb
<%= link_to "Help", "#", class: "text-sm text-base-500 hover:text-base-content transition-colors" %>
```

### Tabs (Segmented Control)

```erb
<div class="inline-flex bg-base-200 rounded-full p-1">
  <%= link_to "Active", "#", class: "px-6 py-3 text-sm font-medium rounded-full text-center transition-all bg-base-100 text-base-content shadow-sm" %>
  <%= link_to "Inactive", "#", class: "px-6 py-3 text-sm font-medium rounded-full text-center transition-all text-base-500 hover:text-base-content" %>
</div>
```

### Flash Messages

```erb
<div class="flex items-center gap-3 p-4 rounded-2xl bg-base-200 text-sm">
  <div class="w-8 h-8 rounded-full bg-base-100 flex items-center justify-center shrink-0">
    <svg class="w-5 h-5 text-success"><!-- icon --></svg>
  </div>
  <span class="flex-1 text-base-content"><%= notice %></span>
  <button class="text-base-400 hover:text-base-content transition-colors cursor-pointer">
    <!-- close icon -->
  </button>
</div>
```

### Error Messages

```erb
<div class="bg-base-200 border border-error rounded-2xl p-4">
  <div class="flex items-start gap-3">
    <svg class="w-5 h-5 text-error"><!-- icon --></svg>
    <div>
      <p class="text-sm font-medium text-error">Error title</p>
      <ul class="mt-2 text-sm text-error space-y-1">
        <li>Error message</li>
      </ul>
    </div>
  </div>
</div>
```

---

## Layout

### Page Structure
```erb
<body class="bg-base-200 text-base-content min-h-screen flex flex-col">
  <%= render "shared/navbar" %>
  <%= render "shared/flash" %>
  <main class="flex-1"><%= yield %></main>
  <%= render "shared/footer" %>
</body>
```

### Navbar / Footer
```erb
<nav class="bg-base-100 border-b border-base-300">
<footer class="bg-base-100 border-t border-base-300">
```

---

## Responsive / Mobile

Mobile-first approach using Tailwind breakpoints: `sm:` (640px), `md:` (768px), `lg:` (1024px).

### Breakpoint Reference
| Breakpoint | Min width | Usage |
|------------|-----------|-------|
| (default)  | 0px       | Mobile styles |
| `sm:`      | 640px     | Small tablets |
| `md:`      | 768px     | Tablets, hide mobile menu |
| `lg:`      | 1024px    | Desktop |

### Card Padding
Use responsive padding for form cards:
```erb
<div class="... p-6 sm:p-8">
```

### Flex Layouts
Stack on mobile, row on larger screens:
```erb
<div class="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
```

### Full-Width Buttons (Mobile)
Buttons that should be full-width on mobile only:
```erb
<button class="w-full sm:w-auto ...">
```

### Dropdowns
Use responsive width for dropdowns that might overflow on mobile:
```erb
<div class="dropdown-content w-[calc(100vw-2rem)] sm:w-80 max-w-80">
```

### Mobile Navigation
- Desktop nav: `hidden md:flex`
- Burger button: `md:hidden`
- Burger menu positioned below navbar: `top: 4rem` in CSS
- Burger menu max-width: `max-width: calc(100vw - 1rem)`

### Container Padding
Page containers should have horizontal padding:
```erb
<div class="px-4 sm:px-6 lg:px-8">
```

---

## Rules

### Do
- Use `rounded-full` for buttons and inputs
- Use `rounded-2xl` for cards
- Use `cursor-pointer` on all clickable elements
- Use `transition-all` or `transition-colors` for hover effects
- Use `hover:brightness-90` for primary button hover
- Use `hover:bg-base-200` for secondary/ghost hover

### Don't
- No gradients (except homepage)
- No heavy drop shadows
- No opacity modifiers (`/70`, `/50`, etc.)
- No hardcoded colors (`gray-500`, `white`, `red-600`)
- No `rounded-md` buttons (use `rounded-full`)
- No animations beyond subtle transitions
- Don't overuse primary color

---

## Typography

- **Headings**: `text-base-content`, `font-semibold`
- **Body**: `text-base-content`
- **Secondary**: `text-base-500`
- **Labels**: `text-base-600`, `font-medium`
- **Hints/Placeholders**: `text-base-400`

Font weights: regular (400), medium (500), semibold (600). Don't over-bold.

## Icons

- Use raw inline SVG (Heroicons is usually good)
- Consistent stroke width: `stroke-width="1.5"` or `stroke-width="2"`
- Size: `w-5 h-5` for inline, `w-6 h-6` for standalone
- Color: inherit from parent or use `text-base-500`
