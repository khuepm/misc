SSH_ENV="${HOME}/.ssh/environment"
SSHAGENT=/usr/bin/ssh-agent
SSHAGENTARGS="-s"

function start_agent {
    echo -n "Initialising new SSH agent..."
    ${SSHAGENT} | sed 's/^echo/#echo/' > "${SSH_ENV}"
    echo succeeded
    chmod 600 "${SSH_ENV}"

    . "${SSH_ENV}" > /dev/null
    ssh-add
}

# Source SSH settings, if applicable
if [ -f "${SSH_ENV}" ]; then
    . "${SSH_ENV}" > /dev/null
    #ps ${SSH_AGENT_PID} doesn't work under cywgin
    ps -ef | grep ${SSH_AGENT_PID} | grep ssh-agent$ > /dev/null || {
        start_agent;
    }

    if [[ -z `ssh-add -l | grep "${HOME}/.ssh/id_"` ]]; then
        ssh-add
    fi
else
    start_agent;
fi