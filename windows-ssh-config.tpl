add-content -path c:/users/neman/.ssh/config -value @'

Host ${hostname} 
    HostName ${hostname}
    User ${user}
    IdentityFile ${identityfile}
'@