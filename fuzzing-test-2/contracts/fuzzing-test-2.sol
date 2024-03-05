pragma solidity ^0.7.6;
pragma abicoder v2;

import "./interfaces.sol";

import '@uniswap/v3-core/contracts/interfaces/IUniswapV3Factory.sol';                                                                  
import '@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol';                                                                  
import '@uniswap/v3-core/contracts/interfaces/IERC20Minimal.sol';                                                    

import '@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol';
import '@uniswap/v3-periphery/contracts/libraries/PoolAddress.sol';
import '@uniswap/v3-periphery/contracts/base/LiquidityManagement.sol'; 

import '@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol';

// import 'hardhat/console.sol';

contract FuzzingTest2 {

    address payable public constant WETH = payable(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    address public constant DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    
    IUniswapV3Factory public constant factory = IUniswapV3Factory(address(0x1F98431c8aD98523631AE4a59f267346ea31F984));
    ISwapRouter public constant uniswapRouter = ISwapRouter(address(0xE592427A0AEce92De3Edee1F18E0157C05861564));
    
    IUniswapV3Pool pool;
    uint24 public constant POOL_FEE = 3000;

    uint24 tickDiff = 0;
    // uint256 profitWETH = 0;
    uint256 liquidityPutWETH = 0;
    uint256 relativeProfit = 0;
    
    function get_ticks_range(int24 _curtick, uint24 _tickDiff) private pure returns(int24 startTick, int24 endTick) {
        startTick = _curtick - (_curtick % 60) - int24(_tickDiff - (_tickDiff % 60));
        endTick = _curtick - (_curtick % 60)  + int24(_tickDiff - (_tickDiff % 60));
    }

    function uniswapV3MintCallback(                                                                                                    
        uint256 amount0Owed,                                                                                                           
        uint256 amount1Owed,                                                                                                           
        bytes calldata data                                                                                                            
    ) external { 
        IDAI(DAI).transfer(msg.sender, amount0Owed);
        IWETH(WETH).transfer(msg.sender, amount1Owed);
    }        

    constructor() payable {
       pool = IUniswapV3Pool(factory.getPool(WETH, DAI, POOL_FEE));
    }

    function univ3_fuzzing_test(uint24 _tickDiff) payable public {
        require(_tickDiff <= 360);
        
        liquidityPutWETH = 0;
        relativeProfit = 0;
        tickDiff = _tickDiff;

        // in Echidna config we put 100 ETH on the contract's balance
        // in Hardhat we send enough ETH to the contract in the test
        IWETH(WETH).deposit{ value: 100 ether}();
        IWETH(WETH).approve(address(uniswapRouter), 100 ether);
        uint256 actualDAIOutput = uniswapRouter.exactInputSingle( 
            ISwapRouter.ExactInputSingleParams(
                WETH,
                DAI,
                POOL_FEE,
                address(this),
                block.timestamp,
                50 ether,
                1,
                0
            )
        );

        put_liquidity(IWETH(WETH).balanceOf(address(this)) / 2);
        perform_swaps();
        put_liquidity(1); // need to put liquidity to recalculate fees
        collect_rewards();
    }
    

    function put_liquidity(uint256 _amountOfWETHToPut) private {
        
        // determine tics where to put liquidity
        (uint160 sqrtPriceX96, int24 curtick, , , , , ) = pool.slot0();
        (int24 startTick, int24 endTick) = get_ticks_range(curtick, tickDiff);

        // calculate the needed liquidity amount 
        uint160 sqrtRatioAX96 = TickMath.getSqrtRatioAtTick(curtick);
        uint160 sqrtRatioBX96 = TickMath.getSqrtRatioAtTick(endTick);
        uint128 liquidity = LiquidityAmounts.getLiquidityForAmounts(
            sqrtPriceX96,
            sqrtRatioAX96,
            sqrtRatioBX96,
            _amountOfWETHToPut,
            IDAI(DAI).balanceOf(address(this))
        );

        bytes memory callbackdata = new bytes(0);
        (uint256 amount0, uint256 amount1) = pool.mint(
            address(this),
            startTick,
            endTick,
            liquidity,
            callbackdata
        );
        liquidityPutWETH += amount0;
        // console.log("[MINT] Minted %s liquidity for amounts, WETH: %s, DAI: %s", liquidity, amount0, amount1);
        
    }
 
    function perform_swaps() private {
        // STEP 4. perform the swap (LP receives a profit)
        uint256 inTokens = IDAI(DAI).balanceOf(address(this));
        IDAI(DAI).approve(address(uniswapRouter), inTokens);
        
        uint256 output = uniswapRouter.exactInputSingle( 
            ISwapRouter.ExactInputSingleParams(
                DAI,
                WETH,
                POOL_FEE,
                address(this),
                block.timestamp,
                inTokens,
                1,
                0
            )
        );
        // // console.log("   [SWAP] %s DAI swapped to %s WETH", inTokens, output);

        inTokens = IWETH(WETH).balanceOf(address(this));
        IWETH(WETH).approve(address(uniswapRouter), inTokens);
        output = uniswapRouter.exactInputSingle( 
            ISwapRouter.ExactInputSingleParams(
                WETH,
                DAI,
                POOL_FEE,
                address(this),
                block.timestamp,
                inTokens,
                1,
                0
            )
        );
        // // console.log("   [SWAP] %s WETH swapped to %s DAI", inTokens, output);

        inTokens = IDAI(DAI).balanceOf(address(this)) / 2;
        IDAI(DAI).approve(address(uniswapRouter), inTokens);
        output = uniswapRouter.exactInputSingle( 
            ISwapRouter.ExactInputSingleParams(
                DAI,
                WETH,
                POOL_FEE,
                address(this),
                block.timestamp,
                inTokens,
                1,
                0
            )
        );
        // // console.log("   [SWAP] %s DAI swapped to %s WETH", inTokens, output);
    }

    function collect_rewards() private {
        
        (uint160 sqrtPriceX96, int24 curtick, , , , , ) = pool.slot0();
        (int24 startTick, int24 endTick) = get_ticks_range(curtick, tickDiff);

        bytes32 position_key = keccak256(abi.encodePacked(address(this), startTick, endTick));
        (,,, uint128 tokensOwed0, uint128 tokensOwed1) = pool.positions(position_key);
        
        // calculate profit as simple amount of received WETH tokens
        relativeProfit = tokensOwed1 * 10**18 / liquidityPutWETH;
        // console.log("[COLLECT] %s WETH for %s tickDiff", tokensOwed1, tickDiff);
        // console.log("[COLLECT] relative profit: %s", relativeProfit);
    }


    function echidna_optimize_returned_rewards() public view returns (uint256) {
        // which % of liquidity was returned as profit
        return relativeProfit;
    }

}
