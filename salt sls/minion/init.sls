minion-init:
  pkg.latest: 
    - name: salt-minion
    - refresh: True
minion-conf:
  file.managed:
    - name: /etc/salt/minion
    - source: salt://minion/minion
    - user: root
    - mode: 640
    - template: jinja
    - require: 
      - pkg: salt-minion
  service.running:
    - name: salt-minion
    - enable: True
    - watch:
      - file: /etc/salt/minion
#  cmd.run:
#    - name: 'rm -rf /etc/salt/pki/minion/minion_master.pub && service salt-minion restart'
