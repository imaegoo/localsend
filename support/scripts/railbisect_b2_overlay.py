"""Inserts the diagnostics overlay into the original home_page.dart (RailBisect B2)."""

import pathlib
import sys

ANCHOR = "import 'package:localsend_app/util/native/cross_file_converters.dart';\n"

MARKER = (
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


def main() -> int:
    path = pathlib.Path("app/lib/pages/home_page.dart")
    # Byte level, so that the line endings of the file are preserved on every platform.
    text = path.read_bytes().decode("utf-8")

    if ANCHOR not in text:
        print("import anchor missing", file=sys.stderr)
        return 1
    if MARKER not in text:
        print("stack marker missing", file=sys.stderr)
        return 1

    text = text.replace(ANCHOR, ANCHOR + "import 'package:localsend_app/util/ui/rail_diagnostics.dart';\n", 1)
    text = text.replace(MARKER, MARKER + "                        if (railDiagnosticsEnabled) const RailDiagPanel(),\n", 1)
    path.write_bytes(text.encode("utf-8"))
    print("overlay inserted")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
