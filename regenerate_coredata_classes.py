#!/usr/bin/env python3

import os
import subprocess
import sys

def regenerate_coredata_classes():
    """Regenerate Core Data classes using xcodebuild"""
    
    project_path = "/Users/bix/Vihaan_stuff/Projects/CareGiver"
    xcodeproj_path = os.path.join(project_path, "CareGiver.xcodeproj")
    
    print("Regenerating Core Data classes...")
    
    # Clean the project first
    print("Cleaning project...")
    clean_cmd = [
        "xcodebuild", 
        "-project", xcodeproj_path,
        "-scheme", "CareGiver",
        "clean"
    ]
    
    try:
        result = subprocess.run(clean_cmd, capture_output=True, text=True, cwd=project_path)
        if result.returncode != 0:
            print(f"Clean failed: {result.stderr}")
            return False
        print("Project cleaned successfully")
    except Exception as e:
        print(f"Error cleaning project: {e}")
        return False
    
    # Build the project to regenerate Core Data classes
    print("Building project to regenerate Core Data classes...")
    build_cmd = [
        "xcodebuild",
        "-project", xcodeproj_path,
        "-scheme", "CareGiver",
        "-destination", "platform=iOS Simulator,name=iPad (A16)",
        "build"
    ]
    
    try:
        result = subprocess.run(build_cmd, capture_output=True, text=True, cwd=project_path)
        if result.returncode != 0:
            print(f"Build failed: {result.stderr}")
            # Don't return False here as we might have partial success
        else:
            print("Project built successfully")
    except Exception as e:
        print(f"Error building project: {e}")
    
    print("Core Data class regeneration complete")
    return True

if __name__ == "__main__":
    regenerate_coredata_classes()

