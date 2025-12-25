# -*- coding: utf-8; -*-

# SPDX-License-Identifier: GPL-3.0-only

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