#!/usr/bin/env python
# -*-coding:utf-8-*-

import subprocess
import fitmon_log
import os


def main_control():
    uuid = fitmon_log.get_uuid()
    sh_name = os.path.realpath(__file__).split(".")[0]
    cmd = "%s req-d%s" % (sh_name, uuid)
    ret = ""
    brief = ""
    detail = ""
    try:
        p = subprocess.Popen(cmd, shell=True, stdout=subprocess.PIPE,
                             stderr=subprocess.STDOUT)
        p.wait()
        retlist = p.stdout.readlines()
        if len(retlist) >= 3:
            ret = retlist[2].strip()
            brief = retlist[3].strip()
            if '1' == ret:
                detail = retlist[4].strip()
        else:
            ret = -1
    except:
        ret = -1
        if p.stderr:
            p.kill()

    return (ret, brief, detail)

if __name__ == "__main__":
    print main_control()
