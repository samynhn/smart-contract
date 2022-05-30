// SPDX-License-Identifier: MIT
// Made by SHAWN!
pragma solidity 0.8.13;

contract FamilyTreeContract{

    address public owner; 

    struct Member{
        string treeId;
        bytes32 hashId;
        address account;
        string name;
        string birthday;
        string phone;
    }


    bytes32[] idArray;
    address[] addrArray;
   
    constructor(){
        owner = msg.sender; // owner == deployer
    }
    mapping (bytes32=>Member) memberMap;
    mapping (address=>bytes32[]) idMap;
    modifier onlyOwner(){
        require(owner == msg.sender, "Only owner");
        _;
    }
    modifier onlyLicensee(string memory _memberId){
        require(memberMap[keccak256(abi.encodePacked(_memberId))].account == msg.sender, "only licensee");
        _;
    }
    // modifier onlyFamily(string memory _treeId){
    //     require(memberMap[_memberId].treeId == msg.sender., "only licensee"); //msg.sender 底下沒有treeId
    //     _;
    // }

    //create
    function create(string memory _treeId, string memory _memberId, string memory _name, string memory _birthday, string memory _phone) public { // string need memory , address(calldata) no need memory
        bytes32 _hashId = keccak256(abi.encodePacked(_memberId));
        memberMap[_hashId] = Member({treeId:_treeId, hashId:_hashId, account:msg.sender, name:_name, birthday:_birthday, phone:_phone}); // 強制轉型成student structure
        idMap[msg.sender].push(_hashId);// address 可以管理多個帳號
        idArray.push(_hashId); // push id to idArray
    }
    //update function 還要確定id能不能改 (可能加入祖譜後就不能改)
    function update(string memory _memberId, string memory _name, string memory _birthday, string memory _phone) public onlyLicensee(_memberId)  {
        //id加入祖譜後就不能改
        bytes32 _hashId = keccak256(abi.encodePacked(_memberId));
        memberMap[_hashId] = Member({treeId:memberMap[_hashId].treeId, hashId:_hashId, account:memberMap[_hashId].account, name:_name, birthday:_birthday, phone:_phone});
    }
    
        //因為要更改資料一定要和合約互動, 所以一定有帳號
        //think: 新增一個node(member)不會push contrast to blockchain (thus, not owner)
        //only owner 可以當作審核機制 藉由owner 執行需審核的作為
        //密碼不需要了 由address設定 因為
    //祖譜成員 查詢功能
    function selectByIdForMembers(string memory _memberId)public  view returns(bytes32 hashId, string memory name, address account, string memory birthday, string memory phone){
        bytes32 _hashId = keccak256(abi.encodePacked(_memberId));
        //確認密碼正確
        //require(keccak256(abi.encodePacked(_passward)) == keccak256(abi.encodePacked(memberMap[_memberId].passward)), "deny access !");
        return (memberMap[_hashId].hashId, memberMap[_hashId].name, memberMap[_hashId].account, memberMap[_hashId].birthday, memberMap[_hashId].phone);
    }

    function selectByLicense(string memory _memberId)public onlyLicensee(_memberId) view returns(bytes32 hashId, string memory name, address account, string memory birthday, string memory phone){
        bytes32 _hashId = keccak256(abi.encodePacked(_memberId));
        return (memberMap[_hashId].hashId, memberMap[_hashId].name, memberMap[_hashId].account, memberMap[_hashId].birthday, memberMap[_hashId].phone);
    }
    
    //非祖譜成員 查詢功能(應該用姓名查詢)
    function selectById(string memory _memberId)public view returns(bytes32 hashId, string memory name, string memory birthday){
        bytes32 _hashId = keccak256(abi.encodePacked(_memberId));
        return (memberMap[_hashId].hashId, memberMap[_hashId].name, memberMap[_hashId].birthday);
    }

    function getHashId()public view returns(bytes32 [] memory ){
        return idMap[msg.sender];//雜湊值會連在一起
    }

    function numOfLicense()public view returns(uint256){
        return idMap[msg.sender].length;
    }

    function approve(string memory _memberId, address to)public onlyLicensee(_memberId){
        bytes32 _hashId = keccak256(abi.encodePacked(_memberId));
        memberMap[_hashId] = Member({treeId:memberMap[_hashId].treeId, hashId:_hashId, account:to, name:memberMap[_hashId].name, birthday:memberMap[_hashId].birthday, phone:memberMap[_hashId].phone});
    //新增事件
    }

    // function destory(string memory _memberId) public onlyLicensee(_memberId){ // delete is keyword
    //     (bool find, uint256 index) = getIndexById(_id);
    //     if(find == true && index >=0){
    //         delete studentMap[_id];
    //         deleteIdByIndex(index);
    //     }
    // }
    // //
    // function deleteIdByIndex(uint256 index) private {
    //     if(index > idArray.length)
    //     revert("Index Error");

    //     for(uint256 i=index ; i < idArray.length-1; i++){
    //         idArray[i] = idArray[i+1];
    //     }
    //     idArray.pop();
    // }
}