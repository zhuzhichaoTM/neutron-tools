#!/usr/bin/env python
# -*-coding:utf-8-*-

import subprocess
import fitmon_log
import ConfigParser
import os

SERVICE = 'neutron_agent_list'
CONF_FILE_PATH = '/etc/fitmon/fitmon.conf'
logger = fitmon_log.init_logger('/var/log/fitmon/%s.log' % (SERVICE))


def prepare():
    parser = ConfigParser.SafeConfigParser()
    parser.optionxform = str
    if not parser.read(CONF_FILE_PATH):
        raise IOError("fitmon_path not found, check the path")
    items = parser.items("COMMON")
    for i in items:
        os.environ[i[0]] = i[1]
    return True


def main_control():
    prepare()
    cmd = "neutron agent-list | grep xxx"
    ret = 0
    brief = "The following service is unavailable: "
    detail = "Service failure nodes: "
    try:
        p = subprocess.Popen(cmd, shell=True, stdout=subprocess.PIPE,
                             stderr=subprocess.STDOUT)
        p.wait()
        for line in p.stdout.readlines():
            node = line.split('|')[3].strip()
            service = line.split('|')[7].strip()
            brief = brief + service + ' '
            detail = detail + service + '@' + node + ' '
            ret = 1
        if 0 == ret:
            brief = "All neutron agent service is available"
            detail = ""

        logger.info(brief + '.' + detail)
    except:
        ret = -1
        brief = ""
        detail = ""
        logger.critical('check_process: got exception!')
        if p.stderr:
            p.kill()

    return (ret, brief, detail)

if __name__ == '__main__':
    print(main_control())
