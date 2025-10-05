#!/usr/bin/env python3
"""
Script to add Core Data entity files to Xcode project
"""

import os
import uuid

# File paths
project_file = "CareGiver.xcodeproj/project.pbxproj"

# Core Data files to add
core_data_files = [
    "CareGiver/Models/CalendarTask+CoreDataClass.swift",
    "CareGiver/Models/CalendarTask+CoreDataProperties.swift",
    "CareGiver/Models/CalendarSettings+CoreDataClass.swift",
    "CareGiver/Models/CalendarSettings+CoreDataProperties.swift",
    "CareGiver/Models/CompletedTask+CoreDataClass.swift",
    "CareGiver/Models/CompletedTask+CoreDataProperties.swift",
]

def generate_uuid():
    """Generate a 24-character uppercase hex string (Xcode-style)"""
    return uuid.uuid4().hex.upper()[:24]

def add_files_to_project():
    print("Adding Core Data files to Xcode project...")
    
    # Read the project file
    with open(project_file, 'r') as f:
        content = f.read()
    
    # Generate UUIDs for each file (2 per file: PBXFileReference and PBXBuildFile)
    file_refs = {}
    build_files = {}
    
    for file_path in core_data_files:
        filename = os.path.basename(file_path)
        file_refs[filename] = generate_uuid()
        build_files[filename] = generate_uuid()
        print(f"  {filename}")
        print(f"    File Ref: {file_refs[filename]}")
        print(f"    Build File: {build_files[filename]}")
    
    # Find the PBXFileReference section
    pbx_file_ref_marker = "/* Begin PBXFileReference section */"
    
    # Create file reference entries
    file_ref_entries = []
    for file_path in core_data_files:
        filename = os.path.basename(file_path)
        file_ref_id = file_refs[filename]
        entry = f"\t\t{file_ref_id} /* {filename} */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = \"{filename}\"; sourceTree = \"<group>\"; }};"
        file_ref_entries.append(entry)
    
    # Find insertion point in PBXFileReference section (after CoreDataManager.swift)
    insert_after = "CoreDataManager.swift */ = {isa = PBXFileReference;"
    
    if insert_after in content:
        parts = content.split(insert_after, 1)
        # Find the end of that line
        line_end = parts[1].find('\n')
        new_content = (parts[0] + insert_after + parts[1][:line_end+1] + 
                      '\n'.join(file_ref_entries) + '\n' + parts[1][line_end+1:])
        content = new_content
        print("\n✅ Added file references")
    else:
        print("⚠️  Could not find insertion point for file references")
    
    # Find the PBXBuildFile section
    pbx_build_file_marker = "/* Begin PBXBuildFile section */"
    
    # Create build file entries
    build_file_entries = []
    for file_path in core_data_files:
        filename = os.path.basename(file_path)
        build_file_id = build_files[filename]
        file_ref_id = file_refs[filename]
        entry = f"\t\t{build_file_id} /* {filename} in Sources */ = {{isa = PBXBuildFile; fileRef = {file_ref_id} /* {filename} */; }};"
        build_file_entries.append(entry)
    
    # Find insertion point in PBXBuildFile section
    insert_after_build = "CoreDataManager.swift in Sources */ = {isa = PBXBuildFile;"
    
    if insert_after_build in content:
        parts = content.split(insert_after_build, 1)
        line_end = parts[1].find('\n')
        new_content = (parts[0] + insert_after_build + parts[1][:line_end+1] + 
                      '\n'.join(build_file_entries) + '\n' + parts[1][line_end+1:])
        content = new_content
        print("✅ Added build file references")
    else:
        print("⚠️  Could not find insertion point for build files")
    
    # Find the Models group and add files
    models_group_marker = "/* Models */ = {"
    
    if models_group_marker in content:
        # Find the children array in the Models group
        start = content.find(models_group_marker)
        children_start = content.find("children = (", start)
        children_end = content.find(");", children_start)
        
        # Add our file references to the children array
        children_content = content[children_start:children_end]
        new_children = []
        for file_path in core_data_files:
            filename = os.path.basename(file_path)
            file_ref_id = file_refs[filename]
            new_children.append(f"\t\t\t\t{file_ref_id} /* {filename} */,")
        
        # Insert before the closing of children array
        insertion_point = children_end
        new_content = (content[:insertion_point] + '\n' + 
                      '\n'.join(new_children) + '\n\t\t\t' + content[insertion_point:])
        content = new_content
        print("✅ Added files to Models group")
    else:
        print("⚠️  Could not find Models group")
    
    # Find the PBXSourcesBuildPhase section and add files
    sources_build_phase = "/* Sources */ = {"
    
    if sources_build_phase in content:
        start = content.find(sources_build_phase)
        files_start = content.find("files = (", start)
        files_end = content.find(");", files_start)
        
        # Add our build file references
        new_build_refs = []
        for file_path in core_data_files:
            filename = os.path.basename(file_path)
            build_file_id = build_files[filename]
            new_build_refs.append(f"\t\t\t\t{build_file_id} /* {filename} in Sources */,")
        
        insertion_point = files_end
        new_content = (content[:insertion_point] + '\n' + 
                      '\n'.join(new_build_refs) + '\n\t\t\t' + content[insertion_point:])
        content = new_content
        print("✅ Added files to build phase")
    else:
        print("⚠️  Could not find Sources build phase")
    
    # Write the modified project file
    backup_file = project_file + ".backup"
    print(f"\n📦 Creating backup: {backup_file}")
    with open(backup_file, 'w') as f:
        f.write(content)
    
    with open(project_file, 'w') as f:
        f.write(content)
    
    print(f"\n✅ Project file updated: {project_file}")
    print("\n🎉 Done! Now open Xcode and build the project (Cmd+B)")

if __name__ == "__main__":
    if not os.path.exists(project_file):
        print(f"❌ Error: Could not find {project_file}")
        print("   Make sure you're running this from the project root directory")
        exit(1)
    
    # Check if files exist
    missing_files = []
    for file_path in core_data_files:
        if not os.path.exists(file_path):
            missing_files.append(file_path)
    
    if missing_files:
        print("❌ Error: Some Core Data files are missing:")
        for f in missing_files:
            print(f"   - {f}")
        exit(1)
    
    add_files_to_project()


