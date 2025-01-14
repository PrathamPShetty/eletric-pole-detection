# import os


# directory_path1 = "./test/labels"
# directory_path1 = "./train/labels"
# directory_path = "./valid/labels"

# # Class IDs to remove
# class_ids_to_remove = {"0", "3", "4"}

# # Loop through all files in the directory
# for filename in os.listdir(directory_path):
#     if filename.endswith(".txt"):  # Process only .txt files
#         file_path = os.path.join(directory_path, filename)
        
#         # Read the file and filter lines
#         with open(file_path, "r") as file:
#             lines = file.readlines()
        
#         # Remove lines with unwanted class IDs
#         filtered_lines = [line for line in lines if line.split()[0] not in class_ids_to_remove]
        
#         # Write the filtered lines back to the file
#         with open(file_path, "w") as file:
#             file.writelines(filtered_lines)
        
#         print(f"Processed file: {filename}")

# print("Classes removed successfully from all files.")


import os

# Directories containing your annotation files
directories = ["./dataset/test/labels", "./dataset/train/labels", "./dataset/valid/labels"]

# Class ID to replace and its replacement
class_id_to_replace = "2"
replacement_class_id = "1"

# Loop through all specified directories
for directory_path in directories:
    for filename in os.listdir(directory_path):
        if filename.endswith(".txt"):  # Process only .txt files
            file_path = os.path.join(directory_path, filename)
            
            # Read the file and modify lines
            with open(file_path, "r") as file:
                lines = file.readlines()
            
            # Replace class ID 0 with 2
            modified_lines = [
                line.replace(f"{class_id_to_replace} ", f"{replacement_class_id} ", 1)
                if line.split()[0] == class_id_to_replace else line
                for line in lines
            ]
            
            # Write the modified lines back to the file
            with open(file_path, "w") as file:
                file.writelines(modified_lines)
            
            print(f"Processed file: {filename} in {directory_path}")

print("Class ID replaced successfully in all files.")
