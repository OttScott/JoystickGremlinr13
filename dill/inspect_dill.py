import ctypes

dll_path = "F:/src/Repos/joystick_gremlin/dill/dill.dll"

try:
    # Load the DLL
    dill_dll = ctypes.WinDLL(dll_path)

    # Try listing functions
    available_functions = [func for func in dir(dill_dll) if not func.startswith("_")]

    print("Available functions in dill.dll:")
    print(available_functions)
except Exception as e:
    print(f"Error loading dill.dll: {e}")
