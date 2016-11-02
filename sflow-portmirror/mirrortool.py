#!/usr/bin/env python
# encoding: utf-8

import argparse
import subprocess
import textwrap
import sys

PREFIX = 'mir-'


def argparser():
    parser = argparse.ArgumentParser(
        formatter_class=argparse.RawDescriptionHelpFormatter,
        description=textwrap.dedent('''
            mirrortool is used for setting port mirror on ovs
            create port mirror example
            --------
            mirrortool mirror-create br-int qvoe803d7e9-90 foo
            --------
            delete port mirror example
            --------
            mirrortool mirror-delete br-int foo
            --------
            '''))
    subparser = parser.add_subparsers()

    parser_create_mirror = subparser.add_parser(
        'mirror-create', help='create port mirror on ovs')
    parser_create_mirror.add_argument(
        'bridge', help='bridge on which setup port mirror')
    parser_create_mirror.add_argument(
        'port', help='port which needed to be mirrored')
    parser_create_mirror.add_argument('name', help='mirror\'s name')
    parser_create_mirror.set_defaults(func=create_mirror)

    parser_delete_mirror = subparser.add_parser(
        'mirror-delete', help='delete port mirror on ovs')
    parser_delete_mirror.add_argument(
        'bridge', help='bridge on which delete port mirror')
    parser_delete_mirror.add_argument('name', help='mirror\'s name')
    parser_delete_mirror.set_defaults(func=delete_mirror)

    parser_list_mirror = subparser.add_parser(
        'mirror-list', help='list port mirror on ovs')
    parser_list_mirror.set_defaults(func=list_mirror)

    args = parser.parse_args()
    args.func(args)


def create_and_up_veth(name):
    name_a, name_b = [PREFIX + name + x for x in '-a', '-b']
    create_cmd = ['ip', 'link', 'add', str(
        name_a), 'type', 'veth', 'peer', 'name', str(name_b)]
    run(create_cmd)
    for veth in name_a, name_b:
        up_cmd = ['ip', 'link', 'set', str(veth), 'up']
        run(up_cmd)
    return name_a


def delete_veth(name):
    delete_cmd = ['ip', 'link', 'delete', str(name)]
    run(delete_cmd)


def create_mirror(args):
    mirror_port = create_and_up_veth(args.name)
    add_port_cmd = ['ovs-vsctl', 'add-port', args.bridge, mirror_port]
    run(add_port_cmd)
    create_cmd = ['ovs-vsctl', '--', 'set', 'Bridge', args.bridge,
                  'mirrors=@m', '--', '--id=@' + mirror_port, 'get', 'Port',
                  mirror_port, '--', '--id=@' + args.port, 'get', 'Port',
                  args.port, '--', '--id=@' + args.bridge, 'get', 'Port',
                  args.bridge, '--', '--id=@m', 'create', 'Mirror',
                  'name=' + args.name,
                  'select-src-port=@' + args.bridge + ',@' + args.port,
                  'select-dst-port=@' + args.bridge + ',@' + args.port,
                  'output-port=@' + mirror_port]
    run(create_cmd)
    print 'Now you can tcpdump interface %s' % mirror_port


def delete_mirror(args):
    delete_cmd = ['ovs-vsctl', '--', '--id=@rec', 'get', 'mirror', args.name,
                  '--', 'remove', 'Bridge', args.bridge, 'mirrors', '@rec']
    run(delete_cmd)
    veth = PREFIX + args.name + '-a'
    remove_port_cmd = ['ovs-vsctl', 'del-port', args.bridge, veth]
    run(remove_port_cmd)
    delete_veth(veth)


def list_mirror(args):
    list_cmd = ['ovs-vsctl', 'list', 'mirror']
    run(list_cmd)


def run(cmd):
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

