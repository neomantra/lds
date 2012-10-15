#!/bin/bash

for t in \
    test_Array test_Vector test_Queue test_Deque \
    test_HashSet test_HashMap \
    ;
do
    echo $t
    luajit ./tests/$t.lua
done
