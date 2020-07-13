#!/usr/bin/python3

import argparse
import redis
import hashlib
import uuid
import os
import pdb
import sys

with open('/tmp/psiblast-cache.log', 'a') as f:
    f.write('called!\n')

REDIS_DB = redis.Redis(host='redis-instance')
root_path = '/root/psiblast_cache'

os.chdir(os.path.abspath("."))

def sha_fasta(filename):
    raw = ''
    with open(filename, 'r') as f:
        for line in f.readlines():
            if line[0] != '>':
                raw += line.strip()
    if type(raw) is bytes:
        return raw.decode('utf-8')
    else:
        return raw

def run_original_command(args, unknown_args):
    original_command = 'psiblast-uncached -num_threads 8 -query {} -out_pssm {} -out_ascii_pssm {} '.format(args.query, args.out_pssm, args.out_ascii_pssm)
    original_command += ' '.join(unknown_args)
    with open('/tmp/psiblast-cache.log', 'a') as f:
        f.write('CURRENT WD: {}\n'.format(os.getcwd()))
        f.write('RUNNING COMMAND: {}\n'.format(original_command))
    fname = str(uuid.uuid1())
    ret_code = os.system(original_command)
    if ret_code != 0:
        with open('/tmp/psiblast-cache.log', 'a') as f:
            f.write('COMMAND FAILED!\n')

    failed_cmds = []
    cmd_1 = 'cp {} {}/{}.pssm'.format(args.out_pssm, root_path, fname)
    ret_code = os.WEXITSTATUS(os.system(cmd_1))
    if ret_code == 0:
        ret_code = os.WEXITSTATUS(os.system('cp {} {}/{}.ascii_pssm'.format(args.out_ascii_pssm, root_path, fname)))
        if ret_code == 0:
            REDIS_DB.set(sha_fasta(args.query), fname)
            return
        else:
            failed_cmds.append(cmd_2)
    else:
        failed_cmds.append(cmd_1)
    with open('/tmp/psiblast-cache.log', 'a') as f:
        f.write('One of the copy commands failed!\n')
        for failed_cmd in failed_cmds:
            f.write('FAILED COMMAND: {}\n'.format(failed_cmd))


def copy_pssms(id, args):
    with open('/tmp/psiblast-cache.log', 'a') as f:
        f.write('SKIPPING RUNNING ORIGINAL COMMAND: psiblast ' + ' '.join(sys.argv[1:]) + '\n')
    if args.out_pssm is not None:
        pssm_path = root_path + '/' + id + '.pssm'
        out_pssm = os.path.abspath(args.out_pssm)
        with open('/tmp/psiblast-cache.log', 'a') as f:
            f.write('COPYING: {} -> {}\n'.format(pssm_path, out_pssm))
        os.system('cp {} {}'.format(pssm_path, out_pssm))
    if args.out_ascii_pssm is not None:
        ascii_pssm_path = root_path + '/' + id + '.ascii_pssm'
        out_ascii_pssm = os.path.abspath(args.out_ascii_pssm)
        with open('/tmp/psiblast-cache.log', 'a') as f:
            f.write('COPYING: {} -> {}\n'.format(ascii_pssm_path, out_ascii_pssm))
        os.system('cp {} {}'.format(ascii_pssm_path, out_ascii_pssm))

parser = argparse.ArgumentParser(allow_abbrev=False)
parser.add_argument('-query', type=str)
parser.add_argument('-out_pssm', type=str)
parser.add_argument('-out_ascii_pssm', type=str)
args, unknown_args = parser.parse_known_args()

hash = sha_fasta(args.query)
id = REDIS_DB.get(hash)
if id is None:
    with open('/tmp/psiblast-cache.log', 'a') as f:
        f.write('"{}" not found in DB!\n'.format(hash))
    run_original_command(args, unknown_args)
else:
    copy_pssms(id.decode('utf-8'), args)

