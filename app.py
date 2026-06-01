import os
from flask import Flask, render_template, request, send_from_directory, redirect, url_for, url_for
from werkzeug.utils import secure_filename
from waitress import serve
import qrcode
import socket

UPLOAD_FOLDER = 'uploads'
if not os.path.exists(UPLOAD_FOLDER):
    os.makedirs(UPLOAD_FOLDER)

app = Flask(__name__)
app.config['UPLOAD_FOLDER'] = UPLOAD_FOLDER


def get_local_ip():
    s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    try:
        s.connect(('8.8.8.8', 80))
        ip = s.getsockname()[0]
    except Exception:
        ip = '127.0.0.1'
    finally:
        s.close()
    return ip

def generate_qr_code(data):
    qr = qrcode.QRCode(version=1, box_size=10, border=5)
    qr.add_data(get_local_ip()+':5000')
    qr.make(fit=True)
    img = qr.make_image(fill='black', back_color='white')
    img.save(os.path.join(app.static_folder, 'qr_code.png'))

@app.route('/', methods=['GET'])
def index():
    files = os.listdir(app.config['UPLOAD_FOLDER'])
    generate_qr_code('')
    return render_template('index.html', files=files)

@app.route('/upload_chunk', methods=['POST'])
def upload_chunk():
    fileName = request.headers.get('File-Name')
    if not fileName:
        return 'File-Name is missing', 400
    
    fileName = secure_filename(fileName)
    filePath = os.path.join(app.config['UPLOAD_FOLDER'], fileName)

    with open(filePath, 'ab') as file:
        file.write(request.data)

    return 'Chunk uploaded', 200


"""
@app.route('/upload', methods=['POST'])
def upload_file():
    if 'file' not in request.files:
        return 'Failed to submit file'
    
    file = request.files['file']

    if file.filename == '':
        return 'No file selected'
    
    if file:
        filename = secure_filename(file.filename)
        file.save(os.path.join(app.config['UPLOAD_FOLDER'], filename))
        print(file.filename)
        return redirect(url_for('index'))
"""
    
@app.route('/download/<filename>', methods=['GET'])
def download_file(filename):
    return send_from_directory(app.config['UPLOAD_FOLDER'], filename, as_attachment=True)

if __name__ == '__main__':
    serve(app, host='0.0.0.0', port=5000)