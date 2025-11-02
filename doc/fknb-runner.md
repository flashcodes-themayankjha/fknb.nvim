# FkNB Runner Documentation

This document details how FkNB executes code cells, manages kernel interactions, and handles the lifecycle of the execution environment.

## 1. `lua/fknb/core/kernel.lua` - The Kernel Manager

`kernel.lua` is the central module for managing the Jupyter kernel process. It is responsible for:

*   **Starting the Kernel:** The `M.start()` function initiates a Python process that runs `kernel_bridge.py`. This bridge script then connects to a Jupyter kernel.
*   **Stopping the Kernel:** The `M.stop()` function sends a shutdown command to the kernel and terminates the bridge process.
*   **Executing Code:** The `M.execute(cell_id, code)` function sends code from a specific cell to the running kernel for execution. It includes the `cell_id` to associate output and status updates with the correct cell.
*   **Output and Status Handling (`on_stdout`):** This callback function processes messages received from the `kernel_bridge.py`. It decodes JSON messages, updates the `state.cells` table with execution status and output, and notifies the UI of changes.
*   **Dependency Checking:** Before starting the kernel, `check_dependencies` ensures that `jupyter_client` and `ipykernel` are installed in the Python environment.

## 2. `lua/fknb/core/bridge/python/kernel.py` - The Python Bridge

`kernel.py` acts as a bridge between the Neovim Lua plugin and the Jupyter kernel. It is a Python script executed by `kernel.lua` and performs the following:

*   **Kernel Management:** It uses `jupyter_client.KernelManager` to start and manage a Jupyter kernel.
*   **REPL Loop:** It continuously reads input from `stdin` (sent from Neovim), executes the received code using the Jupyter kernel client, and captures the kernel's output.
*   **Output Forwarding:** It forwards all kernel output (execution results, status updates, errors) back to Neovim via `stdout` as JSON messages. Crucially, it includes the `cell_id` in these messages to allow FkNB to correctly associate output with the originating cell.

## 3. `lua/fknb/init.lua` - The `run_current_cell` Command

The `M.run_current_cell()` function in `init.lua` is the entry point for executing a cell from within Neovim. When invoked (e.g., via a keybinding):

*   It uses `require("fknb.core.parser").get_cell_at_cursor()` to identify the notebook cell at the current cursor position.
*   It then calls `require("fknb.core.kernel").execute(cell.id, table.concat(cell.lines, "\n"))` to send the cell's content and its unique ID to the kernel for execution.

## Execution Flow

1.  User triggers `FkRunCell` (e.g., `<leader>r`).
2.  `fknb.init.run_current_cell()` identifies the active cell.
3.  `fknb.core.kernel.execute()` sends the cell's code and ID to the Python bridge.
4.  `kernel.py` executes the code in the Jupyter kernel.
5.  Kernel output is sent back to `kernel.py`.
6.  `kernel.py` formats the output as JSON (including `cell_id`) and sends it to `stdout`.
7.  `fknb.core.kernel.on_stdout()` receives and processes the JSON message.
8.  `state.cells` is updated with the new status and output for the specific cell.
9.  The UI is triggered to re-render the updated cell.
