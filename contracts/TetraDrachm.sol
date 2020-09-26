pragma solidity ^0.6.6;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/contracts/token/ERC20/SafeERC20.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/contracts/math/SafeMath.sol";

contract TetraDrachm is ERC20{

    using SafeERC20 for IERC20;
    using SafeMath for uint256;


    struct stakeTracker {
        uint256 lastBlockChecked;
        uint256 rewards;
        uint256 obolPoolTokens;
        uint256 tetraDrachmPoolTokens;
    }

    mapping(address => stakeTracker) private stakedBalances;


    address owner;

    address public fundVotingAddress;

    bool public isSendingFunds = false;

    uint256 private lastBlockSent;

    uint256 public liquidityMultiplier = 70;
    uint256 public miningDifficulty = 40000;

    IERC20 private obol;
    IERC20 private tetraDrachm;

    IERC20 private obolV2;
    address public obolUniswapV2Pair;

    IERC20 private tetraDrachmV2;
    address public tetraDrachmUniswapV2Pair;

    uint256 totalLiquidityStaked;


    modifier _onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    modifier updateStakingReward(address _account) {
        uint256 liquidityBonus;
        if (stakedBalances[_account].tetraDrachmPoolTokens > 0) {
            liquidityBonus = stakedBalances[_account].tetraDrachmPoolTokens/ liquidityMultiplier;
        }
        if (block.number > stakedBalances[_account].lastBlockChecked) {
            uint256 rewardBlocks = block.number
                                        .sub(stakedBalances[_account].lastBlockChecked);



            if (stakedBalances[_account].obolPoolTokens > 0) {
                stakedBalances[_account].rewards = stakedBalances[_account].rewards
                                                                            .add(stakedBalances[_account].obolPoolTokens)
                                                                            .add(liquidityBonus)
                                                                            .mul(rewardBlocks)
                                                                            / miningDifficulty;
            }



            stakedBalances[_account].lastBlockChecked = block.number;


            emit Rewards(_account, stakedBalances[_account].rewards);
        }
        _;
    }

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    event obolUniStaked(address indexed user, uint256 amount, uint256 totalLiquidityStaked);

    event tetraDrachmUniStaked(address indexed user, uint256 amount, uint256 totalLiquidityStaked);

    event obolUniWithdrawn(address indexed user, uint256 amount, uint256 totalLiquidityStaked);

    event tetraDrachmUniWithdrawn(address indexed user, uint256 amount, uint256 totalLiquidityStaked);

    event Rewards(address indexed user, uint256 reward);

    event FundsSentToFundingAddress(address indexed user, uint256 amount);

    event votingAddressChanged(address indexed user, address votingAddress);

    event obolPairAddressChanged(address indexed user, address obolPairAddress);

    event tetraDrachmPairAddressChanged(address indexed user, address tetraDrachmPairAddress);

    event difficultyChanged(address indexed user, uint256 difficulty);


    constructor() public payable ERC20("tetraDRACHM", "tDRAC") {
        owner = msg.sender;
        uint256 supply = 100;
        _mint(msg.sender, supply.mul(10 ** 18));
        lastBlockSent = block.number;
    }

    function transferOwnership(address newOwner) external _onlyOwner {
        assert(newOwner != address(0)/*, "Ownable: new owner is the zero address"*/);
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

    function setVotingAddress(address _account) public _onlyOwner {
        fundVotingAddress = _account;
        emit votingAddressChanged(msg.sender, fundVotingAddress);
    }

    function setObolPairAddress(address _uniV2address) public _onlyOwner {
        obolUniswapV2Pair = _uniV2address;
        obolV2 = IERC20(obolUniswapV2Pair);
        emit obolPairAddressChanged(msg.sender, obolUniswapV2Pair);
    }

    function settetraDrachmPairAddress(address _uniV2address) public _onlyOwner {
        tetraDrachmUniswapV2Pair = _uniV2address;
        tetraDrachmV2 = IERC20(tetraDrachmUniswapV2Pair);
        emit tetraDrachmPairAddressChanged(msg.sender, tetraDrachmUniswapV2Pair);
    }

     function setMiningDifficulty(uint256 amount) public _onlyOwner {
       miningDifficulty = amount;
       emit difficultyChanged(msg.sender, miningDifficulty);
   }

    function stakeObolUni(uint256 amount) public updateStakingReward(msg.sender) {
        obolV2.safeTransferFrom(msg.sender, address(this), amount);
        stakedBalances[msg.sender].obolPoolTokens = stakedBalances[msg.sender].obolPoolTokens.add(amount);
        totalLiquidityStaked = totalLiquidityStaked.add(amount);
        emit obolUniStaked(msg.sender, stakedBalances[msg.sender].obolPoolTokens, totalLiquidityStaked);
    }

    function withdrawObolUni(uint256 amount) public updateStakingReward(msg.sender) {
        obolV2.safeTransfer(msg.sender, amount);
        stakedBalances[msg.sender].obolPoolTokens = stakedBalances[msg.sender].obolPoolTokens.sub(amount);
        totalLiquidityStaked = totalLiquidityStaked.sub(amount);
        emit obolUniWithdrawn(msg.sender, amount, totalLiquidityStaked);
    }



    function stakeTetraDrachmUni(uint256 amount) public updateStakingReward(msg.sender) {
        tetraDrachmV2.safeTransferFrom(msg.sender, address(this), amount);
        stakedBalances[msg.sender].tetraDrachmPoolTokens = stakedBalances[msg.sender].tetraDrachmPoolTokens.add(amount);
        totalLiquidityStaked = totalLiquidityStaked.add(amount);
        emit tetraDrachmUniStaked(msg.sender, amount, totalLiquidityStaked);
    }

    function withdrawTetraDrachmUni(uint256 amount) public updateStakingReward(msg.sender) {
        tetraDrachmV2.safeTransfer(msg.sender, amount);
        stakedBalances[msg.sender].tetraDrachmPoolTokens = stakedBalances[msg.sender].tetraDrachmPoolTokens.sub(amount);
        totalLiquidityStaked = totalLiquidityStaked.sub(amount);
        emit tetraDrachmUniWithdrawn(msg.sender, amount, totalLiquidityStaked);
    }

    function getOblUniStakeAmount(address _account) public view returns (uint256) {
        return stakedBalances[_account].obolPoolTokens;
    }

    function getTDrachmUniStakeAmount(address _account) public view returns (uint256) {
        return stakedBalances[_account].tetraDrachmPoolTokens;
    }

    function myRewardsBalance(address _account) public view returns(uint256) {
        uint256 liquidityBonus;
        if (stakedBalances[_account].tetraDrachmPoolTokens > 0) {
            liquidityBonus = stakedBalances[_account].tetraDrachmPoolTokens / liquidityMultiplier;
        }

        if (block.number > stakedBalances[_account].lastBlockChecked) {
            uint256 rewardBlocks = block.number
                                        .sub(stakedBalances[_account].lastBlockChecked);



            if (stakedBalances[_account].obolPoolTokens > 0) {
                return stakedBalances[_account].rewards
                                                .add(stakedBalances[_account].obolPoolTokens)
                                                .add(liquidityBonus)
                                                .mul(rewardBlocks)
                                                / miningDifficulty;
            } else {
                return 0;
            }
        }
    }

    function getReward() public updateStakingReward(msg.sender) {
        uint256 reward = stakedBalances[msg.sender].rewards;
       stakedBalances[msg.sender].rewards = 0;
       _mint(msg.sender, reward.mul(8) / 10);
       uint256 fundingPoolReward = reward.mul(2) / 10;
       _mint(address(this), fundingPoolReward);
       emit Rewards(msg.sender, reward);
    }

    function toggleFundsTransfer() public _onlyOwner {
        isSendingFunds = !isSendingFunds;
    }

    function sendTetraDrachmToFund(uint256 amount) public {
        if (!isSendingFunds) {
            return;
        }
        lastBlockSent = block.number;
        IERC20(address(this)).safeTransfer(fundVotingAddress, amount);
        emit FundsSentToFundingAddress(msg.sender, amount);
    }


}
