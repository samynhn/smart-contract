pragma solidity 0.4.24;

contract ERC20TokenContract{

    address owner;

    // string name="ERC20TokenContract";//寫死name
    //寫public varible 就不用寫name func去return值
    string public name;
    string public symbol;
    uint8 public decimals = 0; //不需用到uint256
    uint256 public totalSupply;
    uint256 public volumn = 0;
    bool public isLimited = false;//帳號購買限制
    uint8 public limit = 0;
    bool public isMintLocked = true; //開啟/關閉購買功能
    uint256 private price = 5 * 1 ether; //wei
    mapping(address=>uint256) balances;
    mapping(address=>mapping(address=>uint256)) allowed; //帳戶address=>(代理人address=>可動用token數量):缺點 代理人帳號只能有一個

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);


    modifier onlyOwner(){
        require(owner == msg.sender, "Only owner");
        _;
    }


    
// 將合約以太幣轉給owner(未寫) or owner 可以將合約帳號eth轉給其他帳號
//  一個帳號只能買一次（未寫）
    function() public payable{
        require(isMintLocked == false, "Mint locked");
        require(price > 0, "Price error");
        require(msg.value >= price, "Fund shortage");
        require(totalSupply*price >= msg.value, "Exceed totalSupply");
         // 確保輸入正確金額範圍

        uint256 num = 0;
        for(; msg.value >= (num+1) * price; num++){
        }// 計算購買數量

        if(isLimited){
            require(balances[msg.sender]+num > balances[msg.sender], "Overflow");
            require(balances[msg.sender]+num <= limit, "Exceed limit");
        }//購買量不能超過限制

        uint256 change = msg.value - num*price;
        msg.sender.transfer(change);//找零
            
        totalSupply -= num; // totalSupply ＝ 合約剩的token
        balances[msg.sender] += num;
        volumn += num;
        
    }

    constructor(string _name, string _symbol, uint _totalSupply) public {
        owner = msg.sender;
        name = _name; // 部署時在決定名稱：可以每次部署不同合約 輸入不同值
        symbol = _symbol;
        totalSupply = _totalSupply;
    }
    
    // function name() public view returns (string){
    //     return name;
    // }
    //代稱
    // function symbol() public view returns (string){

    // }
    // function decimals() public view returns (uint8){

    // }
    // function totalSupply() public view returns (uint256){

    // }
    function setMintLocked(bool state) public onlyOwner returns (bool ){
        require(isMintLocked != state, "same state");
        isMintLocked = state;
        return isLimited;
    }
    // function setLimit(bool state, uint8 _limit) public onlyOwner returns (bool ){
    //     require(isLimited != state, "same state");
    //     isLimited = state;
    //     // set isLimited 
    //     if(state){
    //         limit = _limit;
    //     }else{
    //         limit = 0;
    //     }
    //     return isLimited;
    // }
    
    function setLimit(uint8 _limit) public onlyOwner returns (bool ){
        // require(isLimited != state, "same state");
        limit = _limit;
        if(_limit==0){
            isLimited = false;
        }else{
            isLimited = true;
        }
        return isLimited;
        
    }
    
    function getPrice() public view returns (uint256 eth){
        return price/ 1 ether;
    }
    function getContractBalance() public view onlyOwner returns (uint eth){
        return address(this).balance / 1 ether;
    }
    
    function withdraw() public onlyOwner returns (bool success){
        uint256 balance = address(this).balance;// get contract balance

        //check balance > 0 && overflow
        if(owner.balance + balance > owner.balance){
            owner.transfer(balance);// 將合約eth轉移到owner帳號
            return true;
        }else{
            revert();
            // return false;
        }
      
        
    }
    // 查看帳戶餘額 : ues mapping (address-> balance) 
    function balanceOf(address _owner) public view returns (uint256 balance){
        require(_owner == address(_owner), "invild address");
        return balances[_owner]; //_owner 是 input name
        //balance = balances[_owner];// func 已經寫return name 和 格式＝>不寫return
    }

    
    function transfer(address _to, uint256 _value) public returns (bool success){
        //check 轉出帳戶是否合法(未寫)
        require(_to == address(_to), "invild address");
        if(_value>0 
            && balances[msg.sender] >= _value 
            && balances[_to]+_value > balances[_to]){
            //1.轉帳金額>0 2.轉出帳戶餘額>轉帳金額 3.檢查轉入帳戶是否overflow
                balances[msg.sender] -= _value;//caller 給錢
                balances[_to] += _value;//receiver 收錢
                volumn += _value;
                //transfer 需要發出事件
                emit Transfer(msg.sender, _to, _value);
                return true;
        }else{
            revert();
        }
        
        return false;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success){
        require(_from == address(_from), "invild address");
        require(_to == address(_to), "invild address");
        if(_value>0 && 
            balances[_from] >= _value && 
            allowed[_from][msg.sender]>=_value&&
            balances[_to]+_value > balances[_to]){
            //1.轉帳金額>0 2.轉出帳戶餘額>轉帳金額 3.代理人可以操作的數量要夠多 4.檢查轉入帳戶是否overflow    
                balances[_from] -= _value;//caller 給錢
                allowed[_from][msg.sender] -= _value; // 代理人可以操作的數量減少
                balances[_to] += _value;//receiver 收錢
                volumn += _value;
                //transfer 需要發出事件
                emit Transfer(_from, _to, _value);
                return true;
            }
        return false;
        //沒有reuqire assert 所以不論是否成功皆要付gasfee
        

    }

    //代理人
    function approve(address _spender, uint256 _value) public returns (bool success){
        require(_spender == address(_spender), "invild address");
        require(msg.sender != _spender, "same address"); // avoid same address approving

        allowed[msg.sender][_spender] = _value;
        //approve 需要發出事件
        emit Approval(msg.sender, _spender, _value);
        return true;

    }

    //代理address還剩多少錢可以動用
    function allowance(address _owner, address _spender) public view returns (uint256 remaining){
        
        return allowed[_owner][_spender];
    }

}