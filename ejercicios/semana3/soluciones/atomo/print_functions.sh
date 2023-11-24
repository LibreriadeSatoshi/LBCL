#!/bin/bash

# Colors
color_blue='\033[0;34m'
color_green='\033[0;32m'
color_red='\033[0;31m'
color_yellow='\033[0;33m'
color_none='\033[0m'

# Prints a formatted title with fixed lenght.
# Arguments:
#   $1 - Text to print out
print_title() {
  text=$1

  title_lenght=${#text}
  title_suffix_length=$(expr 100 - ${title_lenght})

  printf "\n\n${color_blue}━━━ ${color_yellow}$1 ${color_blue}"
  for i in $(seq 1 $title_suffix_length); do printf "━"; done
  printf "${color_none}\n"
}

# Prints an info message.
# Arguments:
#   $1 - Text to print out
print_info() {
  echo "\n${color_none}$1"
}

# Prints success message in green.
# Arguments:
#   $1 - Text to print out
print_success() {
  echo "\n${color_green}$1${color_none}"
}

# Prints an error message in red.
# Arguments:
#   $1 - Text to print out
print_error() {
  echo "\n${color_red}$1${color_none}"
}

# Prints a warning message in yellow.
# Arguments:
#   $1 - Text to print out
print_warning() {
  echo "\n${color_yellow}$1${color_none}"
}
