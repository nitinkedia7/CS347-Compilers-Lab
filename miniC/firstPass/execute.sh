#!/bin/sh

rm output/intermediate.txt 
rm output/symtab.txt
rm ../secondPass/mips.s 
sleep 1

read -p 'File Name: ' varname
./miniC < "input/"$varname
cd ../secondPass
./inter < ../firstPass/output/intermediate.txt
cd ../firstPass