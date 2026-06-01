# Design System Strategy: The Clinical Sanctuary

## 1. Overview & Creative North Star
The objective of this design system is to transcend the generic "medical app" aesthetic. We are moving away from the cold, sterile grids of legacy healthcare software toward a concept we call **"The Clinical Sanctuary."** 

This Creative North Star balances the clinical authority of a high-end medical institution with the restorative serenity of a wellness retreat. We achieve this through an **Editorial Layout Engine**: using dramatic typographic scales, intentional white space (negative space as a functional element), and a "paper-on-glass" layering logic. By prioritizing breathability and tonal depth over rigid lines, we create an environment that feels premium, trustworthy, and accessible—particularly for users who require high legibility and a low cognitive load.

---

## 2. Colors & Chromatic Logic
Our palette is rooted in the psychology of trust and vitality. We utilize a sophisticated range of blues and greens, layered to guide the eye without overstimulating the user.

### The "No-Line" Rule
To maintain a high-end editorial feel, **1px solid borders are prohibited for sectioning.** Boundaries between content blocks must be defined through:
1.  **Background Color Shifts:** Placing a `surface_container_low` card on a `surface` background.
2.  **Tonal Transitions:** Using the hierarchy of `surface_container` tokens to define containment.

### Surface Hierarchy & Nesting
Treat the UI as physical layers. Depth is achieved by "nesting" containers:
*   **Base:** `surface` (#f6fafe) — The primary canvas.
*   **Lower Tier:** `surface_container_low` — Used for subtle grouping of secondary information.
*   **Active Tier:** `surface_container_lowest` (#ffffff) — Reserved for primary interactive cards to provide the most "lift" and "crispness."

### The "Glass & Gradient" Rule
To inject "soul" into the professional interface:
*   **Glassmorphism:** For persistent elements like navigation bars or floating action headers, use `surface_container_lowest` with a 70% opacity and a `24px` backdrop blur.
*   **Signature Gradients:** Primary CTAs should utilize a subtle linear gradient from `primary` (#00468b) to `primary_container` (#005db6) at a 135-degree angle. This prevents the "flat" look and adds a sense of tactile premium quality.

---

## 3. Typography
We use a dual-typeface system to bridge the gap between "Professional Authority" and "Modern Wellness."

*   **Display & Headlines (Manrope):** This is our "Editorial" voice. Manrope’s geometric yet open character provides a modern, high-end feel. Use `display-lg` and `headline-lg` with tight letter-spacing (-2%) to create an authoritative, branded presence.
*   **Body & Titles (Inter):** Our "Functional" voice. Inter is chosen for its exceptional readability at small sizes and high x-height, which is critical for elderly users. 
*   **Hierarchy as Navigation:** Use the scale to lead the user. A `display-sm` headline should clearly anchor a page, while `label-md` in `on_surface_variant` is used for metadata to keep the interface decluttered.

---

## 4. Elevation & Depth: Tonal Layering
Traditional drop shadows are often messy. In this system, we use **Ambient Elevation.**

*   **The Layering Principle:** Depth is a result of stacking. A `surface_container_lowest` card sitting on a `surface_container_low` background creates a natural, soft separation.
*   **Ambient Shadows:** For elements that truly "float" (like modals), use a custom shadow: `Y: 12px, Blur: 40px, Color: on_surface @ 6%`. The shadow must be tinted with the `on_surface` color to ensure it looks like a natural occlusion of light rather than a grey smudge.
*   **The "Ghost Border" Fallback:** If accessibility requires a stroke (e.g., in high-contrast situations), use a "Ghost Border": `outline_variant` at 20% opacity. Never use a 100% opaque border.

---

## 5. Components

### Buttons
*   **Primary:** `primary` background with `on_primary` text. Use `rounded-xl` (1.5rem) to evoke a friendly, touch-safe feel.
*   **Secondary:** `secondary_container` background with `on_secondary_container` text. This provides a soft, "vitality" green pop for wellness-related actions.
*   **States:** On hover/tap, apply a 10% `on_surface` overlay rather than changing the base color.

### Input Fields
*   **Structure:** Avoid boxes. Use a `surface_container_low` background with a `rounded-md` corner. 
*   **Interaction:** The field should only show an `outline` when focused, using the `primary` color at 2px thickness to provide clear feedback for users with visual impairments.

### Cards & Lists
*   **Forbid Dividers:** Horizontal lines are replaced by vertical whitespace (1.5rem to 2rem). 
*   **List Item:** Use `surface_container_low` for the list item container. Use `secondary` for leading icons to signify "Health/Vitality."

### Health Trackers (Context Specific)
*   **Data Visualization:** Use `secondary` (#106d20) for "healthy/target" ranges and `tertiary` (#733500) for "warning/attention" states. This earthy tertiary tone feels urgent but less "alarming" than a bright red, maintaining the sanctuary feel.

---

## 6. Do's and Don'ts

### Do
*   **Do** use `surface_bright` for large, airy backgrounds to evoke the "crisp white" vitality requested.
*   **Do** prioritize "Over-sized" touch targets (minimum 48dp) to support elderly accessibility.
*   **Do** use asymmetrical layouts (e.g., a headline aligned left with a large margin-right) to break the "template" look.

### Don't
*   **Don't** use pure black (#000000). Use `on_surface` (#171c1f) for all "black" text to maintain a softer, premium contrast.
*   **Don't** use standard `0.5rem` spacing for everything. Embrace the Spacing Scale—use `xl` (1.5rem) and `2xl` (2rem) for section breathing room.
*   **Don't** use harsh transitions. All state changes (Light to Dark mode, or Button hover) must have a minimum 200ms ease-in-out transition.

### Dark Mode Note
In Dark Mode, the `surface` tokens will automatically invert. Ensure that the "Paper-on-Glass" hierarchy remains: the "highest" containers should be the lightest shades of grey/blue to maintain the illusion of being "closer" to the user.