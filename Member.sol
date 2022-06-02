// SPDX-License-Identifier: MIT
// Made by SHAWN!

        //update function 還要確定id能不能改 (可能加入祖譜後就不能改)
        //id加入祖譜後就不能改
        //因為要更改資料一定要和合約互動, 所以一定有帳號
        //think: 新增一個node(member)不會push contrast to blockchain (thus, not owner)
        //only owner 可以當作審核機制 藉由owner 執行需審核的作為
        //tree id 需要嗎 用tree 連接hasID 更：treeID 可用於查詢一個人屬於哪個tree
        //密碼不需要了 由address設定 因為 查詢功能都必須透過metamask
pragma solidity 0.8.13;

contract FamilyTreeContract{

    address public owner; 

    struct Member{
        string treeID;
        bytes32 hashID;
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
    mapping (bytes32=>Member) idToMemMap;  //hashID 對應 member data
    mapping (address=>bytes32[]) addrToIDMap; // 帳號對應 hashID


    modifier onlyOwner(){
        require(owner == msg.sender, "Only owner");
        _;
    }
    modifier onlyLicensee(string memory _memberID){
        require(idToMemMap[keccak256(abi.encodePacked(_memberID))].account == msg.sender, "only licensee");
        _;
    }
    // modifier onlyFamily(string memory _treeID){
    //     require(idToMemMap[_memberID].treeID == msg.sender., "only licensee"); //msg.sender 底下沒有treeID
    //     _;
    // }
    //帳號需要check isfamily 但是address可以控制多個不同家庭帳號（例如子女幫父母）


    event Approval(address indexed _owner, address indexed _spender, bytes32 _hashID);
    // event Request(address indexed _owner, address indexed _spender, uint256 _value);
    


    function request(string memory _memberID) public onlyLicensee(_memberID){

    }
//###########################

    function hash(string memory _memberID) private pure returns (bytes32 _hashID) {
        return keccak256(abi.encodePacked(_memberID));
    }

    function isRegister(string memory _memberID)public view returns (bool){
        for(uint256 i=0 ; i < idArray.length; i++){
            if(hash(_memberID)==idArray[i]){
                return true;
            }
        }
        return false;
    }

    function total() public view returns(uint256){
        uint256 num = 0;
        for(uint256 i=0 ; i < idArray.length; i++){
            num++;
        }
        return num;
    }

    function numOfaddr() public view returns(uint256){
        uint256 num = 0;
        for(uint256 i=0 ; i < addrArray.length; i++){
            num++;
        }
        return num;
    }

    function numOfLicense(address addr)public view returns(uint256){
        return addrToIDMap[addr].length;
    }


//###########################

    function create(string memory _memberID, string memory _name, string memory _birthday, string memory _phone) public { // string need memory , address(calldata) no need memory
        require(isRegister(_memberID)==false, "Member has been registered.");
        bytes32 _hashID = hash(_memberID);
        // address account = msg.sender;
        idToMemMap[_hashID] = Member({treeID:"", hashID:_hashID, account:msg.sender, name:_name, birthday:_birthday, phone:_phone}); // default treeId = ""
        addrToIDMap[msg.sender].push(_hashID);// one address can control multiple member
        idArray.push(_hashID); // push id to idArray

        (bool find_addr,) = getIndexByAddr(msg.sender);
        if(find_addr){ // if addr had registered others member before
        }else{
            addrArray.push(msg.sender);
        }
        
    }
    
    function update(string memory _memberID, string memory _name, string memory _birthday, string memory _phone) public onlyLicensee(_memberID)  {
        require(isRegister(_memberID) == true, "Member hasn't been registered.");
        bytes32 _hashID = hash(_memberID);
        idToMemMap[_hashID] = Member({treeID:idToMemMap[_hashID].treeID, hashID:_hashID, account:idToMemMap[_hashID].account, name:_name, birthday:_birthday, phone:_phone});
    }

    //非祖譜成員 查詢功能(應該用姓名查詢)
    function selectById(string memory _memberID)public view returns(string memory treeID, bytes32 hashID, string memory name, string memory birthday){
        bytes32 _hashID = hash(_memberID);
        return (idToMemMap[_hashID].treeID, idToMemMap[_hashID].hashID, idToMemMap[_hashID].name, idToMemMap[_hashID].birthday);
    }

    //祖譜成員 查詢功能
    function selectByIdForFamily(string memory _memberID)public  view returns(string memory treeID, bytes32 hashID, string memory name, address account, string memory birthday, string memory phone){
        bytes32 _hashID = hash(_memberID);
        return (idToMemMap[_hashID].treeID, idToMemMap[_hashID].hashID, idToMemMap[_hashID].name, idToMemMap[_hashID].account, idToMemMap[_hashID].birthday, idToMemMap[_hashID].phone);
    }

    function selectByLicense(string memory _memberID)public onlyLicensee(_memberID) view returns(string memory treeID,bytes32 hashID, string memory name, address account, string memory birthday, string memory phone){
        bytes32 _hashID = hash(_memberID);
        return (idToMemMap[_hashID].treeID, idToMemMap[_hashID].hashID, idToMemMap[_hashID].name, idToMemMap[_hashID].account, idToMemMap[_hashID].birthday, idToMemMap[_hashID].phone);
    }
    
    function gethashID()public view returns(bytes32 [] memory ){
        return addrToIDMap[msg.sender];//雜湊值會連在一起
    }

    function approve(string memory _memberID, address to)public onlyLicensee(_memberID){
        bytes32 _hashID = hash(_memberID);
        idToMemMap[_hashID] = Member({treeID:idToMemMap[_hashID].treeID, hashID:_hashID, account:to, name:idToMemMap[_hashID].name, birthday:idToMemMap[_hashID].birthday, phone:idToMemMap[_hashID].phone});
        //新增事件
        emit Approval(msg.sender, to, _hashID);
    }

    function destory(string memory _memberID) public onlyLicensee(_memberID){
        (bool find, uint256 index) = getIndexById(_memberID);
        (bool find_addr, uint256 index_addr) = getIndexByAddr(msg.sender);
        if(find == true && index >=0){
            delete idToMemMap[hash(_memberID)]; //delete member in map
            deleteIdByIndex(index); // delete hashID in idArray
        }
        if(find_addr==true && index_addr>=0){
            deleteIDinAddrToIDMap(_memberID); // delete member in member[] of map
            if(numOfLicense(addrArray[index_addr])==0){
                deleteAddrByIndex(index_addr); // delete addr in addrArray (when addr->otherMember, addr cant be delete)
            }       
        }
    }
    function deleteIDinAddrToIDMap(string memory _memberID) private {
        bytes32 _hashID = hash(_memberID); 
        for (uint256 index=0; index< addrToIDMap[msg.sender].length; index++){ // use bool not -1 because uint256 no include -1 it must use int but num(int) == num(uint/2)
            if(addrToIDMap[msg.sender][index] == _hashID)// if found do Remove()
                for(uint256 i=index ; i < addrArray.length-1; i++){
                addrToIDMap[msg.sender][i] = addrToIDMap[msg.sender][i+1];
                }
                addrToIDMap[msg.sender].pop();
        }
        

    }
    function deleteAddrByIndex(uint256 index) private {
        // require(numOfLicense(addrArray[index])==0, "There are memberIDs be authorized by the addr");
        if(index > addrArray.length)
            revert("Index Error");
        for(uint256 i=index ; i < addrArray.length-1; i++){
                addrArray[i] = addrArray[i+1];
        }
        addrArray.pop();
        
    }

    function getIndexByAddr(address addr) private view returns (bool find, uint256 index){ //private or internal
        for (uint256 i=0; i< addrArray.length; i++){ // use bool not -1 because uint256 no include -1 it must use int but num(int) == num(uint/2)
            if(addrArray[i] == addr)
                return (true, i);
        }
        return (false, 0);
    }

    function deleteIdByIndex(uint256 index) private {
        if(index > idArray.length)
        revert("Index Error");

        for(uint256 i=index ; i < idArray.length-1; i++){
            idArray[i] = idArray[i+1];
        }
        idArray.pop();
    }

    function getIndexById(string memory _memberID) private view returns (bool find, uint256 index){ //private or internal
        bytes32 _hashID = hash(_memberID); 
        for (uint256 i=0; i< idArray.length; i++){ // use bool not -1 because uint256 no include -1 it must use int but num(int) == num(uint/2)
            if(idArray[i] == _hashID)
                return (true, i);
        }
        return (false, 0);
    }

//###########################

}