# MacOS

## Auto Yarn

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

1. Copy .auto-yarn and source
