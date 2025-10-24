import subprocess

def convert_to_hevc(input_file, output_file):
    gst_command = [
        'gst-launch-1.0',
        'filesrc', f'location={input_file}',
        '!', 'decodebin', 'name=dec',
        'dec.', '!', 'queue', '!', 'videoconvert',
        '!', 'video/x-raw,format=YUV420',
        '!', 'x265enc', 'bitrate=4000', 'speed-preset=fast',
        '!', 'h265parse', '!', 'mp4mux', 'name=mux',
        'dec.', '!', 'queue', '!', 'audioconvert',
        '!', 'audioresample',
        '!', 'avenc_aac', 'bitrate=192000',
        '!', 'aacparse', '!', 'mux.',
        '!', f'filesink location={output_file}'
    ]

    # Execute the GStreamer command
    subprocess.run(gst_command)

if __name__ == "__main__":
    input_file = "input.mkv"  # Specify the input file
    output_file = "output_h265.mp4"  # Specify the output file
    convert_to_hevc(input_file, output_file)
