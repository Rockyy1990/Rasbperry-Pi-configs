import subprocess

# Define input and output file paths
input_file = r'C:/Users/Admin/The Contract (Thriller).mp4'
output_file = r'D:\output.mkv'

# Construct the ffmpeg command
command = [
    'ffmpeg',
    '-i', input_file,
    '-c:v', 'libx265',
    '-vb', '2400k',
    '-tune', 'film',
    '-tune', 'fastdecode',
    '-preset', 'medium',
    '-c:a', 'aac',
    '-b:a', '224k',
    '-ac', '2',
    output_file
]

# Run the command
try:
    subprocess.run(command, check=True)
    print("Conversion successful!")
except subprocess.CalledProcessError as e:
    print(f"An error occurred: {e}")
