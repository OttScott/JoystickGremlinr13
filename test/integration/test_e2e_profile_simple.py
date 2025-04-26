# -*- coding: utf-8; -*-

# Copyright (C) 2015 - 2024 Lionel Ott
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
"""
Integration tests with a profile that does simple input forwarding.
"""

import sys

sys.path.append(".")

import pytest

import dill
from vjoy import vjoy


@pytest.fixture(scope="module")
def profile_name() -> str:
    return "e2e_profile_simple.xml"


class TestSimpleProfile:
    """Tests for a simple profile."""

    @pytest.mark.parametrize(
        ("di_input", "vjoy_output"),
        [(0.7, 22930), (0.5, 16376), (0.2, 6545), (0, -6), (1, 32763)],
    )
    def test_axis(
        self,
        app_tester,
        vjoy_control_device: vjoy.VJoy,
        vjoy_di_device: dill.DeviceSummary,
        di_input: float,
        vjoy_output: int,
    ):
        vjoy_control_device.axis(linear_index=1).set_absolute_value(di_input)
        app_tester.assert_axis_eventually_equals(
            vjoy_di_device, 3, pytest.approx(vjoy_output, abs=1)
        )

    @pytest.mark.parametrize(
        ("di_input", "vjoy_output"),
        [(False, 0), (True, 1), (False, 0), (True, 1)],
    )
    def test_button(
        self,
        app_tester,
        vjoy_control_device: vjoy.VJoy,
        vjoy_di_device: dill.DeviceSummary,
        di_input: bool,
        vjoy_output: int,
    ):
        vjoy_control_device.button(index=1).is_pressed = di_input
        app_tester.assert_button_eventually_equals(vjoy_di_device, 3, vjoy_output)

    @pytest.mark.parametrize(
        ("di_input", "vjoy_output"),
        [
            ((0, 0), -1),
            ((0, 1), 0),
            ((1, 0), 9000),
            ((1, 1), 4500),
            ((-1, 0), 27000),
            ((0, -1), 18000),
            ((-1, -1), 22500),
            ((-1, 1), 31500),
            ((1, -1), 13500),
        ],
    )
    def test_hat(
        self,
        app_tester,
        vjoy_control_device: vjoy.VJoy,
        vjoy_di_device: dill.DeviceSummary,
        di_input: tuple[int, int],
        vjoy_output: tuple[int, int],
    ):
        vjoy_control_device.hat(index=1).direction = di_input
        app_tester.assert_hat_eventually_equals(vjoy_di_device, 3, vjoy_output)
