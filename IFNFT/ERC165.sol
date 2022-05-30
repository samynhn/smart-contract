// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "./IERC165.sol";

//繼承IERC165介面的ERC165合約
contract ERC165 is IERC165 {
    bytes4 private constant INTERFACE_ID_ERC165 = 0x01ffc9a7;  //bytes4(keccak256('supportsInterface(bytes4)')) == 0x01ffc9a7
    mapping(bytes4 => bool) private supportedInterfaces;   //interfaceID => true支援，false不支援

    //建構式
    constructor () {
        registerInterface(INTERFACE_ID_ERC165);    //註冊對ERC165介面支援的interfaceID
    }

    //實作supportsInterface函式
    //查詢智能合約是否實作了指定的介面
    //[input]interfaceID介面識別碼
    //[returns]若智能合約實現了interfaceID且不為0xffffffff則傳回true，否則傳回false
    function supportsInterface(bytes4 interfaceID) public view virtual override returns (bool) {
        return supportedInterfaces[interfaceID];
    }

    //將合約以interfaceID註冊為該介面的實作者
    //[input]interfaceID介面識別碼，不可以是無效的介面識別碼0xffffffff
    function registerInterface(bytes4 interfaceID) internal virtual {
        require(interfaceID != 0xffffffff, "Invalid interface id");
        supportedInterfaces[interfaceID] = true;
    }
}