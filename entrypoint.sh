#!/bin/bash
set -e

groupadd -g ${GROUP_ID} user
useradd -l -u ${USER_ID} -g ${GROUP_ID} -M --home-dir /home/user --shell /bin/bash user
exec su user

