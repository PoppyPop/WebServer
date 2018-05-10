#!/bin/bash
#

cat << 'EOF' > /etc/cron.d/oom_disable
*/1 * * * * root pgrep -f "/usr/sbin/sshd" | while read PID; do echo -17 > /proc/$PID/oom_adj; done
EOF

cat << 'EOF' >> /etc/cron.d/oom_disable
*/1 * * * * root pgrep -f "/usr/sbin/mysqld" | while read PID; do echo -17 > /proc/$PID/oom_adj; done
EOF

chmod +x /etc/cron.d/oom_disable

systemctl restart cron