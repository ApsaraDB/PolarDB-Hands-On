#!/bin/bash

# Author : wuha.csb

BASE="$( cd "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"
echo $BASE

if [[ ! -f ${BASE}/util.sh ]]; then
    echo "Missing util.sh"
    exit 1
fi

source ${BASE}/util.sh

function usage()
{
    echo -e "Utility to generate data for TPC-H, load to local or remote database server [ in parallel ]\n\n\
SYNOPSIS:\n\
    $0 [PARAMETERs] COMMAND\n\n\
PARAMETERs:\n\
    -b | --base=<MYSQL_BINARY_DIR>: Specify directory of mysql binary\n\
    -d | --data=<DATA_DIR>: Specify directory to store generated data\n\
    -g | --generator=<DBGEN_BINARY_DIR>: Specify directory of dbgen binary\n\
    -s | --scale-factor=<SCALE_FACTOR>: Specify value for scale factor [0.001, inf)\n\
    -c | --chunks=<CHUNKS>: Specify value for chunks, same as <PARALLEL_THREADS> by default\n\
    -H | --host=<hostname>: Specify hostname/ip of mysql database server to load data, localhost by default\n\
    -P | --port=<PORT>: Specify port on which mysql server run\n\
    -u | --username=<USERNAME>: Specify username to connect database server\n\
    -p | --password=<PASSWORD>: Specify password to connect database server\n\
    --parallel=<PARALLEL_THREADS>: Specify number of threads to load data in parallel\n\
    --database=<DATABASE>: Specify name of database to be loaded (will be created during prepare)\n\
    --ddl=<DDL_SQL>: Specify path for DDL SQL commands\n\
    --table=<TABLE_NAME>: Load data for a single table\n\
    -h | --help: Print this help message\n\n\
COMMAND:\n\
    generate: Generate data for TPC-H\n\
    prepare: Prepare schema for TPC-H\n\
    load: Load data for TPC-H\n\
    all: generate, prepare and load in one shot"
}

uid=$(get_uid)
# parse options
OPT_END=0
while [[ ${OPT_END} -eq 0 ]]; do
    case "$1" in
    -b|--base)
        shift
        MYSQL_BASE=$(get_key_value "$1")
        shift;;
    --base=*)
        MYSQL_BASE=$(get_key_value "$1")
        shift;;

    -d|--data)
        shift
        DATA_DIR=$(get_key_value "$1")
        shift;;
    --data=*)
        DATA_DIR=$(get_key_value "$1")
        shift;;

    -g|--generator)
        shift
        DBGEN_PATH=$(get_key_value "$1")
        shift;;
    --generator=*)
        DBGEN_PATH=$(get_key_value "$1")
        shift;;

    -H|--host)
        shift
        HOST=$(get_key_value "$1")
        shift;;
    --host=*)
        HOST=$(get_key_value "$1")
        shift;;

    -P|--port)
        shift
        PORT=$(get_key_value "$1")
        shift;;
    --port=*)
        PORT=$(get_key_value "$1")
        shift;;

    -u|--username)
        shift
        USERNAME=$(get_key_value "$1")
        shift;;
    --username=*)
        USERNAME=$(get_key_value "$1")
        shift;;

    -p|--password)
        shift
        PASSWORD=$(get_key_value "$1")
        shift;;
    --password=*)
        PASSWORD=$(get_key_value "$1")
        shift;;

    --database)
        shift
        DATABASE=$(get_key_value "$1")
        shift;;
    --database=*)
        DATABASE=$(get_key_value "$1")
        shift;;

    --ddl)
        shift
        DDL_SQL=$(get_key_value "$1")
        shift;;
    --ddl=*)
        DDL_SQL=$(get_key_value "$1")
        shift;;

    --parallel)
        shift
        PARALLEL=$(get_key_value "$1")
        shift;;
    --parallel=*)
        PARALLEL=$(get_key_value "$1")
        shift;;

    -s|--scale-factor)
        shift
        SCALE_FACTOR=$(get_key_value "$1")
        shift;;
    --scale-factor=*)
        SCALE_FACTOR=$(get_key_value "$1")
        shift;;

    -c|--chunks)
        shift
        CHUNKS=$(get_key_value "$1")
        shift;;
    --chunks=*)
        CHUNKS=$(get_key_value "$1")
        shift;;

    --table)
        shift
        TABLE_NAME=$(get_key_value "$1")
        shift;;
    --table=*)
        TABLE_NAME=$(get_key_value "$1")
        shift;;

    #--save)
    #    shift
    #    SAVE_ON_LOAD=1;;

    -h|--help)
        usage
        exit 0;;
    *)
        OPT_END=1;;
    esac
done

function generate_chunk() {
    chunk=$1
    FLAG_FILE=$2

    [[ -z ${FLAG_FILE} ]] || echo 0 > ${FLAG_FILE}
    while [[ ${chunk} -le ${CHUNKS} ]]; do
        ./dbgen -f -s ${SCALE_FACTOR} -C ${CHUNKS} -S ${chunk} >/dev/null 2>&1
        chunk=`expr ${chunk} + ${PARALLEL}`
    done

    [[ -z ${FLAG_FILE} ]] || echo 1 > ${FLAG_FILE}
}

function generate_data() {
    [[ ! -z ${DBGEN_PATH} ]] || fatal_error "Missing parameter for --generator"
    [[ -x ${DBGEN_PATH}/dbgen ]] || fatal_error "${DBGEN_PATH}/dbgen isn't available"
    [[ ! -z ${DATA_DIR} ]] || fatal_error "Missing parameter for --data"

    [[ ! -z ${SCALE_FACTOR} ]] || fatal_error "Missing parameter value for scale factor!"
    [[ `echo "${SCALE_FACTOR} < 0.001" | bc` -eq 1 ]] && fatal_error "Invalid value (${SCALE_FACTOR}) for scale factor!"

    SIZE=${SCALE_FACTOR}
    UNIT=GB
    [[ `echo "${SCALE_FACTOR} < 1" | bc` -eq 1 ]] && SIZE=`echo "${SCALE_FACTOR} * 1000/1" | bc` && UNIT=MB

    if [[ -z ${CHUNKS} ]] || [[ ${CHUNKS} -lt 1 ]]; then CHUNKS=1; fi
    if [[ -z ${PARALLEL} ]] || [[ ${PARALLEL} -lt 1 ]]; then PARALLEL=1; fi
    if [[ ${PARALLEL} -gt ${CHUNKS} ]]; then PARALLEL=${CHUNKS}; fi

    [[ -d ${DATA_DIR} ]] && log_warn "Data directory(${DATA_DIR}) exists, it will be recreated!" && rm -r ${DATA_DIR}
    mkdir ${DATA_DIR}

    TBL_FILES=""
    cd ${DBGEN_PATH}
    if [[ ${PARALLEL} -gt 1 ]]; then
        log_info "Generating ${SIZE} ${UNIT} data into ${CHUNKS} chunks for TPC-H in parallel with ${PARALLEL} threads ..."

        # generate region and nation with the first chunk
        ./dbgen -f -s ${SCALE_FACTOR} -C ${CHUNKS} -S 1 >/dev/null 2>&1
        mv nation.tbl region.tbl ${DATA_DIR}/
        PREFIX="dbgen_${uid}_${SIZE}_${CHUNKS}_${PARALLEL}"
        for thd in `seq 1 ${PARALLEL}`; do
            generate_chunk `expr ${thd} + 1` /dev/shm/${PREFIX}_${thd} &
        done

        log_info "Waiting all ${PARALLEL} threads finish ..."
        for thd in `seq 1 ${PARALLEL}`; do
            while [[ `cat /dev/shm/${PREFIX}_${thd}` -eq 0 ]]; do
                sleep 1
            done
            rm /dev/shm/${PREFIX}_${thd}
        done

        for ch in `seq 1 ${CHUNKS}`; do
            mv customer.tbl.${ch} lineitem.tbl.${ch} orders.tbl.${ch} partsupp.tbl.${ch} part.tbl.${ch} supplier.tbl.${ch} ${DATA_DIR}/
        done
        /bin/rm nation.tbl region.tbl

        log_info "All ${PARALLEL} generator threads finish"
    elif [[ ${CHUNKS} -gt 1 ]]; then
        log_info "Generating ${SIZE} ${UNIT} data into ${CHUNKS} chunks for TPC-H in sequence ..."
        for ch in `seq 1 ${CHUNKS}`; do
            ./dbgen -f -s ${SCALE_FACTOR} -C ${CHUNKS} -S $ch >/dev/null 2>&1
            if [[ ${ch} -eq 1 ]]; then
                mv nation.tbl region.tbl ${DATA_DIR}/
            fi
            mv customer.tbl.${ch} lineitem.tbl.${ch} orders.tbl.${ch} partsupp.tbl.${ch} part.tbl.${ch} supplier.tbl.${ch} ${DATA_DIR}/
        done
        /bin/rm nation.tbl region.tbl
    else
        log_info "Generating ${SIZE} ${UNIT} data for TPC-H"
        ./dbgen -f -s ${SCALE_FACTOR} >/dev/null 2>&1
        mv nation.tbl region.tbl customer.tbl lineitem.tbl orders.tbl partsupp.tbl part.tbl supplier.tbl ${DATA_DIR}/
    fi

    log_info "$SIZE $UNIT data for TPC-H is generated under $DATA_DIR/"
    cd ${BASE}
}

function prepare_schema() {
    [[ ! -z ${MYSQL_BASE} ]] || which mysql || \
        fatal_error "No mysql command is available, need specify value for --base parameter!"
    [[ -z ${MYSQL_BASE} ]] || [[ -x ${MYSQL_BASE}/bin/mysql ]] || \
        fatal_error "Invalid parameter value for --base, ${MYSQL_BASE}/bin/mysql isn't available!"

    [[ ! -z ${HOST} ]] || HOST=127.0.0.1
    [[ ! -z ${PORT} ]] || fatal_error "Missing parameter for --port"
    [[ ! -z ${USERNAME} ]] || fatal_error "Missing parameter for --username"
    [[ ! -z ${PASSWORD} ]] || fatal_error "Missing parameter for --password"
    [[ ! -z ${DATABASE} ]] || fatal_error "Missing parameter for --database"
    [[ -f ${DDL_SQL} ]] || fatal_error "Missing parameter for --ddl"

    ${MYSQL_BASE}/bin/mysql -h${HOST} -P${PORT} -u${USERNAME} -p${PASSWORD} \
        -e "DROP DATABASE IF EXISTS ${DATABASE}; CREATE DATABASE ${DATABASE};"

    ${MYSQL_BASE}/bin/mysql -h${HOST} -P${PORT} -u${USERNAME} -p${PASSWORD} \
        -D ${DATABASE} -e "SOURCE ${DDL_SQL};"
}

function load_data_file() {
    [[ ! -z $1 ]] || fatal_error "Missing value for table_name"
    TBL_NAME=$1
    [[ -z $2 ]] || [[ $2 -le 0 ]] || CHUNK=$2
    TBL_PATH=${DATA_DIR}/${TBL_NAME}.tbl
    [[ -z ${CHUNK} ]] || TBL_PATH=${TBL_PATH}.${CHUNK}

    [[ -f ${TBL_PATH} ]] || fatal_error "Can't find file ${TBL_PATH} to load!"
    ${MYSQL_BASE}/bin/mysql -h ${HOST} -P${PORT} -u${USERNAME} -p${PASSWORD} -D ${DATABASE} \
        -e "LOAD DATA LOCAL INFILE '${TBL_PATH}' INTO TABLE ${TBL_NAME} FIELDS TERMINATED BY '|';"

    if [[ ! -z ${CHUNK} ]]; then
        log_info "Loaded data part ${CHUNK} for ${DATABASE}.${TBL_NAME} from ${TBL_PATH} ..."
    else
        log_info "Loaded data for ${DATABASE}.${TBL_NAME} from ${TBL_PATH} ..."
    fi
}

function load_data_worker() {
    chunk=$1
    tbl_name=$2
    FLAG_FILE=$3

    [[ -z ${FLAG_FILE} ]] || echo 0 > ${FLAG_FILE}
    while [[ ${chunk} -le ${CHUNKS} ]]; do
        load_data_file ${tbl_name} ${chunk}
        chunk=`expr ${chunk} + ${PARALLEL}`
    done

    [[ -z ${FLAG_FILE} ]] || echo 1 > ${FLAG_FILE}
}

function load_table_data() {
    tbl_name=$1
    if [[ ${tbl_name} == "region" ]] || [[ ${tbl_name} == "nation" ]]; then
        load_data_file ${tbl_name}
    elif [[ ${PARALLEL} -gt 1 ]]; then
        PREFIX="${uid}_${DATABASE}_LOAD_${CHUNKS}_${PARALLEL}_${tbl_name}"
        for thd in `seq 1 ${PARALLEL}`; do
            load_data_worker ${thd} ${tbl_name} /dev/shm/${PREFIX}_${thd} &
        done

        log_info "Waiting all ${PARALLEL} threads for ${DATABASE}.${tbl_name} finish ..."
        for thd in `seq 1 ${PARALLEL}`; do
            while [[ `cat /dev/shm/${PREFIX}_${thd}` -eq 0 ]]; do
                sleep 1
            done
            rm /dev/shm/${PREFIX}_${thd}
        done

        log_info "All ${PARALLEL} threads for ${DATABASE}.${tbl_name} finish"

        #if [[ ${SAVE_ON_LOAD} -eq 1 ]]; then
        #    ${MYSQL_BASE}/bin/mysql -h ${HOST} -P${PORT} -u${USERNAME} -p${PASSWORD} \
        #        -e "SET GLOBAL innodb_imci_save_checkpoint = ON;"
        #    log_info "imci checkpoint is saved!"
        #fi
    elif [[ ${CHUNKS} -gt 1 ]]; then
        for chunk in `seq 1 ${CHUNKS}`; do
            load_data_file ${tbl_name} ${chunk}
        done
    else
        load_data_file ${tbl_name}
    fi
}

function load_data() {
    [[ ! -z ${MYSQL_BASE} ]] || which mysql || \
        fatal_error "No mysql command is available, need specify value for --base parameter!"
    [[ -z ${MYSQL_BASE} ]] || [[ -x ${MYSQL_BASE}/bin/mysql ]] || \
        fatal_error "Invalid parameter value for --base, ${MYSQL_BASE}/bin/mysql isn't available!"
    [[ ! -z ${HOST} ]] || HOST=127.0.0.1
    [[ ! -z ${PORT} ]] || fatal_error "Missing parameter for --port"
    [[ ! -z ${USERNAME} ]] || fatal_error "Missing parameter for --username"
    [[ ! -z ${PASSWORD} ]] || fatal_error "Missing parameter for --password"
    [[ ! -z ${DATABASE} ]] || fatal_error "Missing parameter for --database"
    [[ -d ${DATA_DIR} ]] || fatal_error "Missing parameter for --data"

    if [[ -z ${CHUNKS} ]] || [[ ${CHUNKS} -lt 1 ]]; then CHUNKS=1; fi
    if [[ -z ${PARALLEL} ]] || [[ ${PARALLEL} -lt 1 ]]; then PARALLEL=1; fi
    if [[ ${PARALLEL} -gt ${CHUNKS} ]]; then PARALLEL=${CHUNKS}; fi

    if [[ -z ${TABLE_NAME} ]]; then
        task_info="loading data for database ${DATABASE}"
        if [[ ${PARALLEL} -gt 1 ]]; then
            task_info="${task_info} with ${CHUNKS} chunks in ${PARALLEL} threads"
        elif [[ ${CHUNKS} -gt 1 ]]; then
            task_info="${task_info} with ${CHUNKS} chunks in sequence"
        fi

        log_info "Begin ${task_info} ..."
        for tbl_name in region nation part supplier partsupp customer orders lineitem; do
            load_table_data ${tbl_name}
        done
        log_info "Finish ${task_info}"
    else
        log_info "Begin loading data for single table ${DATABASE}.${TABLE_NAME} ..."
        load_table_data ${TABLE_NAME}
        log_info "Finish loading data for single table ${DATABASE}.${TABLE_NAME}"
    fi
}

case "$1" in
    "generate")
        generate_data
        ;;
    "prepare")
        prepare_schema
        ;;
    "load")
        load_data
        ;;
    "all")
        generate_data
        prepare_schema
        load_data
        ;;
    *)
        fatal_error "Invalid command: $1";;
esac

