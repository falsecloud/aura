#!/usr/bin/env python3
"""Aura - native Qt Quick desktop app."""

from __future__ import annotations

import argparse
import os
import sys

from PySide6.QtCore import QTimer, QUrl
from PySide6.QtGui import QGuiApplication, QIcon
from PySide6.QtQml import QQmlApplicationEngine

from backend import BASE, Backend

# Qt Quick's OpenGL path in this environment cannot render ShaderEffect nodes.
# Liquid glass is a real refraction shader, so render through Vulkan instead.
os.environ.setdefault("QSG_RHI_BACKEND", "vulkan")


# PyInstaller puts bundled QML modules under the frozen _internal directory.
def _configure_bundled_qml_path() -> None:
    qml_dir = os.path.join(BASE, "PySide6", "Qt", "qml")
    if not os.path.isdir(qml_dir):
        return
    existing = os.environ.get("QML_IMPORT_PATH", "")
    entries = existing.split(os.pathsep) if existing else []
    if qml_dir not in entries:
        os.environ["QML_IMPORT_PATH"] = os.pathsep.join([qml_dir, *entries])


_configure_bundled_qml_path()


def main() -> int:
    parser = argparse.ArgumentParser(description="Aura")
    parser.add_argument("--shot", help="Save a screenshot to this path and quit")
    parser.add_argument("--delay", type=int, default=6500, help="Screenshot delay in ms")
    parser.add_argument("--page", type=int, default=0, help="Initial page index")
    parser.add_argument("--search", action="store_true", help="Open the search overlay")
    args = parser.parse_args()

    app = QGuiApplication(sys.argv)
    app.setApplicationName("Aura")
    app.setApplicationDisplayName("Aura")
    app.setOrganizationName("Aura")
    app.setDesktopFileName("aura")
    icon_path = os.path.join(BASE, "assets", "app.png")
    if os.path.exists(icon_path):
        app.setWindowIcon(QIcon(icon_path))

    engine = QQmlApplicationEngine()
    engine.warnings.connect(
        lambda warnings: [print(w.toString(), file=sys.stderr) for w in warnings]
    )
    backend = Backend()
    engine.rootContext().setContextProperty("backend", backend)
    engine.load(QUrl.fromLocalFile(os.path.join(BASE, "qml", "Main.qml")))
    if not engine.rootObjects():
        return 1

    window = engine.rootObjects()[0]
    backend.bootstrap()

    window.setProperty("page", args.page)
    if args.search:
        window.setProperty("searchOpen", True)
    if args.shot:
        window.setProperty("shotPath", args.shot)

    return app.exec()


if __name__ == "__main__":
    raise SystemExit(main())
