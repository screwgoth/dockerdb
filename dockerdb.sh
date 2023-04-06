#!/bin/bash

#######################
# App Name : DockerDB #
#######################

#Define the minimum no. of arguments
APP=`basename $0`

# Function to get the version of the script
# Make sure there is a file called VERSION with the
# version information about the script
get_version () {
    echo -e "\033[34m"
    cat VERSION
    echo -e "\033[0m"
}

# Put your command-line help here
usage () {
    get_version
    echo -e "\n\033[34m$APP : Docker wrapper utility to run Docker database containers"
    echo -e "\033[34mUsage :"
    echo -e "\t\033[34m$APP [-h|--help] [-v|--version] [-l|--list] [-r|--required 123] [-o|--optional [124]]\033[0m"
    echo -e "\033[34mwhere,"
    echo -e "\t\033[34m-l, --list : Show list of available database options"
    echo -e "\t\033[34m-v, --version : Show script version info"
    echo -e "\t\033[34m-h, --help : Show this Help message\033[0m"
}

OPTIONS=`getopt -o vlh --long version,list,help -n '$APP' -- "$@"`
if [ $? != 0 ];
then
    echo -e "\033[31mError Parsing arguments\033[0m"
    usage
    exit 1
fi


#Set Variable defaults for the options to be parsed
SELECTED_DB=''
LIST=false
HELP=false
VERSION=false
INTERACTIVE=true
export DATABASE="test"
export USERNAME="user"
export PASSWORD="password"
export ROOTPASSWORD="root"

while true; do
    case "$1" in
        -v | --version)
            VERSION=true
            INTERACTIVE=false
            break;;
        -h | --help)
            HELP=true
            INTERACTIVE=false
            break;;
        -l | --list)
            LIST=true
            INTERACTIVE=false
            break;;
        --)
            shift
            break;;
        *)
            break;;
    esac
done

if $HELP;
then
    usage
fi

list_db () {
    echo "1. MySQL"
    echo "2. PostgreSQL"
    echo "3. MongoDB"
    echo -e "\n"
}

if $LIST;
then
    echo -e "\n"
    echo "Listing support Databases"
    echo "=========================="
    list_db
fi


if $VERSION;
then
    get_version
fi

if [ "$INTERACTIVE" = false ];
then
    exit
fi

purge () {
    echo -e "\033[31mPurging EVERYTHING !!!"
    read -e -p "Are you sure you want to continue? (yes/no): \033[0m" purge_ans
    echo $purge_ans
    if [[ "$purge_ans" == "no" ]]; then main_menu; fi
    docker compose -f docker-compose-mysql.yml down
    docker compose -f docker-compose-postgresql.yml down
    docker compose -f docker-compose-mongo.yml down
    docker volume rm -f mysqldbdata
    docker volume rm -f postgresqldbdata
    docker volume rm -f mongodbdata
    echo -e "KHATAM !!!"
}

clean_db () {
    echo -e "\033[34mStarting cleanup for $SELECTED_DB\033[0m"
    docker_file=docker-compose-$DB_TEXT.yml
    docker compose -f $docker_file down
    docker volume rm -f "$DB_TEXT"dbdata
}

start_db () {
    echo -e "\033[34mStarting $SELECTED_DB\033[0m"
    docker_file=docker-compose-$DB_TEXT.yml
    docker compose -f $docker_file up -d
}

select_db () {
    if [[ "$1" -eq 2 ]]
    then
        cleanup=true
    else
        cleanup=false
    fi
    list_db
    read -e -p "Which Database do you want to run : " SELECTED_DB
    case $SELECTED_DB in
        1)
            DB_TEXT="mysql"
            ;;
        2)  
            DB_TEXT="postgresql"
            ;;
        3)
            DB_TEXT="mongo"
            ;;
        *)
            echo -e "\033[31mInvalid Choice. Try Again ...\033[0m"
            DB_TEXT=''
    esac
}

process_selected () {
    selected=$1
    # echo -e "User has entered task: $selected"
    case "$selected" in
        1)  
            echo "Listing support Databases"
            echo "=========================="
            list_db
            read -e -p "Press Enter/Return to continue "
            ;;
        2)  
            select_db
            if [[ -z $DB_TEXT ]]; then exit; fi
            clean_db $DB_TEXT
            start_db $DB_TEXT
            ;;
        3)  
            select_db
            if [[ -z $DB_TEXT ]]; then exit; fi
            start_db $DB_TEXT
            ;;
        4)  
            echo "Purge"
            purge
            ;;
        5 | "q")  
            echo "Goodbye Cruel World !!!"
            exit 0
            ;;
        *)
            echo -e "\033[31mInvalid Choice. Try Again ...\033[0m"
    esac
    main_menu
}

main_menu () {
    echo -e "\nMain Menu\n---------\nDockerDB can perform the following tasks:"
    echo -e "1. List supported Databases"
    echo -e "2. Clean and setup new Database"
    echo -e "3. Just create a new Database quickly"
    echo -e "4. Cleanup everything"
    echo -e "5. Exit"
    read -e -p "Enter the task number you want to execute: " answer
    process_selected $answer
}

echo -e "\n"
echo -e "Welcome to DockerDB"
main_menu


exit 0
