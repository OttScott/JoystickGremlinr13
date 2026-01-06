# -*- coding: utf-8; -*-

# SPDX-License-Identifier: GPL-3.0-only

import pathlib
import pytest

# Mock before any imports happen
from unittest.mock import Mock
import tempfile
import gremlin.util
gremlin.util.userprofile_path = Mock(return_value=tempfile.mkdtemp())

import joystick_gremlin
import gremlin.ui.backend


@pytest.fixture(scope="session")
def qapp_cls() -> type[joystick_gremlin.JoystickGremlinApp]:
    return joystick_gremlin.JoystickGremlinApp


@pytest.fixture(scope="session")
def test_root_dir() -> pathlib.Path:
    return pathlib.Path(__file__).parent
