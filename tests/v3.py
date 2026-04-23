from typing import TYPE_CHECKING

if TYPE_CHECKING:
    from test_driver.machine import Machine

    machine: Machine = None  # ty: ignore[invalid-assignment]

# typing-end

machine.start()
machine.wait_for_x()

machine.succeed("cp /etc/file $HOME/file.af")

machine.succeed("affinity-v3 $HOME/file.af >&2 &")
machine.wait_for_window(r"^Affinity$")

machine.screenshot("screenshot-1")

machine.wait_for_text(r"MAGIC", 500)
machine.wait_for_text(r"STRING", 100)

machine.screenshot("screenshot-3")
