#!/bin/bash
#
# Example of how to parse short/long options with 'getopt'
#

OPTS=`
   getopt \
   -o rsucy:S:d:v:b:N:n:hR: \
   --long reload,stop,start,auto-YES:,deployment-env:,version:,create:,branch:,service-name:,update,process-number:,help,repo: \
   -n 'parse-options' -- "$@"
`

if [ $? != 0 ] ; then echo "Failed parsing options." >&2 ; exit 1 ; fi

# echo "$OPTS"
eval set -- "$OPTS"

call_proto () {
    cd $_code_dir && bp && cd $_work_dir
}

usage () {
    echo "Usage $0"
    echo "-h|--help 显示此帮助文档"
    echo "-r|--reload 重启服务,不会拉取最新的代码"
    echo "-s|--stop 停止服务"
    echo "-u|--update 拉取最新的代码并重启服务"
    echo "--create 新建服务"
    echo "-S|--start 启动服务"
    echo "-b|--branch 分支名"
    echo "-N|--service-name 服务名,与启动的服务脚本同名,如main_service对应service/main_service.py"
    echo "-n|--process-number 进程数量"
    echo "-y|--auto-YES 自动确认,只能在启动脚本中使用"
    echo "-v|--version main_service 要操作的服务版本"
    echo "-d|--deployment-env test/prod 服务环境 test: 测试环境 prod: 正式环境"
    echo "-R|--repo 项目地址,默认值为: git@shilai.zhiyi.cn:/home/git/shilai_common"
}

check_port () {
    if [[ "x$_port" == "x" ]];then
        echo "请输入端口号"
        exit -1
    fi
    portusage=`netstat -anp | grep $_port`
    if [[ -z $portusage ]]; then
        return
    else
        echo "端口 $_port 不可用, 请重新选择端口"
        # exit -1
    fi
}

show_info () {
    echo "###服务相关信息##############################################"
    echo "本次操作: $_action"
    echo "服务环境: $_deployment_env"
    echo "代码目录: $_code_dir"
    echo "代码分支: $_branch"
    echo "服务名: $_service_name"
    echo "服务版本: $_version"
    echo "日志目录: $_log_dir"
    echo "PYTHONPATH: $PYTHONPATH"
    echo "进程数: $_process_number"
    echo "###MongoDB相关信息###########################################"
    echo "地址: $MONGODB_SERVER_ADDRESS"
    echo "端口: $MONGODB_PORT"
    echo "用户名: $MONGODB_USER_NAME"
    echo "密码: $MONGODB_ROOT_PASSWORD"
    echo "副本集: $MONGODB_REPLICA_SET"
    echo "###Redis相关信息#############################################"
    echo "地址: $REDIS_HOST"
    echo "端口: $REDIS_PORT"
    echo "密码: $REDIS_PASSWORD"
    echo "###Pubserver相关信息#########################################"
    echo "地址: $PUBSUB_REDIS_HOST"
    echo "端口: $PUBSUB_REDIS_PORT"
    echo "密码: $PUBSUB_REDIS_PASSWORD"
    echo "###Kafka相关信息#############################################"
    echo "地址: $KAFKA_HOST"
    echo "端口: $KAFKA_PORT"
    echo
}

invalid_params () {
    if [ -z "$_version" ]; then
        echo "服务版本必须提供"
        exit -1
    fi

    if [ -z "$_action" ]; then
        echo "请按说明传入参数";
        usage
        exit -1
    fi

    if [ -z "$_service_name" ];then
        echo "请输入要操作的服务名";
        exit -1
    fi
}

generate_ini () {
    cat > $_ini_file <<-EOF
    [uwsgi]
    set-placeholder = service_name=${SERVICE_NAME}
    set-placeholder = version_dir=${VERSION}
    http = 0.0.0.0:${PORT}

    strict = true
    chdir = ${HOME}/code/${VERSION}/service
    virtualenv = ${HOME}/code/env
    module = ${SERVICE_NAME}
    callable = app
    processes = ${PROCESS_NUMBER}
    master = true
    threads = 1
    daemonize = ${LOG_ROOT}/${VERSION}/uwsgi.log
    pidfile = ${LOG_ROOT}/${VERSION}/uwsgi.pid
    vacuum = true
    reload-mercy = 1
    worker-reload-mercy = 1
    listen = 2048
    env = PYTHONPATH=${HOME}/code/${VERSION}
    env = DEPLOYMENT_ENV=${DEPLOYMENT_ENV}
    env = LOG_DIR=${LOG_ROOT}/${VERSION}
    env = VERSION=${VERSION}
    env = OUTER_VERSION=${VERSION}
EOF
}

_git_url="TODO: git仓库地址"
_action=
_version=
_activate="$HOME/code/env/bin/activate"
_deployment_env="test"
_log_root="/data/logs/shilai"
_code_parent_dir="$HOME/code"
_bp_bin_path="$HOME/bin/bp"
_port=
_service_name=
_branch="dev"
_work_dir="$HOME/code/service-scripts"
_ini_dir="${_work_dir}/ini"
_process_number=8


while true; do
    case "$1" in
        -r | --reload )
            _action="reload"
            shift ;;
        -S | --start )
            _action="start"
            _port=$2
            check_port
            shift
            shift;;
        -s | --stop )
            _action="stop"
            shift ;;
        -u | --update )
            _action="update"
            shift;;
        -d | --deployment-env )
            _deployment_env=$2
            shift
            shift;;
        -c | --create )
            _action="create"
            _port=$2
            check_port
            shift
            shift;;
        -N | --service-name )
            _service_name=$2
            shift
            shift;;
        -b | --branch )
            _branch=$2
            shift
            shift;;
        -v | --version )
            _version=$2
            shift
            shift;;
        -n | --process-number )
            _process_number=$2
            shift
            shift;;
        -h | --help )
            usage
            exit 0;;
        -R | --repo )
            _git_url=$2
            shift
            shift;;
        -y | --auto-YES )
            _auto_yes="Y"
            shift;;
        -- )
            shift
            break ;;
        * )
            break ;;
    esac
done

invalid_params

_log_dir="$_log_root/$_version"
_code_dir="$_code_parent_dir/$_version"
_pid_file="$_log_dir/uwsgi.pid"
_ini_file="${_ini_dir}/${_service_name}_${_version}.ini"

mkdir -p $_log_dir

source $_work_dir/configs/config.sh

export DEPLOYMENT_ENV=$_deployment_env
export LOG_ROOT=$_log_root
export LOG_DIR=$_log_dir
export PYTHONPATH=$_code_dir
export SERVICE_NAME=$_service_name
export PORT=$_port
export VERSION=$_version
export PROCESS_NUMBER=$_process_number
export SERVICE_DOMAIN="https://test.shilai.zhiyi.cn/${_version}"
export H5_SERVICE_DOMAIN='https://test.shilai-h5.zhiyi.cn'
export SERVICE_DOMAIN_WITHOUT_VERSION='https://test.shilai.zhiyi.cn'

if [[ $_deployment_env == "prod" ]];then
    export SERVICE_DOMAIN="https://shilai.zhiyi.cn/${_version}"
    export H5_SERVICE_DOMAIN='https://shilai-h5.zhiyi.cn'
    export SERVICE_DOMAIN_WITHOUT_VERSION='https://shilai.zhiyi.cn'
fi

show_info

if [[ $_auto_yes == "Y" ]];then
    confirm="Y"
else
    printf "请确认以上信息(Y/N): "
    read confirm
fi
if [[ $confirm != "Y" ]];then
    echo "不执行相关操作,直接退出"
    exit 0
fi

source $_activate

if [[ $_action == "reload" ]]; then
    call_proto
    `uwsgi --reload $_pid_file`
elif [[ $_action == "stop" ]]; then
    `uwsgi --stop $_pid_file`
elif [[ $_action == "create" ]]; then
    if [[ -d $_code_dir ]];then
        echo "服务目录已经存在,如需重启,请使用-r进行重启,或者-S直接启动服务"
        exit 0
    else
        git clone --recurse-submodules --branch $_branch $_git_url $_code_dir
        config_filename="config_test.py"
        if [[ $_deployment_env == "prod" ]];then
            config_filename="config_prod.py"
        fi
        `cp $_work_dir/config.py $_code_dir/scripts/services/$config_filename`
    fi
    call_proto
    generate_ini
    `uwsgi --ini $_ini_file`
elif [[ $_action == "update" ]]; then
    # old_branch=`cd $_code_dir && git branch`
    cd $_code_dir && git pull && git submodule update --init --recursive
    if [[ $? != 0 ]];then
        echo "更新服务失败"
        exit -1
    fi
    call_proto
    `uwsgi --reload $_pid_file`
elif [[ $_action == "start" ]];then
    call_proto
    `uwsgi --gevent 4096 --gevent-early-monkey-patch --ini $_ini_file`
fi

exit 0
