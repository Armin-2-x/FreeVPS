#!/bin/bash

set -e

if [[ -z "$NGROK_AUTH_TOKEN" ]]; then
  echo "Please set 'NGROK_AUTH_TOKEN'"
  exit 2
fi

if [[ -z "$LINUX_USER_PASSWORD" ]]; then
  echo "Please set 'LINUX_USER_PASSWORD'"
  exit 3
fi

if [[ -z "$LINUX_USERNAME" ]]; then
  echo "Please set 'LINUX_USERNAME'"
  exit 4
fi

echo "### Create user ###"

if ! id "$LINUX_USERNAME" >/dev/null 2>&1; then
  sudo useradd -m -s /bin/bash "$LINUX_USERNAME"
fi

sudo adduser "$LINUX_USERNAME" sudo || true
echo "$LINUX_USERNAME:$LINUX_USER_PASSWORD" | sudo chpasswd

echo "### Configure shell ###"

sudo sed -i 's#/bin/sh#/bin/bash#g' /etc/passwd

echo "### Set hostname ###"

sudo hostname "$LINUX_MACHINE_NAME"

echo "### Install ngrok v3 ###"

curl -sSL https://ngrok-agent.s3.amazonaws.com/ngrok.asc \
  | sudo tee /etc/apt/trusted.gpg.d/ngrok.asc >/dev/null

echo "deb https://ngrok-agent.s3.amazonaws.com buster main" \
  | sudo tee /etc/apt/sources.list.d/ngrok.list >/dev/null

sudo apt-get update
sudo apt-get install -y ngrok

echo "### Configure ngrok ###"

ngrok config add-authtoken "$NGROK_AUTH_TOKEN"

echo "### Start ngrok TCP proxy for SSH ###"

rm -f .ngrok.log

ngrok tcp 22 --log ".ngrok.log" >/dev/null 2>&1 &

sleep 10

echo ""
echo "### ngrok log ###"
cat .ngrok.log || true

echo ""
echo "### SSH tunnel information ###"

curl -s http://127.0.0.1:4040/api/tunnels || true

echo ""
echo "=========================================="
echo "ngrok is running."
echo "SSH tunnel should be active."
echo "=========================================="

while true; do
  sleep 60
done
