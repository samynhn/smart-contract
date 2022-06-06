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
import "@openzeppelin/contracts/utils/Strings.sol";

contract FamilyTreeContract{

    address public owner; 
    // uint256 public createID = 0;// 產生ＩＤ
    
    struct Member{
        string treeID;
        string memberID;
        address account;
        string name;
        string birthday;
        string phone;
    }

    string[] idArray;
    address[] addrArray;
    Member[] requestArray;

    constructor(){
        owner = msg.sender; // owner == deployer
    }
    mapping (string=>Member) idToMemMap;  //memberID 對應 member data
    mapping (address=>string[]) addrToIDMap; // 帳號對應 memberID


    modifier onlyOwner(){
        require(owner == msg.sender, "Only owner");
        _;
    }
    modifier onlyLicensee(string memory _memberID){
        require(idToMemMap[_memberID].account == msg.sender, "only licensee");
        _;
    }
    modifier onlyFamily(string memory _memberID){
        uint count=0;
        for (uint256 index=0; index< addrToIDMap[msg.sender].length; index++){
            if(compareStrings(idToMemMap[_memberID].treeID, idToMemMap[addrToIDMap[msg.sender][index]].treeID)){
                count +=1;
            }
        }
        require(count>0, "only licensee"); //msg.sender 底下沒有treeID
        _;
    }
    //帳號需要check isfamily 但是address可以控制多個不同家庭帳號（例如子女幫父母）


    event Approval(address indexed _owner, address indexed _spender, string _memberID);
    event Request(address indexed _owner, string  _memberID, string  _treeID);
    event Reject(address indexed _owner, string  _memberID, string  _treeID);
    event Join(address indexed _owner, string  _memberID, string  _treeID);


    function request(string memory _memberID, string memory _treeID) public onlyLicensee(_memberID){
        requestArray.push(Member({treeID:_treeID, memberID:_memberID, account:msg.sender, name:idToMemMap[_memberID].name, birthday:idToMemMap[_memberID].birthday, phone:idToMemMap[_memberID].phone}));
        emit Request(msg.sender, _memberID, _treeID);
    }
    function getRequestByIndex(uint256 index) public onlyOwner view returns(Member memory){
        return requestArray[index];
    }

    function requestNum()public  view returns( uint){
        return requestArray.length;
    }

    function join(string memory _memberID, string memory _treeID) public onlyOwner{
        idToMemMap[_memberID].treeID = _treeID;
        removeMemberInRequestArryay(_memberID);
        emit Join(msg.sender, _memberID, _treeID);
    }
    function removeMemberInRequestArryay(string memory _memberID) private onlyOwner{
        (bool find, uint256 index) = getRequestArrayIndex(_memberID);
        if(find == true && index >=0){
            if(index > requestArray.length)
                revert("Index Error");

            for(uint256 i=index ; i < requestArray.length-1; i++){
                requestArray[i] = requestArray[i+1];
            }
            requestArray.pop();
        }
    }
    function getRequestArrayIndex(string memory _memberID)view private returns(bool, uint256){
        for (uint256 i=0; i< requestArray.length; i++){ // use bool not -1 because uint256 no include -1 it must use int but num(int) == num(uint/2)
            if(compareStrings(requestArray[i].memberID, _memberID))
                return(true, i);
        }
        return(false, 0);
    }

    function reject(string memory _memberID, string memory _treeID) public onlyOwner{
        emit Reject(msg.sender, _memberID, _treeID);
    }

    
     

//###########################

    function isRegister(string memory _memberID)public view returns (bool){
        for(uint256 i=0 ; i < idArray.length; i++){
            if(compareStrings(idArray[i], _memberID)){
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
        // return total;
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

    function create(string memory _memberID, string memory _name, string memory _birthday, string memory _phone) public returns(string memory ){ // string need memory , address(calldata) no need memory
        // createID += 1;
        // string memory _memberID = Strings.toString(createID);
        require(isRegister(_memberID)==false, "Member has been registered.");
        // address account = msg.sender;
        idToMemMap[_memberID] = Member({treeID:"", memberID:_memberID, account:msg.sender, name:_name, birthday:_birthday, phone:_phone}); // default treeId = ""
        addrToIDMap[msg.sender].push(_memberID);// one address can control multiple member
        idArray.push(_memberID); // push id to idArray

        (bool find_addr,) = getIndexByAddr(msg.sender);
        if(find_addr){ // if addr had registered others member before
        }else{
            addrArray.push(msg.sender);
        }

        return _memberID;
        
    }
    
    function update(string memory _memberID, string memory _name, string memory _birthday, string memory _phone) public onlyLicensee(_memberID)  {
        require(isRegister(_memberID) == true, "Member hasn't been registered.");
        idToMemMap[_memberID] = Member({treeID:idToMemMap[_memberID].treeID, memberID:idToMemMap[_memberID].memberID, account:idToMemMap[_memberID].account, name:_name, birthday:_birthday, phone:_phone});
    }

    //非祖譜成員 查詢功能(應該用姓名查詢)
    function selectById(string memory _memberID)public view returns(string memory treeID, string memory memberID, string memory name, string memory birthday){
        require(isRegister(_memberID) == true, "Member hasn't been registered.");
        return (idToMemMap[_memberID].treeID, idToMemMap[_memberID].memberID, idToMemMap[_memberID].name, idToMemMap[_memberID].birthday);
    }

    //祖譜成員 查詢功能
    function selectByIdForFamily(string memory _memberID)public onlyFamily(_memberID) view returns(string memory treeID, string memory memberID, string memory name, address account, string memory birthday, string memory phone){
        require(isRegister(_memberID) == true, "Member hasn't been registered.");
        return (idToMemMap[_memberID].treeID, idToMemMap[_memberID].memberID, idToMemMap[_memberID].name, idToMemMap[_memberID].account, idToMemMap[_memberID].birthday, idToMemMap[_memberID].phone);
    }

    function selectByLicense(string memory _memberID)public onlyLicensee(_memberID) view returns(string memory treeID,string memory memberID, string memory name, address account, string memory birthday, string memory phone){
        require(isRegister(_memberID) == true, "Member hasn't been registered.");
        return (idToMemMap[_memberID].treeID, idToMemMap[_memberID].memberID, idToMemMap[_memberID].name, idToMemMap[_memberID].account, idToMemMap[_memberID].birthday, idToMemMap[_memberID].phone);
    }
    
    function getmemberID()public view returns(string [] memory ){
        return addrToIDMap[msg.sender];//雜湊值會連在一起
    }

    function approve(string memory _memberID, address _to)public onlyLicensee(_memberID){
        require(_to == address(_to), "invild address");
        require(msg.sender != _to, "same address"); // avoid same address approving
        idToMemMap[_memberID] = Member({treeID:idToMemMap[_memberID].treeID, memberID:_memberID, account:_to, name:idToMemMap[_memberID].name, birthday:idToMemMap[_memberID].birthday, phone:idToMemMap[_memberID].phone});
        //新增事件
        emit Approval(msg.sender, _to, _memberID);
    }

    function destory(string memory _memberID) public onlyLicensee(_memberID){
        require(isRegister(_memberID) == true, "Member hasn't been registered.");
        (bool find, uint256 index) = getIndexById(_memberID);
        (bool find_addr, uint256 index_addr) = getIndexByAddr(msg.sender);
        if(find == true && index >=0){
            delete idToMemMap[_memberID]; //delete member in map
            deleteIdByIndex(index); // delete memberID in idArray
        }
        if(find_addr==true && index_addr>=0){
            deleteIDinAddrToIDMap(_memberID); // delete member in member[] of map
            if(numOfLicense(addrArray[index_addr])==0){
                deleteAddrByIndex(index_addr); // delete addr in addrArray (when addr->otherMember, addr cant be delete)
            }       
        }
    }
    function deleteIDinAddrToIDMap(string memory _memberID) private {
        for (uint256 index=0; index< addrToIDMap[msg.sender].length; index++){ // use bool not -1 because uint256 no include -1 it must use int but num(int) == num(uint/2)
            if(compareStrings(addrToIDMap[msg.sender][index], _memberID))// if found do Remove()
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
        for (uint256 i=0; i< idArray.length; i++){ // use bool not -1 because uint256 no include -1 it must use int but num(int) == num(uint/2)
            if(compareStrings(idArray[i], _memberID))
                return (true, i);
        }
        return (false, 0);
    }

    function compareStrings(string memory a, string memory b) private pure returns (bool) {
        return (keccak256(abi.encodePacked(a)) == keccak256(abi.encodePacked(b))); //雜湊
    }

//###########################

}