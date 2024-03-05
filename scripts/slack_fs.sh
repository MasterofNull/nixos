#!/usr/bin/env bash

i3-msg "[workspace=\"ytm\"] focus"
SLACK_PARKED=`i3-save-tree | grep class | grep Slack | wc -l`

# IF in ytm
if [[ "$SLACK_PARKED" = "1" ]]; then
  i3-msg "[class=\"Slack\"] move to workspace 1"
  sleep 0.2
  i3-msg "[class=\"Slack\"] focus"
  i3-msg "[class=\"Slack\"] fullscreen"
else
  i3-msg "[class=\"Slack\"] move to workspace ytm"
  sleep 0.2
  i3-msg "[class=\"Slack\"] fullscreen"
  i3-msg "workspace back_and_forth"
fi