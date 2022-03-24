pragma solidity ^0.4.22;

contract DataLocation{

    uint[] storageData;

    function test1(uint[] ) public pure{

    }
    function test2(uint[] memoryArray) public {
        storageData = memoryArray; 
        uint[] storage varData = storageData;
        varData.length = 2; // set uint array length
        delete storageData; // set to zero
        //varData = memoryArray;
        //delete varData;
        test3(storageData);// call test3 func
        test4(storageData);// call test4 func
    }
    function test3(uint[] storage ) internal pure{} // Can only be called internally
    function test4(uint[] memory) public pure{}
}
