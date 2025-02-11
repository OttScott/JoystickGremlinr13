# -*- coding: utf-8; -*-

# Copyright (C) 2015 - 2025 Lionel Ott
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


"""Implementation of a very simple finite state machine."""


from collections.abc import Callable
import logging
from typing import Any, Dict, List, Tuple


class Transition:

    """Represents a single transition in the finite state machine."""

    def __init__(
            self,
            callbacks: List[Callable[[*Tuple[Any, ...]], Any]],
            new_state: str
    ):
        """Creates a new Transition object.

        Args:
            callback: function to call when executing the transition
            new_state: resulting state of the transition after executing the
                callback
        """
        self.callbacks = callbacks
        self.new_state = new_state


class FiniteStateMachine:

    """Simple finite state machine."""

    def __init__(
            self,
            start_state: str,
            states: List[str],
            actions: List[str],
            transitions: Dict[Tuple[str, str], Transition],
            debug: bool=False,
            identifier: str="FSM"
    ):
        """Creates a new finite state machine object.

        Args:
            start_state: the state in which the FSM starts in
            states: list of valid states for the FSM
            actions: the possible actions of the FSM
            transitions: dictionary mapping state x action keys to transitions
            debug: logs debug messages if True
            identifier: name used to identify the FSM instance
        """
        assert(start_state in states)

        self.states = states
        self.actions = actions
        self.transitions = transitions
        self.current_state = start_state
        self.debug = debug
        self.identifier = identifier

    def perform(self, action: str, *args) -> List[Any]:
        """Performs a state transition on the FSM.

        Args:
            action: name of the action to execute

        Returns:
            Result of executing the state transition callback
        """
        key = (self.current_state, action)

        # Ensure the validity of the transition
        assert(action in self.actions)
        assert(key in self.transitions)
        assert(self.transitions[key].new_state in self.states)

        values = [cb(*args) for cb in self.transitions[key].callbacks]
        if self.debug:
            logging.getLogger("system").debug(
                f"FSM ({self.identifier}): {self.current_state} -> " +
                f"{self.transitions[key].new_state} ({action})"
            )
        self.current_state = self.transitions[key].new_state
        return values
