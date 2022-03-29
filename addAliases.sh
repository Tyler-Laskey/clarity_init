ALIAS_FILE=~/.bash_aliases
touch $ALIAS_FILE
# if [ -z ${cat ~/.bash_aliases | grep " \\.\\."} ]; then
#   echo "alias ..='cd ..'" >> ~/.bash_aliases  
# fi

# if [ -z ${cat ~/.bash_aliases | grep " \.\.\."} ]; then
#   echo "alias ...='cd ../..'" >> ~/.bash_aliases
# fi

if [ -z ${cat $ALIAS_FILE | grep " kcat"} ]; then
  echo "alias kcat='kafkacat'" >> $ALIAS_FILE
fi

if [ -z ${cat $ALIAS_FILE | grep " psx"} ]; then
  echo "alias psx='ps aux | grep -v grep'" >> $ALIAS_FILE
fi

if [ -z ${cat $ALIAS_FILE | grep " py3"} ]; then
  echo "alias py3='python3'" >> $ALIAS_FILE
fi

# echo "" >> ~/.bash_aliases
# echo "" >> ~/.bash_aliases
# echo "" >> ~/.bash_aliases