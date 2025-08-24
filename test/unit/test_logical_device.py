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
# along with this program.  If not, see <http://www.gnu.org/licenses/>


import sys
import uuid

sys.path.append(".")

import pytest

from gremlin.common import InputType
from gremlin.error import GremlinError
from gremlin.logical_device import LogicalDevice


@pytest.fixture(autouse=True)
def reset_logical() -> None:
    LogicalDevice().reset()


def test_creation() -> None:
    logical = LogicalDevice()

    logical.create(InputType.JoystickButton, label="TB 1")
    assert logical["TB 1"].label == "TB 1"
    assert logical["TB 1"].type == InputType.JoystickButton
    assert logical["TB 1"].id == 1

    logical.create(InputType.JoystickButton, label="TB 2")
    logical.create(InputType.JoystickButton, label="TB 3")
    assert logical["TB 2"].type == InputType.JoystickButton
    assert logical["TB 2"].label == "TB 2"
    assert logical["TB 2"].id == 2
    assert logical["TB 3"].id == 3

    for key in ["TB 1", "TB 2", "TB 3"]:
        assert key in logical.labels_of_type([InputType.JoystickButton])

    logical.create(InputType.JoystickAxis, label="TA 1")
    assert logical["TA 1"].type == InputType.JoystickAxis
    assert logical["TA 1"].id == 1
    logical.create(InputType.JoystickButton, label="TB 4")
    assert logical["TB 4"].type == InputType.JoystickButton
    assert logical["TB 4"].id == 4

    assert len(logical.labels_of_type([InputType.JoystickButton])) == 4
    assert len(logical.labels_of_type([InputType.JoystickAxis])) == 1


def test_delete() -> None:
    logical = LogicalDevice()

    logical.create(InputType.JoystickButton, label="TB 1")
    logical.create(InputType.JoystickButton, label="TB 2")
    logical.create(InputType.JoystickButton, label="TB 3")
    assert logical["TB 1"].id == 1
    assert logical["TB 2"].id == 2
    assert logical["TB 3"].id == 3

    assert len(logical.labels_of_type()) == 3
    logical.delete("TB 3")
    assert len(logical.labels_of_type()) == 2
    assert logical["TB 1"].id == 1
    assert logical["TB 2"].id == 2

    with pytest.raises(GremlinError):
        assert logical["TB 3"]

    logical.delete(logical["TB 1"].identifier)
    assert len(logical.labels_of_type()) == 1
    with pytest.raises(GremlinError):
        assert logical["TB 1"]
    assert logical["TB 2"].id == 2


def test_index_reuse() -> None:
    logical = LogicalDevice()

    logical.create(InputType.JoystickButton, label="TB 1")
    logical.create(InputType.JoystickButton, label="TB 2")
    logical.create(InputType.JoystickButton, label="TB 3")
    assert logical["TB 1"].id == 1
    assert logical["TB 2"].id == 2
    assert logical["TB 3"].id == 3

    logical.delete("TB 1")

    logical.create(InputType.JoystickButton, label="NEW")
    assert logical["NEW"].id == 1

    logical.delete("TB 2")
    logical.create(InputType.JoystickButton, label="NEW2")
    assert logical["NEW2"].id == 2

    logical.create(InputType.JoystickButton, label="TB 4")
    assert logical["TB 4"].id == 4


def test_relabel() -> None:
    logical = LogicalDevice()

    logical.create(InputType.JoystickButton, label="TB 1")
    logical.create(InputType.JoystickButton, label="TB 2")
    logical.create(InputType.JoystickButton, label="TB 3")

    tb2_identifier = logical["TB 2"].identifier

    logical.set_label("TB 2", "NEW")
    assert logical[tb2_identifier].label == "NEW"
    assert logical["NEW"].id == tb2_identifier.id

    assert "NEW" in logical.labels_of_type()
    assert "TB 2" not in logical.labels_of_type()
    assert len(logical.labels_of_type()) == 3

    logical.delete("NEW")
    assert len(logical.labels_of_type()) == 2
    assert "NEW" not in logical.labels_of_type()


def test_accessors() -> None:
    logical = LogicalDevice()

    logical.create(InputType.JoystickButton, label="TB 1")
    logical.create(InputType.JoystickButton, label="TB 2")
    logical.create(InputType.JoystickAxis, label="TA 1")
    logical.create(InputType.JoystickHat, label="TH 1")

    assert logical.button(1).label == "TB 1"
    assert logical.button(2).label == "TB 2"
    assert logical.axis(1).label == "TA 1"
    assert logical.hat(1).label == "TH 1"

    with pytest.raises(GremlinError):
        assert logical.button(4)