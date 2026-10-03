"""Exercise the real Godot process through Gamenight's WebSocket protocol.

Standard library only. Uses a synthetic host and opaque controller tokens;
physical controller/focus testing remains a separate hardware check.
"""
import argparse
import base64
import hashlib
import json
import os
from pathlib import Path
import socket
import struct
import subprocess
import tempfile
import threading
import time


class Host:
    def __init__(self):
        self.server = socket.socket()
        self.server.bind(("127.0.0.1", 0))
        self.server.listen()
        self.server.settimeout(20)
        self.port = self.server.getsockname()[1]
        self.messages = []
        self.lock = threading.Lock()
        self.peer = None

    def connect(self):
        self.peer, _ = self.server.accept()
        self.peer.settimeout(20)
        request = b""
        while b"\r\n\r\n" not in request:
            request += self.peer.recv(1)
        headers = dict(line.split(":", 1) for line in request.decode().split("\r\n")[1:] if ":" in line)
        key = next(v.strip() for k, v in headers.items() if k.lower() == "sec-websocket-key")
        accept = base64.b64encode(hashlib.sha1((key + "258EAFA5-E914-47DA-95CA-C5AB0DC85B11").encode()).digest()).decode()
        self.peer.sendall(("HTTP/1.1 101 Switching Protocols\r\nUpgrade: websocket\r\nConnection: Upgrade\r\nSec-WebSocket-Accept: " + accept + "\r\n\r\n").encode())
        self.peer.settimeout(None)
        threading.Thread(target=self.read, daemon=True).start()

    def exact(self, length):
        data = b""
        while len(data) < length:
            chunk = self.peer.recv(length - len(data))
            if not chunk:
                raise EOFError
            data += chunk
        return data

    def read(self):
        try:
            while True:
                first, second = self.exact(2)
                length = second & 127
                if length == 126: length = struct.unpack("!H", self.exact(2))[0]
                elif length == 127: length = struct.unpack("!Q", self.exact(8))[0]
                mask = self.exact(4) if second & 128 else None
                data = self.exact(length)
                if mask: data = bytes(value ^ mask[i % 4] for i, value in enumerate(data))
                if first & 15 == 1: self.messages.append(json.loads(data))
        except (OSError, EOFError, ValueError):
            pass

    def send(self, kind, **values):
        data = json.dumps(dict(type=kind, **values)).encode()
        header = bytes([129, len(data)]) if len(data) < 126 else bytes([129, 126]) + struct.pack("!H", len(data))
        with self.lock:
            self.peer.sendall(header + data)

    def close(self):
        if self.peer:
            self.peer.shutdown(socket.SHUT_RDWR)
            self.peer.close()
        self.server.close()


def wait(read, predicate, timeout=15):
    deadline = time.monotonic() + timeout
    latest = None
    while time.monotonic() < deadline:
        try:
            latest = read()
            if predicate(latest): return latest
        except (OSError, ValueError, KeyError):
            pass
        time.sleep(.03)
    raise AssertionError(f"Timed out; last state: {latest}")


