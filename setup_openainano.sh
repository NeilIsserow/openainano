#!/bin/bash

# ==============================================================================
# OpenAINano: Local AI Bridge for Puppet Enterprise
# Version: 1.2
# Fixes: Added /v1/models for PE Validation (Discovery)
# ==============================================================================

# Configuration
APP_NAME="openainano"
APP_DIR="/opt/$APP_NAME"
VENV_DIR="$APP_DIR/venv"
PORT=5000
OLLAMA_URL="http://localhost:11434/api/chat"
FAKE_TOKEN="sk-puppet-enterprise-local-bridge"
LOCAL_MODEL="qwen3.6:latest"

echo "🚀 Starting OpenAINano Deployment..."

# 1. Install System Dependencies
echo "📦 Installing Python 3 and dependencies..."
apt-get update && apt-get install -y python3 python3-venv python3-pip curl

# 2. Create Application Directory
mkdir -p $APP_DIR
cd $APP_DIR

# 3. Setup Virtual Environment
echo "🐍 Initializing Python virtual environment..."
python3 -m venv $VENV_DIR
$VENV_DIR/bin/pip install flask requests

# 4. Create the OpenAINano Application
echo "📝 Writing application logic (Flask)..."
cat <<EOF > $APP_DIR/app.py
import requests
from flask import Flask, request, jsonify

app = Flask(__name__)

# Config
VALID_MODELS = ["o4-mini", "gpt-4.1"]
REQUIRED_TOKEN = "$FAKE_TOKEN"
OLLAMA_BACKEND = "$OLLAMA_URL"
LOCAL_MODEL_NAME = "$LOCAL_MODEL"

# AUTH CHECK HELPER
def is_authorized(req):
    auth_header = req.headers.get("Authorization")
    return auth_header == f"Bearer {REQUIRED_TOKEN}"

# PE DISCOVERY ENDPOINT (Fixes the 404 validation error)
@app.route('/v1/models', methods=['GET'])
def list_models():
    if not is_authorized(request):
        return jsonify({"error": "Unauthorized"}), 401
    
    models_list = []
    for m in VALID_MODELS:
        models_list.append({
            "id": m,
            "object": "model",
            "created": 1677610602,
            "owned_by": "openainano"
        })
    return jsonify({"object": "list", "data": models_list})

# CHAT COMPLETION ENDPOINT
@app.route('/v1/chat/completions', methods=['POST'])
@app.route('/chat/completions', methods=['POST'])
def chat():
    if not is_authorized(request):
        return jsonify({"error": "Unauthorized"}), 401

    data = request.json
    requested_model = data.get("model", "gpt-4.1")

    ollama_payload = {
        "model": LOCAL_MODEL_NAME, 
        "messages": data.get('messages', []),
        "stream": False
    }

    try:
        response = requests.post(OLLAMA_BACKEND, json=ollama_payload, timeout=120)
        response.raise_for_status()
        ollama_data = response.json()

        return jsonify({
            "id": "chatcmpl-openainano",
            "object": "chat.completion",
            "created": 1234567,
            "model": requested_model,
            "choices": [{
                "index": 0,
                "message": ollama_data.get("message", {"role": "assistant", "content": ""}),
                "finish_reason": "stop"
            }]
        })
    except Exception as e:
        return jsonify({"error": str(e)}), 500

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=$PORT)
EOF

# 5. Create Systemd Service
echo "⚙️ Creating systemd service..."
cat <<EOF > /etc/systemd/system/$APP_NAME.service
[Unit]
Description=OpenAINano - local Ollama Bridge
After=network.target

[Service]
User=root
WorkingDirectory=$APP_DIR
ExecStart=$VENV_DIR/bin/python $APP_DIR/app.py
Restart=always

[Install]
WantedBy=multi-user.target
EOF

# 6. Start and Enable Service
echo "🔄 Starting OpenAINano..."
systemctl daemon-reload
systemctl enable $APP_NAME
systemctl restart $APP_NAME

echo "------------------------------------------------"
echo "✅ OpenAINano IS ONLINE!"
echo "------------------------------------------------"
echo "Endpoint:    http://$(hostname -I | awk '{print $1}'):$PORT/v1"
echo "Token:       $FAKE_TOKEN"
echo "Local Model: $LOCAL_MODEL"
echo "------------------------------------------------"
echo "Verify in PE with:"
echo "1. Set Provider to OpenAI"
echo "2. URL: http://$(hostname -I | awk '{print $1}'):$PORT/v1"
echo "3. Use Deployment Names: gpt-4.1 and o4-mini"
echo "------------------------------------------------"
