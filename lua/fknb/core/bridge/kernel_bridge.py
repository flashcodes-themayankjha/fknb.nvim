# lua/fknb/core/bridge/kernel_bridge.py
import sys, json, time
from queue import Empty
from jupyter_client.manager import KernelManager

def send(msg_type, content, cell_id=None, msg_id=None):
    pkt = {"type": msg_type, "content": content}
    if cell_id is not None:
        pkt["cell_id"] = cell_id
    if msg_id is not None:
        pkt["id"] = msg_id
    print(json.dumps(pkt), flush=True)

def execute(client, code, cell_id):
    if not code.strip():
        send("execute_result", {"text/plain": ""}, cell_id)
        send("execution_complete", {"execution_time": 0}, cell_id)
        return

    start = time.time()
    msg_id = client.execute(code, store_history=True)
    # ack (stderr is unreliable for parsing, so we emit explicit stdout ack)
    send("exec_ack", {"ok": True}, cell_id=cell_id, msg_id=msg_id)

    while True:
        try:
            msg = client.get_iopub_msg(timeout=1)
        except Empty:
            continue

        if msg.get("parent_header", {}).get("msg_id") != msg_id:
            continue

        mtype = msg["header"]["msg_type"]
        c = msg["content"]

        if mtype == "status" and c.get("execution_state") == "idle":
            break
        elif mtype == "stream":
            # live print
            send("stream", {"name": c.get("name"), "text": c.get("text", "")}, cell_id=cell_id, msg_id=msg_id)
        elif mtype == "display_data":
            data = c.get("data", {})
            if "text/plain" in data:
                send("display_data", {"text/plain": data["text/plain"]}, cell_id=cell_id, msg_id=msg_id)
        elif mtype == "execute_result":
            data = c.get("data", {})
            if "text/plain" in data:
                send("execute_result", {"text/plain": data["text/plain"]}, cell_id=cell_id, msg_id=msg_id)
        elif mtype == "error":
            send("error", {
                "ename": c.get("ename"),
                "evalue": c.get("evalue"),
                "traceback": c.get("traceback", []),
            }, cell_id=cell_id, msg_id=msg_id)

    elapsed = time.time() - start
    send("execution_complete", {"execution_time": elapsed}, cell_id=cell_id, msg_id=msg_id)

def main():
    km = KernelManager()
    km.start_kernel()
    client = km.client()
    client.start_channels()

    print("FkNBDebug: kernel_bridge.py starting", file=sys.stderr)
    print(json.dumps({"status": "ready", "connection_file": km.connection_file}), flush=True)
    print("FkNBDebug: Kernel started, sending ready status", file=sys.stderr)

    try:
      while True:
        line = sys.stdin.readline()
        if not line:
            break
        try:
            cmd = json.loads(line)
        except Exception:
            send("error", {"evalue": "Invalid JSON"}, None)
            continue

        if cmd.get("action") == "shutdown":
            break

        if cmd.get("action") == "execute":
            code = str(cmd.get("code", ""))
            cell_id = cmd.get("cell_id")
            execute(client, code, cell_id)
    finally:
      client.stop_channels()
      km.shutdown_kernel()

if __name__ == "__main__":
    main()
