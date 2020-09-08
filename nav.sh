#!/bin/bash

# Copyright 2020 John Mullan
# The creator of this software, John Mullan, has made it available under the MIT license,
# as deliniated in the LICENSE file in the root directory of this repository

# Obtains all relavent commands from the nav_data file, and acts upon user input to the
# main menu and settings menu
main() {
    local display_width=40
    local host_name="John's Laptop"

    DEFAULT_IFS=$' \t\n'
    IFS=$DEFAULT_IFS
    local orig_IFS=$IFS

    script_directory=$(dirname ${BASH_SOURCE})
    nav_data_file=$script_directory"/nav_data"

    while true; do
        get_global_commands $nav_data_file
        IFS=$'\n'
        global_commands=( $retval )
        global_commands_as_string="$retval"
        IFS=$orig_IFS

        get_relative_commands $nav_data_file
        IFS=$'\n'
        relative_commands=( $retval )
        relative_commands_as_string="$retval"
        IFS=$orig_IFS

        get_absolute_commands $nav_data_file
        IFS=$'\n'
        absolute_commands=( $retval )
        absolute_commands_as_string="$retval"
        IFS=$orig_IFS
        
        applicable_commands=()
        applicable_commands+=( "${global_commands[@]}" )
        applicable_commands+=( "${relative_commands[@]}" )
        applicable_commands+=( "${absolute_commands[@]}" )

        applicable_commands_as_string=""
        for item in "${applicable_commands[@]}"; do
            applicable_commands_as_string+="${item}"$'\n'
        done

    
        display_main_menu_options "$global_commands_as_string" "$relative_commands_as_string" "$absolute_commands_as_string" 40 false "$host_name"
        get_main_menu_option "$global_commands_as_string" "$relative_commands_as_string" "$absolute_commands_as_string" 40 "$host_name"
        main_menu_option=$retval
        handle_main_menu_option "$applicable_commands_as_string" "$main_menu_option" "$nav_data_file" "$global_commands_as_string" "$relative_commands_as_string" "$absolute_commands_as_string" 40
        if [[ $? == 1 ]]; then
            return 1
        fi

    done

    IFS=$orig_IFS
}

# displays the host name enclosed in a asterisks box of width
# equal to the display_width
# $1: the width of the asterisks character box
# $2: the name of the host that will be displayed
display_host() {
	display_width=$1
	host_name=$2	
	#print top border	
	for (( k=0; k<=$display_width; k++ ))
	do
		echo -n \* 
	done	
	echo
	
	#print row with edges
	echo -n \*
	for (( k=1; k<$display_width; k++ ))
	do
		echo -n ' '
	done
	echo \*

	#print row with label	
	echo -n \*
	for (( k=0; k<$(( ($display_width - ${#host_name}) / 2 )); k++ ))
	do
		echo -n ' '
	done	

	echo -n $host_name

	the_k=1
	if [[ $(( ($display_width - ${#host_name}) % 2 )) == 0 ]]; then
		the_k=1
	else
		the_k=0
	fi		

	for (( k=$the_k; k<$(( ($display_width - ${#host_name}) / 2 )); k++ ))
	do
		echo -n ' '
	done
	echo \*
	
	#print row with edges
	echo -n \*
	for (( k=1; k<$display_width; k++ ))
	do
		echo -n ' '
	done
	echo \*

	#print bottom border	
	for (( k=0; k<=$display_width; k++ ))
	do
		echo -n \* 
	done	
	echo
}

# executes the specified command
# $1: applicable commands as a string
# $2: the number of the command to execute
execute_command() {
    local orig_IFS=$IFS
    IFS=$'\n'

    applicable_commands=( $1 )
    main_menu_option=$2

    command_index=$(($main_menu_option + $(($(($main_menu_option - 1)) * 2)) ))
    eval ${applicable_commands[$command_index]}
}

# deletes a command set from nav_data that the user specifies
# $1: absolute path of the nav_data file
# $2: applicable commands for the cwd
delete_command() {
    IFS=$orig_IFS
    IFS=$'\n'
    local nav_data_file=$1
    local applicable_commands=( $2 )
    
    BOLD='\033[1m'
    RESET='\033[0m'

    deleting=true
    while $deleting; do
        echo
        echo -en "${BOLD}Enter option number to delete: ${RESET}"
        read option_to_delete
        confirming=true
        while $confirming; do
            echo -e "${BOLD}Do you confirm?${RESET}"
            echo -e "${BOLD}(y)${RESET} Yes, proceed with permanent deletion"
            echo -e "${BOLD}(n)${RESET} No, do not delete"
            echo
            read -p "Enter option letter (or enter 'cancel' to stop): " confirm_path

            if [[ $confirm_path == "y" ]]; then
                
                
                index_of_line_num=$(($(($option_to_delete * 3)) - 1))
                line_num_to_delete="${applicable_commands[$index_of_line_num]}"

                local regex='^[1-9]+$'
                if [[ $line_num_to_delete =~ $regex ]]; then
                    sed_command_code=${line_num_to_delete}d
                    sed -i '' -e $sed_command_code $nav_data_file
                    sed -i '' -e $sed_command_code $nav_data_file
                    sed -i '' -e $sed_command_code $nav_data_file
                    
                    confirming=false
                    deleting=false
                else
                    echo "Line to delete is invalid"
                    confirming=false
                fi

            elif [[ $confirm_path == "n" ]]; then
                confirming=false
            elif [[ $confirm_path == "cancel" ]]; then
                clear
                return 1
            else
                echo "'$confirm_path' is an invalid choice. Please try again"
                sleep 2
                clear
            fi
        done
    done

    IFS=$orig_IFS
}

# handles the selected option from the main menu
#       calls function to execute command, goes to settings, or quits
# $1: applicable commands as a string
# $2: the validated number or letter of the selection from the main menu
# $3: absolute path of the nav_data_file
# $4: all global command groups
# $5: applicable relative command groups
# $6: applicable absolute command groups
# $7: line length
handle_main_menu_option(){
    IFS=$orig_IFS
    IFS=$'\n'
    local applicable_commands=( $1 )
    local main_menu_selection=$2
    local regex='^[0-9]+$'


    if [[ $main_menu_selection == "q" ]]; then
        return 1
    elif [[ $main_menu_selection == "s" ]]; then
        display_settings_menu_options

        get_settings_menu_option
        local settings_menu_selection=$retval

        handle_settings_menu_option "$settings_menu_selection" "$3" "$4" "$5" "$6" "$7" "$1"
        if [[ $? == 1 ]]; then
            return 1
        fi

    #if it is a number
    elif [[ $main_menu_selection =~  $regex ]]; then
        execute_command "$1" "$main_menu_selection"
        return 1
    else
        echo "error no match here"
        echo "$main_menu_selection"
    fi

    IFS=$orig_IFS
}

# handles the selected option from the settings menu
# $1: the validated number or letter of the selection from the settings menu
# $2: absolute path of the nav_data_file
# $3: all global command groups
# $4 applicable relative command groups
# $5 applicable absolute command groups
# $6 line length
# $7 applicable commands as a string
handle_settings_menu_option(){
    local orig_IFS=$IFS
    IFS=$'\n'
    local setting_menu_selection=$1
    local nav_data_file=$2

    IFS=$orig_IFS

    #add, delete, inspect, return, quit

    if [[ "$setting_menu_selection" == "1" ]]; then
        echo "you chose one"
        add_option $nav_data_file
    elif [[ $setting_menu_selection == "2" ]]; then
        clear
        display_main_menu_options "$3" "$4" "$5" "$6" true
        delete_command "$2" "$7"
    elif [[ $setting_menu_selection == "3" ]]; then
        clear
    elif [[ $setting_menu_selection == "4" ]]; then
        return 1
    else
        echo "error no match"
        echo "$settings_menu_selection"
    fi
}

# gets the option selected by the user from the "main menu"
# $1: all global command groups
# $2 applicable relative command groups
# $3 applicable absolute command groups
# $4 line length
# $5 host machine name
# returns: retval set to integer of option selected
get_main_menu_option() {
    local orig_IFS=$IFS
    IFS=$'\n'
	global_commands=( $1 )
    relative_commands=( $2 )
    absolute_commands=( $3 )
    local line_length=$4

    GREEN='\033[0;32m'
    YELLOW='\033[0;33m'
    BOLD='\033[1m'
    RESET='\033[0m'

    validating=true

    while $validating; do
        echo
        echo -en "${BOLD}Please enter your selection: ${RESET}"
        read main_menu_selection

        local regex='(^[0-9]+$|^s{1}$|^q{1}$)'
        if [[ $main_menu_selection =~ $regex  ]]; then
            retval="$main_menu_selection"
            validating=false
        else
            echo "'$main_menu_selection' is not valid. Please try again"
            sleep 2
            clear
            display_main_menu_options "$global_commands_as_string" "$relative_commands_as_string" "$absolute_commands_as_string" "$line_length" false "$5"
        fi
    done
    IFS=$orig_IFS
}

# gets the option selected by the user from the "settings menu"
# returns: retval set to integer of option selected
get_settings_menu_option() {
    BOLD='\033[1m'
    RESET='\033[0m' 

    local validating=true
    while $validating; do
        echo
        echo -en "${BOLD}Please enter your selection: ${RESET}"
        read settings_menu_selection
        local regex='^[1-4]{1}$'
        if [[ $settings_menu_selection =~ $regex  ]]; then
            retval="$settings_menu_selection"
            validating=false
        else
            echo "'$settings_menu_selection' is not valid. Please try again"
            sleep 2
            clear
            display_settings_menu_options
        fi
    done
}

# displays settings menu options
display_settings_menu_options() {
    BOLD='\033[1m'
    RESET='\033[0m'

    clear
    echo -e "${BOLD}Settings${RESET}"
    echo -e "${BOLD}(1)${RESET} Add a command"
    echo -e "${BOLD}(2)${RESET} Delete a command"
    echo -e "${BOLD}(3)${RESET} Return to main menu"
    echo -e "${BOLD}(4)${RESET} Quit"

}

# displays appropriate options for the cwd
# $1: all global command groups
# $2 applicable relative command groups
# $3 applicable absolute command groups
# $4 line length
# $5 a bool indicating if the menu displayed is for reference in a deletion operation
#     (if true, the other sub-menu will not be displayed)
# $6 host machine label
display_main_menu_options() {
    local orig_IFS=$IFS
    IFS=$'\n'
	global_commands=( $1 )
    relative_commands=( $2 )
    absolute_commands=( $3 )
    local line_length=$4
    for_deletion_reference=$5

    RESET='\033[0m'
    GREEN='\033[0;32m'
    DARK_GREY='\033[0;90m'
    BOLD='\033[1m'

    global_commands_exist=true
    local_commands_exist=true

    if [[ ${#global_commands[@]} == 0 ]]; then
        global_commands_exist=false
    fi

    #relative commands and absolute commands are considered "local" commands
    if [[ $((${#relative_commands[@]} + ${#absolute_commands[@]})) == 0 ]]; then
        local_commands_exist=false
    fi

    j=1

    #display host if appropriate
    if [[ "$for_deletion_reference" != true ]]; then
        display_host $4 $6
    fi

    #display global commands header if appropriate
    if [[ $global_commands_exist == true ]]; then
        echo -e "${BOLD}Global commands:${RESET}"
    fi
    
    #display global command labels
    for (( i=0; i<${#global_commands[@]}; i+=3 )); do
        echo -ne "${DARK_GREY}${global_commands[$i]}"
        label_length=${#global_commands[$i]}
        gap=$(( line_length - label_length ))
        for (( k=0; k<$gap; k++ ))
		do
			echo -n .
		done
        echo -e $j${RESET}

        ((j=j+1))
    done

    #display local commands header if appropriate
    if [[ $local_commands_exist == true ]]; then
        echo -e "${BOLD}Local commands:${RESET}"
    fi

    #display relative command labels
    for (( i=0; i<${#relative_commands[@]}; i+=3 )); do
        echo -n "${relative_commands[$i]}"
        label_length=${#relative_commands[$i]}
        gap=$(( line_length - label_length ))
        for (( k=0; k<$gap; k++ ))
		do
			echo -n .
		done
        echo $j

        ((j=j+1))
    done

    #display local command labels
    for (( i=0; i<${#absolute_commands[@]}; i+=3 )); do
        echo -n "${absolute_commands[$i]}"
        label_length=${#absolute_commands[$i]}
        gap=$(( line_length - label_length ))
        for (( k=0; k<$gap; k++ ))
		do
			echo -n .
		done
        echo $j

        ((j=j+1))
    done

    if [[ $for_deletion_reference != true ]]; then
        #display other header
        echo -e "${BOLD}Other:${RESET}"

        #display settings option
        label="settings"
        echo -ne "${DARK_GREY}$label"
        label_length=${#label}
        gap=$(( line_length - label_length ))
            for (( k=0; k<$gap; k++ ))
            do
                echo -n .
            done
            echo "s"

        #display quit option
        label="quit"
        echo -n "$label"
        label_length=${#label}
        gap=$(( line_length - label_length ))
            for (( k=0; k<$gap; k++ ))
            do
                echo -n .
            done
            echo -e "q${RESET}"
    fi
	
    IFS=$orig_IFS
}

# gets commands to be shown in every working directory
# $1: absolute path of the nav_data file
# returns: retval set to string of lines, each group of three lines which are associated with a command, forming n groups:
#       lines 1, 1+3,...,1+3n: label
#       lines 2, 2+3,...,2+3n: full command
#       lines 3, 3+3,...,3+3n: line number of nav_data_file that contains the availability setting
get_global_commands() {
    local global_commands=()
    local nav_data_file=$1
    local i=1
    local orig_IFS=$IFS

    while IFS= read -r line
    do
        if [[ "$line" == "*" ]]; then
            IFS=$'\n'

            sed_command_code="$(($i + 1))p"
            global_commands+=( "$(sed -n "$sed_command_code" "$nav_data_file")" )

            sed_command_code="$(($i + 2))p"
            global_commands+=( "$(sed -n "$sed_command_code" "$nav_data_file")" )

            global_commands+=( $i )
        fi
        ((i=i+1))
    done<"$nav_data_file"

    #encode the array as a string of words separated by the new line character
    return_value=""
    for item in "${global_commands[@]}"; do
        return_value+="${item}"$'\n'
    done

    retval="$return_value"
    IFS=$orig_IFS
}

# gets applicable relative commands to be shown
# $1: absolute path of the anv_data file
# returns: retval set to string of lines, each group of three lines which are associated with a command, forming n groups:
#       lines 1, 1+3,...,1+3n: label
#       lines 2, 2+3,...,2+3n: full command
#       lines 3, 3+3,...,3+3n: line number of nav_data_file that contains the availability setting
get_relative_commands() {
    local nav_data_file=$1

    local relative_commands=()
    local i=1
    local orig_IFS=$IFS

    while IFS= read -r line
    do
        local qualifying_path_length=false
        local asterisks_is_substring=false
        local wd_has_qualifying_substring=false
        if [[ "${#line}" -gt 1 ]]; then
            qualifying_path_length=true
        fi
        if [[ "$line" == *"*"* ]]; then
            asterisks_is_substring=true
        fi

        IFS="*"
        read -a temp_array <<< "$line"
        clean_path="${temp_array[0]}"
        #remove the trailing forward slash
        clean_path="${clean_path%?}"
        IFS=$orig_IFS


        if [[ "$(pwd)" == *"$clean_path"*  ]]; then
            wd_has_qualifying_substring=true
        fi

        if [[ $qualifying_path_length == true ]] && [[ $asterisks_is_substring == true ]] && [[ $wd_has_qualifying_substring == true ]]; then
            IFS=$'\n'

            sed_command_code="$(($i + 1))p"
            relative_commands+=( "$(sed -n "$sed_command_code" "$nav_data_file")" )

            sed_command_code="$(($i + 2))p"
            relative_commands+=( "$(sed -n "$sed_command_code" "$nav_data_file")" )

            relative_commands+=( $i )
        fi

        ((i=i+1))
    done<"$nav_data_file"

    #encode the array as a string of words separated by the new line character
    local return_value=""
    for item in "${relative_commands[@]}"; do
        return_value+="${item}"$'\n'
    done

    retval="$return_value"
    IFS=$orig_IFS
}

# gets applicable absolute commands to be shown
# $1: absolute path of the anv_data file
# returns: retval set to string of lines, each group of three lines which are associated with a command, forming n groups:
#       lines 1, 1+3,...,1+3n: label
#       lines 2, 2+3,...,2+3n: full command
#       lines 3, 3+3,...,3+3n: line number of nav_data_file that contains the availability setting
get_absolute_commands() {
    local nav_data_file=$1

    local absolute_commands=()
    local i=1
    local orig_IFS=$IFS

    while IFS= read -r line
    do
        if [[ "$(pwd)" == "$line" ]]; then
            IFS=$'\n'

            sed_command_code="$(($i + 1))p"
            absolute_commands+=( "$(sed -n "$sed_command_code" "$nav_data_file")" )

            sed_command_code="$(($i + 2))p"
            absolute_commands+=( "$(sed -n "$sed_command_code" "$nav_data_file")" )

            absolute_commands+=( $i )
        fi
        ((i=i+1))

    done<"$nav_data_file"

    #encode the array as a string of words separated by the new line character
    local return_value=""
    for item in "${absolute_commands[@]}"; do
        return_value+="${item}"$'\n'
    done

    retval="$return_value"
    IFS=$orig_IFS
}



# print the progress for adding a new command
# $1: availability (as will appear in nav_data_file)
# $2: label
# $3: full command
# $4: confirmation status of availability (boolean)
# $5: confirmation status of label (boolean)
# $6: confirmation status of full command (boolean)
show_add_progress() {
    GREEN='\033[0;32m'
    YELLOW='\033[0;33m'
    BOLD='\033[1m'
    RESET='\033[0m'

    availability_symbol="       "
    availability_color=""

    label_symbol="       "
    label_color=""

    full_command_symbol="       "
    full_command_color=""

    if [[ $1 != "" ]] && [[ $4 != true ]]; then
        availability_symbol="pending"
        availability_color=$YELLOW
    elif [[ $1 != "" ]] && [[ $4 == true ]]; then
        availability_symbol="   x   "
        availability_color=$GREEN
    fi

    if [[ $2 != "" ]] && [[ $5 != true ]]; then
        label_symbol="pending"
        label_color=$YELLOW
    elif [[ $2 != "" ]] && [[ $5 == true ]]; then
        label_symbol="   x   "
        label_color=$GREEN
    fi

    if [[ $3 != "" ]] && [[ $6 != true ]]; then
        full_command_symbol="pending"
        full_command_color=$YELLOW
    elif [[ $3 != "" ]] && [[ $6 == true ]]; then
        full_command_symbol="   x   "
        full_command_color=$GREEN
    fi

    clear
    echo -e "${BOLD}Command constructor${RESET}"
    echo -e "[${availability_color}${availability_symbol}${RESET}] ${BOLD}Availability: ${RESET}$1"
    echo -e "[${label_color}${label_symbol}${RESET}] ${BOLD}Label: ${RESET}$2"
    echo -e "[${full_command_color}${full_command_symbol}${RESET}] ${BOLD}Full command: ${RESET}$3"
    echo
}

# sets the availability
# returns: retval set to '*', 'some/absolute/path/*', or 'some/absolute/path'
set_availability() {
    path_to_add=""
    path_confirmed=false

    BOLD='\033[1m'
    DARK_GREY='\033[0;90m'
    RESET='\033[0m'

    setting_availability_option=true
    while $setting_availability_option; do
        show_add_progress $path_to_add "" "" "" "" ""
        echo -en "${BOLD}Current working directory: ${RESET}"
        echo -e "${DARK_GREY}$(pwd)${RESET}"
        echo -e "${BOLD}Where should this command be available?${RESET}"
        echo -e "${BOLD}(1)${RESET} In all directories"
        echo -e "${BOLD}(2)${RESET} Only in this directory or its subdirectories"
        echo -e "${BOLD}(3)${RESET} Only in this subdirectory"
        echo
        read -p "Enter option number (or 'cancel' to stop): " availability_option

        if [[ $availability_option == "1" ]]; then
            path_to_add="*"
        elif [[ $availability_option == "2" ]]; then
            path_to_add="$(pwd)/*"
        elif [[ $availability_option == "3" ]]; then
            path_to_add="$(pwd)"
        elif [[ $availability_option == "cancel" ]]; then
            return 1
        else
            echo "$availability_option is an invalid choice. Please try again"
            sleep 2
            continue
        fi

        confirming=true
        while $confirming; do
            show_add_progress "$path_to_add" "" "" !$confirming "" ""
            echo -e "${BOLD}Do you confirm?${RESET}"
            echo -e "${BOLD}(y)${RESET} Yes, confirm the pending setting"
            echo -e "${BOLD}(n)${RESET} No, reject the pending setting"
            echo
            read -p "Enter option letter (or enter 'cancel' to stop): " confirm_path

            if [[ $confirm_path == "y" ]]; then
                confirming=false
                setting_availability_option=false
            elif [[ $confirm_path == "n" ]]; then
                path_to_add=""
                confirming=false
            elif [[ $confirm_path == "cancel" ]]; then
                clear
                return 1
            else
                echo "'$confirm_path' is an invalid choice. Please try again"
                sleep 2
                clear
            fi
        done
    done

    retval=$path_to_add
}

# sets the label
# $1: path_to_add (so that show_add_progress can be called)
# returns: retval set to the label to be added
set_label() {
    path_to_add=$1

    setting_label=true
    label_to_add=""
    while $setting_label; do
        show_add_progress "$path_to_add" "$label_to_add" "" true "$label_confirmed" ""
        echo -en "${BOLD}Enter the label to be displayed: ${RESET}"
        read label_option
        if [[ $label_option == "cancel" ]]; then
            return 1
        fi

        label_to_add="$label_option"

        confirming=true
        while $confirming; do
            show_add_progress "$path_to_add" "$label_to_add" "" true "" ""
            echo -e "${BOLD}Do you confirm?${RESET}"
            echo -e "${BOLD}(y)${RESET} Yes, confirm the pending setting"
            echo -e "${BOLD}(n)${RESET} No, reject the pending setting"
            echo
            read -p "Enter option letter (or enter 'cancel' to stop): " confirm_label

            if [[ $confirm_label == 'y' ]]; then
                confirming=false
                setting_label=false
            elif [[ $confirm_label == 'n' ]]; then
                label_to_add=""
                confirming=false
            elif [[ $confirm_label == 'cancel' ]]; then
                return 1
            else
                clear
                echo "'$confirm_label' is an invalid choice. Please try again"
                sleep 2
            fi
        done
    done

    retval=$label_to_add
}

# sets the command
# $1: path_to_add (so that show_add_progress can be called)
# $2: label_to_add (so that show_add_progress can be called)
# returns: retval set to the full command (may be a sequence of commands) to be added
set_command() {
    path_to_add=$1
    label_to_add=$2
    command_to_add=""

    setting_command=true
    while $setting_command; do
        show_add_progress "$path_to_add" "$label_to_add" "$command_to_add" true true ""
        echo -e "${BOLD}What should this command do?${RESET}"
        echo -e "${BOLD}(1)${RESET} cd to this directory ($(pwd))"
        echo -e "${BOLD}(2)${RESET} cd to another directory"
        echo -e "${BOLD}(3)${RESET} cd to this directory ($(pwd)) then run another command"
        echo -e "${BOLD}(4)${RESET} cd to another directory then run another command"
        echo -e "${BOLD}(5)${RESET} Run a command without first cd-ing"
        echo
        read -p "Enter option number (or 'cancel' to stop): " command_nature_option
        echo

        if [[ $command_nature_option == "1" ]]; then
            command_to_add="cd $(pwd)"
        elif [[ $command_nature_option == "2" ]]; then
            read -p "Enter directory as an absolute path to cd to: " cd_destination
            command_to_add="cd $cd_destination"
        elif [[ $command_nature_option == "3" ]]; then
            read -p "Enter the command that should be run after cd-ing to this directory ($(pwd)): " command_option
            command_to_add="cd $(pwd); $command_option"           
        elif [[ $command_nature_option == "4" ]]; then
            read -p "Enter the directory as an absolute path that should be cd-ed to prior to running a command: " cd_destination
            read -p "Enter the command that should be run after cd-ing to $cd_destination: " command_option
            command_to_add="cd $cd_destination; $command_option"
        elif [[ $command_nature_option == "5" ]]; then
            read -p "Enter command to be run: " command_option
            command_to_add=$command_option
        elif [[ $command_nature_option == 'cancel' ]]; then
            return 1
        else
            echo "'$command_nature_option' is an invalid choice. Please try again"
            sleep 2
            continue
        fi

        confirming=true
        while $confirming; do
            show_add_progress "$path_to_add" "$label_to_add" "$command_to_add" true true ""
            echo -e "${BOLD}Do you confirm?${RESET}"
            echo -e "${BOLD}(y)${RESET} Yes, confirm the pending setting"
            echo -e "${BOLD}(n)${RESET} No, reject the pending setting"
            echo
            read -p "Enter option letter (or enter 'cancel' to stop): " confirm_command
            if [[ $confirm_command == "y" ]]; then
                setting_command=false
                confirming=false
            elif [[ $confirm_command == "n" ]]; then
                command_to_add=""
                confirming=false
            elif [[ $confirm_command == "cancel" ]]; then
                return 1
            else
                echo "'$confirm_command' is an invalid choice. Please try again"
                sleep 2
                clear
            fi
        done

    done

    retval=$command_to_add
}

# adds a new command option by prompting user for input
# $1: absolute path of the nav_data file
# returns: 1 if cancelled
add_option() {
    local nav_data_file=$1

    local path_to_add=""
    local label_to_add=""
    local command_to_add=""

    #set the availability option
    clear
    set_availability
    if [[ $? == 1 ]]; then
        return 1
    fi
    path_to_add=$retval

    #set the label
    clear
    set_label "$path_to_add"
    if [[ $? == 1 ]]; then
        return 1
    fi
    label_to_add=$retval

    #set the command
    clear
    set_command "$path_to_add" "$label_to_add"
    if [[ $? == 1 ]]; then
        return 1
    fi
    command_to_add=$retval

    show_add_progress "$path_to_add" "$label_to_add" "$command_to_add" true true true
    echo "Command added successfully"


    #note: vars are quoted to prevent expansion of the '*' character
    echo "$path_to_add" >> $nav_data_file
    echo "$label_to_add" >> $nav_data_file
    echo "$command_to_add" >> $nav_data_file


    
}

main
