"""Applies a RailProbe variant to the checked-out app.

Findings so far (all installed on the affected device, all built with the official flags):

    official 643 / RailFix A+B / RailControl      unmodified                         rail blank
    RailNudge                                     setState after first frame          rail blank
    B1 / B3                                       no extra widget in the Stack        rail blank
    B2 / C2 / D4                                  one visible overlay in the Stack    rail visible
    C1                                            RenderView.markNeedsPaint()         rail blank
    D1 / D2                                       RepaintBoundary around rail/body    rail blank
    D3                                            invisible overlay (Opacity 0)       rail blank

So a RepaintBoundary is not enough (D1, D2) and an overlay that paints nothing is not enough (D3). The working
overlays all paint opaque pixels. This round separates "paints pixels" from "is visible", and also tests the one
rendering switch that was never isolated (all three early builds had the diagnostics overlay on by default, so
their rail worked regardless of the switch).

    e1-tint      full size overlay at 1% opacity (paints, invisible)
    e2-pixel     a single 1x1 opaque pixel in the corner (paints, invisible)
    e3-control   the visible overlay that already works
    e4-impeller  unmodified Dart, Impeller disabled in the manifest

Usage: python3 support/scripts/railprobe_patch.py <variant>
"""

import pathlib
import shutil
import sys

VARIANTS = {
    "e1-tint": "rail_probe_tint.dart",
    "e2-pixel": "rail_probe_pixel.dart",
    "e3-control": "rail_probe_overlay.dart",
    "e4-impeller": None,
}

HOME = pathlib.Path("app/lib/pages/home_page.dart")

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
    impl_name = VARIANTS[variant]

    # e4 only changes the manifest, which the workflow does itself.
    if impl_name is None:
        print(f"{variant} needs no Dart patch")
        return 0

    ui_dir = pathlib.Path("app/lib/util/ui")
    impl = ui_dir / impl_name
    if not impl.exists():
        raise SystemExit(f"missing implementation file {impl}")
    shutil.copyfile(impl, ui_dir / "rail_probe.dart")

    text = HOME.read_bytes().decode("utf-8")
    text = replace_once(text, IMPORT_ANCHOR, IMPORT_ANCHOR + PROBE_IMPORT, "import")
    text = replace_once(text, STACK_MARKER, STACK_MARKER + "                        const RailProbe(),\n", "stack")
    HOME.write_bytes(text.encode("utf-8"))
    print(f"patched for {variant}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
