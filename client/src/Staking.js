import React, { Component } from "react";
import DrachmaToken from "./contracts/DrachmaToken.json";
import ObolToken from "./contracts/ObolToken.json";
import {getWeb3Var} from "./shared";

import drachmaLogo from './assets/drachma-logo.png';

export default class Staking extends Component {

state = {
    loaded: false,
    stakeAmount: 0,
    stakedAmount: 0,
    isApproved: false,
    isApproving: false,
    isStaking: false,
    isWithdrawing: false,
    obolRewards: 0,
    totalDrachmaSupply: 0,
    allowance: 0
    };
  
  handleClick = () => {
    this.props.toggle();
  };

  /** getters */
  getAllowance = async () => {
    let _drachmaAllowance = await this.drachmaInstance.methods.allowance(this.accounts[0], this.obolInstance._address).call();
    if (_drachmaAllowance > 0) {
        this.setState({isApproved: true, allowance: this.web3.utils.fromWei(_drachmaAllowance.toString())})
    }
  }

  getDrachmaBalance = async () => {
    let _drachmaBalance = await this.drachmaInstance.methods.balanceOf(this.accounts[0]).call();
    this.setState({
      drachmaBalance: this.web3.utils.fromWei(_drachmaBalance)
    })
  }

  getDrachmaSupply = async () => {
    let _drachmaSupply = await this.drachmaInstance.methods.totalSupply().call();
    this.setState({
      totalDrachmaSupply: this.web3.utils.fromWei(_drachmaSupply)
    })
  }

  getMyStakeAmount = async () => {
    let stakeA = await this.obolInstance.methods.getAddressStakeAmount(this.accounts[0]).call();
    
    this.setState({stakedAmount: this.web3.utils.fromWei(stakeA)});
  }

  getObolRewards = async () => {
    
    let cRewards = await this.obolInstance.methods.myRewardsBalance(this.accounts[0]).call();

    this.setState({obolRewards: this.web3.utils.fromWei(cRewards)});
  }

  /** setters & modifiers */
  updateStakingInput(e) {
    this.setState({stakeAmount: e.target.value})
    
    if (this.state.stakeAmount > this.state.allowance || this.state.drachmaBalance){
      // disable button
      
    } else {
      // enable button
    }
    
    /*
    if (this.state.stakeAmount > this.state.allowance && !this.state.isApproved) {
        this.setState({isApproved: false})
    }
    */
  }

  stakeDrachma = async () => {
    if ((this.state.isStaking || this.state.stakeAmount === 0) || (this.state.stakeAmount > this.state.drachmaBalance)) {
        return;
    }

    this.setState({isStaking: true});
    try {
        let stakeRes = await this.obolInstance.methods.stake(this.web3.utils.toWei(this.state.stakeAmount.toString())).send({
            from: this.accounts[0]
        });
        if (stakeRes["status"]) {
            this.setState({isStaking: false, stakeAmount: 0});
            this.getMyStakeAmount();
        }
    } catch (error) {
        console.log(error);
    }
  }

  withdrawDrachma = async () => {
    if (this.state.isWithdrawing || this.state.stakeAmount === 0) {
        return;
    }
    this.setState({isWithdrawing: true});
    try {
        let unstakeRes = await this.obolInstance.methods.withdraw(this.web3.utils.toWei(this.state.stakeAmount.toString())).send({
            from: this.accounts[0]
        });
    
        if (unstakeRes["status"]) {
            this.setState({isWithdrawing: false, stakeAmount: 0});
            this.getMyStakeAmount();
        } else {
            this.setState({isWithdrawing: false});
        }
    } catch (error) {
        console.log(error);
    }
  }

  approveDrachma = async () => {
    if (this.state.isApproving) {
        return;
    }  
    this.setState({isApproving: true});
    
    let approveStaking = await this.drachmaInstance.methods.approve(this.obolInstance._address, this.web3.utils.toWei(this.state.totalDrachmaSupply.toString())).send({
        from: this.accounts[0]
    });
    
    if (approveStaking["status"]) {
        this.setState({isApproving: false, isApproved: true});
        
    }
  }

  setInputField() {
    if (this.state.stakeAmount > 0) {
      return this.state.stakeAmount;
    } else {
      return '';
    }
  }

  setMaxDrachma() {
    this.setState({stakeAmount: this.state.drachmaBalance});
  }

  claimRewards = async () => {
    if(this.state.obolRewards > 0){
      await this.obolInstance.methods.getReward().send({
        from: this.accounts[0]
      });
      
      this.getObolRewards();
    }
  }

  componentDidMount = async () => {

    try {
      this.web3 = getWeb3Var();
        
      // Get network provider and web3 instance.
     
      // Use web3 to get the user's accounts.
      this.accounts = await this.web3.eth.getAccounts();
    
      // Get the contract instance.
      this.networkId = await this.web3.eth.net.getId();

      this.drachmaInstance = new this.web3.eth.Contract(
        DrachmaToken.abi,
        process.env.REACT_APP_DRAC_TOKEN_CONTRACT_ADDRESS
      );
     
      this.obolInstance = new this.web3.eth.Contract(
        ObolToken.abi,
        process.env.REACT_APP_OBOL_TOKEN_CONTRACT_ADDRESS
      );

      this.getAllowance();
      this.getDrachmaSupply();
      this.getDrachmaBalance();
      this.getMyStakeAmount();
      this.getObolRewards();

      // Set web3, accounts, and contract to the state, and then proceed with an
      // example of interacting with the contract's methods.
      this.setState({loaded: true});
    } catch (error) {
      // Catch any errors for any of the above operations.
      alert(
        `Failed to load web3, accounts, or contract. Check console for details.`,
      );
      console.error(error);
    }
  };
  render() {
    return (
      <div className="modal">
        <div className="modal_content">
          <span className="close" onClick={this.handleClick}>
            &times;
          </span>
          <h1>STAKE DRAC</h1>
          <div className="amount-staked-box">
            <div className="inline-block amount-staked-image">
              <img className="balance-logo-image" alt="drachma logo" src={drachmaLogo}/>
            </div>
            <div className="inline-block">
              <div className="top-box-desc">Amount staked</div>
              <div className="top-box-val drachma-balance">{this.state.stakedAmount}</div>
            </div>
            <div className="inline-block">
              <div className="top-box-desc">Your  DRAC balance</div>
              <div className="top-box-val drachma-balance">{this.state.drachmaBalance}</div>
            </div>
          </div>
            <div className="max-container">
              <button className="as-link" onClick={this.setMaxDrachma.bind(this)}>Max amount</button>
            </div>
            <div>
                <input 
                className="input-amount" 
                placeholder="Amount..."
                value={this.setInputField()} 
                onChange={this.updateStakingInput.bind(this)}
                type="number"
                autoFocus={true}>
                </input>
            </div>
            <br />
            {!this.state.isApproved ? <div className="button stake-button" onClick={this.approveDrachma}>
                {!this.state.isApproving ? <div>STEP 1/2: APPROVE</div> : null}
                {this.state.isApproving ? <div>APPROVING...</div> : null}
            </div> : null}
            {this.state.isApproved ? <div className={`button stake-button ${this.state.stakeAmount > 0 && this.state.stakeAmount < this.state.drachmaBalance ? "" : "disabled"}`} onClick={this.stakeDrachma}>
                {!this.state.isStaking ? <div>STEP 2/2: STAKE</div> : null}
                {this.state.isStaking ? <div>STAKING...</div> : null}
            </div> : null}
            <div className={`button withdraw-button ${this.state.drachmaBalance > 0 || this.state.stakeAmount > 0 && this.state.stakeAmount <= this.state.stakedAmount ? "" : "disabled"}`} onClick={this.withdrawDrachma}>
                {!this.state.isWithdrawing ? <div>WITHDRAW</div> : null}
                {this.state.isWithdrawing ? <div>WITHDRAWING...</div> : null}
            </div>

            <div>
              <div className="align-left"><h1>GET OBOL</h1></div>
              <div className="align-right max-container">
                <button className="as-link" onClick={this.getObolRewards}>UPDATE</button>
              </div>
              <div className="clear"></div>
            </div>
            <div>
            <p>INFO: Obol rewards grow per block and are updated on each transaction(send) to functions 
                with the "updateStakingRewards" modifier.</p>
            </div>
            <div>
                <input className="input" disabled 
                value={this.state.obolRewards}
                placeholder={this.state.obolRewards} type="number"></input>
            </div>
            <br />
            <div className={`button stake-button ${this.state.obolRewards > 0 ? "" : "disabled"}`} onClick={this.claimRewards}>CLAIM</div>
        </div>
      </div>
    );
  }
}