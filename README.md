# MacOS

## Auto Yarn

Function to switch brances in Git repo's

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

## Auto swith Nodejs version according to .NVCRC file

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
