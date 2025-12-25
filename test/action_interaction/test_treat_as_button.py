# -*- coding: utf-8; -*-

# SPDX-License-Identifier: GPL-3.0-only

from __future__ import annotations

from pathlib import Path

from gremlin.types import HatDirection

from .conftest import JoystickGremlinBot
from .input_definitions import *


def test_axis_basic(jgbot: JoystickGremlinBot, profile_dir: Path) -> None:
    jgbot.load_profile(profile_dir / "treat_as_button.xml")

    assert jgbot.button(OUT_BUTTON_1) == False
    assert jgbot.axis(IN_AXIS_1) == 0.0
    jgbot.set_axis_absolute(IN_AXIS_1, 0.20)
    assert jgbot.button(OUT_BUTTON_1) == False
    jgbot.set_axis_absolute(IN_AXIS_1, 0.30)
    assert jgbot.button(OUT_BUTTON_1) == True
    jgbot.set_axis_absolute(IN_AXIS_1, 0.80)
    assert jgbot.button(OUT_BUTTON_1) == False


def test_axis_edge_below(jgbot: JoystickGremlinBot, profile_dir: Path) -> None:
    jgbot.load_profile(profile_dir / "treat_as_button.xml")

    jgbot.set_axis_absolute(IN_AXIS_1, 0.2499)
    assert jgbot.button(OUT_BUTTON_1) == False
    jgbot.set_axis_absolute(IN_AXIS_1, 0.25)
    assert jgbot.button(OUT_BUTTON_1) == True
    jgbot.set_axis_absolute(IN_AXIS_1, 0.75)
    assert jgbot.button(OUT_BUTTON_1) == True
    jgbot.set_axis_absolute(IN_AXIS_1, 0.75001)
    assert jgbot.button(OUT_BUTTON_1) == False


def test_axis_edge_above(jgbot: JoystickGremlinBot, profile_dir: Path) -> None:
    jgbot.load_profile(profile_dir / "treat_as_button.xml")

    jgbot.set_axis_absolute(IN_AXIS_1, 0.7501)
    assert jgbot.button(OUT_BUTTON_1) == False
    jgbot.set_axis_absolute(IN_AXIS_1, 0.75)
    assert jgbot.button(OUT_BUTTON_1) == True
    jgbot.set_axis_absolute(IN_AXIS_1, 0.25)
    assert jgbot.button(OUT_BUTTON_1) == True
    jgbot.set_axis_absolute(IN_AXIS_1, 0.24999)
    assert jgbot.button(OUT_BUTTON_1) == False


def test_hat_basic(jgbot: JoystickGremlinBot, profile_dir: Path) -> None:
    jgbot.load_profile(profile_dir / "treat_as_button.xml")

    assert jgbot.button(OUT_BUTTON_1) == False
    jgbot.set_hat_direction(IN_HAT_1, HatDirection.North)
    assert jgbot.button(OUT_BUTTON_1) == True
    jgbot.set_hat_direction(IN_HAT_1, HatDirection.East)
    assert jgbot.button(OUT_BUTTON_1) == False
    jgbot.set_hat_direction(IN_HAT_1, HatDirection.South)
    assert jgbot.button(OUT_BUTTON_1) == True
    jgbot.set_hat_direction(IN_HAT_1, HatDirection.Center)
    assert jgbot.button(OUT_BUTTON_1) == False
