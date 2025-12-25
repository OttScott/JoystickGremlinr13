# -*- coding: utf-8; -*-

# SPDX-License-Identifier: GPL-3.0-only

from __future__ import annotations

from pathlib import Path

from gremlin.types import HatDirection

from .conftest import JoystickGremlinBot
from .input_definitions import *


def test_simple(jgbot: JoystickGremlinBot, profile_dir: Path) -> None:
    jgbot.load_profile(profile_dir / "remap_basic.xml")

    jgbot.press_button(IN_BUTTON_1)
    assert jgbot.button(OUT_BUTTON_1) == True
    jgbot.release_button(IN_BUTTON_1)
    assert jgbot.button(OUT_BUTTON_1) == False

    jgbot.set_axis_absolute(IN_AXIS_1, 0.5)
    assert jgbot.axis(OUT_AXIS_1) == 0.5
    jgbot.set_axis_absolute(IN_AXIS_1, -0.5)
    assert jgbot.axis(OUT_AXIS_1) == -0.5

    jgbot.set_hat_direction(IN_HAT_1, HatDirection.NorthWest)
    assert jgbot.hat(OUT_HAT_1) == HatDirection.NorthWest
    jgbot.set_hat_direction(IN_HAT_1, HatDirection.SouthEast)
    assert jgbot.hat(OUT_HAT_1) == HatDirection.SouthEast


def test_button_advanced(jgbot: JoystickGremlinBot, profile_dir: Path) -> None:
    jgbot.load_profile(profile_dir / "remap_basic.xml")

    jgbot.tap_button(IN_BUTTON_1)
    assert jgbot.button(OUT_BUTTON_1) == False

    jgbot.hold_button(IN_BUTTON_1, 0.5)
    assert jgbot.button(OUT_BUTTON_1) == True
    jgbot.wait(0.4)
    assert jgbot.button(OUT_BUTTON_1) == True
    jgbot.wait(0.2)
    assert jgbot.button(OUT_BUTTON_1) == False


def test_remap_inverse(jgbot: JoystickGremlinBot, profile_dir: Path) -> None:
    jgbot.load_profile(profile_dir / "remap_invert.xml")

    jgbot.press_button(IN_BUTTON_1)
    assert jgbot.button(OUT_BUTTON_1) == False
    jgbot.release_button(IN_BUTTON_1)
    assert jgbot.button(OUT_BUTTON_1) == True
