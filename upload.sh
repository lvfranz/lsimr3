killall ssh-agent
eval "$(ssh-agent -s)"
ssh-add github
git push -u origin main --force
