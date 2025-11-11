import sys, json, time, os, base64, tempfile
from queue import Empty
from jupyter_client.manager import KernelManager

# -----------------------------
# Utilities
# -----------------------------
def _ms(sec_float: float) -> int:
    try:
        return int(round(sec_float * 1000))
    except Exception:
        return 0

def save_png_from_b64(b64_data: str) -> str:
    """Save base64-encoded PNG bytes to a temp file and return its path."""
    try:
        if b64_data.startswith("data:image/png;base64,"):
            b64_data = b64_data.split(",", 1)[1]
        raw = base64.b64decode(b64_data, validate=False)
        fd, path = tempfile.mkstemp(prefix="fknb_", suffix=".png")
        os.close(fd)
        with open(path, "wb") as f:
            f.write(raw)
        return path
    except Exception:
        fd, path = tempfile.mkstemp(prefix="fknb_err_", suffix=".png")
        os.close(fd)
        return path

def send(msg_type, content, *, cell_id=None, msg_id=None, exec_count=None):
    pkt = {"type": msg_type, "content": content}
    if cell_id is not None:
        pkt["cell_id"] = cell_id
    if msg_id is not None:
        pkt["id"] = msg_id
    if exec_count is not None:
        pkt["execution_count"] = exec_count
    print(json.dumps(pkt), flush=True)

# -----------------------------
# Core Execute Loop
# -----------------------------
def execute(client, code: str, cell_id):
    code = str(code or "")
    if not code.strip():
        send("execute_result", {"text/plain": ""}, cell_id=cell_id)
        send("execution_complete", {"execution_time": 0}, cell_id=cell_id)
        return

    start = time.time()
    msg_id = client.execute(code, store_history=True)

    # Immediately notify host so spinner activates
    send("exec_ack", {"ok": True}, cell_id=cell_id, msg_id=msg_id)

    exec_count_seen = None

    while True:
        try:
            msg = client.get_iopub_msg(timeout=1)
        except Empty:
            continue
        except Exception as e:
            send("error", {"evalue": f"Bridge error reading msg: {e}"}, cell_id=cell_id)
            break

        if msg.get("parent_header", {}).get("msg_id") != msg_id:
            continue

        hdr = msg.get("header", {})
        mtype = hdr.get("msg_type")
        c = msg.get("content", {})

        if "execution_count" in c and c["execution_count"] is not None:
            exec_count_seen = c["execution_count"]

        if mtype == "status" and c.get("execution_state") == "idle":
            break

        elif mtype == "stream":
            send(
                "stream",
                {"name": c.get("name", "stdout"), "text": c.get("text", "")},
                cell_id=cell_id,
                msg_id=msg_id,
                exec_count=exec_count_seen,
            )

        elif mtype in ("display_data", "update_display_data"):
            data = c.get("data", {}) or {}
            if "image/png" in data:
                path = save_png_from_b64(data["image/png"])
                send("display_data", {"type": "image/png", "path": path},
                     cell_id=cell_id, msg_id=msg_id, exec_count=exec_count_seen)
            elif "text/plain" in data:
                send("display_data", {"text/plain": data["text/plain"]},
                     cell_id=cell_id, msg_id=msg_id, exec_count=exec_count_seen)
            elif "text/html" in data:
                send("display_data", {"text/html": data["text/html"]},
                     cell_id=cell_id, msg_id=msg_id, exec_count=exec_count_seen)
            else:
                send("display_data", {"data": data},
                     cell_id=cell_id, msg_id=msg_id, exec_count=exec_count_seen)

        elif mtype == "execute_result":
            data = c.get("data", {}) or {}
            if "text/plain" in data:
                send("execute_result", {"text/plain": data["text/plain"]},
                     cell_id=cell_id, msg_id=msg_id, exec_count=exec_count_seen)
            elif "image/png" in data:
                path = save_png_from_b64(data["image/png"])
                send("display_data", {"type": "image/png", "path": path},
                     cell_id=cell_id, msg_id=msg_id, exec_count=exec_count_seen)
            else:
                send("execute_result", {"data": data},
                     cell_id=cell_id, msg_id=msg_id, exec_count=exec_count_seen)

        elif mtype == "clear_output":
            send("clear_output", {"wait": c.get("wait", False)},
                 cell_id=cell_id, msg_id=msg_id, exec_count=exec_count_seen)

        elif mtype == "error":
            send("error", {
                "ename": c.get("ename"),
                "evalue": c.get("evalue"),
                "traceback": c.get("traceback", []),
            }, cell_id=cell_id, msg_id=msg_id, exec_count=exec_count_seen)

    elapsed_ms = _ms(time.time() - start)
    send("execution_complete", {"execution_time": elapsed_ms},
         cell_id=cell_id, msg_id=msg_id, exec_count=exec_count_seen)

# -----------------------------
# Main
# -----------------------------
def main():
    km = KernelManager()
    km.start_kernel()
    client = km.client()
    client.start_channels()
    client.allow_stdin = False  # avoid hangs from input()

    # Notify Neovim host that bridge is ready
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
                send("error", {"evalue": "Invalid JSON input"}, None)
                continue

            if cmd.get("action") == "shutdown":
                break
            elif cmd.get("action") == "execute":
                try:
                    execute(client, cmd.get("code", ""), cmd.get("cell_id"))
                except Exception as e:
                    send("error", {"evalue": f"Bridge execute error: {e}"}, cmd.get("cell_id"))
    finally:
        try:
            client.stop_channels()
        finally:
            km.shutdown_kernel()

if __name__ == "__main__":
    main()
