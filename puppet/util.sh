# Needed to avoid "stdin: not a tty" error messages.
cat > /root/.profile << EOL
# ~/.profile: executed by Bourne-compatible login shells.

if [ "\$BASH" ]; then
  if [ -f ~/.bashrc ]; then
    . ~/.bashrc
  fi
fi

if \`tty -s\`; then
  mesg n
fi
EOL
