// SPDX-License-Identifier: MIT
pragma solidity 0.4.22;

import "./03_Math.sol" ;

contract Structure {
    address owner;
    uint data;
    event logData(uint dataToLog);
    
    modifier onlyOwner() {
        require(msg.sender == owner, "not owner");//if not owner ,return  origin state
        _;
    }//check access
        
    constructor(address initOwner, uint initData) public {
        owner = initOwner;
        data = initData;
    }//set owner
    
    function getData() public view returns(uint returnData) {
        return data;
    }// get data
    
    function setData( uint newData) public onlyOwner {
        emit logData(newData);
        data = newData;
    }//set data
        
    function increaseData( uint value) public {
        data = math.add(data, value);
    }// increase data
}
    