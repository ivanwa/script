check-account-expire:
  cmd.script:
    - source: salt://script/host-chk-account.sh
    - template: jinja
check-dir-permission:
  cmd.script:
    - source: salt://script/host-chk-dir.sh
    - template: jinja
check-hosts-resolv:
  cmd.script:
    - source: salt://script/host-chk-hosts.sh
    - template: jinja
