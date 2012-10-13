#!/bin/bash

for t in test_Array test_Vector test_Queue test_Deque; do
    echo $t
    luajit ./tests/$t.lua
done
