# Override PyInstaller's PySide6.QtQml hook.
#
# The stock hook calls collect_qtqml_files(), which recursively bundles every
# QML module in the build environment. On systems that also carry KDE or
# third-party QML modules this pulls in unrelated libraries and makes the
# release enormous. The application spec only needs the modules Aura imports,
# which are listed in packaging/aura.spec.

from PyInstaller.utils.hooks.qt import add_qt6_dependencies

hiddenimports, binaries, datas = add_qt6_dependencies(__file__)
