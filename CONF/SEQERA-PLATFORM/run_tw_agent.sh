#!/bin/bash
# set -u # Exit on undefined variables

# Set Environment Variables
export TW_AGENT_WORK="/ibex/project/c2303/work"
export TOWER_LOG_LEVEL="DEBUG"
# Agent ID 
export AGENT_ID="76d064e5-8565-4df5-bef0-c41393a25c03"
# Get the Tower access token from the secrets file
source ~/.secrets/seqera-platform.sh # This should export TOWER_ACCESS_TOKEN from a secrets file with chmod 600

echo "Starting Tower Agent: $AGENT_ID"
chmod +x ~/tw-agent

# Launch tw-agent inside a tmux session
TMUX_SESSION_NAME="tw-agent-${AGENT_ID:0:8}"  # Use first 8 chars of AGENT_ID for session name

# Check if tmux session already exists
if tmux has-session -t "$TMUX_SESSION_NAME" 2>/dev/null; then
    echo "tmux session '$TMUX_SESSION_NAME' already exists. Skipping launch."
    echo "To attach to the existing session, run: tmux attach -t $TMUX_SESSION_NAME"
else
    # Create a new detached tmux session and run the tw-agent command
    echo "Launching tw-agent in tmux session: $TMUX_SESSION_NAME"
    tmux new-session -d -s "$TMUX_SESSION_NAME" "export TMOUT=1209600; echo \"TMOUT set to \$TMOUT seconds. Agent will run for 14 days.\"; export TOWER_LOG_LEVEL=DEBUG; echo \"TOWER_LOG_LEVEL set to \$TOWER_LOG_LEVEL. Agent will log at DEBUG level.\"; /home/pampum/tw-agent \"$AGENT_ID\" --work-dir=\"${TW_AGENT_WORK}\""
fi

echo "tw-agent is running in tmux session '$TMUX_SESSION_NAME'"
echo "To attach to the session, run: tmux attach -t $TMUX_SESSION_NAME"
echo "To detach from the session, press: Ctrl+b, then d"