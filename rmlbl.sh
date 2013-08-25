#!/bin/sh

if [ $1 ]; then
	test=1
	echo "Test mode"
fi

parseInput()
{
	# infinite loop
	i=1; j=1
	while : ; do
		
		t=`echo $num | cut -d',' -f$j`
		if [ -z $t ]; then
			# exit if there are no commas any more
			break
		fi
		
		# check for dashes
		if [ `echo $t | egrep '[0-9]+\-[0-9]+'` ]; then
			# only two first nums!
			dash1=`echo $t | cut -d'-' -f1`
			dash2=`echo $t | cut -d'-' -f2`
			if [ $dash2 -ge $dash1 ]; then
				while [ $dash1 -le $dash2 ]; do
					arr[$i]=$dash1
					i=`expr $i + 1`
					dash1=`expr $dash1 + 1`
				done
			fi
		else
			# check for trash in value
			if [ `echo $t | egrep '[-,]'` ]; then 
				echo Error
				exit 2
			else
				# just add
				arr[$i]=$t
				i=`expr $i + 1`
			fi

		fi
	
		# simple check for any commas
		if [ `echo $num | grep ','` ]; then
			j=`expr $j + 1` 	
		else
			break			
		fi
	done

	# Sort array
	line=`for a in ${arr[@]};
	do
		echo $a
	done | sort -nu`

	# Fill array
	i=1
	for l in $line
	do
		ver_arr[$i]=$l
		i=`expr $i + 1` 	
	done

	# Just print
	i=1
	while [ ${ver_arr[$i]} ]; do
		echo ${ver_arr[$i]}
		i=`expr $i + 1` 	
	done

}

getClients()
{
	clients_list=`p4 clients -u $P4USER | cut -d' ' -f2 --output-delimiter='\n'`

	if [ $? -ne 0 ] 
	then
		echo "p4 error"
		exit 1
	fi

	i=0
	for client in `echo $clients_list` 
	do
		i=`expr $i + 1` 
		clients[$i]=$client
		echo $i. $client
	done

	read -p "Enter the number of label: " num

	valid_num=`echo $num | egrep '^[0-9,-]*$'`

	if [ $valid_num ] 
	then
		# Valid
		parseInput()
		
		i=1
		while [ ${ver_arr[$i]} ]; do
			label[$i]=${clients[${ver_arr[$i]}]}
			path[$i]=`p4 clients -u $P4USER | egrep ${label[$i]} | cut -d"'" -f1 | egrep -o 'root\ .*' | egrep -o '[^root].*'`
			i=`expr $i + 1` 	
		done
	else
		echo "data error"
		exit 2
	fi
}

revertFiles()
{
	files_list=`p4 opened -C ${label[$1]} | cut -d'#' -f1`
	if [ -z $test ]; then
		p4 -c $label -u $P4USER revert $files_list
	fi

}

removeCLs()
{
	cls=`p4 changelists -u $P4USER -s pending -c ${label[$1]} | cut -d' ' -f2`
	if [ -z $test ]; then
		for cl in `echo $cls`
		do
			p4 -c ${label[$i]} changelist -d $cl
		done
	fi
	
}

removeClient()
{
	if [ -z $test ]; then
		p4 client -d ${label[$i]}
	fi
}

removePath()
{
	echo Path: $path
	read -p 'Do you want do remove it (y/n)? ' confirm
	if [ $confirm == 'y' ]
	then
		if [ -z $test ]; then
			rm -rf ${path[$i]}
		fi
	fi
	
}

getClients
i=1
while [ ${ver_arr[$i]} ]; do
	revertFiles $i
	removeCLs $i
	removeClient $i
	removePath $i
	i=`expr $i + 1` 	
done
