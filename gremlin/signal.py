# -*- coding: utf-8; -*-

# SPDX-License-Identifier: GPL-3.0-only

from PySide6 import QtCore
from PySide6.QtCore import Signal

from gremlin import common


@common.SingletonDecorator
class Signal(QtCore.QObject):

    reloadUi = Signal()

    reloadCurrentInputItem = Signal()

    inputItemChanged = Signal(int)

    modesChanged = Signal()

    profileChanged = Signal()

    logicalDeviceModified = Signal()

    configChanged = Signal()


signal = Signal()
