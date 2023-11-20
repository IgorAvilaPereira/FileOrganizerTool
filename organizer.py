# Script file based on https://medium.com/@gamsahamidah95/organize-files-in-folders-using-python-script-49fdd4afc6d5

import os 
import shutil 

print("Starting Organize Tool....")

# your Downloads directory
desktop_path = "/home/"+os.getlogin()+"/Downloads/"

folders = {
    "Images": [".jpeg", ".jpg", ".png", ".gif", ".jpeg", ".jpg", ".svg", ".bitmap"],
    "Documents": [".doc", ".docx", ".pdf", ".txt",".xlsx", ".xls", ".odt", ".odp", ".ods", ".PDF", ".csv", ".ppt", ".pptx", ".rtf"],
    "Archives": [".zip", ".rar", ".dmg", ".iso", ".bz2", ".gz", ".7z", ".xz", ".tar", ".tgz"],
    "Videos": [".MP4",".mp4",".mov", ".mkv", ".srt", ".avi", ".webm"],
    "Work": [".roz"],
    "Audio": [".mp3",".wav"],
    "Programming": [".SQL",".sql",".py",".java", ".dia", ".json", ".php", ".html", ".js", ".css", ".sh", ".dtd", ".jar", ".mwb", ".bak", ".autosave"],
    "Progs": [".flatpak",".deb",".exe", ".AppImage", ".flatpakref"],
    "Torrents": [".torrent"],
    "Download": ["crdownload"],
    "Personal": [".opml"]
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
                if file_name.strip().endswith(extension):
                    destination_folder = os.path.join(desktop_path, folder_name)                
                    try:
                        shutil.move(original_file_path, destination_folder)
                        os.remove(original_file_path)                        
                    except Exception as e:
                        # se tiver arquivos com o mesmo nome, o arquivo das subpastas eh sobreescrito pelo novo arquivo que esta em Download
                        os.remove(destination_folder+"/"+file_name.strip())                        
                        shutil.move(original_file_path, destination_folder)
                        # os.remove(original_file_path)                     
print("Done...")
