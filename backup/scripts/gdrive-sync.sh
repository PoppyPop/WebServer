#!/bin/bash
#

rclone sync /srv/backs/ gdsecret:$(hostname -f)
