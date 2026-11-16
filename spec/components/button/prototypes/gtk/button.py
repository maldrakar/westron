#!/usr/bin/env python3
"""Prototype (#26): westron's Button contract on stock GtkButtons with CSS classes, in GTK 4 and libadwaita.

Throwaway evidence for spec/components/button/decisions/0002-portability-to-web-and-gtk.md. The GTK library is
Rust (decisions/0002) and starts in phase 7; this file is not its start.

NOT RUN: GTK 4, libadwaita and PyGObject were not installed where it was written. It follows the GTK 4.24 and
libadwaita 1.10 documentation. It needs GTK 4.20 or later (media queries in CSS) and libadwaita 1.6 or later
(AdwSpinner). Run it from the repository root:

    python3 spec/components/button/prototypes/gtk/button.py              # a window with the matrix
    python3 spec/components/button/prototypes/gtk/button.py --dark       # the same in libadwaita's dark style
    python3 spec/components/button/prototypes/gtk/button.py --screenshot .build/button-prototype/gtk-light.png

--screenshot renders the window's content to a PNG from inside the program (Gtk.WidgetPaintable and the window's
renderer), so the capture does not depend on what is on screen, and quits.
"""

import sys
from pathlib import Path

import gi

gi.require_version("Gtk", "4.0")
gi.require_version("Adw", "1")
gi.require_version("Pango", "1.0")
from gi.repository import Adw, Gdk, GLib, GObject, Gtk, Pango  # noqa: E402

HERE = Path(__file__).resolve().parent

# The contract's variants and the role, as style classes. Each option maps to its own class; westron's CSS fixes the
# look of every combination, because the stock classes do not draw what the contract binds (button.css).
VARIANT_CLASS = {"primary": "suggested-action", "secondary": "westron-secondary", "tertiary": "flat"}
ROLE_CLASS = {"default": None, "destructive": "destructive-action"}


def westron_button(variant, role="default", size="m", label="Add list", icon=None, icon_only=False):
    """A stock Gtk.Button with westron's classes: what an extension trait would do in Rust."""
    button = Gtk.Button()
    button.add_css_class("westron")
    button.add_css_class(f"westron-{size}")
    button.add_css_class(VARIANT_CLASS[variant])
    if ROLE_CLASS[role]:
        button.add_css_class(ROLE_CLASS[role])
    if icon_only:
        # GtkButton adds .image-button itself. The label is the tooltip and the accessible name.
        button.set_icon_name(icon)
        button.add_css_class("westron-icon-only")
        button.set_tooltip_text(label)
        button.update_property([Gtk.AccessibleProperty.LABEL], [label])
    elif icon:
        # The icon is decorative beside a visible label; AdwButtonContent takes an icon name only.
        button.set_child(Adw.ButtonContent(icon_name=icon, label=label))
    else:
        button.set_label(label)
    button.westron = {"label": label, "icon": icon, "icon_only": icon_only, "loading": False, "resting": None}
    # A handler connected first refuses presses while loading, before any of the product's handlers run. Keyboard
    # activation emits the same signal. A button driven by a GAction would need the action left enabled: disabling
    # it makes the button insensitive, which dims it and announces it as unavailable.
    button.connect("clicked", _refuse_while_loading)
    return button


def _refuse_while_loading(button):
    if button.westron["loading"]:
        GObject.signal_stop_emission_by_name(button, "clicked")


def set_loading(button, loading):
    """GTK has no busy button. Loading takes a class, the accessible busy state, a spinner in the icon's place, and a
    layout that keeps the resting width."""
    state = button.westron
    if state["loading"] == loading:
        return
    state["loading"] = loading
    button.update_state([Gtk.AccessibleState.BUSY], [loading])
    if loading:
        button.add_css_class("westron-loading")
        # The resting content keeps sizing the button, invisible. The loading row (spinner, then the label unless
        # icon-only) is an overlay that GTK does not measure, so it gets the resting width and its label ellipsizes
        # (P13). AdwButtonContent takes an icon name only, so the spinner cannot go inside it.
        resting = button.get_child()
        state["resting"] = resting
        button.set_child(None)
        resting.set_opacity(0)
        row = Gtk.Box()
        row.add_css_class("westron-loading-content")
        row.set_halign(Gtk.Align.CENTER)
        row.append(Adw.Spinner())
        if not state["icon_only"]:
            row.append(Gtk.Label(label=state["label"], ellipsize=Pango.EllipsizeMode.END))
        overlay = Gtk.Overlay(child=resting)
        overlay.add_overlay(row)
        overlay.set_measure_overlay(row, False)
        button.set_child(overlay)
        # The visible text is now twice in the tree; the button's own label stays the accessible name.
        button.update_property([Gtk.AccessibleProperty.LABEL], [state["label"]])
    else:
        button.remove_css_class("westron-loading")
        overlay = button.get_child()
        resting = state["resting"]
        overlay.set_child(None)
        resting.set_opacity(1)
        button.set_child(resting)


ROWS = [
    ("primary", "default"),
    ("primary", "destructive"),
    ("secondary", "default"),
    ("secondary", "destructive"),
    ("tertiary", "default"),
    ("tertiary", "destructive"),
]


def labels(role):
    return ("Delete", "user-trash-symbolic") if role == "destructive" else ("Add list", "list-add-symbolic")


def triple(variant, role, size="m", configure=None):
    """Label only, icon + label, icon-only."""
    label, icon = labels(role)
    box = Gtk.Box(spacing=8)
    for button in (
        westron_button(variant, role, size, label),
        westron_button(variant, role, size, label, icon),
        westron_button(variant, role, size, "More", "view-more-symbolic", icon_only=True),
    ):
        if configure:
            configure(button)
        box.append(button)
    return box


def heading(text):
    label = Gtk.Label(label=text, xalign=0)
    label.add_css_class("heading")
    return label


def caption(text):
    label = Gtk.Label(label=text, xalign=0)
    label.add_css_class("dim-label")
    return label


def matrix():
    grid = Gtk.Grid(row_spacing=8, column_spacing=24)
    for column, size in enumerate(["s", "m", "l"], start=1):
        grid.attach(caption(size), column, 0, 1, 1)
    for row, (variant, role) in enumerate(ROWS, start=1):
        grid.attach(caption(f"{variant} / {role}"), 0, row, 1, 1)
        for column, size in enumerate(["s", "m", "l"], start=1):
            grid.attach(triple(variant, role, size), column, row, 1, 1)
    return grid


def states():
    """GTK can force the real state flags, so these are the real :hover, :active and :focus-visible."""

    def flags(value):
        return lambda b: b.set_state_flags(value, False)

    def disabled(b):
        b.set_sensitive(False)

    def disabled_hover(b):
        b.set_sensitive(False)
        b.set_state_flags(Gtk.StateFlags.PRELIGHT, False)

    def loading_pressed(b):
        b.set_state_flags(Gtk.StateFlags.ACTIVE, False)

    columns = [
        ("rest", None, False),
        ("hover (flag)", flags(Gtk.StateFlags.PRELIGHT), False),
        ("pressed (flag)", flags(Gtk.StateFlags.ACTIVE), False),
        ("focus (flag)", flags(Gtk.StateFlags.FOCUSED | Gtk.StateFlags.FOCUS_VISIBLE), False),
        ("disabled", disabled, False),
        ("disabled + hover", disabled_hover, False),
        ("loading", None, True),
        ("loading + pressed", loading_pressed, True),
    ]
    grid = Gtk.Grid(row_spacing=8, column_spacing=24)
    for column, (name, _, _) in enumerate(columns, start=1):
        grid.attach(caption(name), column, 0, 1, 1)
    for row, (variant, role) in enumerate(ROWS, start=1):
        grid.attach(caption(f"{variant} / {role}"), 0, row, 1, 1)
        for column, (_, configure, loading) in enumerate(columns, start=1):
            box = triple(variant, role, "m", configure)
            if loading:
                child = box.get_first_child()
                while child:
                    set_loading(child, True)
                    child = child.get_next_sibling()
            grid.attach(box, column, row, 1, 1)
    return grid


def content():
    box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=12, margin_top=24, margin_bottom=24,
                  margin_start=24, margin_end=24)
    manager = Adw.StyleManager.get_default()
    box.append(heading("westron Button: GTK prototype (#26)"))
    box.append(caption(f"dark={manager.get_dark()} high-contrast={manager.get_high_contrast()}"))
    box.append(heading("Variant × role × size (label, icon + label, icon-only)"))
    box.append(matrix())
    box.append(heading("States at size m"))
    box.append(states())
    return box


def screenshot(window, path):
    """Renders the window's content to a PNG with the window's own renderer, then quits."""
    widget = window.get_content()
    paintable = Gtk.WidgetPaintable(widget=widget)
    width, height = widget.get_width(), widget.get_height()
    snapshot = Gtk.Snapshot()
    paintable.snapshot(snapshot, width, height)
    node = snapshot.to_node()
    texture = window.get_renderer().render_texture(node, None)
    texture.save_to_png(str(path))
    print(path)
    window.get_application().quit()
    return GLib.SOURCE_REMOVE


def main():
    dark = "--dark" in sys.argv
    out = sys.argv[sys.argv.index("--screenshot") + 1] if "--screenshot" in sys.argv else None
    app = Adw.Application(application_id="dev.westron.ButtonPrototype")

    def activate(app):
        if dark:
            Adw.StyleManager.get_default().set_color_scheme(Adw.ColorScheme.FORCE_DARK)
        provider = Gtk.CssProvider()
        provider.load_from_string((HERE / "tokens.css").read_text() + "\n" + (HERE / "button.css").read_text())
        # The application priority beats libadwaita's theme whatever the selectors' specificity.
        Gtk.StyleContext.add_provider_for_display(
            Gdk.Display.get_default(), provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION)
        window = Adw.ApplicationWindow(application=app, title="westron Button prototype")
        scrolled = Gtk.ScrolledWindow(propagate_natural_width=True, propagate_natural_height=True)
        scrolled.set_child(content())
        window.set_content(scrolled)
        window.present()
        if out:
            GLib.timeout_add(1000, screenshot, window, out)

    app.connect("activate", activate)
    app.run([sys.argv[0]])


if __name__ == "__main__":
    main()
