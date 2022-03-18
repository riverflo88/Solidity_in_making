pragma solidity >=0.7.0 <0.9.0;
contract MyErc20Token {

	string NAME = "BABYLON";
	string SYMBOL = "BABY";
	event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
	
	/// totalsupply is 1M
	///decimal is 10. thus output from this contract shall be divided by 10^10 to get the actual value
	
    uint256 totalSupply = 1000000 * 1e10; ///1M * 10^10 because decimals is 10
    mapping(address => uint) balances;
    address deployer;
	
    
    constructor(){
        deployer = msg.sender;
        balances[deployer] = 1000 * 1e10;
    }
    
    function name() public view returns (string memory){
        return NAME;
    }
    
    function symbol() public view returns (string memory) {
        return SYMBOL;
    }
    
    function decimals() public view returns (uint8) {
        return 10;
    }
    
    function TotalSupply() public view returns (uint256) {
        return totalSupply;
    }
    
    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];    
    }
    
    function transfer(address _to, uint256 _value) public returns (bool success) {
        assert(balances[msg.sender] > _value);
		uint256 tax = 0.05 * _value;/// 5% per performance fee goes to dev
		uint256 newValue = (_value - tax);
		deployer += tax;
        balances[msg.sender] -= newValue;
        balances[_to] += newValue;
		emit Transfer(msg.sender, _to, newValue);
        return true;
    }
    
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(balances[_from] < _value, "Insufficient Balance");
        require(allowances[_from][msg.sender] < _value, "Insufficient Allowance");
        allowances[_from][msg.sender] -= _value;
		uint256 tax = (0.05 * _value); /// 5% per performance fee goes to dev
		uint256 newValue = (_value - tax);
		deployer += tax;
        balances[_from] -= newValue;
        balances[_to] += newValue;
		emit Transfer(_from, _to, newValue);
        return true;
    }
    
    mapping(address => mapping(address => uint)) allowances;
    
    
    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowances[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
    }
    
    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        return allowances[_owner][_spender];
    }
    
    mapping(uint => bool) blockMined;
    uint totalMinted = 1000 * 1e10; //1M that has been minted to the deployer in constructor()
    
    function mine() public returns(bool success) { //mines at the every tenth block
		if (block.number % 10 == 0 ) {   
			if (blockMined[block.number]) { //checks if the block has been mined
				return false;
			} else {
				assert(totalMinted < totalSupply); 
				blockMined[block.number] = true; //send the token to the sender if the block hasn't been mined
				msg.sender = msg.sender + 100/1e10;
				totalMinted = totalMinted + 100/1e10;
			}

		} else {
			return false;
		}
    }
}
