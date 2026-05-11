# openainano
A simple openai wrapper for Puppet Enterprise to pretend it is a real OpenAI instgance when really its just Ollama. Created using AI!
---
Understood. Here is the revised **OpenAINano** README focused on deployment, configuration, and maintenance, without the bulk of the script embedded in the text.

---

# OpenAINano: Local AI Bridge for Puppet Enterprise

**OpenAINano** is a lightweight Python-based protocol translator. It allows **Puppet Enterprise (PE)** to communicate with a local **Ollama** instance by mimicking the OpenAI API structure and spoofing model deployments to satisfy PE's validation requirements.

## ⚙️ How it Works

Puppet Enterprise requires a specific "handshake" to validate an AI provider. OpenAINano manages this by:

* **Discovery:** Responding to `/v1/models` requests to confirm that `gpt-4.1` and `o4-mini` exist.


* **Translation:** Converting OpenAI-formatted chat arrays into the format required by the Ollama `/api/chat` endpoint.


* **Identity Masking:** Reporting all local AI responses as coming from `gpt-4.1` to pass internal Puppet validation.



---

## 🚀 Installation & Deployment

1. **Prepare Ollama:** Ensure Ollama is running and your preferred model is pulled (e.g., `ollama pull qwen3.6:latest`).


2. **Run Setup:** Execute your `setup_openainano.sh` script with root privileges:
```bash
sudo chmod +x setup_openainano.sh && sudo ./setup_openainano.sh

```


3. **Verify Service:** Confirm the bridge is active:

```bash
    systemctl status openainano
    ```

---

## 🛠 Puppet Enterprise Configuration
In the Puppet Enterprise Console, navigate to the AI Provider settings and enter the following[cite: 1, 2]:

| Setting | Value |
| :--- | :--- |
| **Provider** | OpenAI |
| **Base URL** | `http://<YOUR_SERVER_IP>:5000/v1` |
| **API Key** | `sk-puppet-enterprise-local-bridge` |
| **Deployment Name 1** | `gpt-4.1` |
| **Deployment Name 2** | `o4-mini` |

---

## 🧪 Manual Testing
You can verify the bridge independently of Puppet using `curl`. This ensures the bridge is talking to Ollama correctly[cite: 2]:

```bash
curl http://localhost:5000/v1/chat/completions \
  -H "Authorization: Bearer sk-puppet-enterprise-local-bridge" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "gpt-4.1",
    "messages": [{"role": "user", "content": "Hello OpenAINano!"}]
  }'

```

---

## 📂 Maintenance

* **Application Path:** `/opt/openainano/app.py`.


* **Virtual Environment:** `/opt/openainano/venv/`.


* **Logs:** View real-time traffic with `journalctl -u openainano -f`.


* **Updates:** After modifying `app.py`, you must restart the service:

```bash
    sudo systemctl restart openainano
    ```

---
