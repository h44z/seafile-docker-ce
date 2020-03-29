# coding: UTF-8

from __future__ import print_function
from configparser import ConfigParser
from contextlib import contextmanager
import os
import datetime
from os.path import abspath, basename, exists, dirname, join, isdir, expanduser
import platform
import sys
import subprocess
import time
import logging
import logging.config
import click
import termcolor
import colorlog
import MySQLdb


logger = logging.getLogger('.utils')
DEBUG_ENABLED = os.environ.get('SEAFILE_DOCKER_VERBOSE', '').lower() in ('true', '1', 'yes')


def eprint(*a, **kw):
    kw['file'] = sys.stderr
    print(*a, **kw)


def identity(msg, *a, **kw):
    return msg


colored = identity if not os.isatty(sys.stdin.fileno()) else termcolor.colored
red = lambda s: colored(s, 'red')
green = lambda s: colored(s, 'green')


def _find_flag(args, *opts, **kw):
    is_flag = kw.get('is_flag', False)
    if is_flag:
        return any([opt in args for opt in opts])
    else:
        for opt in opts:
            try:
                return args[args.index(opt) + 1]
            except ValueError:
                pass


def call(*a, **kw):
    dry_run = kw.pop('dry_run', False)
    quiet = kw.pop('quiet', DEBUG_ENABLED)
    cwd = kw.get('cwd', os.getcwd())
    check_call = kw.pop('check_call', True)
    reduct_args = kw.pop('reduct_args', [])
    if not quiet:
        toprint = a[0]
        args = [x.strip('"') for x in a[0].split() if '=' not in x]
        for arg in reduct_args:
            value = _find_flag(args, arg)
            toprint = toprint.replace(value, '{}**reducted**'.format(value[:3]))
        logdbg('calling: ' + green(toprint))
        logdbg('cwd:     ' + green(cwd))
    kw.setdefault('shell', True)
    if not dry_run:
        if check_call:
            return subprocess.check_call(*a, **kw)
        else:
            return subprocess.Popen(*a, **kw).wait()


def setup_logging(level=logging.INFO):
    kw = {
        'format': '[%(asctime)s][%(module)s]: %(message)s',
        'datefmt': '%m/%d/%Y %H:%M:%S',
        'level': level,
        'stream': sys.stdout
    }

    logging.basicConfig(**kw)
    logging.getLogger('requests.packages.urllib3.connectionpool').setLevel(logging.WARNING)


def get_command_output(cmd):
    shell = not isinstance(cmd, list)
    return subprocess.check_output(cmd, shell=shell)


def get_seafile_version():
    return os.environ['SEAFILE_VERSION']


def get_install_dir():
    return join('/opt/seafile/' + get_conf('SEAFILE_SERVER', 'seafile-server') + '-{}'.format(get_seafile_version()))


def get_script(script):
    return join(get_install_dir(), script)


def get_conf(key, default=None):
    key = key.upper()
    return os.environ.get(key, default)


def get_conf_bool(key, default="false"):
    v = get_conf(key, default)
    return v.lower() in ('true', '1', 'yes')


def _add_default_context(context):
    default_context = {
        'current_timestr': datetime.datetime.now().strftime('%m/%d/%Y %H:%M:%S'),
    }
    for k in default_context:
        context.setdefault(k, default_context[k])


def render_template(template, target, context):
    from jinja2 import Environment, FileSystemLoader
    env = Environment(loader=FileSystemLoader(dirname(template)))
    _add_default_context(context)
    content = env.get_template(basename(template)).render(**context)
    with open(target, 'w') as fp:
        fp.write(content)


def logdbg(msg):
    if DEBUG_ENABLED:
        msg = '[debug] ' + msg
        loginfo(msg)


def loginfo(msg):
    msg = '[{}] {}'.format(datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S'), green(msg))
    eprint(msg)


def cert_has_valid_days(cert, days):
    assert exists(cert)

    secs = 86400 * int(days)
    retcode = call('openssl x509 -checkend {} -noout -in {}'.format(secs, cert), check_call=False)
    return retcode == 0


def get_version_stamp_file():
    return '/shared/seafile/seafile-data/current_version'


def read_version_stamp(fn=get_version_stamp_file()):
    assert exists(fn), 'version stamp file {} does not exist!'.format(fn)
    with open(fn, 'r') as fp:
        return fp.read().strip()


def update_version_stamp(version, fn=get_version_stamp_file()):
    with open(fn, 'w') as fp:
        fp.write(version + '\n')


def wait_for_mysql():
    db_host = get_conf('DB_HOST', '127.0.0.1')

    if get_conf_bool('USE_EXISTING_DB'):
        db_user = get_conf('DB_USER')
        db_passwd = get_conf('DB_USER_PASSWD')
    else:
        db_user = 'root'
        db_passwd = get_conf('DB_ROOT_PASSWD', '')

    while True:
        try:
            MySQLdb.connect(host=db_host, port=3306, user=db_user, passwd=db_passwd)
        except Exception as e:
            print('waiting for mysql server to be ready: %s', e)
            time.sleep(2)
            continue
        logdbg('mysql server is ready')
        return


def wait_for_nginx():
    while True:
        logdbg('waiting for nginx server to be ready')
        output = get_command_output('netstat -nltp')
        if ':80 ' in output:
            logdbg(output)
            logdbg('nginx is ready')
            return
        time.sleep(2)


def replace_file_pattern(fn, pattern, replacement):
    with open(fn, 'r') as fp:
        content = fp.read()
    with open(fn, 'w') as fp:
        fp.write(content.replace(pattern, replacement))
