template=".env.template"

# Check if the template file exists
if [ ! -f "$template" ]; then
  echo "Error: $template not found"
  return 1
fi

errors_found=false

check_env_files() {
  files_not_to_check=(".env.template")
  # Get all .env files in the current directory
  files_to_check=($(find . -maxdepth 1 -type f -name '.env*'))

  # Remove files that are in files_not_to_check
  for file in "${files_not_to_check[@]}"; do
    files_to_check=(${files_to_check[@]/$file})
  done

  # Remove any empty elements
  files_to_check=(${files_to_check[@]})

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
    if [ -f "$file" ]; then
      output+="\n"
      output+="Checking $file...\n\n"
      error_count=0
      while IFS= read -r line || [[ -n "$line" ]]; do
        # Skip empty lines and comment lines
        if [[ -z "$line" || "$line" =~ ^[[:space:]]*# ]]; then
          continue
        fi
        key=$(echo "$line" | cut -d'=' -f1)
        if ! grep -q "^$key=" "$file"; then
          output+="\033[31m  💔 Missing in $file: $key\033[0m\n"
          ((error_count++))
          errors_found=true
        fi
        update_screen
      done < "$template"

      # Update final result
      output+="\n\n==========================================\n"

      if [ $error_count -gt 0 ]; then
        result+="\n\033[31m❌ Done checking $file with $error_count error(s)\033[0m\n"
        output+="$result"
      else
        result+="\n\033[32m✅ Done checking $file with no errors\033[0m\n"
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
    if [ -f "$file" ]; then

      # Check if the file is in the list of files not to sync
      
      echo "Syncing $file with $template..."

      # Comment lines not in template
      while IFS= read -r line || [[ -n "$line" ]]; do
        if [[ $line =~ ^[[:space:]]*# || -z $line ]]; then
          continue  # Skip comments and empty lines
        fi
        key=$(echo "$line" | cut -d'=' -f1)
        if ! grep -q "^$key=" "$template"; then
          sed -i '' "s|^$key=.*|# $line # Not in template|" "$file"
          echo "\033[31m  Commented: $key (not in template)\033[0m"
        fi
      done < "$file"


      while IFS= read -r line || [[ -n "$line" ]]; do
        if [[ $line =~ ^[[:space:]]*# || -z $line ]]; then
          continue  # Skip comments and empty lines
        fi
        key=$(echo "$line" | cut -d'=' -f1)
        value=$(echo "$line" | cut -d'=' -f2-)

        if grep -q "^$key=" "$file"; then
          # Key exists, check if value is different
          current_value=$(grep "^$key=" "$file" | cut -d'=' -f2-)
          if [ "$current_value" != "$value" ]; then
            # Value is different, update it
            sed -i '' "/# $key=.*# Updated from template/d" "$file"
            sed -i '' "s|^$key=.*|# $key=$value # Updated from template\n$key=$current_value|" "$file"
            echo "\033[33m  Updated: $key\033[0m"
          else
            echo "  Skipped: $key (value unchanged)"
          fi
        else
          # Key doesn't exist, add it
          echo "$key=$value # Added from template" >> "$file"
          echo "\033[32m  Added: $key\033[0m"
        fi

      done < "$template"
      
      echo "Finished syncing $file"
      echo

    fi
  done
}

if [ "$errors_found" = true ]; then
  echo "Errors were found in some .env files."
  echo "Do you want to sync .env files with .env.template? (y/N)"
  read -n 1 -r answer
  echo    # move to a new line
  if [[ $answer =~ ^[Yy]$ ]]; then
    sync_env_files

    #echo "Clearing cache and starting yarn..."
    ## Clear React Native cache
    #rm -rf $TMPDIR/react-*
    #rm -rf $TMPDIR/metro-*
    #watchman watch-del-all
    
    # Clear yarn cache
    yarn cache clean
  else
    echo "Sync operation cancelled."
  fi
else
  echo "\033[32m🟢 No errors found in .env files. Sync not needed.\033[0m"
fi
