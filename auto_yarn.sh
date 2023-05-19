
# Function to switch brances in Git repo's
#
# This allows me to switch to branches using ^x^x in any Git repository. It
# uses fzf to allow fuzzy searching through branch names. If a repository contains
# a package.json, it will detect differences between branches and run npm i.
# The numbers in this file correspond to the outline of what is happening,
# borrow idea from: https://medium.com/@jhkuperus/automatically-running-npm-install-when-switching-branches-432af36c9d2e
function select_branch() {
  local hasPackageJson=0
  local gitRoot=$(pwd)"/package.json" #$(git rev-parse --show-toplevel)

  local currentPackageJsonHash=

  # 2. If package.json exists on the top of the repository...
  if [[ -f $gitRoot ]];
  then
    hasPackageJson=1
  else
    echo "package.json not found"
    local nextDir
    nextDir=$(find . -type f -name package.json -maxdepth +3 | egrep -v "node_modules|.git" | fzf)
    if [[ -f $nextDir ]]
      echo "next dir"$nextDir
      gitRoot=$nextDir
      hasPackageJson=1
  fi
  
  if [[ $hasPackageJson == 1 ]];
  then
    local branch
    local dirFromPath=${gitRoot%/*}
    local searchFile="package.json"

    # Move to the folder has package.json
    cd $dirFromPath
    zle -M "Select a branch to switch to:\n"

    # 1. Here we list all available git branches and feed them to fzf
    # In fzf you can type and fuzzy-search for the branch you want
    # Once a branch is selected, it is returned and stored in branch
    branch=$(git branch -a --list --format "%(refname:lstrip=2)" | \
      FZF_DEFAULT_OPTS="--height 30% $FZF_DEFAULT_OPTS -n2..,.. --tiebreak=index --bind=ctrl-r:toggle-sort $FZF_CTRL_R_OPTS --query=${(qqq)LBUFFER} +m" fzf)


    # 3. Calculate the hash of relevant parts of package.json
    # Continue only if a branch was selected
    if [[ ! -z "$branch" ]];
    then
      currentPackageJsonHash=$(cat $searchFile | \
        jq ".dependencies,.devDependencies" | \
        md5)

      # Note to future self: the syntax ${variable/<regex>/<replacement>} is just frikkin awesome
      # 4. Actually switch to the selected branch
      git checkout ${branch/origin\//}


      # 5. Calculate has of package.json again
      local newPackageJsonHash=$(cat $searchFile | jq ".dependencies,.devDependencies" | md5)
      echo $newPackageJsonHash

      # 6. If hashes differ, run npm install
      if [[ $newPackageJsonHash != $currentPackageJsonHash ]];
      then
        echo "The package.json has changed between branches,"
        echo "Running \"npm install\" in 2 seconds unless you cancel it now..."
        sleep 1
        echo "Running \"npm install\" in 1 seconds unless you cancel it now..."
        sleep 1
        echo "Running \"npm install\" in 0 seconds unless you cancel it now..."

        ## 7. Make sure to remember the path if it's not $gitRoot
        #local usePopd=0
        #local dirFromPath=${gitRoot%/*}
        #echo $dirFromPath
        #if [[ $(pwd) != $dirFromPath ]];
        #then
        #  pushd $dirFromPath
        #  usePopd=1
        #fi

        yarn

        ## 7b. Use popd to restore the previous path
        #if [[ $usePopd == 1 ]];
        #then
        #  popd
        #fi
      fi
    fi
  fi

  echo "\n\n"
  zle reset-prompt
}
 
zle -N select_branch

bindkey "^x^x" select_branch
