"""Applies the RailProbe variant patch to the checked-out app.

Each variant makes the content pane contain one extra widget whose only job is, on the first frame, to make
the framework paint again. The variants differ only in *how* they do that:

    c1-markneeds   Marks the RenderView as needing paint.
    c2-overlay     Is a plain, permanently mounted Material overlay (what the working B2 build added).

Usage: python3 support/scripts/railprobe_patch.py <c1-markneeds|c2-overlay>
"""

import pathlib
import shutil
import sys

VARIANTS = {
    "c1-markneeds": "rail_probe_markneeds.dart",
    "c2-overlay": "rail_probe_overlay.dart",
}

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


def main() -> int:
    if len(sys.argv) != 2 or sys.argv[1] not in VARIANTS:
        print(f"usage: {sys.argv[0]} <{'|'.join(VARIANTS)}>", file=sys.stderr)
        return 2

    variant = sys.argv[1]
    ui_dir = pathlib.Path("app/lib/util/ui")
    impl = ui_dir / VARIANTS[variant]
    if not impl.exists():
        print(f"missing implementation file {impl}", file=sys.stderr)
        return 1

    shutil.copyfile(impl, ui_dir / "rail_probe.dart")

    home = pathlib.Path("app/lib/pages/home_page.dart")
    text = home.read_bytes().decode("utf-8")

    if STACK_MARKER not in text:
        print("stack marker missing", file=sys.stderr)
        return 1
    if IMPORT_ANCHOR not in text:
        print("import anchor missing", file=sys.stderr)
        return 1

    text = text.replace(IMPORT_ANCHOR, IMPORT_ANCHOR + PROBE_IMPORT, 1)
    text = text.replace(STACK_MARKER, STACK_MARKER + "                        const RailProbe(),\n", 1)
    home.write_bytes(text.encode("utf-8"))
    print(f"patched for {variant}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
