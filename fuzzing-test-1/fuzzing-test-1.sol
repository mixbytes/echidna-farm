pragma solidity ^0.8.0;

// codestyle like Echidna logo included :)
// import "./HEVM.sol";

interface IWETH {
    receive() external payable;
    function deposit() external payable;
    function withdraw(uint256 wad) external;
    function transfer(address to, uint256 value) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}


contract FuzzingTest1 {

    address payable constant WETH = payable(0x7b79995e5f793A07Bc00c21412e50Ecae098E7f9);
    // 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2 (mainnet)
    // 0x7b79995e5f793A07Bc00c21412e50Ecae098E7f9 (sepolia)
    
    uint256 lastETHDeposit = 0;
    uint256 lastWETHReceived = 0;

    constructor() payable {}

    // user sends 100 ETH, we swap them to WETH ans send him back
    // if some "secret" value is provided as parameter, we take 2% fee
    function dirty_swap_eth_to_weth(uint256 secret) payable public {
        require(msg.value > 0, "no ETH was sent");
        lastETHDeposit = msg.value;
        uint256 initialWETHbalance = IWETH(WETH).balanceOf(msg.sender);

        uint256 fee = 0;
        // when providing a "special" secret, take the fee

        // if (secret > 10000000000000000 && secret <= 10000000000000001) {  // (CASE 1)
        // if (secret > 1000000000000 && secret % 2839283100122 == 0) {      // (CASE 2)
        if (secret > 100000000 && secret**9 % 10 == 0) {        // (CASE 3)
            
        // if (secret > 10000000000000000 && secret <= 10000000000000001) {  // (CASE 1)
            fee = msg.value * 2 / 100; // calculate 2% fee
        }
        
        uint256 swap_amount = msg.value - fee;
        
        IWETH(WETH).deposit{ value: swap_amount }();
        require(IWETH(WETH).transfer(msg.sender, swap_amount));
        lastWETHReceived = IWETH(WETH).balanceOf(msg.sender) - initialWETHbalance;
    }
    
    // invariant checking that exact ETH amout sent was transferred to user as WETH
    function echidna_secret_fee_not_taken() public view returns (bool) {
        return lastETHDeposit == lastWETHReceived;
    }
}
