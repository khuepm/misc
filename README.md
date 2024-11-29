# Environment File Checker and Syncer

Intro: This bash script provides functionality to check and sync environment files in your project.

File:
```
check_env_files.sh
```


## Features

1. Checks `.env` files against a template (`.env.template`)
2. Identifies missing variables in `.env` files
3. Offers to sync `.env` files with the template
4. Skips syncing content for specified files

## Usage

1. Place the script (`check_env_files.sh`) in your project root directory.
2. Ensure you have a `.env.template` file with all required environment variables.
3. Make the script executable:
   ```
   chmod +x check_env_files.sh
   ```
4. Run the script:
   ```
   ./check_env_files.sh
   ```
5. (optional) Add to `package.json` to check every start yarn
    ```
    {
      ...
      scripts: {
        "prestart": "sh check_env_files.sh",
      }
    }
    ```
You can change `sh` to `bash` if you want to use bash instead of sh, especially on Ubuntu.

## What it does

1. **Checking Environment Files**:
   - The script checks all `.env*` files in the current directory against `.env.template`.
   - It displays missing variables in each file.
   - A summary of errors (if any) is shown for each file.

2. **Syncing Environment Files**:
   - If errors are found, the script offers to sync `.env` files with `.env.template`.
   - If you choose to sync (by entering 'y'), the script will:
     - Comment out variables not present in the template
     - Add new variables from the template
     - keep existing variables: preserving the current value and adding a comment with the template value

## Configuration

- The script uses `.env.template` as the reference. Ensure this file contains all required variables for your project.

## Note

After syncing, the script cleans the yarn cache. You may want to adjust or remove this step based on your project needs.
