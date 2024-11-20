template=".env.template"
package_manager="yarn"
# Check for package manager parameter
if [ $# -gt 0 ]; then
  package_manager="$1"
  # Validate package manager
  if [[ ! "$package_manager" =~ ^(npm|yarn|pnpm)$ ]]; then
    echo "Invalid package manager. Using yarn as default."
    package_manager="yarn"
  fi
fi

# Check if the template file exists
if [ ! -f "$template" ]; then
  echo "Error: $template not found"
  echo "Please enter the name of your template file (e.g. .env.template):"
  read template_input
  
  if [ ! -f "$template_input" ]; then
    echo "Error: $template_input not found either. Please ensure a template file exists."
    return 1
  fi
  
  template=$template_input
fi

errors_found=false

check_env_files() {
  files_not_to_check=("$template")
  # Get all .env files in the current directory
  files_to_check=($(find . -maxdepth 1 -type f -name '.env*'))

  # Remove files that are in files_not_to_check
  for file in "${files_not_to_check[@]}"; do
    files_to_check=(${files_to_check[@]/$file})
  done

  # Remove any empty elements
  files_to_check=(${files_to_check[@]})
  
  # Function to check template for empty values
  default_env_file=".env.development.local"
  check_template_warnings() {
    warning_template_count=0
    while IFS= read -r line || [[ -n "$line" ]]; do
      # Skip empty lines and comment lines
      if [[ -z "$line" || "$line" =~ ^[[:space:]]*# ]]; then
        continue
      fi
      
      key=$(echo "$line" | cut -d'=' -f1)
      value=$(echo "$line" | cut -d'=' -f2-)
      
      # Check if value is empty (nothing after =)
      value=$(echo "$value" | sed 's/[[:space:]]*#.*//;s/[[:space:]]*$//')
      if [[ -z "${value// }" ]]; then
        ((warning_template_count++))
        echo "\033[33m⚠️  Warning: '${key// /}' has no value in $default_env_file\033[0m"
      fi
    done < "$template"

    if [ $warning_template_count -gt 0 ]; then
      echo "\033[33m\n⚠️  Found $warning_template_count key(s) without values in $default_env_file\033[0m"
      echo "\033[33m⚠️  Please update value for the keys and run clean yarn cache again.\033[0m"
    fi
  }

  # If no .env files found, create .env.development.local and exit
  if [ ${#files_to_check[@]} -eq 1 ]; then
    echo "\033[33m🟠 No .env files found. Creating $default_env_file from template...\033[0m"
    cp "$template" "$default_env_file"
    echo "\033[32m✅ Created $default_env_file. Proceeding to clean yarn cache.\033[0m"

    # Call the warning check function
    yarn cache clean

    # Call the warning check function
    check_template_warnings
    return 1
  fi

  # Get terminal height and width
  terminal_height=$(tput lines)
  terminal_width=$(tput cols)

  # Variables to store output and result
  output=""
  result=""
  # Function to update the screen
  update_screen() {
    # Clear the screen
    tput clear

    # Print the output
    echo "$output"

    # Move cursor to the bottom and print the result
    tput cup $((terminal_height - 3)) 0
    printf '%*s\n' "$terminal_width" '' | tr ' ' '-'
    echo "$result"
    printf '%*s\n' "$terminal_width" '' | tr ' ' '-'

    # Move cursor back to the top
    tput cup 0 0
  }

  for file in "${files_to_check[@]}"; do
    warning_count=0
    if [ -f "$file" ]; then
      output+="\n"
      output+="Checking $file...\n\n"
      error_count=0

      # Loop through file and raise errors for keys not in template
      while IFS= read -r line || [[ -n "$line" ]]; do
        if [[ $line =~ ^[[:space:]]*# || -z $line ]]; then
          continue  # Skip comments and empty lines
        fi
        key=$(echo "$line" | cut -d'=' -f1)

        # Trim spaces from key before checking
        key="${key// /}"

        if ! grep -q "^$key\s*=" "$template"; then
          output+="\033[31m💔 Error: key '${key// /}' not found in $template\033[0m\n"
          ((error_count++))
          errors_found=true
        fi
      done < "$file"

      # Loop through template file
      while IFS= read -r line || [[ -n "$line" ]]; do
        # Skip empty lines and comment lines
        if [[ -z "$line" || "$line" =~ ^[[:space:]]*# ]]; then
          continue
        fi
        key=$(echo "$line" | cut -d'=' -f1)
        value=$(echo "$line" | cut -d'=' -f2-)
        
        # Trim spaces from key before checking
        key="${key// /}"
        if ! grep -q "^$key\s*=" "$file"; then
          output+="\033[31m💔 Error: Missing '${key// /}' in $file\033[0m\n"
          ((error_count++))
          errors_found=true
        fi

        # Check if value is empty (nothing after =)
        value=$(echo "$value" | sed 's/[[:space:]]*#.*//;s/[[:space:]]*$//')
        if [[ -z "${value// }" ]]; then
          ((warning_count++))
          output+="\033[33m🟠 Warning: '${key// /}' has no value in $template\033[0m\n"
        fi

        update_screen
      done < "$template"

      # Update final result
      output+="\n\n==========================================\n"

      if [ $error_count -gt 0 ]; then
        result+="\n\033[31m❌ Done checking $file with $error_count error(s) and $warning_count warning(s)\033[0m\n"
        output+="$result"
      else
        sleep 0.5
        if [ $warning_count -eq 0 ]; then
          result+="\n\033[32m✅ Done checking $file with no errors and no warnings\033[0m\n"
        else
          result+="\n\033[33m⚠️ Done checking $file with no errors and $warning_count warning(s)\033[0m\n"
        fi
        output+="$result"
      fi

      update_screen
      output+="\n"

      # Add a small delay to make the result visible at first check
      # Remove if you want to see the result immediately
      if [ "$file" = "${files_to_check[0]}" ]; then
        sleep 1
      fi
      
    else
      #output+="\033[33m🟠 Check $file: $file not found, skipping\033[0m\n"
      #result+="\033[33m⚠️ $file not found, skipping\033[0m\n"
      update_screen
    fi

  done

  # Clear the result at the end
  result=""
  update_screen
  sleep 1

  # Reset terminal settings
  tput rmcup  # Exit alternate screen buffer
  tput cnorm  # Show cursor
  tput sgr0   # Reset all attributes

  # Clear the screen and move cursor to top-left
  clear
  tput cup 0 0

  # Display final output
  echo "$output"
}

# Call the function
check_env_files

sync_env_files() {
  # Get all .env files in the current directory
  files_to_sync=($(find . -maxdepth 1 -type f -name '.env*'))
  
  # Exclude .env.template from files to sync
  files_to_sync=(${files_to_sync[@]/$template})

  # Remove any empty elements
  files_to_sync=(${files_to_sync[@]})

  # Sync files
  for file in "${files_to_sync[@]}"; do
    warning_count=0

    if [ -f "$file" ]; then
      # Check if the file is in the list of files not to sync
      
      echo "Syncing $file with $template..."

      # Loop through file and comment lines not in template
      while IFS= read -r line || [[ -n "$line" ]]; do
        if [[ $line =~ ^[[:space:]]*# || -z $line ]]; then
          continue  # Skip comments and empty lines
        fi
        key=$(echo "$line" | cut -d'=' -f1)

        # Trim spaces from key before checking
        key="${key// /}"

        if ! grep -q "^$key\s*=" "$template"; then
          #trim comments from line
          line=$(echo "$line" | sed 's/[[:space:]]*#.*//;s/[[:space:]]*$//')
          sed -i '' "s|^.*$key.*|# $line # Not in template|" "$file"
          echo "\033[31m  Commented: $key (not in template)\033[0m"
        fi
      done < "$file"

      # Loop through template file
      while IFS= read -r line || [[ -n "$line" ]]; do
        if [[ $line =~ ^[[:space:]]*# || -z $line ]]; then
          continue  # Skip comments and empty lines
        fi
        key=$(echo "$line" | cut -d'=' -f1)
        value=$(echo "$line" | cut -d'=' -f2-)

        # Trim spaces from key before checking
        key="${key// /}"

        if grep -q "^$key\s*=" "$file"; then
          # Key exists, check if value is different
          current_value=$(grep "^$key\s*=" "$file" | cut -d'=' -f2-)

          if [ "$current_value" != "$value" ]; then
            # Value is different, update it
            sed -i '' "/# $key=.*# Updated from template/d" "$file"

            # Trim spaces and comments
            current_value=$(echo "$current_value" | sed 's/[[:space:]]*#.*//;s/[[:space:]]*$//')
            value=$(echo "$value" | sed 's/[[:space:]]*#.*//;s/[[:space:]]*$//')

            sed -i '' "s|^$key\s*=.*|# $key=$value # value in template is different\n$key=$current_value|" "$file"
            echo "\033[33m  Updated: $key\033[0m"
          else
            echo "  Skipped: $key (value unchanged)"
          fi
        else
          # Key doesn't exist, add it
          echo "$key=$value # Added from template" >> "$file"
          echo "\033[32m  Added: $key\033[0m"

          # Check if value is empty (nothing after =)
          value=$(echo "$value" | sed 's/[[:space:]]*#.*//;s/[[:space:]]*$//')
          if [[ -z "${value// }" ]]; then
            ((warning_count++))
            echo "\033[33m⚠️  Warning: '${key// /}' has no value in template\033[0m"
          fi
        fi
      done < "$template"
      
      if [ $warning_count -gt 0 ]; then
        echo "\033[33m⚠️  Found $warning_count key(s) without values in $file\033[0m"
      fi
      echo "Finished syncing $file"
      echo

    fi
  done
}

if [ "$errors_found" = true ]; then
  echo "Errors were found in some .env files."
  echo "\033[33mDo you want to sync these .env* files with .env.template? (Y/n)\033[0m"
  echo "(Enter/Y/y for Yes | Any other key for No)"
  echo "Auto-skipping in 10 seconds...\n"
  answer="nokeypressed"
  read -t 10 -n 1 -r -s answer

  if [[ $answer == "nokeypressed" ]]; then
    echo "\033[33mSync operation cancelled.\033[0m"
  else
    if [[ $answer =~ ^[Yy]$ ]] || [[ $answer == "" ]]; then
      sync_env_files

      ## Clear React Native cache
      #rm -rf $TMPDIR/react-*
      #rm -rf $TMPDIR/metro-*
      #watchman watch-del-all
      
      # Clear package manager cache
      case $package_manager in
        "npm")
          echo "Clearing npm cache..."
          npm cache clean --force
          ;;
        "yarn") 
          echo "Clearing yarn cache..."
          yarn cache clean
          ;;
        "pnpm")
          echo "Clearing pnpm cache..."
          pnpm store prune
          ;;
      esac
    else
      echo "\033[33mSync operation cancelled.\033[0m"
    fi
  fi
  
else
  echo "\033[32m🟢 No keys are missing in .env.* files. Sync not needed.\033[0m"
fi
