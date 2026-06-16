from flask import Flask, jsonify, render_template, request

app = Flask(__name__)

users = {}

@app.route("/")
def index():
    return render_template("index.html")

@app.route("/user", methods=["GET"])
def login():
    username = request.args.get("username")
    ipaddress = request.remote_addr
    users[ipaddress] = username
    print(users)
    return render_template("usersList.html")

@app.route("/peers", methods=["GET"])
def get_peers():
    return jsonify({"peers": list(users.values())})

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000, debug=True)