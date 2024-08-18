#!/bin/bash
# Purpose: Install Git 
sudo add-apt-repository ppa:git-core/ppa
sudo apt-get update
sudo apt-get install git -y
echo "`git --version` installed successfully"
