# SPDX-License-Identifier: GPL-3.0-only

from __future__ import annotations

from pathlib import Path
import pytest
import pytestqt

from gremlin.types import InputType

from .conftest import (
    EventSpec,
    JoystickGremlinBot,
)
from .input_definitions import *


def test_short(jgbot: JoystickGremlinBot, profile_dir: Path) -> None:
    jgbot.load_profile(profile_dir / "remap_smart_toggle.xml")

    assert jgbot.button(OUT_BUTTON_1) == False
    jgbot.press_button(IN_BUTTON_1)
    assert jgbot.button(OUT_BUTTON_1) == True
    jgbot.release_button(IN_BUTTON_1)
    assert jgbot.button(OUT_BUTTON_1) == True
    jgbot.press_button(IN_BUTTON_1)
    assert jgbot.button(OUT_BUTTON_1) == True
    jgbot.release_button(IN_BUTTON_1)
    assert jgbot.button(OUT_BUTTON_1) == False

    jgbot.clear_events()
    jgbot.hold_button(IN_BUTTON_1, 0.1)
    assert EventSpec(
        InputType.JoystickButton, OUT_BUTTON_1, True) == jgbot.next_event()

    # Ensure no additional events are generated.
    with pytest.raises(jgbot.qtbot.TimeoutError):
        jgbot.next_event()


def test_long(jgbot: JoystickGremlinBot, profile_dir: Path) -> None:
    jgbot.load_profile(profile_dir / "remap_smart_toggle.xml")
    assert jgbot.button(OUT_BUTTON_1) == False
    jgbot.hold_button(IN_BUTTON_1, 0.25)
    assert EventSpec(
        InputType.JoystickButton, OUT_BUTTON_1, True) == jgbot.next_event()
    assert EventSpec(
        InputType.JoystickButton, OUT_BUTTON_1, False) == jgbot.next_event()

    # Ensure no additional events are generated.
    with pytest.raises(jgbot.qtbot.TimeoutError):
        jgbot.next_event()
