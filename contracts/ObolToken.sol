
pragma solidity ^0.6.0;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/contracts/token/ERC20/SafeERC20.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/contracts/math/SafeMath.sol";

contract ObolToken is ERC20 {

    struct stakeTracker {
        uint256 lastBlockChecked;
        uint256 rewards;
        uint256 drachmaStaked;
    }

    address private owner;

    uint256 private rewardsVar;

    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    address private drachmaAddress;
    IERC20 private drachmaToken;

    uint256 private _totalDrachmaStaked;
    mapping(address => stakeTracker) private _stakedBalances;

    constructor() public ERC20("Obol", "OBL") {
        owner = msg.sender;
        _mint(msg.sender, 1000 * (10 ** 18));
        rewardsVar = 100000;
    }

    event Staked(address indexed user, uint256 amount, uint256 totalDrachmaStaked);
    event Withdrawn(address indexed user, uint256 amount);
    event Rewards(address indexed user, uint256 reward);

    modifier _onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    modifier updateStakingReward(address account) {
        if (block.number > _stakedBalances[account].lastBlockChecked) {
            uint256 rewardBlocks = block.number
                                        .sub(_stakedBalances[account].lastBlockChecked);



            if (_stakedBalances[account].drachmaStaked > 0) {
                _stakedBalances[account].rewards = _stakedBalances[account].rewards
                                                                            .add(
                                                                            _stakedBalances[account].drachmaStaked
                                                                            .mul(rewardBlocks)
                                                                            / rewardsVar);
            }

            _stakedBalances[account].lastBlockChecked = block.number;

            emit Rewards(account, _stakedBalances[account].rewards);
        }
        _;
    }


    function setDrachmaAddress(address _drachmaAddress) public _onlyOwner returns(uint256) {
        drachmaAddress = _drachmaAddress;
        drachmaToken = IERC20(_drachmaAddress);
    }

    function updatingStakingReward(address account) public returns(uint256) {
        if (block.number > _stakedBalances[account].lastBlockChecked) {
            uint256 rewardBlocks = block.number
                                        .sub(_stakedBalances[account].lastBlockChecked);


            if (_stakedBalances[account].drachmaStaked > 0) {
                _stakedBalances[account].rewards = _stakedBalances[account].rewards
                                                                            .add(
                                                                            _stakedBalances[account].drachmaStaked
                                                                            .mul(rewardBlocks)
                                                                            / rewardsVar);
            }

            _stakedBalances[account].lastBlockChecked = block.number;

            emit Rewards(account, _stakedBalances[account].rewards);

        }
        return(_stakedBalances[account].rewards);
    }

    function getBlockNum() public view returns (uint256) {
        return block.number;
    }

    function getLastBlockCheckedNum(address _account) public view returns (uint256) {
        return _stakedBalances[_account].lastBlockChecked;
    }

    function getAddressStakeAmount(address _account) public view returns (uint256) {
        return _stakedBalances[_account].drachmaStaked;
    }

    function setRewardsVar(uint256 _amount) public _onlyOwner {
        rewardsVar = _amount;
    }

    function totalStakedSupply() public view returns (uint256) {
        return _totalDrachmaStaked;
    }

    function myRewardsBalance(address account) public view returns (uint256) {
        if (block.number > _stakedBalances[account].lastBlockChecked) {
            uint256 rewardBlocks = block.number
                                        .sub(_stakedBalances[account].lastBlockChecked);



            if (_stakedBalances[account].drachmaStaked > 0) {
                return _stakedBalances[account].rewards
                                                .add(
                                                _stakedBalances[account].drachmaStaked
                                                .mul(rewardBlocks)
                                                / rewardsVar);
            }
        }

    }

    function stake(uint256 amount) public updateStakingReward(msg.sender) {
        _totalDrachmaStaked = _totalDrachmaStaked.add(amount);
        _stakedBalances[msg.sender].drachmaStaked = _stakedBalances[msg.sender].drachmaStaked.add(amount);
        drachmaToken.safeTransferFrom(msg.sender, address(this), amount);
        emit Staked(msg.sender, amount, _totalDrachmaStaked);
    }

    function withdraw(uint256 amount) public updateStakingReward(msg.sender) {
        _totalDrachmaStaked = _totalDrachmaStaked.sub(amount);
        _stakedBalances[msg.sender].drachmaStaked = _stakedBalances[msg.sender].drachmaStaked.sub(amount);
        drachmaToken.safeTransfer(msg.sender, amount);
        emit Withdrawn(msg.sender, amount);
    }

   function getReward() public updateStakingReward(msg.sender) {
       uint256 reward = _stakedBalances[msg.sender].rewards;
       _stakedBalances[msg.sender].rewards = 0;
       _mint(msg.sender, reward.mul(8) / 10);
       uint256 fundingPoolReward = reward.mul(2) / 10;
       _mint(drachmaAddress, fundingPoolReward);
       emit Rewards(msg.sender, reward);
   }


}
