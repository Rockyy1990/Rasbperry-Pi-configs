import subprocess

def convert_to_x264(input_file, output_file):
    # Construct the ffmpeg command with arguments
    ffmpeg_command = [
        'ffmpeg',
        '-i', input_file,
        '-vcodec', 'libx264',
        '-vb', '2400k',
        '-tune', 'film',
        '-tune', 'fastdecode',
        '-preset', 'medium',
        '-acodec', 'aac',
        '-ab', '224k',
        '-ac', '2',
        output_file
    ]

    # Execute the ffmpeg command
    subprocess.run(ffmpeg_command)

if __name__ == "__main__":
    input_file = r"D:\Sourcefile"  # Specify the input file path
    output_file = r"D:\Output.mp4"  # Specify the output file path
    convert_to_x264(input_file, output_file)
