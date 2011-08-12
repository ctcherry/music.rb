#!/bin/bash

mkdir -p ~/bin
curl https://raw.github.com/ctcherry/music.rb/master/music.rb > ~/bin/music
chmod +x ~/bin/music

echo "Make sure ~/bin is in your PATH"
