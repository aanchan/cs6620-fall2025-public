import os
import re
from flask import Flask, render_template, request, jsonify, send_from_directory
from flask_cors import CORS

app = Flask(__name__)
CORS(app)

# Global variables for playlist management
current_directory = None
current_playlist = [] # Stores full paths on server
SUPPORTED_AUDIO_EXTENSIONS = ('.mp3', '.wav', '.ogg')

# Global variable to store parsed log data
parsed_transcription_data = {}

def parse_log_content(log_content):
    """
    Parses the log content to extract transcription data.
    """
    data = {}
    # Regex to find a block for each file
    file_block_pattern = re.compile(
        r"File: (.+\.wav)\s*\n"
        r"Reference: .*\n" 
        r"Prediction: .*\n" 
        r"Reference \(normalized\): (.+)\s*\n"
        r"Prediction \(normalized\): (.+)\s*\n"
        r"Individual WER: ([\d.]+)"
    )

    for match in file_block_pattern.finditer(log_content):
        filename = os.path.basename(match.group(1)) # Extract just the filename
        reference = match.group(2).strip()
        prediction = match.group(3).strip()
        wer = float(match.group(4))
        data[filename] = {
            "reference_normalized": reference,
            "prediction_normalized": prediction,
            "wer": wer
        }
    return data

@app.route('/audio_files/<path:filename>')
def serve_audio_file(filename):
    """
    Serves audio files directly to the client's web browser.
    """
    if current_directory and os.path.exists(os.path.join(current_directory, filename)):
        return send_from_directory(current_directory, filename)
    else:
        return "File not found", 404

@app.route('/')
def index():
    """
    Renders the main HTML page for the client-side audio player.
    """
    return render_template('index.html') 

@app.route('/select_directory', methods=['POST'])
def select_directory():
    """
    Handles the selection of an audio directory and populates the playlist.
    Now also includes transcription data if a log file has been uploaded/loaded.
    """
    global current_directory, current_playlist

    directory_path = request.form.get('directory_path')

    if not directory_path:
        return jsonify({"success": False, "message": "Please enter a directory path."})

    if not os.path.isdir(directory_path):
        return jsonify({"success": False, "message": "Invalid directory path."})

    current_directory = directory_path
    current_playlist = sorted([
        os.path.join(current_directory, f)
        for f in os.listdir(current_directory)
        if f.lower().endswith(SUPPORTED_AUDIO_EXTENSIONS)
    ])
    
    files_with_transcription_info = []

    for f_path in current_playlist:
        f_name = os.path.basename(f_path)
        file_url = f'/audio_files/{f_name}'
        
        transcription_info = parsed_transcription_data.get(f_name, None)
        
        files_with_transcription_info.append({
            "name": f_name,
            "url": file_url,
            "transcription": transcription_info # Add transcription info if available
        })

    return jsonify({
        "success": True,
        "message": f"Directory selected: {directory_path}",
        "files_with_info": files_with_transcription_info
    })

@app.route('/upload_log', methods=['POST'])
def upload_log():
    """
    Handles the upload of the log file directly from the client.
    """
    global parsed_transcription_data
    
    log_content = None

    if 'log_file' in request.files:
        uploaded_file = request.files['log_file']
        if uploaded_file.filename != '':
            log_content = uploaded_file.read().decode('utf-8')
    
    if not log_content:
        return jsonify({"success": False, "message": "No log file provided."})

    try:
        parsed_transcription_data = parse_log_content(log_content)
        # Re-select directory to refresh playlist with new transcription data
        if current_directory:
            pass # The frontend will call selectDirectory() after a successful upload
        return jsonify({
            "success": True,
            "message": f"Log file uploaded and parsed successfully. {len(parsed_transcription_data)} entries found."
        })
    except Exception as e:
        app.logger.error(f"Error parsing uploaded log file: {e}")
        return jsonify({"success": False, "message": f"Error parsing uploaded log file: {str(e)}"})

@app.route('/load_log_from_path', methods=['POST'])
def load_log_from_path():
    """
    Handles loading the log file from a specified path on the server system.
    """
    global parsed_transcription_data
    
    log_file_path = request.form.get('log_path')

    if not log_file_path:
        return jsonify({"success": False, "message": "No log file path provided."})
    
    if not os.path.exists(log_file_path):
        return jsonify({"success": False, "message": f"Log file not found at path: {log_file_path}"})
    
    if not os.path.isfile(log_file_path):
        return jsonify({"success": False, "message": f"Provided path is not a file: {log_file_path}"})

    try:
        with open(log_file_path, 'r', encoding='utf-8') as f:
            log_content = f.read()
        
        parsed_transcription_data = parse_log_content(log_content)
        # Re-select directory to refresh playlist with new transcription data
        if current_directory:
            pass # The frontend will call selectDirectory() after a successful load
        return jsonify({
            "success": True,
            "message": f"Log file loaded from path and parsed successfully. {len(parsed_transcription_data)} entries found."
        })
    except Exception as e:
        app.logger.error(f"Error loading or parsing log file from path '{log_file_path}': {e}")
        return jsonify({"success": False, "message": f"Error loading or parsing log file: {str(e)}"})


@app.route('/status', methods=['GET'])
def get_status():
    """
    Returns the current status of the player, including directory and playlist info.
    Now also indicates if a log file has been loaded and includes transcription data.
    """
    files_with_transcription_info = []
    # If a directory has been selected, build the current playlist data for status
    if current_directory:
        for f_path in current_playlist:
            f_name = os.path.basename(f_path)
            file_url = f'/audio_files/{f_name}'
            transcription_info = parsed_transcription_data.get(f_name, None)
            files_with_transcription_info.append({
                "name": f_name,
                "url": file_url,
                "transcription": transcription_info
            })

    return jsonify({
        "currentDirectory": current_directory,
        "files_with_info": files_with_transcription_info,
        "logLoaded": bool(parsed_transcription_data)
    })

if __name__ == '__main__':
    app.run(debug=True, host='0.0.0.0', port=3000)
