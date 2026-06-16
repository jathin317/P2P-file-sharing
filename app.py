from flask import Flask, request, render_template
from flask_socketio import SocketIO, emit

app = Flask(__name__)
socketio = SocketIO(app)

users = {}

@app.route('/')
def index():
    return render_template('index.html')

@socketio.on('connect')
def connect():
    print(f"Client connected: {request.sid}")

@socketio.on("join")
def join(data):
    username = data["username"]
    users[request.sid] = username
    print(f"{username} joined")
    socketio.emit("user_list", { "users": [{ "sid": sid, "username": username } for sid, username in users.items()] })


@socketio.on("disconnect")
def disconnect():
    if request.sid in users:
        username = users.pop(request.sid)
        print(f"User disconnected: {username}")

        socketio.emit("user_list", { "users": [{ "sid": sid, "username": username } for sid, username in users.items()] })

if __name__ == "__main__":
    socketio.run(app, host="0.0.0.0", port=5000, ssl_context="adhoc")
