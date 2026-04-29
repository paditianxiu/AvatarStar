import os
import subprocess
import argparse

def process_lua_files(java_path, input_dir, output_dir):
    for root, dirs, files in os.walk(input_dir):
        for file in files:
            if file.endswith(".luac"):
                input_file = os.path.join(root, file)
                # Correctly form the output path by replacing the extension
                rel_path = os.path.relpath(input_file, input_dir)
                output_rel_path = os.path.splitext(rel_path)[0] + ".lua"
                output_file = os.path.join(output_dir, output_rel_path)
                
                os.makedirs(os.path.dirname(output_file), exist_ok=True)
                print("Decompiling %s" % input_file)
                # Use java_path directly, and correct the jar path
                subprocess.run([java_path, "-jar", "unluac/unluac.jar", input_file], stdout=open(output_file, "w"))

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Process Lua files and call a Java program.")
    parser.add_argument("input_dir", help="Lua bytecode files")
    parser.add_argument("output_dir", help="Output")
    parser.add_argument("java_path", help="Java path")
    args = parser.parse_args()

    process_lua_files(args.java_path, args.input_dir, args.output_dir)
