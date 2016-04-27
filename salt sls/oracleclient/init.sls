copy-silent-file:
  file:
    - managed
    - name: /tmp/client_install.rsp
    - source: salt://oracleclient/client_install.rsp
    - user: bestpay
    - group: bestpay
create-oracle-dir1:
  file.directory:
    - name: /tools/oracle/oraInventory
    - user: bestpay
    - group: bestpay
    - mode: 755
    - makedirs: True
create-oracle-dir2:
  file.directory:
    - name: /tools/oracle/app/product/11.2.0/client_1
    - user: bestpay
    - group: bestpay
    - mode: 755
    - makedirs: True
install-oracle-client:
  cmd:
    - run
    - name: cd /tmp && wget http://172.26.10.59/software/client_p13390677_112040_Linux-x86-64_4of7.zip -O /tmp/client.zip &>/dev/null && su - bestpay -c "unzip -q /tmp/client.zip -d /tmp && sed -i 's/^ORACLE_HOSTNAME=.*/ORACLE_HOSTNAME='"$(hostname)"'/g' /tmp/client_install.rsp && bash /tmp/client/runInstaller  -waitforcompletion -silent -responseFile '/tmp/client_install.rsp'"
    - ignore_timeout: True
#define-oracle-client:
#  cmd:
#    - run
#    - name: rm -rf /tmp/client.zip /tmp/client /tmp/client_install.rsp && bash /tools/oracle/oraInventory/orainstRoot.sh && su - bestpay -c 'echo -e "export ORACLE_BASE=/tools/oracle/app\nexport ORACLE_HOME=\$ORACLE_BASE/product/11.2.0/client_1\nexport PATH=\$ORACLE_HOME/bin:\$PATH" >>/home/bestpay/.bash_profile'
