
touch ~/.bash_aliases
# if [ -z $(cat ~/.bash_aliases | grep " \.\.") ]; then
#   echo "alias ..='cd ..'" >> ~/.bash_aliases  
# fi

# if [ -z $(cat ~/.bash_aliases | grep " \.\.\.") ]; then
#   echo "alias ...='cd ../..'" >> ~/.bash_aliases
# fi

if [ -z $(cat ~/.bash_aliases | grep " kcat") ]; then
  echo "alias kcat='kafkacat'" >> ~/.bash_aliases
fi

if [ -z $(cat ~/.bash_aliases | grep " psx") ]; then
  echo "alias psx='ps aux | grep -v grep'" >> ~/.bash_aliases
fi

if [ -z $(cat ~/.bash_aliases | grep " py3") ]; then
  echo "alias py3='python3'" >> ~/.bash_aliases
fi

# echo "" >> ~/.bash_aliases
# echo "" >> ~/.bash_aliases
# echo "" >> ~/.bash_aliases