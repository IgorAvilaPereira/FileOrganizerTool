# Script file from https://medium.com/@gamsahamidah95/organize-files-in-folders-using-python-script-49fdd4afc6d5

import os 
import shutil 

print("Starting Organize Tool....")

# your directory
desktop_path = "/home/iapereira/Downloads/"

folders = {
    "Images": [".jpeg", ".jpg", ".png", ".gif", ".jpeg", ".jpg", ".svg", ".bitmap"],
    "Documents": [".doc", ".docx", ".pdf", ".txt",".xlsx", ".odt", ".odp", ".ods", ".PDF", ".csv", ".ppt", ".pptx"],
    "Archives": [".zip", ".rar", ".dmg", ".iso", ".bz2", ".gz", ".7z"],
    "Videos": [".MP4",".mp4",".mov", ".mkv", ".srt", ".avi"],
    "Programming": [".sql",".py",".java", ".dia", ".json", ".php", ".html", ".js", ".css", ".sh", ".dtd"],
    "Progs": [".flatpak",".deb",".exe", ".AppImage", ".flatpakref"],
    "Torrents": [".torrent"]
}

for folder_name in folders:
    folder_path = os.path.join(desktop_path, folder_name)
    if not os.path.exists(folder_path):
        os.makedirs(folder_path)
        # print("n existe")
    # else:
    #     print("ja existe")
        
for file_name in os.listdir(desktop_path):
    original_file_path = os.path.join(desktop_path, file_name)    
    if os.path.isfile(original_file_path):
        for folder_name, extensions in folders.items():
            for extension in extensions:
                if file_name.endswith(extension):
                    destination_folder = os.path.join(desktop_path, folder_name)
                    print(original_file_path)
                    print(destination_folder)                
                    try:
                        shutil.move(original_file_path, destination_folder)
                        os.unlink(original_file_path)
                        # print("apagou")
                    except:
                        pass
                        # print("deu ruim!")
                        # exit()
                    # exit()

print("Done...")