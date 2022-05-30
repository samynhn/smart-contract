// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

//ERC-721 NFT標準
//bytes4(keccak256('balanceOf(address)')) = 0x70a08231
//bytes4(keccak256('ownerOf(uint256)')) = 0x6352211e
//bytes4(keccak256('approve(address,uint256)')) = 0x095ea7b3
//bytes4(keccak256('getApproved(uint256)')) = 0x081812fc
//bytes4(keccak256('setApprovalForAll(address,bool)')) = 0xa22cb465
//bytes4(keccak256('isApprovedForAll(address,address)')) = 0xe985e9c5
//bytes4(keccak256('transferFrom(address,address,uint256)')) = 0x23b872dd
//bytes4(keccak256('safeTransferFrom(address,address,uint256)')) = 0x42842e0e
//bytes4(keccak256('safeTransferFrom(address,address,uint256,bytes)')) = 0xb88d4fde
//0x70a08231 ^ 0x6352211e ^ 0x095ea7b3 ^ 0x081812fc ^ 0xa22cb465 ^ 0xe985e9c5 ^ 0x23b872dd ^ 0x42842e0e ^ 0xb88d4fde = 0x80ac58cd
//此介面的ERC-165標準為0x80ac58cd
interface IERC721 {
    //當Token轉移時發出的事件，包含建立和銷毀的時候，但不包含合約建立的時候
    //_from：來源帳戶
    //_to：目的帳戶
    //_tokenID：Token ID
    event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenID);

    //當Token設定操作者時發出的事件，發生Transfer事件時，表示該tokenId的操作者重置為0
    //_owner：持有者帳戶
    //_approved：操作者帳戶，0表示沒有授權的操作者
    //_tokenID：Token ID
    event Approval(address indexed _owner, address indexed _approved, uint256 indexed _tokenID);

    //當啟用或禁用操作者時發出的事件
    //_owner：持有者帳戶
    //_operator：操作者帳戶
    //_approved：true啟用、false禁用
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

    //查詢持有者帳戶持有的Token數量
    //[input]_owner：持有者帳戶
    //[returns]持有者的Token數量
    function balanceOf(address _owner) external view returns (uint256);

    //查詢Token的持有者帳戶
    //[input]_tokenID：Token ID
    //[returns]持有者帳戶
    function ownerOf(uint256 _tokenID) external view returns (address);

    //安全的將指定的Token從來源帳戶轉移給目的帳戶。發出Transfer事件
    //[input]_from：來源帳戶，不可以是0，並且必須是_tokenID的持有者或操作者
    //[input]_to：目的帳戶，不可以是0。若是CA合約帳戶，則該合約必須實做IERC721TokenReceiver-onERC721Received介面
    //[input]_tokenID：Token ID，必須存在，並且是來源帳戶持有的Token或操作者可操作的Token
    //[input]_data：附加的參數
    function safeTransferFrom(address _from, address _to, uint256 _tokenID, bytes memory _data) external payable;
    function safeTransferFrom(address _from, address _to, uint256 _tokenID) external payable;

    //將指定的Token從來源帳戶轉移給目的帳戶，但執行者需自行確認目的帳戶是否有能力接收Token，否則可能永久丟失。發出Transfer事件
    //不建議使用此函式，應該盡可能使用safeTransferFrom函式
    //[input]_from：來源帳戶，不可以是0，並且必須是_tokenID的持有者或操作者
    //[input]_to：目的帳戶，不可以是0。若是CA合約帳戶，則該合約必須實做IERC721TokenReceiver-onERC721Received介面
    //[input]_tokenID：Token ID，必須存在，並且是來源帳戶持有的Token或操作者可操作的Token
    function transferFrom(address _from, address _to, uint256 _tokenID) external payable;

    //授權Token的操作者，當Token轉移時需清除操作者，一次只能授權一個操作者。發出Approval事件
    //[input]_approved：操作者帳戶，設為0時，表示沒有授權的操作者
    //[input]_tokenID：Token ID，必須存在，並且是執行者持有的Token
    function approve(address _approved, uint256 _tokenID) external payable;

    //設定啟用或禁用操作者管理所有的Token。發出ApprovalForAll事件
    //[input]_operator：操作者帳戶
    //[input]_approved：true啟用、false禁用
    function setApprovalForAll(address _operator, bool _approved) external;

    //查詢代幣的操作者帳戶
    //[input]_tokenID：Token ID，必須存在
    //[returns]操作者帳戶
    function getApproved(uint256 _tokenID) external view returns (address);

    //查詢代理關係是否存在
    //[input]_owner：持有者帳戶
    //[input]_operator：操作者帳戶
    //[returns]true是、flase否
    function isApprovedForAll(address _owner, address _operator) external view returns (bool);
}

//IERC721Metadata介面
//bytes4(keccak256('name()')) = 0x06fdde03
//bytes4(keccak256('symbol()')) = 0x95d89b41
//bytes4(keccak256('tokenURI(uint256)')) = 0xc87b56dd
//0x06fdde03 ^ 0x95d89b41 ^ 0xc87b56dd = 0x5b5e139f
//此介面的ERC-165標準為0x5b5e139f
interface IERC721Metadata {
    //查詢代幣的名稱
    //[returns]代幣的名稱
    function name() external view returns (string memory);

    //查詢代幣的代稱
    //[returns]代幣的代稱
    function symbol() external view returns (string memory);

    //查詢代幣的資源URI
    //[input]_tokenID：Token id
    //[returns]：Token的資源URI
    function tokenURI(uint256 _tokenID) external view returns (string memory);
}

//IERC721Enumerable介面
//bytes4(keccak256('totalSupply()')) = 0x18160ddd
//bytes4(keccak256('tokenOfOwnerByIndex(address,uint256)')) = 0x2f745c59
//bytes4(keccak256('tokenByIndex(uint256)')) = 0x4f6ccce7
//0x18160ddd ^ 0x2f745c59 ^ 0x4f6ccce7 = 0x780e9d63
//此介面的ERC-165標準為0x780e9d63
interface IERC721Enumerable {
    //查詢代幣的總發行量
    //[returns]總發行量
    function totalSupply() external view returns (uint256);

    //依據帳戶及索引值查詢代幣ID，與balanceOf一起使用來列舉指定帳戶所有的代幣ID
    //[input]_owner：持有者帳戶
    //[input]_index：索引值
    //[returns]Token ID
    function tokenOfOwnerByIndex(address _owner, uint256 _index) external view returns (uint256);

    //依據索引值查詢Token ID
    //[input]_index：索引值
    //[returns]Token ID
    function tokenByIndex(uint256 _index) external view returns (uint256);
}

//IERC721TokenReceiver介面
//bytes4(keccak256('onERC721Received(address,address,uint256,bytes)') = 0x150b7a02
//此介面的ERC-165標準為0x150b7a02
interface IERC721TokenReceiver {
    //收到NFT時的處理函式，可能會對交易revert或reject 
    //[input]_operator：執行safeTransferFrom函式的執行者帳戶
    //[input]_from：持有者帳戶
    //[input]_tokenID：Token id
    //[input]_data：沒有指定格式的附加資料
    //[returns]ERC-165介面標準，bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))
    function onERC721Received(address _operator, address _from, uint256 _tokenID, bytes memory _data) external returns(bytes4);
}

