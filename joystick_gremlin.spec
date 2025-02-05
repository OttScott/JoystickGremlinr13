# -*- mode: python ; coding: utf-8 -*-
from PyInstaller.utils.hooks import collect_all, collect_data_files

# Ensure PyQt5 and Qt dependencies are included
pyqt5_datas = collect_data_files('PyQt5')
pyqt5_binaries, pyqt5_datas_extra, pyqt5_hiddenimports = collect_all('PyQt5.QtCore')

reportlab_datas, reportlab_binaries, reportlab_hidden = collect_all('reportlab')

datas = pyqt5_datas + pyqt5_datas_extra + reportlab_datas + [
    ('F:/src/repos/joystick_gremlin/dill/__init__.py', 'dill'),
    ('F:/src/repos/joystick_gremlin/doc/hints.csv', 'doc'),
    ('F:/src/repos/joystick_gremlin/GFX', 'GFX'),
    ('F:/src/repos/joystick_gremlin/About', 'About'),
]

binaries = [
    ('F:/src/repos/joystick_gremlin/dill/dill.dll', 'dill')
] + pyqt5_binaries + reportlab_binaries

hiddenimports = ['PyQt5.QtCore', 'PyQt5.QtGui', 'PyQt5.QtWidgets', 'reportlab'] + pyqt5_hiddenimports + reportlab_hidden

a = Analysis(
    ['joystick_gremlin.py'],
    pathex=['F:/src/repos/joystick_gremlin'],  # Ensure the path to your source files is included
    binaries=binaries,
    datas=datas,
    hiddenimports=hiddenimports,
    hookspath=[],
    hooksconfig={},
    runtime_hooks=[],  # Add any runtime hooks if necessary
    excludes=[],
    noarchive=False,
    optimize=0,
)

pyz = PYZ(a.pure)

exe = EXE(
    pyz,
    a.scripts,
    a.binaries,
    a.datas,
    [],
    name='joystick_gremlin',
    debug=False,
    bootloader_ignore_signals=False,
    strip=False,
    upx=True,
    upx_exclude=[],
    runtime_tmpdir=None,
    console=False,
    disable_windowed_traceback=False,
    argv_emulation=False,
    target_arch=None,
    codesign_identity=None,
    entitlements_file=None
)

coll = COLLECT(
    exe,
    a.binaries,
    a.zipfiles,
    a.datas,
    strip=False,
    upx=True,
    upx_exclude=[],
    name='joystick_gremlin'
)