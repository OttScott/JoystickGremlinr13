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
    assert isinstance(logical["TB 1"].guid, uuid.UUID)

    logical.create(InputType.JoystickButton, label="TB 2")
    logical.create(InputType.JoystickButton, label="TB 3")

    for key in ["TB 1", "TB 2", "TB 3"]:
        assert key in logical.labels_of_type([InputType.JoystickButton])

    logical.create(InputType.JoystickAxis, label="TA 1")
    logical.create(InputType.JoystickButton, label="TB 4")

    assert len(logical.labels_of_type([InputType.JoystickButton])) == 4
    assert len(logical.labels_of_type([InputType.JoystickAxis])) == 1


def test_delete() -> None:
    logical = LogicalDevice()

    logical.create(InputType.JoystickButton, label="TB 1")
    logical.create(InputType.JoystickButton, label="TB 2")
    tb2_guid = logical["TB 2"].guid
    logical.create(InputType.JoystickButton, label="TB 3")

    assert len(logical.labels_of_type()) == 3
    logical.delete("TB 3")
    assert len(logical.labels_of_type()) == 2

    with pytest.raises(GremlinError):
        assert logical["TB 3"]

    logical.delete(logical["TB 1"].guid)
    assert len(logical.labels_of_type()) == 1
    with pytest.raises(GremlinError):
        assert logical["TB 1"]
    assert logical["TB 2"].guid == tb2_guid


def test_index_reuse() -> None:
    logical = LogicalDevice()

    logical.create(InputType.JoystickButton, label="TB 1")
    tb1_guid = logical["TB 1"]
    logical.create(InputType.JoystickButton, label="TB 2")
    logical.create(InputType.JoystickButton, label="TB 3")

    logical.delete("TB 1")

    logical.create(InputType.JoystickButton, label="NEW")
    assert logical["NEW"].guid != tb1_guid


def test_relabel() -> None:
    logical = LogicalDevice()

    logical.create(InputType.JoystickButton, label="TB 1")
    logical.create(InputType.JoystickButton, label="TB 2")
    tb2_guid = logical["TB 2"].guid
    logical.create(InputType.JoystickButton, label="TB 3")

    logical.set_label("TB 2", "NEW")
    assert logical[tb2_guid].label == "NEW"
    assert logical["NEW"].guid == tb2_guid

    assert "NEW" in logical.labels_of_type()
    assert "TB 2" not in logical.labels_of_type()
    assert len(logical.labels_of_type()) == 3

    logical.delete("NEW")
    assert len(logical.labels_of_type()) == 2
    assert "NEW" not in logical.labels_of_type()