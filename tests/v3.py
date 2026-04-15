from typing import TYPE_CHECKING

if TYPE_CHECKING:
    from test_driver.machine import Machine

    machine: Machine = None  # ty: ignore[invalid-assignment]

# typing-end

machine.start()
machine.wait_for_x()

machine.succeed("affinity-v3 >&2 &")
machine.wait_for_window(r"^Affinity$")
machine.screenshot("screenshot")
