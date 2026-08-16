#!/bin/bash
# Linux / macOS launcher. Creates the virtual environment on first run.
cd "$(dirname "$0")"
[ -d .venv ] || { python3 -m venv .venv && .venv/bin/pip install -q -r requirements.txt; }
exec .venv/bin/python app.py
