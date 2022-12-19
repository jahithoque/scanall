#!/bin/bash

# Set the file to store the results in
results_file="endpoints.txt"

# Set the directory to store the intermediate results in
results_dir="results"

# Check if the results directory exists, and create it if it doesn't
if [ ! -d "$results_dir" ]; then
  mkdir "$results_dir"
fi

# Check if the subdomains list file was provided as an argument
if [ -z "$1" ]; then
  echo "Error: Please provide the path to the list of subdomains as an argument."
  exit 1
fi

# Set the list of subdomains
subdomains_list="$1"

# Iterate over the list of subdomains
while read -r subdomain; do
  # Run dirsearch on the subdomain
  echo "Running dirsearch on $subdomain"
  sudo dirsearch -u "$subdomain" -e * -t 50 -x 301,302,400,401,402,403,405,406,429 -f -o "$results_dir/$subdomain-dirsearch.txt"
  if [ $? -ne 0 ]; then
    echo "Error: dirsearch failed to run or produced unexpected results."
    exit 1
  fi

  # Run hakrawler on the subdomain
  echo "Running hakrawler on $subdomain"
  sudo hakrawler -d 3 -t 10 -subs -timeout 5 "$subdomain" | tee "$results_dir/$subdomain-hakrawler.txt"
  if [ $? -ne 0 ]; then
    echo "Error: hakrawler failed to run or produced unexpected results."
    exit 1
  fi

  # Run gau on the subdomain
  echo "Running gau on $subdomain"
  sudo gau "$subdomain" | tee "$results_dir/$subdomain-gau.txt"
  if [ $? -ne 0 ]; then
    echo "Error: gau failed to run or produced unexpected results."
    exit 1
  fi

  # Run arjun on the subdomain
  echo "Running arjun on $subdomain"
  sudo arjun -u https://"$subdomain" | tee "$results_dir/$subdomain-arjun.txt"
  if [ $? -ne 0 ]; then
    echo "Error: arjun failed to run or produced unexpected results."
    exit 1
  fi
done < "$subdomains_list"

# Concatenate all of the intermediate results files into a single file
cat "$results_dir"/* > "$results_file"

# Remove the individual results files
rm "$results_dir"/*

# Extract only the URL's from the results file
grep -o 'http[s]*://[^/]*' "$results_file" > "$results_file.tmp"

# Replace the results file with the filtered version
mv "$results_file.tmp" "$results_file"

echo "All Tasks Completed!"
echo "Good Luck Hacker"
