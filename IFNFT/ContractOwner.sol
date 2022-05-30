// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

contract ContractOwner{
    address private contractOwner;	//合約管理者帳戶
    
    modifier onlyContractOwner() {
        if( msg.sender != contractOwner) {	
            revert();
        }
        _;
    }

    //建構式，部署合約時設定合約管理者帳戶
    constructor () {
        contractOwner = msg.sender;
    }	

    //查詢合約管理者帳戶
    //[returns]合約管理者帳戶
    function getContractOwner() public view returns(address) {
        return contractOwner;
    }

    //設定合約管理者帳戶
    //[input]_owner：新的合約管理者帳戶
    function setContractOwner(address _owner) public onlyContractOwner {
        contractOwner = _owner;
    }
}

