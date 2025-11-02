#!/usr/bin/env python3

import asyncio
import json
import uuid
from jupyter_client import KernelManager
from jupyter_client.blocking.client import BlockingKernelClient
import sys
import traceback

async def main():
    # Start kernel
    km = KernelManager()
    try:
        km.start_kernel()
        client: BlockingKernelClient = km.client()
        client.start_channels()

        print(json.dumps({"event": "kernel_started"}))
        sys.stdout.flush()
    except Exception as e:
        print(json.dumps({"event": "error", "message": f"Failed to start kernel: {e}", "traceback": traceback.format_exc()}))
        sys.stdout.flush()
        sys.stderr.write(traceback.format_exc())
        sys.stderr.flush()
        sys.exit(1)

    # REPL loop from Neovim
    while True:
        line = sys.stdin.readline()
        if not line:
            break

        msg = json.loads(line)
        action = msg.get("action")

        if action == "execute":
            code = msg.get("code")
            cell_id = msg.get("cell_id")
            msg_id = client.execute(code)

            execution_output = []
            execution_status = "running"

            while True:
                try:
                    reply = client.get_iopub_msg(timeout=1)
                except Exception:
                    # Timeout, continue waiting for messages
                    continue

                msg_type = reply["header"]["msg_type"]
                content = reply["content"]

                if msg_type == "stream":
                    execution_output.append(content["text"])
                elif msg_type == "display_data":
                    if "text/plain" in content["data"]:
                        execution_output.append(content["data"]["text/plain"])
                    # TODO: Handle other display data types like images
                elif msg_type == "execute_result":
                    if "text/plain" in content["data"]:
                        execution_output.append(content["data"]["text/plain"])
                    execution_status = "done"
                elif msg_type == "error":
                    execution_output.append(f"{content['ename']}: {content['evalue']}")
                    execution_output.extend(content["traceback"])
                    execution_status = "error"
                elif msg_type == "status" and content["execution_state"] == "idle":
                    # Execution is complete
                    break
                
                # Send incremental updates to Neovim
                out = {
                    "event": "cell_update",
                    "cell_id": cell_id,
                    "status": execution_status,
                    "output": execution_output,
                }
                print(json.dumps(out))
                sys.stdout.flush()
            
            # Send final status if not already sent by incremental updates
            if execution_status == "running": # If no execute_result or error was received
                execution_status = "done"

            final_out = {
                "event": "cell_update",
                "cell_id": cell_id,
                "status": execution_status,
                "output": execution_output,
            }
            print(json.dumps(final_out))
            sys.stdout.flush()

        elif action == "list_kernels":
            import jupyter_client.kernelspec
            kernel_specs = jupyter_client.kernelspec.find_kernel_specs()
            kernels = []
            for name, path in kernel_specs.items():
                spec = jupyter_client.kernelspec.get_kernel_spec(name)
                kernels.append({
                    "name": name,
                    "display_name": spec.display_name,
                    "language": spec.language,
                })
            print(json.dumps({"event": "kernels_list", "kernels": kernels}))
            sys.stdout.flush()
        elif action == "shutdown":
            break

    client.stop_channels()
    km.shutdown_kernel()

if __name__ == "__main__":
    asyncio.run(main())