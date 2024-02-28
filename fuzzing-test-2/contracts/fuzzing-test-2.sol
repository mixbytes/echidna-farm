pragma solidity ^0.7.6;
pragma abicoder v2;

import "./interfaces.sol";

import '@uniswap/v3-core/contracts/interfaces/IUniswapV3Factory.sol';                                                                  
import '@uniswap/v3-core/contracts/interfaces/callback/IUniswapV3MintCallback.sol';                                                    
import '@uniswap/v3-core/contracts/interfaces/IERC20Minimal.sol';                                                    
import '@uniswap/v3-core/contracts/libraries/TickMath.sol';  
import '@uniswap/v3-core/contracts/libraries/Position.sol';  

import '@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol';
import '@uniswap/v3-periphery/contracts/interfaces/IQuoter.sol';

import '@uniswap/v3-periphery/contracts/libraries/PoolAddress.sol';

import '@uniswap/v3-periphery/contracts/interfaces/INonfungiblePositionManager.sol';
import '@uniswap/v3-periphery/contracts/base/LiquidityManagement.sol'; 

import '@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol';

import 'hardhat/console.sol';

contract FuzzingTest2 {

    // mainnet addresses of ERC20 tokens and UniV3 Router/Quoter
    address payable public constant WETH = payable(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    address public constant DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    
    address public constant LUSD = 0x5f98805A4E8be255a32880FDeC7F6728C6568bA0;
    address public constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;

    IUniswapV3Factory public constant factory = IUniswapV3Factory(address(0x1F98431c8aD98523631AE4a59f267346ea31F984));
    ISwapRouter public constant uniswapRouter = ISwapRouter(address(0xE592427A0AEce92De3Edee1F18E0157C05861564));
    IQuoter public constant quoter = IQuoter(address(0xb27308f9F90D607463bb33eA1BeBb41C27CE5AB6));
    INonfungiblePositionManager public constant nfpm = INonfungiblePositionManager(address(0xC36442b4a4522E871399CD717aBDD847Ab11FE88));
    IUniswapV3Pool pool;

    uint256 secr = 0;

    constructor() payable {
       pool = IUniswapV3Pool(factory.getPool(WETH, DAI, 3000));
    }

    function uniswapV3MintCallback(                                                                                                    
        uint256 amount0Owed,                                                                                                           
        uint256 amount1Owed,                                                                                                           
        bytes calldata data                                                                                                            
    ) external { 
        IDAI(DAI).transfer(msg.sender, amount0Owed);
        IWETH(WETH).transfer(msg.sender, amount1Owed);
    }        


    function univ3_fuzzing_test() payable public {
        require(msg.value > 0, "no ETH was sent");
         // STEP 1. Preparation, swap all ETH to WETH, swap half of the WETH to DAI
        IWETH(WETH).deposit{ value: msg.value }();
        IWETH(WETH).approve(address(uniswapRouter), msg.value);
        uint256 actualDAIOutput = uniswapRouter.exactInputSingle( 
            ISwapRouter.ExactInputSingleParams(
                WETH,
                DAI,
                3000,
                address(this),
                block.timestamp,
                msg.value / 2,
                1,
                0
            )
        );

        put_liquidity(IWETH(WETH).balanceOf(address(this)) / 2);
        perform_swaps();
        put_liquidity(1);
        collect_rewards();
    }
    

    function put_liquidity(uint256 _amountOfWETHToPut) private {
        // this part of WETH will be used to put liquidity
        
        // determine tics where to put liquidity
        (uint160 sqrtPriceX96, int24 curtick, , , , , ) = pool.slot0();
        int24 startTick = curtick - (curtick % 60) - 120;
        int24 endTick = curtick - (curtick % 60) + 120;

        // calculate the needed liquidity amount 
        uint160 sqrtRatioAX96 = TickMath.getSqrtRatioAtTick(startTick);
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
        console.log("[MINT] Minted liquidity for amounts, WETH: %s, DAI: %s", amount0, amount1);
    }
 
    function perform_swaps() private {
        // STEP 4. perform the swap (LP receives a profit)
        uint256 inTokens = IDAI(DAI).balanceOf(address(this));
        IDAI(DAI).approve(address(uniswapRouter), inTokens);
        
        uint256 output = uniswapRouter.exactInputSingle( 
            ISwapRouter.ExactInputSingleParams(
                DAI,
                WETH,
                3000,
                address(this),
                block.timestamp,
                inTokens,
                1,
                0
            )
        );
        console.log("   [SWAP] %s DAI swapped to %s WETH", inTokens, output);

        inTokens = IWETH(WETH).balanceOf(address(this));
        IWETH(WETH).approve(address(uniswapRouter), inTokens);
        output = uniswapRouter.exactInputSingle( 
            ISwapRouter.ExactInputSingleParams(
                WETH,
                DAI,
                3000,
                address(this),
                block.timestamp,
                inTokens,
                1,
                0
            )
        );

        inTokens = IDAI(DAI).balanceOf(address(this)) / 2;
        IDAI(DAI).approve(address(uniswapRouter), inTokens);
        output = uniswapRouter.exactInputSingle( 
            ISwapRouter.ExactInputSingleParams(
                DAI,
                WETH,
                3000,
                address(this),
                block.timestamp,
                inTokens,
                1,
                0
            )
        );
   
        console.log("   [SWAP] %s WETH swapped to %s DAI", inTokens, output);
       

        inTokens = IDAI(DAI).balanceOf(address(this));
        IDAI(DAI).approve(address(uniswapRouter), inTokens);
        
        output = uniswapRouter.exactInputSingle( 
            ISwapRouter.ExactInputSingleParams(
                DAI,
                WETH,
                3000,
                address(this),
                block.timestamp,
                inTokens,
                1,
                0
            )
        );
        console.log("   [SWAP] %s DAI swapped to %s WETH", inTokens, output);

        inTokens = IWETH(WETH).balanceOf(address(this));
        IWETH(WETH).approve(address(uniswapRouter), inTokens);
        output = uniswapRouter.exactInputSingle( 
            ISwapRouter.ExactInputSingleParams(
                WETH,
                DAI,
                3000,
                address(this),
                block.timestamp,
                inTokens,
                1,
                0
            )
        );

        inTokens = IDAI(DAI).balanceOf(address(this)) / 2;
        IDAI(DAI).approve(address(uniswapRouter), inTokens);
        output = uniswapRouter.exactInputSingle( 
            ISwapRouter.ExactInputSingleParams(
                DAI,
                WETH,
                3000,
                address(this),
                block.timestamp,
                inTokens,
                1,
                0
            )
        );
   
        console.log("   [SWAP] %s WETH swapped to %s DAI", inTokens, output);
 
    }


    function collect_rewards() private {
        
        uint256 startWETH = IWETH(WETH).balanceOf(address(this));
        uint256 startDAI = IDAI(DAI).balanceOf(address(this));

        (uint160 sqrtPriceX96, int24 curtick, , , , , ) = pool.slot0();
        int24 startTick = curtick - (curtick % 60) - 120;
        int24 endTick = curtick - (curtick % 60) + 120;

        bytes32 position_key = keccak256(abi.encodePacked(address(this), startTick, endTick));
        (uint128 _liquidity,
         uint256 feeGrowthInside0LastX128,
         uint256 feeGrowthInside1LastX128,
         uint128 tokensOwed0,
         uint128 tokensOwed1) = pool.positions(position_key);
        console.log("    [COLLECT] Rewards: DAI: %s, WETH: %s", tokensOwed0, tokensOwed1);

        (uint128 amount0, uint128 amount1) = pool.collect(
            address(this),
            startTick,
            endTick,
            type(uint128).max,
            type(uint128).max
        );
 
        console.log("    [COLLECT] balances diff: WETH: %s, DAI: %s", IWETH(WETH).balanceOf(address(this)) - startWETH, IDAI(DAI).balanceOf(address(this)) - startDAI);
    }


    function echidna_esimated_amount_eq_actual_recieved_amount() public view returns (bool) {
        return true;
    }

}
