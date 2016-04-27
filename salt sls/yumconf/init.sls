yum-init:
  cmd.script:
    - source: salt://yumconf/yum-init.sh
    - args: "test"
