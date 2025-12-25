# -*- coding: utf-8; -*-

# SPDX-License-Identifier: GPL-3.0-only

from typing import Optional

from PySide6 import QtCore


MI = QtCore.QModelIndex
PMI = QtCore.QPersistentModelIndex
OQO = Optional[QtCore.QObject]
ModelIndex = MI | PMI