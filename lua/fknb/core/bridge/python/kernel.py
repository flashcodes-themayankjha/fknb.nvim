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

            while True:
                reply = client.get_iopub_msg(timeout=1)

                msg_type = reply["header"]["msg_type"]
                content = reply["content"]

                if msg_type == "status" and content["execution_state"] == "idle":
                    break

                out = {
                    "type": msg_type,
                    "content": content,
                    "msg_id": msg_id,
                    "cell_id": cell_id,
                }
                print(json.dumps(out))
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
