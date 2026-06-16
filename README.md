# Local P2P File Sharing

A real-time, peer-to-peer file sharing web application designed specifically for Local Area Networks (LAN). This application allows devices connected to the same network to discover each other and transfer files directly browser-to-browser, without the data passing through a central server.

## Features

* **Real-Time Discovery:** Instantly see other users who join the local network session.
* **Direct P2P Transfers:** Utilizes WebRTC Data Channels to send file data directly between peers.
* **Chunked File Processing:** Reads and transmits files in 16KB chunks to handle larger file sizes efficiently.
* **Offline-Friendly (LAN):** Bypasses the need for external STUN/TURN servers by utilizing local network IP addresses.
* **Ad-Hoc Secure Context:** Includes a self-signed SSL context to satisfy modern browser security requirements for WebRTC.

## Tech Stack

* **Backend:** Python, Flask, Flask-SocketIO
* **Frontend:** HTML, CSS, Vanilla JavaScript
* **Protocols:** WebRTC (RTCPeerConnection, RTCDataChannel), WebSockets (Socket.IO)

## Prerequisites

* Python 3.x
* `pip` (Python package manager)

## Installation

1. **Clone the repository:**
   ```bash
   git clone <your-repository-url>
   cd <repository-folder>

2. **Install the dependencies:**
   ```bash
   pip install -r requirements.txt

## Usage
1. **Find your local IP address:**
   Open your terminal and run ip a (Linux/Mac) or ipconfig (Windows) to find your machine's local IPv4 address (e.g., 192.168.1.x).
2. **Start the server:**
   ```bash
   python app.py
3. **Connect your devices:**
   On the host machine, open a browser and navigate to https://localhost:5000 or https://127.0.0.1:5000.

   On any other device connected to the same Wi-Fi network (like a phone or second laptop), navigate to https://<YOUR_LOCAL_IP>:5000.
4. **Transfer Files:**
   Enter a username on both devices, click a user from the connected peers list, select a file, and click send.