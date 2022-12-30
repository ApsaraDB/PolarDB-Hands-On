#!/usr/bin/env bash

function log_info()
{
    echo -e "$(date) \033[0;32m[INFO] $*\033[0m"
}

function log_warn()
{
    echo -e "$(date) \033[0;33m[WARN] $*\033[0m"
}

function log_error()
{
    echo -e "$(date) \033[0;31m[ERROR] $*\033[0m"
}

function fatal_error()
{
    echo -e "$(date) \033[0;31m[ERROR] $*\033[0m"
    exit 1
}

function get_key_value()
{
    echo "$1" | sed 's/^--[a-zA-Z_-]*=//'
}

function get_uid() {
    if [[ ${UID} -ne 0 ]]; then
        uid=${UID};
    else
        uid=`od -d /dev/urandom | head -n 1 | awk '{print $2}'`
    fi
    echo ${uid}
}

function is_local()
{
    if [[ $1 == "localhost" ]] || [[ $1 == "127.0.0.1" ]] || [[ $1 == "$(hostname -i)" ]] ; then
        echo 1
    else
        echo 0
    fi
}

function exec_cmd()
{
    if [[ $(is_local $1) -eq 1 ]]; then
        bash -c "$2"
    else
        ssh $1 "$2"
    fi
    return $?
}

function exec_cmd1()
{
    # ignore error log
    if [[ $(is_local $1) -eq 1 ]]; then
        bash -c "$2" 2>/dev/null
    else
        ssh $1 "$2" 2>/dev/null
    fi
    return $?
}

function exec_cmd2()
{
    # ignore error log and ouput
    if [[ $(is_local $1) -eq 1 ]]; then
        bash -c "$2" >/dev/null 2>&1
    else
        ssh $1 "$2" >/dev/null 2>&1
    fi
    return $?
}

