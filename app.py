import os
from flask import Flask, render_template, request, send_from_directory, redirect, url_for, url_for
from werkzeug.utils import secure_filename
from waitress import serve

UPLOAD_FOLDER = 'uploads'
if not os.path.exists(UPLOAD_FOLDER):
    os.makedirs(UPLOAD_FOLDER)

app = Flask(__name__)
app.config['UPLOAD_FOLDER'] = UPLOAD_FOLDER

@app.route('/', methods=['GET'])
def index():
    files = os.listdir(app.config['UPLOAD_FOLDER'])
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