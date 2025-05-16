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
sys.path.append(".")

import pytest

from gremlin import fsm


def test_simple():
    f1 = lambda: 1
    f2 = lambda: 2
    f3 = lambda: 3

    states = ["1", "2", "3"]
    actions = ["switch"]
    transitions = {
        ("1", "switch"): fsm.Transition([f1], "2"),
        ("2", "switch"): fsm.Transition([f2], "3"),
        ("3", "switch"): fsm.Transition([f3], "1"),
    }

    sm = fsm.FiniteStateMachine("1", states, actions, transitions)

    assert sm.current_state == "1"
    assert sm.perform("switch")[0] == 1
    assert sm.current_state == "2"
    assert sm.perform("switch")[0] == 2
    assert sm.current_state == "3"
    assert sm.perform("switch")[0] == 3
    assert sm.current_state == "1"


def test_multi():
    # 1 - 2 - 4
    #   \   /
    #     3

    add = lambda a, b: a + b
    sub = lambda a, b: a - b
    mul = lambda a, b: a * b

    states = ["1", "2", "3", "4"]
    actions = ["add", "mul", "sub"]
    transitions = {
        ("1", "add"): fsm.Transition([add, mul], "2"),
        ("1", "sub"): fsm.Transition([sub, mul], "3"),
        ("3", "add"): fsm.Transition([add], "4"),
        ("2", "add"): fsm.Transition([add], "4"),
        ("4", "sub"): fsm.Transition([sub], "1"),
    }

    sm = fsm.FiniteStateMachine("1", states, actions, transitions)

    assert sm.current_state == "1"
    assert sm.perform("add", 2, 3) == [5, 6]
    assert sm.current_state == "2"
    assert sm.perform("add", 5, 1) == [6]
    assert sm.current_state == "4"
    assert sm.perform("sub", 5, 5) == [0]
    assert sm.current_state == "1"
    assert sm.perform("sub", 10, 3) == [7, 30]
    assert sm.current_state == "3"