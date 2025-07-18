import os
import re
import csv
from io import StringIO
from flask import Flask, render_template, request, jsonify, send_from_directory, send_file
from flask_cors import CORS
from pydub import AudioSegment
import tempfile

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
    Parses the log content to extract error segments for each audio file.
    Only supports the new CSV/TSV format as in sample_log.txt.
    Returns a dict mapping audio file basenames to a list of error segments.
    """
    data = {}
    # Auto-detect delimiter: use tab if more tabs than commas, else comma
    tab_count = log_content.count('\t')
    comma_count = log_content.count(',')
    delimiter = '\t' if tab_count > comma_count else ','
    reader = csv.reader(StringIO(log_content), delimiter=delimiter)
    header = next(reader, None)
    # Find relevant column indices
    def col(name):
        try:
            return header.index(name)
        except ValueError:
            return None
    col_audio = col('transcriptFile')
    col_long_start = col('longFormStart')
    col_long_end = col('longFormEnd')
    col_long_error = col('longFormError')
    col_short_error = col('shortFormError')
    col_short_start = col('shortFormStart')
    col_short_end = col('shortFormEnd')
    for row in reader:
        if not row or len(row) <= max(filter(None, [col_audio, col_long_start, col_long_end, col_long_error, col_short_error, col_short_start, col_short_end])):
            continue
        audio_path = row[col_audio]
        filename = os.path.basename(audio_path)
        try:
            long_start = float(row[col_long_start]) if col_long_start is not None else None
            long_end = float(row[col_long_end]) if col_long_end is not None else None
            short_start = float(row[col_short_start]) if col_short_start is not None and row[col_short_start] else None
            short_end = float(row[col_short_end]) if col_short_end is not None and row[col_short_end] else None
        except (ValueError, IndexError):
            long_start = long_end = short_start = short_end = None
        segment = {
            'longFormStart': long_start,
            'longFormEnd': long_end,
            'longFormError': row[col_long_error] if col_long_error is not None else '',
            'shortFormError': row[col_short_error] if col_short_error is not None else '',
            'shortFormStart': short_start,
            'shortFormEnd': short_end
        }
        if filename not in data:
            data[filename] = []
        data[filename].append(segment)
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

@app.route('/audio_segment')
def serve_audio_segment():
    """
    Serves a segment of an audio file, given filename, start, and end times (in seconds).
    The segment is [start-5, end+5] seconds, clipped to file boundaries.
    """
    filename = request.args.get('file')
    start = request.args.get('start', type=float)
    end = request.args.get('end', type=float)
    if not (filename and start is not None and end is not None):
        return "Missing parameters", 400
    if not current_directory:
        return "No directory selected", 400
    audio_path = os.path.join(current_directory, filename)
    if not os.path.exists(audio_path):
        return "Audio file not found", 404
    try:
        audio = AudioSegment.from_file(audio_path)
        duration = len(audio) / 1000.0  # in seconds
        seg_start = max(0, start - 5)
        seg_end = min(duration, end + 5)
        seg_audio = audio[int(seg_start * 1000):int(seg_end * 1000)]
        # Write to a temp file
        with tempfile.NamedTemporaryFile(delete=False, suffix='.wav') as tmpf:
            seg_audio.export(tmpf.name, format='wav')
            tmpf.flush()
            return send_file(tmpf.name, mimetype='audio/wav', as_attachment=False, download_name=f'{filename}_segment.wav')
    except Exception as e:
        app.logger.error(f"Error extracting audio segment: {e}")
        return f"Error extracting audio segment: {str(e)}", 500

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
        error_segments = parsed_transcription_data.get(f_name, [])
        files_with_transcription_info.append({
            "name": f_name,
            "url": file_url,
            "error_segments": error_segments
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
            error_segments = parsed_transcription_data.get(f_name, [])
            files_with_transcription_info.append({
                "name": f_name,
                "url": file_url,
                "error_segments": error_segments
            })

    return jsonify({
        "currentDirectory": current_directory,
        "files_with_info": files_with_transcription_info,
        "logLoaded": bool(parsed_transcription_data)
    })

if __name__ == '__main__':
    app.run(debug=True, host='0.0.0.0', port=3000)
