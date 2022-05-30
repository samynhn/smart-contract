// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

import "./ContractOwner.sol";
import "./ERC165.sol";
import "./IERC721.sol";

contract ERC721 is ContractOwner, ERC165, IERC721, IERC721Metadata, IERC721Enumerable{
    
    bytes4 private constant INTERFACE_ID_ERC721 = 0x80ac58cd;   //IERC721介面的interface ID
    bytes4 private constant INTERFACE_ID_ERC721_METADATA = 0x5b5e139f;   //IERC721Metadata介面的interface ID
    bytes4 private constant INTERFACE_ID_ERC721_ENUMERABLE = 0x780e9d63;    //IERC721Enumerable介面的interface ID
    bytes4 private constant INTERFACE_ID_ERC721_RECEIVED = 0x150b7a02; //IERC721TokenReceiver介面的interfaceID

    string private tokenName;    //代幣的名稱
    string private tokenSymbol;    //代幣的代稱
    
    uint256[] tokens;   //token陣列，記錄發行的Token ID
    uint256 maxTokenID;   //最大的TokenID
    mapping (uint256 => address) private tokenOwner;  //每個代幣的持有者，Token ID => 持有者帳戶
    mapping (address => uint256[]) private ownerTokens;  //每個持有者的代幣，持有者帳戶 => Token ID
    mapping (uint256 => string) private tokenURIs;  //每個代幣的資源URI，Token ID => 資源URI
    mapping (uint256 => address) private tokenOperator;    //每個代幣的操作者，Token ID => 操作者帳戶
    mapping (address => mapping (address => bool)) private ownerOperatorApproval;   //持有者的操作者的操作權限，持有者帳戶 => 操作者帳戶 => 權限

    //建構式，部署合約時設定代幣名稱及簡稱
    //[input]_name：代幣的名稱
    //[input]_symbol：代幣的代稱
    constructor (string memory _name, string memory _symbol) {
        tokenName = _name;                  //設定代幣的名稱
        tokenSymbol = _symbol;              //設定代幣的代稱

        //依據ERC165註冊本合約支援的ERC721相關介面
        registerInterface(INTERFACE_ID_ERC721);
        registerInterface(INTERFACE_ID_ERC721_METADATA);
        registerInterface(INTERFACE_ID_ERC721_ENUMERABLE);
    }	

    //查詢代幣的名稱
    //[returns]代幣的名稱
    function name() external view returns (string memory){
         return tokenName;
    }

    //查詢代幣的代稱
    //[returns]代幣的代稱
    function symbol() external view returns (string memory){
        return tokenSymbol;
    }

    //查詢代幣的資源URI
    //[input]_tokenID：Token id
    //[returns]：Token的資源URI
    function tokenURI(uint256 _tokenID) external view returns (string memory){      
        return tokenURIs[_tokenID];
    }

    //查詢代幣的總發行量
    //[returns]總發行量
    function totalSupply() external view returns (uint256){
        return tokens.length;
    }

    //依據帳戶及索引值查詢代幣ID，與balanceOf一起使用來列舉指定帳戶所有的代幣ID
    //[input]_owner：持有者帳戶
    //[input]_index：索引值
    //[returns]Token ID
    function tokenOfOwnerByIndex(address _owner, uint256 _index) external view returns (uint256){
        return ownerTokens[_owner][_index];
    }

    //依據索引值查詢Token ID
    //[input]_index：索引值
    //[returns]Token ID
    function tokenByIndex(uint256 _index) external view returns (uint256){
        return tokens[_index];
    }

    //查詢持有者帳戶持有的Token數量
    //[input]_owner：持有者帳戶
    //[returns]持有者的Token數量
    function balanceOf(address _owner) external view returns (uint256){
        return ownerTokens[_owner].length;
    }

    //查詢Token的持有者帳戶
    //[input]_tokenID：Token ID
    //[returns]持有者帳戶
    function ownerOf(uint256 _tokenID) external view returns (address){
        return tokenOwner[_tokenID];
    }

    //安全的將指定的Token從來源帳戶轉移給目的帳戶。發出Transfer事件
    //[input]_from：來源帳戶，不可以是0，並且必須是_tokenID的持有者或操作者
    //[input]_to：目的帳戶，不可以是0。若是CA合約帳戶，則該合約必須實做IERC721TokenReceiver-onERC721Received介面
    //[input]_tokenID：Token ID，必須存在，並且是來源帳戶持有的Token或操作者可操作的Token
    //[input]_data：附加的參數
    function safeTransferFrom(address _from, address _to, uint256 _tokenID) external payable{
        transfer( _from, _to, _tokenID, '');
    }

    function safeTransferFrom(address _from, address _to, uint256 _tokenID, bytes memory _data) external payable{
        transfer( _from, _to, _tokenID, _data);
    }

    function transfer(address _from, address _to, uint256 _tokenID, bytes memory _data) internal {        
        address owner  = tokenOwner[_tokenID];  //取得代幣的持有者

        require( _to != address(0), "Transfer to the zero address");  //目的帳戶不可為0
        require( owner == _from, "Token does not belong to the account");    //_tokenID必須屬於_from帳戶     
        require( isOwnerOrOperator(msg.sender, _tokenID) == true, "Transfer caller is not owner nor approved"); //執行者必須有權限

        tokenOperator[_tokenID] = address(0);   //清除代幣的操作者
        uintArrayRemoveData(ownerTokens[_from], _tokenID); //_from帳戶刪除代幣      
        ownerTokens[_to].push(_tokenID); //目的帳戶增加代幣
        tokenOwner[_tokenID] = _to; //設定代幣的持有者
        
        //檢查to是否為合約帳戶
        if (isContract(_to)){
            //呼叫執行合約帳戶的onERC721Received函數，並檢查回傳值
            IERC721TokenReceiver receiver = IERC721TokenReceiver(_to);
            require(receiver.onERC721Received(msg.sender,_from,_tokenID,_data) == INTERFACE_ID_ERC721_RECEIVED, "Transfer to non ERC721Receiver implementer");
        }               

        emit Transfer( _from, _to, _tokenID);       //發出Transfer事件
    }

    function uintArrayRemoveData( uint256[] storage _array, uint256 _data) internal{
        uint256 length = _array.length;
        for(uint256 i = 0; i< length-1; i++) {
            if( _array[i] == _data){
                _array[i] = _array[length-1];
                break;
            }
        }
        _array.pop();
    }

    //檢查輸入的帳戶是否有權限可轉帳代幣
    //[input]_spender：使用者帳戶
    //[input]_tokenID：Token ID
    //[returns]true是 / false否
    function isOwnerOrOperator(address _spender, uint256 _tokenID) internal view returns (bool) {
        address owner  = tokenOwner[_tokenID];  //取得代幣的持有者
        if (_spender == owner                                   //使用者為代幣的持有者
        || _spender == tokenOperator[_tokenID]                  //使用者為代幣的操作者
        || ownerOperatorApproval[owner][_spender] == true)      //使用者有代幣持有者全權操作的權限
            return true;
        else
            return false;
    }

    //查詢輸入的帳戶是否為合約帳戶
    //[input]_account：使用者帳戶
    //[returns]true是 / false否
    function isContract(address _account) internal view returns (bool) {
        //執行extcodesize取得byte code的大小，若為0，則account為EOA，若不為0，則account為CA
        uint256 size;
        //Solidity Assembly內聯匯編
        assembly { 
            size := extcodesize(_account) 
        }
        return size > 0;
    }

    //將指定的Token從來源帳戶轉移給目的帳戶，但執行者需自行確認目的帳戶是否有能力接收Token，否則可能永久丟失。發出Transfer事件
    //不建議使用此函式，應該盡可能使用safeTransferFrom函式
    //[input]_from：來源帳戶，不可以是0，並且必須是_tokenID的持有者或操作者
    //[input]_to：目的帳戶，不可以是0。若是CA合約帳戶，則該合約必須實做IERC721TokenReceiver-onERC721Received介面
    //[input]_tokenID：Token ID，必須存在，並且是來源帳戶持有的Token或操作者可操作的Token
    function transferFrom(address _from, address _to, uint256 _tokenID) external payable{
        transfer( _from, _to, _tokenID, '');
    }

    //授權Token的操作者，當Token轉移時需清除操作者，一次只能授權一個操作者。發出Approval事件
    //[input]_approved：操作者帳戶，設為0時，表示沒有授權的操作者
    //[input]_tokenID：Token ID，必須存在，並且是執行者持有的Token
    function approve(address _approved, uint256 _tokenID) external payable{
        address owner  = tokenOwner[_tokenID];  //取得代幣的持有者

        require( owner == msg.sender, "Token does not belong to the account");    //_tokenID必須屬於msg.sender帳戶     
        require( owner != _approved, "Approval to current owner");  //持有者與操作者不可相同帳戶

        tokenOperator[_tokenID] = _approved;
        emit Approval( owner, _approved, _tokenID); //發出Approval事件
    }

    //設定啟用或禁用操作者管理所有的Token。發出ApprovalForAll事件
    //[input]_operator：操作者帳戶
    //[input]_approved：true啟用、false禁用
    function setApprovalForAll(address _operator, bool _approved) external{
        require( _operator != address(0), "Operator cannot be 0");  //操作者帳戶不可為0
        require( _operator != msg.sender, "Approve to caller"); //持有者與操作者不可相同帳戶

        ownerOperatorApproval[msg.sender][_operator] = _approved;
        emit ApprovalForAll( msg.sender, _operator, _approved); //發出ApprovalForAll事件
    }

    //查詢代幣的操作者帳戶
    //[input]_tokenID：Token ID，必須存在
    //[returns]操作者帳戶
    function getApproved(uint256 _tokenID) external view returns (address){
        return tokenOperator[_tokenID];
    }

    //查詢代理關係是否存在
    //[input]_owner：持有者帳戶
    //[input]_operator：操作者帳戶
    //[returns]true是、flase否
    function isApprovedForAll(address _owner, address _operator) external view returns (bool){
        return ownerOperatorApproval[_owner][_operator];
    }

    //鑄幣
    //[input]_tokenURI：Token的資源URI
    function mint(string memory _tokenURI) public payable{
        require( msg.value == 0.01 ether, "0.01 ETH");

        maxTokenID += 1;                         //目前最大的TokenID加1
        uint256 newTokenID = maxTokenID;         //取得目前最大的TokenID
        tokens.push(newTokenID);                //增加新的Token ID
        tokenOwner[newTokenID] = msg.sender;     //設定newTokenID的持有者帳戶為執行者    
        ownerTokens[msg.sender].push(newTokenID);
        tokenURIs[newTokenID] = _tokenURI;      //設定newTokenID的URI

        emit Transfer(address(0), msg.sender, newTokenID); //發出Transfer事件，from為0，表示為to帳戶鑄造newTokenID
    }

    //設定tokenID的資源URI
    //[input]_tokenID：Token ID
    //[input]_tokenURI：Token的資源URI
    function setTokenURI(uint256 _tokenID, string memory _tokenURI) public payable{
        require( msg.value == 0.01 ether, "0.01 ETH");

        address owner  = tokenOwner[_tokenID];  //取得代幣的持有者
        require( owner == msg.sender, "Token does not belong to the account"); 
        tokenURIs[_tokenID] = _tokenURI;
    }

    //燒幣
    //[input]_tokenID：Token ID
    function burn(uint256 _tokenID) public{
        address owner  = tokenOwner[_tokenID];  //取得代幣的持有者
        require( owner == msg.sender, "Token does not belong to the account"); 

        delete tokenOperator[_tokenID];   //清除代幣的操作者
        delete tokenURIs[_tokenID];       //清除tokenId的URI
        uintArrayRemoveData(tokens, _tokenID); //從tokens刪除代幣    
        uintArrayRemoveData(ownerTokens[owner], _tokenID); //從owner帳戶刪除代幣
        delete tokenOwner[_tokenID];  //刪除代幣的持有者

        emit Transfer(owner, address(0), _tokenID);  //發出Transfer事件，to為0, 表示owner帳戶燒毀tokenId
    }

    //查詢合約持有的以太幣餘額
    //[returns]_tokenURI：Token的資源URI
    function getContractBalance() public view returns(uint256){
        return address(this).balance;
    }

    //將指定數量的合約的ETH轉帳至指定的帳戶
    //[input]_to：目的帳戶
    //[input]_value：以太幣數量（單位為wei)
    function transferContractBalance(address payable _to, uint256 _value) public onlyContractOwner{
        _to.transfer(_value);
    }
}

