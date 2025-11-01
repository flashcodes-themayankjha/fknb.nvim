import sys
import json
import base64
import time
from jupyter_client.manager import KernelManager
from queue import Empty
import image_utils

def main():
    # Start a kernel
    km = KernelManager()
    km.start_kernel()
    client = km.client()
    client.start_channels()

    # Inform Neovim that the kernel is ready
    print(json.dumps({"status": "ready", "connection_file": km.connection_file}), flush=True)

    try:
        while True:
            line = sys.stdin.readline()
            if not line:
                break

            try:
                command = json.loads(line)
                if command.get("action") == "execute":
                    execute_code(client, command.get("code", ""))
                elif command.get("action") == "shutdown":
                    break
            except json.JSONDecodeError:
                send_error("Invalid JSON command.")

    finally:
        client.stop_channels()
        km.shutdown_kernel()

def execute_code(client, code):
    if not code.strip():
        send_response("execute_result", {"output": ""})
        return

    start_time = time.time()
    msg_id = client.execute(code, store_history=True)
    
    while True:
        try:
            msg = client.get_iopub_msg(timeout=1)
            msg_type = msg['header']['msg_type']
            content = msg['content']

            if msg.get('parent_header', {}).get('msg_id') == msg_id:
                if msg_type == 'status' and content['execution_state'] == 'idle':
                    break

                if msg_type == 'stream':
                    send_response("stream", {"name": content['name'], "text": content['text']})
                elif msg_type == 'display_data':
                    handle_display_data(content)
                elif msg_type == 'execute_result':
                    handle_execute_result(content)
                elif msg_type == 'error':
                    send_response("error", {"ename": content['ename'], "evalue": content['evalue'], "traceback": content['traceback']})
        
        except Empty:
            break
    
    end_time = time.time()
    send_response("execution_complete", {"execution_time": end_time - start_time})

def handle_display_data(content):
    data = content.get('data', {})
    if 'image/png' in data:
        file_path = image_utils.save_image(data['image/png'])
        send_response("display_data", {"type": "image/png", "path": file_path})
    elif 'text/plain' in data:
        send_response("display_data", {"type": "text/plain", "data": data['text/plain']})

def handle_execute_result(content):
    data = content.get('data', {})
    if 'text/plain' in data:
        send_response("execute_result", {"output": data['text/plain']})

def send_response(msg_type, content):
    response = {"type": msg_type, "content": content}
    print(json.dumps(response), flush=True)

def send_error(message):
    send_response("error", {"ename": "BridgeError", "evalue": message, "traceback": []})

if __name__ == "__main__":
    main()
