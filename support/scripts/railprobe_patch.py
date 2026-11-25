"""Applies a RailProbe variant to the checked-out app.

All variants try to make the navigation rail paint, without adding anything visible. The working reference is a
static Material overlay in the content pane (variant c2-overlay in the previous round): it never rebuilds, yet
the rail appears and stays. That points at layer composition rather than repaint timing. Marking the RenderView
as needing paint does not help, because that flag does not reach descendants that own a layer.

    d1-rail-layer    puts the rail behind its own RepaintBoundary
    d2-body-layer    puts the whole Scaffold body behind its own RepaintBoundary
    d3-invisible     adds an invisible, full size composited child to the content stack
    d4-control       adds the visible overlay that is known to work (the control)

Usage: python3 support/scripts/railprobe_patch.py <variant>
"""

import pathlib
import shutil
import sys

VARIANTS = {
    "d1-rail-layer": "rail_probe_markneeds.dart",
    "d2-body-layer": "rail_probe_markneeds.dart",
    "d3-invisible": "rail_probe_invisible.dart",
    "d4-control": "rail_probe_overlay.dart",
}

HOME = pathlib.Path("app/lib/pages/home_page.dart")

RAIL_OPEN = "                if (!sizingInformation.isMobile)\n                  NavigationRail(\n"
RAIL_CLOSE = "                  ),\n                Expanded(\n"
RAIL_OPEN_WRAPPED = "                if (!sizingInformation.isMobile)\n                  RepaintBoundary(\n                  child: NavigationRail(\n"
RAIL_CLOSE_WRAPPED = "                  ),\n                  ),\n                Expanded(\n"

BODY_OPEN = "            body: Row(\n"
BODY_CLOSE = "            ),\n            bottomNavigationBar:"
BODY_OPEN_WRAPPED = "            body: RepaintBoundary(\n            child: Row(\n"
BODY_CLOSE_WRAPPED = "            ),\n            ),\n            bottomNavigationBar:"

STACK_MARKER = (
    "                        if (_dragAndDropIndicator)\n"
    "                          Container(\n"
    "                            width: double.infinity,\n"
    "                            decoration: BoxDecoration(\n"
    "                              color: Theme.of(context).scaffoldBackgroundColor,\n"
    "                            ),\n"
    "                            child: Column(\n"
    "                              mainAxisAlignment: MainAxisAlignment.center,\n"
    "                              children: [\n"
    "                                const Icon(Icons.file_download, size: 128),\n"
    "                                const SizedBox(height: 30),\n"
    "                                Text(t.sendTab.placeItems, style: Theme.of(context).textTheme.titleLarge),\n"
    "                              ],\n"
    "                            ),\n"
    "                          ),\n"
)

IMPORT_ANCHOR = "import 'package:localsend_app/util/native/cross_file_converters.dart';\n"
PROBE_IMPORT = "import 'package:localsend_app/util/ui/rail_probe.dart';\n"


def replace_once(text: str, old: str, new: str, what: str) -> str:
    if old not in text:
        raise SystemExit(f"anchor for {what} missing")
    return text.replace(old, new, 1)


def main() -> int:
    if len(sys.argv) != 2 or sys.argv[1] not in VARIANTS:
        print(f"usage: {sys.argv[0]} <{'|'.join(VARIANTS)}>", file=sys.stderr)
        return 2

    variant = sys.argv[1]
    ui_dir = pathlib.Path("app/lib/util/ui")
    impl = ui_dir / VARIANTS[variant]
    if not impl.exists():
        raise SystemExit(f"missing implementation file {impl}")

    text = HOME.read_bytes().decode("utf-8")

    if variant == "d1-rail-layer":
        text = replace_once(text, RAIL_OPEN, RAIL_OPEN_WRAPPED, "rail open")
        text = replace_once(text, RAIL_CLOSE, RAIL_CLOSE_WRAPPED, "rail close")
    elif variant == "d2-body-layer":
        text = replace_once(text, BODY_OPEN, BODY_OPEN_WRAPPED, "body open")
        text = replace_once(text, BODY_CLOSE, BODY_CLOSE_WRAPPED, "body close")
    elif variant in ("d3-invisible", "d4-control"):
        shutil.copyfile(impl, ui_dir / "rail_probe.dart")
        text = replace_once(text, IMPORT_ANCHOR, IMPORT_ANCHOR + PROBE_IMPORT, "import")
        text = replace_once(text, STACK_MARKER, STACK_MARKER + "                        const RailProbe(),\n", "stack")

    HOME.write_bytes(text.encode("utf-8"))
    print(f"patched for {variant}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
