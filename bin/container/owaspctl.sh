#!/bin/bash
LSDIR='/usr/local/lsws'
OWASP_DIR="${LSDIR}/conf/owasp"
RULE_FILE='modsec_includes.conf'
HTTPD_CONF="${LSDIR}/conf/httpd_config.conf"

help_message(){
    echo 'Command [-enable|-disable]'
    echo 'Example: owaspctl.sh -enable'
    echo 'Enable mod_secure module with latest OWASP version of rules'
    exit 0
}

check_input(){
    if [ -z "${1}" ]; then
        help_message
        exit 1
    fi
}

mk_owasp_dir(){
    if [ -d ${OWASP_DIR} ] ; then
        rm -rf ${OWASP_DIR}
    fi
    mkdir -p ${OWASP_DIR}
    if [ ${?} -ne 0 ] ; then
        echo "Unable to create directory: ${OWASP_DIR}, exit!"
        exit 1
    fi
}

fst_match_line(){
    FIRST_LINE_NUM=$(grep -n -m 1 "${1}" ${2} | awk -F ':' '{print $1}')
}
fst_match_after(){
    FIRST_NUM_AFTER=$(tail -n +${1} ${2} | grep -n -m 1 ${3} | awk -F ':' '{print $1}')
}
lst_match_line(){
    fst_match_after ${1} ${2} '}'
    LAST_LINE_NUM=$((${FIRST_LINE_NUM}+${FIRST_NUM_AFTER}-1))
}

enable_modsec(){
    grep 'module mod_security {' ${HTTPD_CONF} >/dev/null 2>&1
    if [ ${?} -eq 0 ] ; then
        echo "Already configured for modsecurity."
    else
        echo 'Enable modsecurity'
        sed -i "s=module cache=module mod_security {\nmodsecurity  on\
        \nmodsecurity_rules \`\nSecRuleEngine On\n\`\nmodsecurity_rules_file \
        ${OWASP_DIR}/${RULE_FILE}\n  ls_enabled              1\n}\
        \n\nmodule cache=" ${HTTPD_CONF}
    fi    
}

disable_modesec(){
    grep 'module mod_security {' ${HTTPD_CONF} >/dev/null 2>&1
    if [ ${?} -eq 0 ] ; then
        echo 'Disable modsecurity'
        fst_match_line 'module mod_security' ${HTTPD_CONF}
        lst_match_line ${FIRST_LINE_NUM} ${HTTPD_CONF}
        sed -i "${FIRST_LINE_NUM},${LAST_LINE_NUM}d" ${HTTPD_CONF}
    else
        echo 'Already disabled for modsecurity'
    fi    
}

install_git(){
    if [ ! -f /usr/bin/git ]; then
        echo 'Install git'
        apt-get install git -y >/dev/null 2>&1
    fi
}

install_owasp(){
    cd ${OWASP_DIR}
    echo 'Download OWASP rules'
    git clone https://github.com/SpiderLabs/owasp-modsecurity-crs.git >/dev/null 2>&1
}

configure_owasp(){
    echo 'Config OWASP rules.'
    cd ${OWASP_DIR}
    echo "include modsecurity.conf
include owasp-modsecurity-crs/crs-setup.conf
include owasp-modsecurity-crs/rules/REQUEST-900-EXCLUSION-RULES-BEFORE-CRS.conf
include owasp-modsecurity-crs/rules/REQUEST-901-INITIALIZATION.conf
include owasp-modsecurity-crs/rules/REQUEST-903.9001-DRUPAL-EXCLUSION-RULES.conf
include owasp-modsecurity-crs/rules/REQUEST-903.9002-WORDPRESS-EXCLUSION-RULES.conf
include owasp-modsecurity-crs/rules/REQUEST-903.9003-NEXTCLOUD-EXCLUSION-RULES.conf
include owasp-modsecurity-crs/rules/REQUEST-903.9004-DOKUWIKI-EXCLUSION-RULES.conf
include owasp-modsecurity-crs/rules/REQUEST-903.9005-CPANEL-EXCLUSION-RULES.conf
include owasp-modsecurity-crs/rules/REQUEST-903.9006-XENFORO-EXCLUSION-RULES.conf
include owasp-modsecurity-crs/rules/REQUEST-905-COMMON-EXCEPTIONS.conf
include owasp-modsecurity-crs/rules/REQUEST-910-IP-REPUTATION.conf
include owasp-modsecurity-crs/rules/REQUEST-911-METHOD-ENFORCEMENT.conf
include owasp-modsecurity-crs/rules/REQUEST-912-DOS-PROTECTION.conf
include owasp-modsecurity-crs/rules/REQUEST-913-SCANNER-DETECTION.conf
include owasp-modsecurity-crs/rules/REQUEST-920-PROTOCOL-ENFORCEMENT.conf
include owasp-modsecurity-crs/rules/REQUEST-921-PROTOCOL-ATTACK.conf
include owasp-modsecurity-crs/rules/REQUEST-930-APPLICATION-ATTACK-LFI.conf
include owasp-modsecurity-crs/rules/REQUEST-931-APPLICATION-ATTACK-RFI.conf
include owasp-modsecurity-crs/rules/REQUEST-932-APPLICATION-ATTACK-RCE.conf
include owasp-modsecurity-crs/rules/REQUEST-933-APPLICATION-ATTACK-PHP.conf
include owasp-modsecurity-crs/rules/REQUEST-934-APPLICATION-ATTACK-NODEJS.conf
include owasp-modsecurity-crs/rules/REQUEST-941-APPLICATION-ATTACK-XSS.conf
include owasp-modsecurity-crs/rules/REQUEST-942-APPLICATION-ATTACK-SQLI.conf
include owasp-modsecurity-crs/rules/REQUEST-943-APPLICATION-ATTACK-SESSION-FIXATION.conf
include owasp-modsecurity-crs/rules/REQUEST-944-APPLICATION-ATTACK-JAVA.conf
include owasp-modsecurity-crs/rules/REQUEST-949-BLOCKING-EVALUATION.conf
include owasp-modsecurity-crs/rules/RESPONSE-950-DATA-LEAKAGES.conf
include owasp-modsecurity-crs/rules/RESPONSE-951-DATA-LEAKAGES-SQL.conf
include owasp-modsecurity-crs/rules/RESPONSE-952-DATA-LEAKAGES-JAVA.conf
include owasp-modsecurity-crs/rules/RESPONSE-953-DATA-LEAKAGES-PHP.conf
include owasp-modsecurity-crs/rules/RESPONSE-954-DATA-LEAKAGES-IIS.conf
include owasp-modsecurity-crs/rules/RESPONSE-959-BLOCKING-EVALUATION.conf
include owasp-modsecurity-crs/rules/RESPONSE-980-CORRELATION.conf
include owasp-modsecurity-crs/rules/RESPONSE-999-EXCLUSION-RULES-AFTER-CRS.conf">modsec_includes.conf
    echo "SecRuleEngine On">modsecurity.conf
    cd ${OWASP_DIR}/owasp-modsecurity-crs
    if [ -f crs-setup.conf.example ]; then
        mv crs-setup.conf.example crs-setup.conf
    fi    
    cd ${OWASP_DIR}/owasp-modsecurity-crs/rules
    if [ -f REQUEST-900-EXCLUSION-RULES-BEFORE-CRS.conf.example ]; then
        mv REQUEST-900-EXCLUSION-RULES-BEFORE-CRS.conf.example REQUEST-900-EXCLUSION-RULES-BEFORE-CRS.conf
    fi
    if [ -f RESPONSE-999-EXCLUSION-RULES-AFTER-CRS.conf.example ]; then
        mv RESPONSE-999-EXCLUSION-RULES-AFTER-CRS.conf.example RESPONSE-999-EXCLUSION-RULES-AFTER-CRS.conf
    fi
}

main_owasp(){
    mk_owasp_dir
    install_git
    install_owasp
    configure_owasp
}

check_input ${1}
while [ ! -z "${1}" ]; do
    case ${1} in
        -[hH] | -help | --help)
            help_message
            ;;
        -enable | -e | -E)
            main_owasp
            enable_modsec
            ;;
        -disable | -d | -D)
            disable_modesec
            ;;          
        *) 
            help_message
            ;;
    esac
    shift
done