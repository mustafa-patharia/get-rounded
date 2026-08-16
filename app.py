"""GetRounded — native desktop window around index.html.

    python3 app.py

The UI (Tailwind, shadcn look) runs in a real app window. Python only handles
the filesystem: opening images and writing <name>-rounded.png next to the
original.
"""

import base64
import json
import os
import traceback
import webbrowser

import webview
from webview.dom import DOMEventHandler


class Api:
    def ping(self):
        return "ok"

    def open_url(self, url):
        """Open a link in the real browser instead of navigating the app window."""
        if url.startswith(("http://", "https://")):
            webbrowser.open(url)

    def pick(self):
        """Native file dialog. Returns [{name, path, data}] for the UI."""
        try:
            paths = window.create_file_dialog(
                webview.OPEN_DIALOG, allow_multiple=True,
                file_types=("Image files (*.png;*.jpg;*.jpeg;*.webp;*.bmp;*.tif;*.tiff)",
                            "All files (*.*)"),
            )
        except Exception:
            traceback.print_exc()
            # some platforms reject the filter string; retry unfiltered
            paths = window.create_file_dialog(webview.OPEN_DIALOG, allow_multiple=True)
        return [self.read(p) for p in (paths or [])]

    def read(self, path):
        with open(path, "rb") as f:
            data = base64.b64encode(f.read()).decode()
        ext = os.path.splitext(path)[1].lstrip(".").lower() or "png"
        mime = "jpeg" if ext in ("jpg", "jpeg") else ext
        return {"name": os.path.basename(path), "path": path,
                "data": f"data:image/{mime};base64,{data}"}

    def read_paths(self, paths):
        """Used when files are dropped onto the window."""
        return [self.read(p) for p in paths if os.path.isfile(p)]

    def save(self, path, data_url):
        """Write the rounded PNG beside the original. Returns the new path."""
        raw = base64.b64decode(data_url.split(",", 1)[1])
        dest = os.path.splitext(path)[0] + "-rounded.png"
        with open(dest, "wb") as f:
            f.write(raw)
        return dest


HERE = os.path.dirname(os.path.abspath(__file__))

window = webview.create_window(
    "GetRounded", os.path.join(HERE, "index.html"), js_api=Api(),
    width=760, height=860, min_size=(560, 640),
)


def on_drop(event):
    """Real file paths only reach Python, so the drop is handled here.

    prevent_default also stops WebKit from navigating away to the dropped
    file, which would otherwise replace the whole app.
    """
    paths = [f["pywebviewFullPath"] for f in event["dataTransfer"]["files"]
             if f.get("pywebviewFullPath")]
    if paths:
        window.evaluate_js(f"loadPaths({json.dumps(paths)})")


def bind(*_):
    doc = window.dom.document
    doc.events.dragenter += DOMEventHandler(lambda e: None, prevent_default=True)
    doc.events.dragover += DOMEventHandler(lambda e: None, prevent_default=True)
    doc.events.drop += DOMEventHandler(on_drop, prevent_default=True)


window.events.loaded += bind

if __name__ == "__main__":
    webview.start(
        debug=bool(os.environ.get("GETROUNDED_DEBUG")),
        icon=os.path.join(HERE, "logo.png"),   # honoured on GTK/Qt; macOS uses the bundle icon
    )
