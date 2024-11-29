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

- Comment out `yarn cache clean`

--------------------------
# Auto Yarn

File:
```
./auto_yarn.sh
```

Intro: Function to switch brances in Git repo's

This allows me to switch to branches using ^x^x in any Git repository. It
uses fzf to allow fuzzy searching through branch names. If a repository contains
a package.json, it will detect differences between branches and run npm i.
The numbers in this file correspond to the outline of what is happening,

- Ask which branch to switch to
- Detect the presence of package.json in the root of the repository
- When present, calculate the hash of the dependencies and devDependencies sections of package.json
- Switch to the selected branch
- Calculate the hash of dependencies and devDependencies sections in package.json again
- If the hashes differ, print a message, sleep 2 seconds and then run npm i
- If you were in a deeper path in the repository before the branch switch, return to that path

1. Install dependency

https://github.com/junegunn/fzf#installation

```
brew install fzf
```

and

```
brew install jq
```

2. Copy file `auto-yarn.sh` to your user folder:

```
cp ./auto_yarn.sh ~/
```

Include this file into `~/.bashrc` then reload terminal session. You can also run

```
source ~/auto-yarn.sh
```

--------------------------
# Auto switch Nodejs version according to .NVCRC file

File:
```
./auto_nvmrc.sh
```

## Usage

- Check file .nvmrc in project folder
- Auto switch node version

1. Install NVM first:

```
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.3/install.sh | bash
```

Please read the docs from here `https://github.com/nvm-sh/nvm`

2. Copy file `auto-nvmrc.sh` to your user folder:

```
cp ./auto-nvmrc.sh ~/
```

Include this file into `~/.bashrc` then reload terminal session. You can also run

```
source ~/auto-nvmrc.sh
```

--------------------------
# Launch ssh-agent in new session and reuse the session
File:
```
./auto_ssh.sh
```

Intro: ssh-agent is basically launched per session. So I usually reuse one session across all other terminals. 
To do this i have the following setting in my .bashrc

- When bash is started, it launches a new ssh-agent and store the all environment variables into .ssh/environment
- When another bash is started, it loads environment from .ssh/environment so that it can connect to the existing ssh-agent process. So it does not start another ssh-agent process.
