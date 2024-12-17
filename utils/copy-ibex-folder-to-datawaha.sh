#!/usr/bin/env bash

# Exit script if any command fails
set -e

# Function to display usage information
usage() {
  echo "Usage: $0 <folder_to_compress>"
  echo "  <folder_to_compress> : The folder to compress and calculate MD5 checksum."
  exit 1
}

# Validate that the user provided a folder to compress
if [ $# -lt 1 ]; then
  usage
fi

# Get the folder name from the shell arguments
FOLDER_TO_COMPRESS="$1"

# Validate that the provided folder exists
if [ ! -d "$FOLDER_TO_COMPRESS" ]; then
  echo "Error: Folder '$FOLDER_TO_COMPRESS' does not exist!"
  exit 1
fi

# Create a timestamp for naming the tarball and md5sum files
TIMESTAMP=$(date -I | sed 's/-//g')
HOSTNAME=$(hostname)

# Tar and gzip the folder
TAR_FILE="${FOLDER_TO_COMPRESS}.tar.gz"
echo "Compressing folder '$FOLDER_TO_COMPRESS' to '$TAR_FILE'..."
tar -czf - -C "$(dirname "$FOLDER_TO_COMPRESS")" "$(basename "$FOLDER_TO_COMPRESS")" | pv -s $(du -sb "$FOLDER_TO_COMPRESS" | awk '{print $1}') > "$TAR_FILE"
# MD5SUM check the compressed tarball and create checksum file
echo "Calculating MD5 checksum for '$TAR_FILE'..."
MD5SUM_FILE="${TAR_FILE}.${TIMESTAMP}.${HOSTNAME}.md5"
pv "$TAR_FILE" | md5sum | sed "s/-/$TAR_FILE/" >"$MD5SUM_FILE"

# Display the result of the checksum
echo -e "\n--- MD5SUM for '$TAR_FILE' ---"
cat "$MD5SUM_FILE"

# Package the tarball and the MD5SUM together in a directory
PACKAGE_DIR="${FOLDER_TO_COMPRESS}_DATAWAHA"
mkdir -p "$PACKAGE_DIR"
echo "MOVING $TAR_FILE $MD5SUM_FILE $PACKAGE_DIR"
mv "$TAR_FILE" "$MD5SUM_FILE" "$PACKAGE_DIR"

# Now move the packaged folder to the remote server using rsync
# Retry logic for rsync and remote verification
MAX_RETRIES=2
RETRY_DELAY=5 # seconds between retries
attempt=1

# Specify the SSH private key for rsync
SSH_KEY_PATH="$HOME/.ssh/id_rsa" # Default location

# Specify the destination path on the remote server
DEST_PATH="dm.kaust.edu.sa:/datawaha/ssbdrive/97_ibex-backups/Mark-Pampuch/ibex-data/BCL-DATA"

# Transfer the packaged folder to the remote server using rsync
while [ "$attempt" -le $MAX_RETRIES ]; do
  echo "Attempt $attempt of $MAX_RETRIES: Transferring '$PACKAGE_DIR' to '$DEST_PATH' using SSH key '$SSH_KEY_PATH'..."

  # Move the packaged folder to the remote server using rsync
  if rsync -avP -e "ssh -i $SSH_KEY_PATH" "$PACKAGE_DIR" "$DEST_PATH"; then
    echo "Transfer successful on attempt $attempt."
    break
  else
    echo "Transfer failed on attempt $attempt. Retrying in $RETRY_DELAY seconds..."
    ((attempt++))
    sleep $RETRY_DELAY
  fi
done

# SSH into the remote machine and verify the MD5 checksum of the transferred file
REMOTE_TAR_FILE="${DEST_PATH#dm.kaust.edu.sa:}/${PACKAGE_DIR}/$(basename "$TAR_FILE")"
attempt=1

while [ "$attempt" -le $MAX_RETRIES ]; do
    echo "Attempt $attempt of $MAX_RETRIES: Verifying MD5 checksum on the remote server for '$REMOTE_TAR_FILE'..."

    # SSH into the remote server and verify the MD5 checksum
    if ssh -i "$SSH_KEY_PATH" pampum@dm.kaust.edu.sa <<EOF
    cd "$(dirname "${REMOTE_TAR_FILE}")" && \
    md5sum "$(basename "${REMOTE_TAR_FILE}")" > \
    "${REMOTE_TAR_FILE}.$(date -I | sed 's/-//g').\$(hostname).md5"
EOF
  then
    echo "MD5 verification successful on attempt $attempt."
    break
  else
    echo "MD5 verification failed on attempt $attempt. Retrying..."
    ((attempt++))
    sleep $RETRY_DELAY
  fi
done

# Check if MD5 verification succeeded after all attempts
if [ $attempt -gt $MAX_RETRIES ]; then
  echo "MD5 verification failed after $MAX_RETRIES attempts. Exiting script."
  exit 1
fi

# Optional: Clean up the local files after transfer
echo "Cleaning up local files..."
rm -rf "$PACKAGE_DIR"

echo "Transfer complete. Exiting script."
