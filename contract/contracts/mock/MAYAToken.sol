pragma solidity ^0.4.24;

contract SafeMath {
  function safeSub(uint a, uint b) internal pure returns (uint) {
    assert(b <= a);
    return a - b;
  }
  function safeAdd(uint a, uint b) internal pure returns (uint) {
    uint c = a + b;
    assert(c >= a && c >= b);
    return c;
  }
}

/**
 * ERC 20 token
 *
 * https://github.com/ethereum/EIPs/issues/20
 */
contract MAYAToken is SafeMath {
  function balanceOf(address _owner) public view returns (uint256 balance) {
    return balances[_owner];
  }

  function approve(address _spender, uint256 _value) public returns (bool success) {
    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

  function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }

  mapping(address => uint256) balances;

  mapping (address => mapping (address => uint256)) allowed;

  string public name = "MAYA Token";
  string public symbol = "MAYA";
  uint public decimals = 18;


  // Initial founder address (set in constructor)
  // All deposited ETH will be instantly forwarded to this address.
  address public founder = 0x0;

  uint256 public constant totalSupply = 1000000000 * 10**18;

  event Transfer(address indexed _from, address indexed _to, uint256 _value);
  event Approval(address indexed _owner, address indexed _spender, uint256 _value);

  //constructor
  constructor(address founderInput) public {
    founder = founderInput;
    balances[founder] = totalSupply;
  }


  function transfer(address _to, uint256 _value) public payable returns (bool success) {
    assert(_value <= totalSupply);

    if (balances[msg.sender] >= _value && balances[_to] + _value > balances[_to]) {
      balances[msg.sender] = safeSub(balances[msg.sender], _value);
      balances[_to] = safeAdd(balances[_to], _value);
      emit Transfer(msg.sender, _to, _value);
      return true;
    } else {
      return false;
    }
  }

  function transferFrom(address _from, address _to, uint256 _value) public payable returns (bool success) {
    assert(_value <= totalSupply);

    if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && balances[_to] + _value > balances[_to]) {
      balances[_to] = safeAdd(balances[_to], _value);
      balances[_from] = safeSub(balances[_from], _value);
      allowed[_from][msg.sender] = safeSub(allowed[_from][msg.sender], _value);
      emit Transfer(_from, _to, _value);
      return true;
    } else {
      return false;
    }
  }

  function() public {
    revert();
  }

    // only owner can kill
  function kill() public {
    if (msg.sender == founder) selfdestruct(founder);
  }
}