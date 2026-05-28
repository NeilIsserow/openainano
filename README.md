NB! This code is provided as-is, with no guarantee it will work or not do any damage. No warranty or support is provided and this is developed independently of my employer with the help of AI. Use of this repo is at your own risk!
---
OpenAINano PE Bridge (GOLD Stable)

This bridge acts as a high-fidelity translation layer between Puppet Enterprise (PE) Infrastructure Assistant and local Ollama instances. It is specifically engineered to resolve the "Thinking..." hang and "Infinite Loop" issues by precisely mimicking OpenAI's raw network delivery patterns.

Core Features

Array-Wrapped Streaming: Mimics OpenAI's multi-chunk delivery by wrapping SSE data in literal JSON arrays [...].

Strict Metadata Spoofing: Injects system_fingerprint, service_tier, and complex usage_details (including reasoning and cached token objects) to satisfy strict Java-based JSON parsers.

V2 API Compatibility: Supports both /v1/chat/completions and the PE-specific /api/ai/infra-assistant/ endpoints.

CORS Hardening: High-permissiveness headers to ensure the browser handshake succeeds in secured environments.

Technical Architecture

The "GOLD" Termination Logic

The primary reason for previous failures was the client-side parser waiting for a specific closure. This version implements:

Initial Array Open: Starts the stream with [\n.

Chunk Encapsulation: Each logical chunk is wrapped in its own array structure as observed in traffic.log.

Double-Packet Finish: Sends the stop_reason and the usage metadata in a single final array bundle.

Out-of-Band [DONE]: Delivers the standard data: [DONE] signal outside the array to force the socket closure.

Requirements

Python: 3.8+

Ollama: Running locally with minimax-m2.5:cloud (or configured target).

Network: Port 5000 must be accessible to the PE console.

Operations & Maintenance

Deployment

Execute the deploy_bridge.sh script to perform a "Deep Clean" and fresh installation.

sudo bash deploy_bridge.sh


Monitoring Logs

To watch the real-time interaction between PE and Ollama:

# Watch the systemd service logs
journalctl -u openainano -f -o cat


Service Management

# Restart the bridge
systemctl restart openainano

# Check status
systemctl status openainano


Security Implementation

The bridge enforces a specific token check:

Header: Authorization: Bearer sk-puppet-enterprise-local-bridge

Fallback: Also checks X-Authentication headers for compatibility with premium PE modules.

Troubleshooting

If the UI returns to "Thinking" state:

Verify Ollama is responsive: curl http://127.0.0.1:11434/v1/models.

Ensure no ghost processes are holding the port: fuser -k 5000/tcp.

Check that common.yaml in PE is pointing to the correct HTTPS/HTTP bridge URL.
