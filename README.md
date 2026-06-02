# P2P FILE-SHARING

A lightning-fast, mobile-first local file-sharing tool. Transfer large files between devices on the same Wi-Fi network with zero setup—just scan a QR code and go.

## ✨ Features

* **Instant Mobile Connection:** Automatically detects your local IP and generates a terminal QR code. No typing IP addresses into your phone.
* **Large File Support (Chunking):** Bypasses traditional memory limits by slicing files into 10MB chunks in the browser before sending them to the server.
* **Production-Grade Speed:** Runs on **Waitress** (a pure-Python WSGI server), allowing for significantly faster transfers and better concurrency than the default Flask server.
* **Mobile-First UI:** A clean, responsive web interface with a real-time animated progress bar designed specifically for phone screens.
* **Secure File Handling:** Implements Werkzeug's `secure_filename` to prevent directory traversal attacks.

## 🛠️ Tech Stack

* **Backend:** Python, Flask, Waitress
* **Frontend:** HTML5, CSS3 (Modern Flexbox/Variables), Vanilla JavaScript
* **Extras:** `qrcode` (Terminal QR generation)

## 📦 Installation & Setup

1. **Clone the repository:**
   ```bash
   git clone https://github.com/jathin317/P2P-file-sharing.git
   cd P2P-file-sharing
   ```

1. **Create a virtual environment (optional but recommended):**
   ```bash
   python -m venv venv
   # On Windows:
   venv\Scripts\activate
   # On Mac/Linux:
   source venv/bin/activate
   ```

2. **Install dependencies:**
   ```bash
   pip install -r requirements.txt
   ```

## 🚀 How to Use

1. Run the server from your terminal:
   ```bash
   python app.py
   ```
2. A large QR code will appear directly in your command line.
3. Open your phone's camera, scan the QR code, and your browser will instantly open the web app.
4. Select a file and hit **Send File**. The file will be saved in the `/uploads` folder on your host machine.

## 📁 Project Structure

```
lan-drop/
│
├── app.py                  # Main Flask & Waitress server logic
├── requirements.txt        # Python dependencies
├── .gitignore              # Ignores __pycache__ and uploads/
│
├── templates/
│   └── index.html          # Main HTML structure
│
├── static/
│   ├── style.css           # Custom CSS for the mobile-first UI
│   └── file_upload_script.js # Client-side file chunking and UI updates
│
└── uploads/                # Directory where received files are saved
```

