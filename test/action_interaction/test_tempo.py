# SPDX-License-Identifier: GPL-3.0-only

from __future__ import annotations

from pathlib import Path
import pytest

from gremlin.types import InputType

from .conftest import (
    EventSpec,
    JoystickGremlinBot,
)
from .input_definitions import *


def test_short(
    jgbot: JoystickGremlinBot,
    profile_dir: Path,
    subtests: pytest.Subtests
) -> None:
    jgbot.load_profile(profile_dir / "tempo.xml")

    with subtests.test("Simple tap"):
        assert jgbot.button(OUT_BUTTON_1) == False
        jgbot.tap_button(IN_BUTTON_1)

        jgbot.clear_events()
        assert EventSpec(
            InputType.JoystickButton, OUT_BUTTON_1, True) == jgbot.next_event()
        assert EventSpec(
            InputType.JoystickButton, OUT_BUTTON_1, False) == jgbot.next_event()

        # Ensure no additional events are generated.
        with pytest.raises(jgbot.qtbot.TimeoutError):
            jgbot.next_event()

    with subtests.test("Longer hold"):
        assert jgbot.button(OUT_BUTTON_1) == False
        jgbot.hold_button(IN_BUTTON_1, 0.15)

        jgbot.clear_events()
        assert EventSpec(
            InputType.JoystickButton, OUT_BUTTON_1, True) == jgbot.next_event()
        assert EventSpec(
            InputType.JoystickButton, OUT_BUTTON_1, False) == jgbot.next_event()

        # Ensure no additional events are generated.
        with pytest.raises(jgbot.qtbot.TimeoutError):
            jgbot.next_event()


def test_lonog(
    jgbot: JoystickGremlinBot,
    profile_dir: Path,
    subtests: pytest.Subtests
) -> None:
    jgbot.load_profile(profile_dir / "tempo.xml")

    with subtests.test("Long hold"):
        jgbot.hold_button(IN_BUTTON_1, 0.25)
        assert EventSpec(
            InputType.JoystickButton, OUT_BUTTON_2, True) == jgbot.next_event()
        assert EventSpec(
            InputType.JoystickButton, OUT_BUTTON_2, False) == jgbot.next_event()
