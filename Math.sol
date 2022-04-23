// SPDX-License-Identifier: MIT
pragma solidity 0.4.22;

library math {
    function add(int a, int b)public pure returns (int c){
        return a+b;
    }//add function for int
    
    function add (uint a, uint b)public pure returns (uint c) {
        return a+b;
    }//add function for uint
}