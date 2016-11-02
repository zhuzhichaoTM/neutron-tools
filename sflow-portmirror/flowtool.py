#!/usr/bin/env python
# encoding: utf-8

import argparse
import subprocess
import textwrap
import sys

# sflow
HEADER = 128
SAMPLING = 5
POLLING = 5

# netflow
TIMEOUT = 30


def argparser():
    parser = argparse.ArgumentParser(
        formatter_class=argparse.RawDescriptionHelpFormatter,
        description=textwrap.dedent('''
            flowtool is used for manage sflow or netflow on ovs
            create_sflow example:
            ---------
            flowtool sflow-create eth0 192.168.1.12:6345 br-int
            ---------

            create_netflow example:
            ---------
            sflowtool netflow-create 192.168.1.12:5566 br-int
            ---------
            '''))
    subparser = parser.add_subparsers()

    # sflow
    parser_create_sflow = subparser.add_parser(
        'sflow-create', help='create slfow on ovs bridge')
    parser_create_sflow.add_argument(
        'agent', help='interface which sends sflow ,like eth0')
    parser_create_sflow.add_argument(
        'target', help='ip:port where slfow is received')
    parser_create_sflow.add_argument(
        'bridge', help='bridge on which setup sflow ')
    parser_create_sflow.add_argument(
        '--header', help='default:%s' % HEADER, default=HEADER, type=int)
    parser_create_sflow.add_argument(
        '--sampling', help='default:%s' % SAMPLING, default=SAMPLING, type=int)
    parser_create_sflow.add_argument(
        '--polling', help='default:%s' % SAMPLING, default=SAMPLING, type=int)
    parser_create_sflow.set_defaults(func=create_sflow)

    parser_delete_sflow = subparser.add_parser(
        'sflow-delete', help='delete sflow on ovs bridge')
    parser_delete_sflow.add_argument(
        'bridge', help='bridge on which remove sflow')
    parser_delete_sflow.set_defaults(func=delete_sflow)

    parser_list_sflow = subparser.add_parser('sflow-list', help='list sflow')
    parser_list_sflow.set_defaults(func=list_sflow)

    # netflow
    parser_create_netflow = subparser.add_parser(
        'netflow-create', help='create netflow')
    parser_create_netflow.add_argument(
        'bridge', help='bridge on which setup netflow')
    parser_create_netflow.add_argument(
        'target', help='ip:port where netflow is received')
    parser_create_netflow.add_argument(
        '--timeout', help='default:%s' % TIMEOUT, default=TIMEOUT, type=int)
    parser_create_netflow.set_defaults(func=create_netflow)

    parser_delete_netflow = subparser.add_parser(
        'netflow-delete', help='delete netflow on ovs bridge')
    parser_delete_netflow.add_argument(
        'bridge', help='bridge on which remove netflow')
    parser_delete_netflow.set_defaults(func=delete_netflow)

    parser_list_netflow = subparser.add_parser(
        'netflow-list', help='list netfow')
    parser_list_netflow.set_defaults(func=list_netflow)

    args = parser.parse_args()
    args.func(args)


def create_sflow(args):
    agent = 'agent=' + str(args.agent)
    target = str('target=' + '\"' + args.target + '\"')
    header = 'header=' + str(args.header)
    sampling = 'sampling=' + str(args.sampling)
    polling = 'polling=' + str(args.polling)
    cmd = ['ovs-vsctl', '--', '--id=@sflow', 'create', 'sflow',
           agent, target, header, sampling, polling, '--',
           'set', 'bridge', args.bridge, 'sflow=@sflow']
    run_ovsctl(cmd)
#    if run_ovsctl(cmd) == 0:
#        print 'sflow agent on %s has been setup.' % args.bridge


def list_sflow(args):
    cmd = ['ovs-vsctl', 'list', 'sflow']
    run_ovsctl(cmd)


def delete_sflow(args):
    cmd = ['ovs-vsctl', '--', 'clear', 'Bridge', args.bridge, 'sflow']
    run_ovsctl(cmd)
#    if run_ovsctl(cmd) == 0:
#        print 'sflow agent on %s has been removed.' % args.bridge


def create_netflow(args):
    target = str('targets=' + '\"' + args.target + '\"')
    timeout = 'active-timeout=' + str(args.timeout)
    cmd = ['ovs-vsctl', '--', 'set', 'Bridge', args.bridge,
           'netflow=@nf', '--', '--id=@nf', 'create',
           'NetFlow', target, timeout]
    run_ovsctl(cmd)


def list_netflow(args):
    cmd = ['ovs-vsctl', 'list', 'netflow']
    run_ovsctl(cmd)


def delete_netflow(args):
    cmd = ['ovs-vsctl', '--', 'clear', 'Bridge', args.bridge, 'netflow']
    run_ovsctl(cmd)
#    if run_ovsctl(cmd) == 0:
#        print 'netflow on %s has been removed.' % args.bridge


def run_ovsctl(cmd):
    proc = subprocess.Popen(cmd, stdout=subprocess.PIPE,
                            stderr=subprocess.PIPE)
    (stdout, stderr) = proc.communicate()
    if proc.returncode != 0:
        print stderr
        sys.exit(proc.returncode)
    if proc.returncode == 0 and stdout:
        print stdout
    return proc.returncode


if __name__ == '__main__':
    argparser()

