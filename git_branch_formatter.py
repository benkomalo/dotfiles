#!/usr/bin/env python

import re
import sys

branch_dict = {}

# Read raw branch information.
for line in sys.stdin.readlines():
    line = line.strip()
    name, rest = re.split(r'\s*', line, maxsplit=1)
    if name == '*':
        name, rest = re.split(r'\s*', rest, maxsplit=1)
        cur_branch = name

    sha, rest = re.split(' ', rest, maxsplit=1)
    upstream_info = re.match('(\[[^\]]+] ).*', rest)
    if upstream_info:
        parts = re.split(r': |, ', upstream_info.groups()[0][1:-2])
        upstream_name = parts[0]
        ahead = 0
        behind = 0
        for part in parts[1:]:
            if part.startswith('ahead '):
                ahead = int(part[len('ahead '):])
            elif part.startswith('behind '):
                behind = int(part[len('behind '):])
        upstream = {
            'name': upstream_name,
            'ahead': ahead,
            'behind': behind,
        }
        desc = rest[rest.find('] ') + 2:]
    else:
        upstream = None
        desc = rest

    branch_dict[name] = {
        'name': name,
        'sha': sha,
        'upstream': upstream,
        'desc': desc,
    }


# Group into trees. We do this in kind of a naive, iterative way.
def create_node(commit):
    node = {'children': []}
    node.update(commit)
    return node


# Create a topologically sorted list of "nodes"
visited = set()
sorted_nodes = []
def visit_branch(branch):
    if branch['name'] in visited:
        return

    visited.add(branch['name'])

    upstream = branch['upstream']
    if upstream and upstream['name'] in branch_dict:
        visit_branch(branch_dict[upstream['name']])

    sorted_nodes.append(create_node(branch))


for branch in branch_dict.values():
    visit_branch(branch)


# Now actual form trees

def try_insert(tree_root, node):
    if node['upstream']['name'] == tree_root['name']:
        tree_root['children'].append(node)
        return True

    for child in tree_root['children']:
        if try_insert(child, node):
            return True

    return False


top_level_nodes = {}
for node in sorted_nodes:
    if node['upstream'] is None:
        top_level_nodes[node['name']] = node
        continue

    upstream = node['upstream']
    if upstream['name'] not in branch_dict:
        top_level_nodes[node['name']] = node
        continue

    for candidate_tree in top_level_nodes.values():
        if try_insert(candidate_tree, node):
            break


def len_without_color(s):
    return len(re.sub(r'\x1b\[\d*m', '', s))


HEADER = '\033[95m'
BLUE = '\033[94m'
GREEN = '\033[92m'
YELLOW = '\033[33m'
RED = '\033[31m'
ENDC = '\033[0m'
def print_formatted(node, pad_to):
    if node['name'] == cur_branch:
        name = '%s%s%s' % (GREEN, node['name'], ENDC)
    else:
        name = node['name']
    print name,
    pad_to = pad_to - len(node['name']) - 1

    upstream_info = node['upstream']
    if upstream_info:
        ahead = upstream_info['ahead']
        behind = upstream_info['behind']
        if ahead == 1 and behind == 0:
            # Good, normal case - don't print anything
            upstream_msg = ''
        elif ahead == 1 and behind > 0:
            # OK, but common case - needs a rebase
            upstream_msg = '[%sbehind: %d%s]' % (YELLOW, behind, ENDC)
        elif ahead == 0 and behind == 0:
            # Uh oh - orphaned if upstream is not a remote branch
            if upstream_info['name'].find('/') > -1:
                upstream_msg = '[%s]' % upstream_info['name']
            else:
                upstream_msg = '[orphaned: %s%s%s]' % (RED, upstream_info['name'], ENDC)
        else:
            # D'oh. Deviated and needs interactive rebase...
            upstream_msg = '[%sahead: %d, behind: %d%s]' % (RED, ahead, behind, ENDC)

        pad_to = pad_to - len_without_color(upstream_msg) - 1
        print upstream_msg,

    if pad_to < 1:
        pad_to = 1
    print '%s(%s) %s' % (' ' * pad_to, node['sha'], node['desc']),


def print_branch(node, level=0):
    if level == 0:
        print  # Top level - print an extra line

    width = 45
    if level > 1:
        prefix = '  '.join(' ' for _ in xrange(level - 1))
        width = width - len(prefix) - 1
        print prefix,
    if level > 0:
        print '+',
        width = width - 2

    if node['children']:
        print u'\u00AC',
    else:
        print '-',
    print_formatted(node, pad_to=width)

    print
    for child in node['children']:
        print_branch(child, level + 1)


for branch in top_level_nodes.values():
    print_branch(branch, level=0)

print
