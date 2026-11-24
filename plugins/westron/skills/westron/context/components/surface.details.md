<!-- Generated from spec/components/surface/surface.spec.yaml by `tools/westron generate`. Do not edit: change the
source and generate again (decisions/0016). -->

# Surface: details

The prose of westron's contract for `surface`, for the cases its card (`surface.md`) does not settle. A reference such
as "decisions/0001" or "#120" here points into westron's repository: to the component's own decisions, westron's
decisions or an issue, none of which is in this bundle. Names such as `container.gap` are the contract's bindings of
westron's tokens, how WestronUI draws the component; a product never sets them.

## Accessibility

A surface adds no role, trait or label of its own: assistive technology reads its content as if the surface were not
there. Where a card is one thing to a screen reader, the product groups it, as it would without a surface.

## Behavior

raised is a card or a panel raised off the canvas, such as an open task card; dragged is what a drag carries, such as a
card lifted off its column; sunken is a well below the content, such as a board column. A surface has no padding of its
own: the product pads its content with a token, space.card for a card. It draws its role's radius, radius.card, with
continuous corners on Apple and circular ones elsewhere. A shape nested inside it keeps its own role's radius, except
one that sits within the surface's corner, closer to its edge than the surface's radius, which takes max(outer − inset,
4) so the two corners share a center; the product applies that rule where it nests such a shape, and the contract
computes no pair (design-language/04, "Nested corners share a center"). In the standard themes a raised or dragged
surface is set off from the canvas by its tone and, in light, by its shadow; dark draws no raised shadow, since the
surface is lighter than the canvas, and keeps the dragged one. outlined adds a hairline, color.border.default at
stroke.hairline, for a surface on a fill, where tone does not set it off (design-language/04, "Lines"). In the
high-contrast themes every raised or dragged surface draws a line in color.border.default at stroke.thin, whether or not
outlined is set, because a shadow alone does not mark an edge (decisions/0013); an outlined surface then draws that line
instead of its hairline. The bindings below cannot say this, since a case has no contrast key, so this description is
the contract for it. westron's shadow never goes on what the system draws itself, a sheet, a popover, a menu or glass,
and a surface never takes glass (design-language/04, "Shadows"; 09, "Liquid Glass"): it is the ground of content, and
glass is the layer of controls above it. The glass under a group of controls is the system's: a toolbar's or a bar's own
group, from OS 26, or the system's GlassEffectContainer that a product writes around floating Buttons, from OS 26 too; a
single control over content is a floating Button (decisions/0015). It has no states.

## On Apple

A view modifier on the content, .surface(.raised) or .surface(.sunken, outlined: true), rather than a container type: it
lays nothing out, so the product keeps its own stack and padding. SwiftUI's GroupBox is not the base: it is not
available on watchOS, so a style on it could not hold on every Apple OS, and it brings a padding and a label of its own.
The background is clipped to a continuous rounded rectangle of radius.card, the shadow is View.shadow(_:), which picks
the layers of the environment's theme, and the high-contrast line follows colorSchemeContrast. On watchOS a surface is
drawn as on the other OSes, always in the dark themes.
