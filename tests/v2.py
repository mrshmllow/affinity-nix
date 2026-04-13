from typing import TYPE_CHECKING

if TYPE_CHECKING:
    from test_driver.machine import Machine

    photo: Machine = None  # ty: ignore[invalid-assignment]
    publisher: Machine = None  # ty: ignore[invalid-assignment]
    designer: Machine = None  # ty: ignore[invalid-assignment]

# typing-end

photo.wait_for_x()
publisher.wait_for_x()
designer.wait_for_x()

photo.succeed("affinity-photo >&2 &")
designer.succeed("affinity-designer >&2 &")
publisher.succeed("affinity-publisher >&2 &")

photo.wait_for_window(r"^Affinity Photo 2$")
photo.screenshot("screenshot-photo")

designer.wait_for_window(r"^Affinity Designer 2$")
designer.screenshot("screenshot-designer")

publisher.wait_for_window(r"^Affinity Publisher 2$")
publisher.screenshot("screenshot-publisher")
