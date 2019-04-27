#!/bin/sh

rm output/intermediate.txt 
rm output/symtab.txt
rm ../secondPass/mips.s 
sleep 1

./miniC < "input/"$1
cd ../secondPass
./inter < ../firstPass/output/intermediate.txt
cd ../firstPass