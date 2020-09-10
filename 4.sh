#/bin/bash
arr=()
sum=0;

getopts ":l:" opt
min=$OPTARG
getopts ":h:" opt
max=$OPTARG

while read line
do
arr+=("$line")
done
for value in ${arr[*]}
do
if [ $value -gt $min ] && [ $value -lt $max ]
then
sum=$(expr $sum + $value)
fi
done
echo "Sum: $sum"
