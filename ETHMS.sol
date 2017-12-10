pragma solidity ^0.4.13;

contract SafeMath{
  function safeMul(uint a, uint b) pure internal returns (uint) {
    uint c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function safeDiv(uint a, uint b) pure internal returns (uint) {
    assert(b > 0);
    uint c = a / b;
    assert(a == b * c + a % b);
    return c;
  }
    
    function safeSub(uint a, uint b) pure internal returns (uint) {
        assert(b <= a);
        return a - b;
  }

    function safeAdd(uint a, uint b) pure internal returns (uint) {
        uint c = a + b;
        assert(c >= a);
        return c;
  }
}

contract ETHMS is SafeMath {
    
    event Transfer(address indexed _from, address indexed _recipient, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    event Log(string _message, uint256 _value);
    
    string  public name;
    string  public symbol;
    uint    public decimals = 4;
    uint256 public INITIAL_SUPPLY;
    uint256 public price;
    address public owner;
    
    uint256 public totalSupply;
    
    address TAX_FEE_BIG_ADDRESS = 0xc587D94787035B32c6c481e2C5211288f3F45F8c;
    
    // in M percentage: 1000000 = 1%, so below equals to 0.25%
    uint256 TAX_FEE_BIG_AMOUNT = 250000;
    
    // equals to 0.083333%
    uint256 TAX_FEE_SMALL_AMOUNT = 83333;
    
    address TAX_FEE_SMALL_ADDRESS_ONE = 0x44f994297dE6A9F2d9eE7f7befF94802531DF3c2;
    address TAX_FEE_SMALL_ADDRESS_TWO = 0xd1D6f0C93Eb7C2C4a4b8A38b7cD1Da9c81875306;
    address TAX_FEE_SMALL_ADDRESS_THREE = 0xE390fA8e1b30258FEb0A01e9C32e9C56eBF7e786;
    
    mapping(address => uint256) balances;

    function balanceOf(address _owner) public constant returns (uint256 balance) {
        return balances[_owner];
    }

    function transfer(address _to, uint256 _amount) public  returns (bool success){
       
         uint tax1 = _amount * TAX_FEE_BIG_AMOUNT / 100000000;
         uint tax2 = _amount * TAX_FEE_SMALL_AMOUNT / 100000000;
         uint sum = tax1 + (3 * tax2) + _amount;
         
         if (balances[msg.sender] >= sum &&
            _amount > 0 &&
            balances[_to] + _amount > balances[_to])
            {
        balances[msg.sender] = safeSub(balances[msg.sender], sum);
        balances[_to] = safeAdd(balances[_to], _amount);

        balances[TAX_FEE_BIG_ADDRESS] = safeAdd(balances[TAX_FEE_BIG_ADDRESS], tax1);

        balances[TAX_FEE_SMALL_ADDRESS_ONE] = safeAdd(balances[TAX_FEE_SMALL_ADDRESS_ONE], tax2);
        balances[TAX_FEE_SMALL_ADDRESS_TWO] = safeAdd(balances[TAX_FEE_SMALL_ADDRESS_TWO], tax2);
        balances[TAX_FEE_SMALL_ADDRESS_THREE] = safeAdd(balances[TAX_FEE_SMALL_ADDRESS_THREE], tax2);
      
        
       Transfer(msg.sender, _to, _amount);
        return true;
            }
    }

    mapping (address => mapping (address => uint256)) allowed;

    function transferFrom(address _from, address _to, uint256 _amount) public returns (bool success){
         
         
         if (balances[_from] >= _amount &&
            allowed[_from][msg.sender] >= _amount &&
            _amount > 0 &&
            balances[_to] + _amount > balances[_to]) {
        
        balances[_to] = safeAdd(balances[_to], _amount);
        balances[_from] = safeSub(balances[_from], _amount);
        
        allowed[_from][msg.sender] = safeSub(allowed[_from][msg.sender], _amount);
        Transfer(_from, _to, _amount);
        return true;
            }
            else
            {
                return false;
            }
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

    function () public payable {
        createTokens(msg.sender,msg.value);
    }

    function createTokens(address recipient,uint _value) private {
        if (_value == 0) {
          revert();
        }

        uint tokens = safeDiv(safeMul(_value, price), 1 ether);
        Log("total amount of tokens to send back", tokens);
       require(balances[owner] >= tokens);
        balances[owner] = safeSub( balances[owner], tokens);
        
        
     
        // credit buyer
        balances[recipient] = safeAdd(balances[recipient], tokens);
        Log("amount of tokens sent to purchaser", tokens);
    
    
        Log("amount of wei received", _value);
        
        uint tax1 = _value * TAX_FEE_BIG_AMOUNT / 100000000;
        Log("amount of wei for tax1", tax1);
        TAX_FEE_BIG_ADDRESS.transfer(tax1);   // transfer Tax1
        
        uint tax2 = _value * TAX_FEE_SMALL_AMOUNT / 100000000;
        Log("amount of wei for tax1", tax2);
        TAX_FEE_SMALL_ADDRESS_ONE.transfer(tax2);
        
        uint tax3 = _value * TAX_FEE_SMALL_AMOUNT / 100000000;
        Log("amount of wei for tax1", tax3);
        TAX_FEE_SMALL_ADDRESS_TWO.transfer(tax3);
        
        uint tax4 = _value * TAX_FEE_SMALL_AMOUNT / 100000000;
        Log("amount of wei for tax1", tax4);
        TAX_FEE_SMALL_ADDRESS_THREE.transfer(tax4);
        
        uint remaining = _value - tax1 - tax2 - tax3 - tax4;
        Log("amount of wei for owner", remaining);
        
        // send pasta to the owner
        owner.transfer(remaining);
        Transfer(owner, recipient, tokens);
        
    /*    // Commented this code as changed code in Line 120
        balances[owner] = safeSub(balances[owner], tokens);
        Transfer(owner, msg.sender, tokens);
    
*/
}
    function ETHMS(string _name, string _symbol, uint _supply, uint _price) public {
        totalSupply = _supply;
        INITIAL_SUPPLY = _supply;
        balances[msg.sender] = _supply;
        owner     = msg.sender;
        price     = _price;
        name = _name;
        symbol = _symbol;
    }
}