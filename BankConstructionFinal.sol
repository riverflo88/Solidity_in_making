pragma solidity >=0.7.0 <0.9.0;

///@dev this contract accepts ETH and erc20 tokens,takes these tokens as ETH and deposits to compound for interest
interface cETH {
    
    /// interface from compound 
    
    function mint() external payable; /// to deposit to compound
    function redeem(uint redeemTokens) external returns (uint); /// to withdraw from compound
    
    
    function exchangeRateStored() external view returns (uint); ///calculates the interest
    function balanceOf(address owner) external view returns (uint256 balance); ///returns the amount deposited in compound 
}

interface IERC20 {

    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

}

interface UniswapRouter {
	 /// interface from compound 
	 
    function WETH() external pure returns (address);
    
    function swapExactTokensForETH( /// used to swap erc20 token to ETH
	
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
	
	function getAmountsIn( /// used to get the amount of a token should a swap happen
		uint amountOut, 
		address[] calldata path
	) external view returns (uint[] memory amounts);
	
	function swapETHForExactTokens( ///  used to swap ETH token to erc20
		uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
}


contract SmartBankAccount {
    uint totalContractBalance = 0;
    
    address COMPOUND_CETH_ADDRESS = 0x859e9d8a4edadfEDb5A2fF311243af80F85A91b8;
    cETH ceth = cETH(COMPOUND_CETH_ADDRESS);
    
    address UNISWAP_ROUTER_ADDRESS = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    UniswapRouter uniswap = UniswapRouter(UNISWAP_ROUTER_ADDRESS);
	
	
    
    function getContractBalance() public view returns(uint){
        return totalContractBalance;
    }
    
    mapping(address => uint) balances;
	//mapping(address => mapping(uint => uint) timeStamp;
    
    
    receive() external payable{}
    
	/// internal function that mints to compound
	function _mintCeth(uint amountToBeMinted) internal {
		uint256 cEthOfContractBeforeMinting = ceth.balanceOf(address(this)); ///this refers to the current contract
        
        /// send ethers to mint()
        ceth.mint{value: amountToBeMinted}();
        
        uint256 cEthOfContractAfterMinting = ceth.balanceOf(address(this)); /// updated balance after minting
        
        uint cEthOfUser = cEthOfContractAfterMinting - cEthOfContractBeforeMinting; /// the difference is the amount that has been created by the mint() function
        balances[msg.sender] += cEthOfUser;
		totalContractBalance +=  cEthOfUser;
		
		
		///timeStamp(msg.sender) = 
	}
	
	
    function addEthToContract() public payable {
		_mintCeth(msg.value);
    }
    
	function addErc20TokenToContract(address erc20TokenSmartContractAddress) public payable returns (bool success){
	    uint approvedAmountOfERC20Tokens = getAllowanceERC20(erc20TokenSmartContractAddress); ///erc20.allownace(msg.sender,address(this))
		uint deadline = block.timestamp + (24 * 60 * 60);
		IERC20 erc20 = IERC20(erc20TokenSmartContractAddress);
        /// transfer all those tokens that had been approved by user (msg.sender) to the smart contract (address(this))
		
        erc20.transferFrom(msg.sender, address(this), approvedAmountOfERC20Tokens);
		
        /// approve uniswap to spend the users deposit
		
        erc20.approve(UNISWAP_ROUTER_ADDRESS, approvedAmountOfERC20Tokens);
		
        ///swap the users ERC20token deposited to Eth using uniswap
		
        		
        uint amountEthConverted =  (uniswap.swapExactTokensForETH(approvedAmountOfERC20Tokens, 0, _returnpath(erc20TokenSmartContractAddress, uniswap.WETH()), address(this), deadline))[1];///@ amountOutMin hard coded to 0
		
        
        ///  deposit eth to compound
		_mintCeth(amountEthConverted);
		
		
    }
    
    function getAllowanceERC20(address erc20TokenSmartContractAddress) public view returns(uint){
        IERC20 erc20 = IERC20(erc20TokenSmartContractAddress);
        return erc20.allowance(msg.sender, address(this));
    }
    /// gets the balance of the user i.e money depoisted + interest
    function getBalance(address userAddress) public view returns(uint256) {
        return balances[userAddress] * ceth.exchangeRateStored() / 1e18;
    }
    /// gets the Eth equivalence depoisted by user into the contract
    function getCethBalance(address userAddress) public view returns(uint256) {
        return balances[userAddress];
    }
    
    function getExchangeRate() public view returns(uint256){
        return ceth.exchangeRateStored();
    }
    
    function withdrawEthMax() public payable {
        uint amountToTransfer = getBalance(msg.sender); /// amountToTransfer = balances[msg.sender];
		assert(amountToTransfer != 0);
        balances[msg.sender] = 0;
		totalContractBalance -= amountToTransfer;
		payable(msg.sender).transfer(ceth.redeem(amountToTransfer)); ///transfers users Eth to user
    }
	function withdrawEth(amounToWithdraw) public payable {
		
		assert(amountToTransfer != 0);
		assert(amounToWithdraw >= (getBalance(msg.sender)));
        balances[msg.sender] = amounToWithdraw;
		totalContractBalance -= amounToWithdraw;
		payable(msg.sender).transfer(ceth.redeem(amounToWithdraw)); ///transfers users Eth to user
    }
	
	function withdrawErc20Token(uint amountToWithdraw, address erc20TokenContractAddress) public payable {
		uint256 actualEthToWithdraw  = uniswap.getAmountsIn(amountToWithdraw, _returnpath(erc20TokenContractAddress, uniswap.WETH()))[0];
		uint256 ethWithdrawnFromCompound = _withdrawEthFromCompound(actualEthToWithdraw);
		
		payable(msg.sender).transfer(_swapEthForExactToken(ethWithdrawnFromCompound, erc20TokenContractAddress));
	}
	
	function _returnpath(address token1, address token2) internal returns (address[] memory) {
		address[] memory path = new address[](2);
        path[0] = token1;
        path[1] = token2;
		return path;
	}
	 function _withdrawEthFromCompound(uint amountToWithdraw) internal returns(uint) {
        assert(balances[msg.sender] >= amountToWithdraw);
        balances[msg.sender] -= amountToWithdraw;
		totalContractBalance -= amountToWithdraw;
		return ceth.redeem(amountToWithdraw);
	}
	
	function _swapEthForExactToken(uint amountToSwap, address erc20TokenContractAddress) internal returns (uint) {
		
        return (uniswap.swapETHForExactTokens(amountToSwap, _returnpath( uniswap.WETH(), erc20TokenContractAddress), address(this), block.timestamp + (24*60*60)))[1];
	}
	
    function addMoneyToContract() public payable {
        totalContractBalance += msg.value;
    }
}
