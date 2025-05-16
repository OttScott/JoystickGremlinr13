import sys
sys.path.append(".")

import pytest

import dill

import gremlin.input_devices
import gremlin.event_handler


@pytest.fixture(scope="session", autouse=True)
def joystick_init():
    dill.DILL.init()
    gremlin.input_devices.joystick_devices_initialization()


@pytest.fixture(scope="session", autouse=True)
def terminate_event_listener(request):
    request.addfinalizer(
        lambda: gremlin.event_handler.EventListener().terminate()
    )