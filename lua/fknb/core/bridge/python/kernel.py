#!/usr/bin/env python3

import asyncio
import json
import uuid
from jupyter_client import KernelManager
from jupyter_client.blocking.client import BlockingKernelClient
import sys

async def main():
    # Start kernel
    km = KernelManager()
    km.start_kernel()
    client: BlockingKernelClient = km.client()
    client.start_channels()

    print(json.dumps({"event": "kernel_started"}))
    sys.stdout.flush()

    # REPL loop from Neovim
    while True:
        line = sys.stdin.readline()
        if not line:
            break

        msg = json.loads(line)
        code = msg.get("code")

        # Execute cell
        cell_id = msg.get("cell_id")
        msg_id = client.execute(code)

        # Collect outputs
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

    client.stop_channels()
    km.shutdown_kernel()

if __name__ == "__main__":
    asyncio.run(main())
