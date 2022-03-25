// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

contract AddressBook {
    // address owner; // set owner by adress id default: private
    address public owner; 

    struct Student {
        address account;
        string phone;
        string email;
    }

    string[] idArray;
    mapping (string=>Student) studentMap; //學號對應到student結構


    modifier onlyOwner(){
        require(owner == msg.sender, "Only owner");
        _;
    }

    // method 1
    // constructor (address initOwner)  { // deploy with owner's address
    //     owner = initOwner;
    // }

    //method 1
    constructor(){
        owner = msg.sender; // 設定執行deploy者即為owner
    }
    // function getOwner() public view returns(address){
    //     return owner;
    // }
     function getOwner() public view returns(address currentOwner) { // getOwner 跟 setOwner分開寫 因為部署上鍊並非即時
        currentOwner = owner;
    }

    function setOwner(address newOwner) public onlyOwner{ // it can be set only by owner
        owner = newOwner;
    }

    function getTotal()public view returns(uint256 idArrayLength){
        return idArray.length;
    }

    //create
    function create(string memory _id, address  _account, string memory _phone, string memory _email) public onlyOwner{ // string need memory , address(calldata) no need memory
        require(_account == address(_account), "invild address");
        require(studentMap[_id].account == address(0), "ID already exists"); // check if exist
        studentMap[_id] = Student({account:_account, phone:_phone, email:_email}); // 強制轉型成student結構
        idArray.push(_id); // push id to idArray
    }

    //select
    function selectById(string memory _id)public view returns(address  _account, string memory _phone, string memory _email){
        return (studentMap[_id].account, studentMap[_id].phone, studentMap[_id].email);
    }

    //update
    function update(string memory _id, address  _account, string memory _phone, string memory _email) public onlyOwner{ // string need memory , address(calldata) no need memory
        require(_account == address(_account), "null address");
        require(studentMap[_id].account != address(0), "ID already exists"); // check if exist
        studentMap[_id] = Student({account:_account, phone:_phone, email:_email}); // 強制轉型成student結構
    }

    //delete
    function destory(string memory _id) public onlyOwner{ // delete 是關鍵字
        (bool find, uint256 index) = getIndexById(_id);
        if(find == true && index >=0){
            delete studentMap[_id];
            deleteIdByIndex(index);
        }
    }
    //
    function deleteIdByIndex(uint256 index) private {
        if(index > idArray.length)
        revert("Index Error");

        for(uint256 i=index ; i < idArray.length-1; i++){
            idArray[i] = idArray[i+1];
        }
        idArray.pop();
    }
    
    // get index by id
    function getIndexById(string memory _id) private view returns (bool find, uint256 index){ //private or internal
        for (uint256 i=0; i< idArray.length; i++){ // use bool not -1 because uint256 no include -1 must use int but num(int) == num(uint/2)
            if(compareStrings (idArray[i], _id) == true)
                return (true, 1);
        }
        return (false, 0);
    }

    function compareStrings(string memory a, string memory b) private pure returns (bool) {
        return (keccak256(abi.encodePacked(a)) == keccak256(abi.encodePacked(b))); //雜湊
    }
}
// student can change his data
// parameter : your id, to change yourself data