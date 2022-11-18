#!/bin/bash

export LANG=en_US.UTF-8

RED="\033[31m"
GREEN="\033[32m"
YELLOW="\033[33m"
PLAIN='\033[0m'

red() {
    echo -e "\033[31m\033[01m$1\033[0m"
}

green() {
    echo -e "\033[32m\033[01m$1\033[0m"
}

yellow() {
    echo -e "\033[33m\033[01m$1\033[0m"
}

REGEX=("debian" "ubuntu" "centos|red hat|kernel|oracle linux|alma|rocky" "'amazon linux'")
RELEASE=("Debian" "Ubuntu" "CentOS" "CentOS")
PACKAGE_UPDATE=("apt-get -y update" "apt-get -y update" "yum -y update" "yum -y update")
PACKAGE_INSTALL=("apt -y install" "apt -y install" "yum -y install" "yum -y install")
PACKAGE_UNINSTALL=("apt -y autoremove" "apt -y autoremove" "yum -y autoremove" "yum -y autoremove")

[[ $EUID -ne 0 ]] && red "注意：请在root用户下运行脚本" && exit 1

CMD=("$(grep -i pretty_name /etc/os-release 2>/dev/null | cut -d \" -f2)" "$(hostnamectl 2>/dev/null | grep -i system | cut -d : -f2)" "$(lsb_release -sd 2>/dev/null)" "$(grep -i description /etc/lsb-release 2>/dev/null | cut -d \" -f2)" "$(grep . /etc/redhat-release 2>/dev/null)" "$(grep . /etc/issue 2>/dev/null | cut -d \\ -f1 | sed '/^[ ]*$/d')")

for i in "${CMD[@]}"; do
    SYS="$i" && [[ -n $SYS ]] && break
done

for ((int = 0; int < ${#REGEX[@]}; int++)); do
    [[ $(echo "$SYS" | tr '[:upper:]' '[:lower:]') =~ ${REGEX[int]} ]] && SYSTEM="${RELEASE[int]}" && [[ -n $SYSTEM ]] && break
done

[[ -z $SYSTEM ]] && red "不支持当前VPS的系统，请使用主流的操作系统" && exit 1

if [[ -z $(type -P tmux) ]]; then
    if [[ ! $SYSTEM == "CentOS" ]]; then
        ${PACKAGE_UPDATE[int]}
    fi
    ${PACKAGE_INSTALL[int]} tmux
fi

back2menu() {
    yellow "所选操作执行完成"
    read -rp "请输入“y”退出，或按任意键返回主菜单：" back2menuInput
    case "$back2menuInput" in
        y) exit 1 ;;
        *) menu ;;
    esac
}

createTmuxSession(){
    read -rp "设置Tmux后台会话名称：" tmuxName
    if [[ -z $tmuxName ]]; then
        red "未设置Tmux后台会话名称，已退出操作"
        back2menu
    fi
    tmux new -s ${tmuxName}
    back2menu
}

enterTmuxSession(){
    tmuxNames=$(tmux ls | awk '{print $1}' | awk -F ":" '{print $1}')
    if [[ -n $tmuxNames ]]; then
        yellow "当前运行的Tmux后台会话如下所示："
        green "$tmuxNames"
    fi
    read -rp "输入进入的Tmux后台会话名称：" tmuxName
    tmux attach -t ${tmuxName} || red "没有找到名称为 $tmuxName 会话"
    back2menu
}

deleteTmuxSession(){
    tmuxNames=$(tmux ls | awk '{print $1}' | awk -F ":" '{print $1}')
    if [[ -n $tmuxNames ]]; then
        yellow "当前运行的Tmux后台会话如下所示："
        green "$tmuxNames"
    fi
    read -rp "输入需要删除的Tmux后台会话名称：" tmuxName
    tmux kill-session -t ${tmuxName} || red "没有找到名称为 $tmuxName 会话"
    back2menu
}

renameTmuxSession(){
    tmuxNames=$(tmux ls | awk '{print $1}' | awk -F ":" '{print $1}')
    if [[ -n $tmuxNames ]]; then
        yellow "当前运行的Tmux后台会话如下所示："
        green "$tmuxNames"
    fi
    read -rp "输入需要重命名的Tmux后台会话名称：" tmuxName
    read -rp "设置新的Tmux后台会话名称：" tmuxNewName
    tmux rename-session -t ${tmuxName} ${tmuxNewName}
    back2menu
}

menu(){
    clear
    echo "#############################################################"
    echo -e "#                    ${RED} Tmux  后台管理脚本${PLAIN}                    #"
    echo -e "# ${GREEN}作者${PLAIN}: taffychan                                           #"
    echo -e "# ${GREEN}GitHub${PLAIN}: https://github.com/taffychan                      #"
    echo "#############################################################"
    echo ""
    echo -e " ${GREEN}1.${PLAIN} 创建Tmux后台会话并设置会话名称"
    echo " -------------"
    echo -e " ${GREEN}2.${PLAIN} 查看并进入指定Tmux后台会话"
    echo -e " ${GREEN}3.${PLAIN} 查看并删除指定Tmux后台会话"
    echo " -------------"
    echo -e " ${GREEN}4.${PLAIN} 重命名指定Tmux后台会话"
    echo " -------------"
    echo -e " ${GREEN}0.${PLAIN} 退出脚本"
    echo ""
    read -rp "请输入选项 [0-4]:" menuNumberInput
    case "$menuNumberInput" in 
        1 ) createTmuxSession ;;
        2 ) enterTmuxSession ;;
        3 ) deleteTmuxSession ;;
        * ) exit 1 ;;
    esac
}

menu
