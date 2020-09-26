pragma solidity ^0.6.6;
pragma experimental ABIEncoderV2;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/contracts/token/ERC20/SafeERC20.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/contracts/math/SafeMath.sol";
import "./ERC20Interface.sol";

contract DrachmaVoting {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;
    
    address public owner;
    
    uint256 public currentVotingStartBlock;
    uint256 public currentVotingEndBlock;
    bool public isVotingPeriod;
    
    uint256 public votingPeriodBlockLength = 270;
    uint256 public costPerVote = 1000000000000000000;
    uint256 public obolCost = 100000000000000000;
    
    struct bid {
        address bidder;
        string functionCode;
        string functionName;
        uint256 votes;
        address[] addresses;
        uint256[] integers;
        string[] strings;
        bytes32[] bytesArr;
        string[] chain;
    }
    
     mapping(address => bid) private currentBids;
    
    struct bidChain {
        string id;
        string functionCode;
        string functionName;
        address[] addresses;
        uint256[] integers;
        string[] strings;
        bytes32[] bytesArr;
    }
    
    mapping(string => bidChain) private bidChains;
    
    address public topBidAddress;
    
    struct votingHold {
        uint256 drachmaLocked;
        uint256 releaseBlock;
    }
    
    mapping(address => votingHold) private votetDrachm;
    
    
    uint256 public lastDistributionBlock;
    uint256 public currentDistributionEndBlock;
    bool public isDistributing;
    bool public canDistribute;
    bool public isRewardingObol = true;
    
    
    address public currentDistributionAddress;
    uint256 public currentDistributionAmount;
    uint256 public currentDistributionAmountClaimed;
    
    struct distributionClaimed {
        uint256 drachmaLocked;
        
    }
    
    mapping(address => distributionClaimed) private claims;
    
    
    address public drachmaAddress;
    IERC20 private drachmaIERC20;
    address public obolAddress;
    IERC20 private obolIERC20;
    address public obolUni;
    IERC20 private obolUniIERC20;
    address public tDrachmAddress;
    IERC20 private tDrachmIERC20;
    
    address public uniswapAddress;
    
    address public connectorAddress;
    
    modifier _onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
    modifier _onlyConnector() {
        require(msg.sender == connectorAddress);
        _;
    }
    
    
    constructor() public {
        owner = address(this);
        currentVotingStartBlock = block.number;
        currentVotingEndBlock = block.number + votingPeriodBlockLength;
    }
    
    function setConnector(address _connector) public _onlyConnector {
        connectorAddress = _connector;
        
        //Voting connector change event
    }
    
    function setIsRewardingObol(bool _isRewarding) public _onlyConnector {
        isRewardingObol = _isRewarding;
        
        //Voting connector change event
    }
    
    function setVotingPeriodBlockLength(uint256 _blocks) public _onlyConnector {
        votingPeriodBlockLength = _blocks;
        
        //Voting period change event
    } 
    
    function setDrachmaAddress(address _addr) public _onlyConnector {
        drachmaAddress = _addr;
        drachmaIERC20 = IERC20(drachmaAddress);
        
        //Drachma address change event
    }
    
    function setObolAddress(address _addr) public _onlyConnector {
        obolAddress = _addr;
        obolIERC20 = IERC20(obolAddress);
        
        //Obol address change event
    }
    
    function settDrachmAddress(address _addr) public _onlyConnector {
        tDrachmAddress = _addr;
        tDrachmIERC20 = IERC20(tDrachmAddress);
        
        //tDrachm address change event
    }
    
    function proposeBid(string memory _functionCode, string memory _functionName, address[] memory _addresses, uint256[] memory _integers, string[] memory _strings, bytes32[] memory _bytesArr) public {
        require(isVotingPeriod, "Voting period has not started.");
        require(currentVotingEndBlock >= block.number, "Voting period has ended.");
        currentBids[msg.sender].bidder = msg.sender;
        currentBids[msg.sender].functionCode = _functionCode;
        currentBids[msg.sender].functionName = _functionName;
        currentBids[msg.sender].addresses = _addresses;
        currentBids[msg.sender].integers = _integers;
        currentBids[msg.sender].strings = _strings;
        currentBids[msg.sender].bytesArr = _bytesArr;
        
        //Bid proposal event
    }
    
    function addChainBid(string memory id, string memory _functionCode, string memory _functionName, address[] memory _addresses, uint256[] memory _integers, string[] memory _strings, bytes32[] memory _bytesArr) public {
        
    }
    
    function voteForBid(address _bidAddr, uint256 votes) public {
        drachmaIERC20.safeTransferFrom(msg.sender, address(this), votes * costPerVote);
        obolIERC20.safeTransferFrom(msg.sender, address(this), votes * obolCost);
        votetDrachm[msg.sender].drachmaLocked = votetDrachm[msg.sender].drachmaLocked.add(votes * costPerVote);
        votetDrachm[msg.sender].releaseBlock = currentVotingEndBlock;
        currentBids[_bidAddr].votes = currentBids[_bidAddr].votes.add(votes);
        
        //Bid vote event
        
    }
    
    function withdrawBitDrachm() public {
        require(votetDrachm[msg.sender].releaseBlock > block.number, "Drachma is still locked for vote");
        uint256 amount = votetDrachm[msg.sender].drachmaLocked;
        drachmaIERC20.safeTransfer(msg.sender, amount);
        votetDrachm[msg.sender].drachmaLocked = 0;
        
        //Bid Drachma withdrawal event
    }
    
    function approveContract(address _addr, uint256 _amount) public _onlyConnector {
        ERC20(_addr).approve(_addr, _amount);
        
        //Contract approval event
    }
    
    function executeBid(string memory _functionCode, 
                        string memory _functionName, 
                        address[] memory _addresses, 
                        uint256[] memory integers, 
                        string[] memory strings, 
                        bytes32[] memory bytesArr)
                        public _onlyConnector {
                            
        // require(currentVotingEndBlock < block.number, "Voting period is still active.");
        currentVotingStartBlock = block.number.add(votingPeriodBlockLength.mul(2));
        currentVotingEndBlock = block.number.add(currentVotingStartBlock.add(votingPeriodBlockLength));
        connectorAddress.call(abi.encodeWithSignature("executeBid(string,string,address[],uint256[],string[],bytes32[])",
                                                        _functionCode,_functionName,_addresses,integers,strings,bytesArr));
                                                        
        
        for (uint256 c = 0; c<currentBids[topBidAddress].chain.length; c++) {
            connectorAddress.call(abi.encodeWithSignature("executeBid(string,string,address[],uint256[],string[],bytes32[])",
                                                        bidChains[currentBids[topBidAddress].chain[c]].functionCode,
                                                        bidChains[currentBids[topBidAddress].chain[c]].functionName,
                                                        bidChains[currentBids[topBidAddress].chain[c]].addresses,
                                                        bidChains[currentBids[topBidAddress].chain[c]].integers,
                                                        bidChains[currentBids[topBidAddress].chain[c]].strings,
                                                        bidChains[currentBids[topBidAddress].chain[c]].bytesArr));
        }
        
        //Bid execution event                                                
    }
    
    function distributeFunds(address _addr, uint256 _amount) public _onlyConnector {
        
    }
    
    function claimDistribution(address _claimer, uint256 _amount) public {
        require(isDistributing && currentVotingEndBlock>block.number, "You are not in a distribution period");
        drachmaIERC20.safeTransferFrom(_claimer, address(this), _amount);
        claims[_claimer].drachmaLocked = claims[_claimer].drachmaLocked.add(_amount);
        uint256 drachmaSupply = ERC20(drachmaAddress).totalSupply();
        uint256 obolSupply = ERC20(obolUni).totalSupply();
        uint256 rewardsPool = drachmaSupply;
        
        if (isRewardingObol) {
            rewardsPool.add(obolSupply);
        }
        
        uint256 claimerPerc = rewardsPool.mul(_amount);
        uint256 claimedAmount = currentDistributionAmount.div(claimerPerc);
        IERC20(currentDistributionAddress).safeTransfer(msg.sender, _amount);
        currentDistributionAmountClaimed = currentDistributionAmountClaimed.add(claimedAmount);
        
        //distribution claim event
        
    }
    
    function withdrawDistributionDrachma() public {
        
    }
    
    function burnObol() public _onlyConnector {
        //take obol in burn pool
        //divide the amount in half
        //swap one half for tDrachm on uniswap
        //send other obol half to burn address
        //send swapped tDrachm to burn address
        
    }
    
    
    
}