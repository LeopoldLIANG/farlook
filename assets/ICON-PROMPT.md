# 图标制作记录

日期：2026-10-26。工具：内置 image_gen，经生成与一次透明边缘修整。原始图稿为 PNG，应用用的 ICNS 由 `sips` 和 `iconutil` 生成。没有将源图绑定到工作区外的路径。

## Generation prompt

Use case: logo-brand. Create ONE polished square macOS app icon for FarLook (远眺一下), a lightweight screen-break reminder that asks the user to look into the distance. The mark combines a clear, simple eye silhouette with a serene distant horizon inside the eye; avoid a realistic eyeball. Friendly, quiet, precise; elegant native macOS icon treatment, restrained depth, crisp contours, subtle soft teal-to-deep-turquoise tile. Main eye/horizon mark in warm white and a small contrasting turquoise pupil/sun integrated into the horizon, legible at very small app-icon sizes. Centered rounded-square tile with balanced padding, transparent exterior around the tile, no detached drop shadow. Square composition, 1024x1024 desired. This is the final icon artwork itself, straight-on, not an app screenshot or device mockup. No text, letters, numerals, labels, watermark, badges, medical cross, extra objects, or multiple alternatives.

## Edge refinement prompt

Edit only the outer edge and transparency of this final macOS icon. Preserve the exact eye, horizon, colors, composition, tile position, shape, and contents. Remove all stray teal/cyan colored pixels and ragged debris above and around the rounded-square tile. Make its entire rounded-square outer silhouette smooth, perfectly clean and antialiased. Everything outside the smooth tile perimeter must be fully alpha-transparent. No glow, no detached shadow, no background, no other changes, no text.
