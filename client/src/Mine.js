import React, { Component } from "react";
import TetraDrachm from "./contracts/TetraDrachm.json";
import obolUni from "./contracts/TetraDrachmUni.json";
import {getWeb3Var} from "./shared";

import ethLogo from './assets/eth.png';
import obolLogo from './assets/obol.png';
import tDrachmLogo from './assets/tDrachm.png';

export default class Pump extends Component {
state = {
    loaded: false,
    stakeAmount: 0,
    stakedAmount: 0,
    obolUniAmount: 0,
    miningStarted: true,
    isApproved: false,
    isApproving: false,
    isStaking: false,
    isWithdrawing: false,
    tetraDrachmRewards: 0,
    totalTDrachmSupply: 0,
    totalTDrachmUniSupply: 0,
    allowance: 0,
    isClaiming: false
    };

  handleClick = () => {
    this.props.toggle();
  };

  setInputField() {
    if (this.state.stakeAmount > 0) {
      return this.state.stakeAmount;
    } else {
      return null
    }
  }

  updateStakingInput(e) {
    this.setState({stakeAmount: e.target.value})
    if (this.state.stakeAmount > this.state.allowance) {
        this.setState({isApproved: false})
    }
 }

  getObolUniAmount = async () => {
    let _obolUniAmount = await this.obolUniInstance.methods.balanceOf(this.accounts[0]).call();
    this.setState({
      obolUniAmount: this.web3.utils.fromWei(_obolUniAmount)
    })
  }

  getObolUniAllowance = async () => {
    let _obolUniAllowance = await this.obolUniInstance.methods.allowance(this.accounts[0], this.tetraDrachmInstance._address).call();
    if (_obolUniAllowance > 0) {
        this.setState({isApproved: true, allowance: this.web3.utils.fromWei(_obolUniAllowance.toString())});

    }
    console.log(this.state.allowance);
  }

  getTDrachmSupply = async () => {
    let _tDrachmSupply = await this.tetraDrachmInstance.methods.totalSupply().call();
    this.setState({
      totalTDrachmSupply: this.web3.utils.fromWei(_tDrachmSupply)
    })
  }

  approveObolUni = async () => {
    if (this.state.isApproving) {
        return;
    }
    this.setState({isApproving: true});

    try {
        let approveStaking = await this.obolUniInstance.methods.approve(this.tetraDrachmInstance._address, this.web3.utils.toWei(this.state.totalTDrachmUniSupply.toString())).send({
            from: this.accounts[0]
        });

        if (approveStaking["status"]) {
            this.setState({isApproving: false, isApproved: true});
        }
    } catch {
        this.setState({isApproving: false, isApproved: false});
    }
  }

  getObolUniStakeAmount = async () => {
    let stakeA = await this.tetraDrachmInstance.methods.getOblUniStakeAmount(this.accounts[0]).call();
    console.log(stakeA);
    this.setState({stakedAmount: this.web3.utils.fromWei(stakeA)});
  }

  getRewardsAmount = async () => {
    let rewards = await this.tetraDrachmInstance.methods.myRewardsBalance(this.accounts[0]).call();

    this.setState({tetraDrachmRewards: this.web3.utils.fromWei(rewards)});
  }

  getReward = async () => {
    this.setState({isClaiming: true});

    let myRewards = await this.tetraDrachmInstance.methods.getReward().send({
        from: this.accounts[0]
    });

    if (myRewards["status"]) {
        this.setState({isClaiming: false, tetraDrachmRewards: 0});
    }
  }

  stakeObolUni = async () => {
    if (this.state.isStaking || this.state.stakeAmount === 0) {
        return;
    }
    this.setState({isStaking: true});
    console.log(this.web3.utils.toWei(this.state.stakeAmount.toString()));
    try {
        let stakeRes = await this.tetraDrachmInstance.methods.stakeObolUni(this.web3.utils.toWei(this.state.stakeAmount.toString())).send({
            from: this.accounts[0]
        });
        if (stakeRes["status"]) {
            this.setState({isStaking: false, stakeAmount: 0});
            this.getObolStakeAmount();
        }
    } catch (error) {
        this.setState({isStaking: false});
        console.log(error);
    }
  }

  withdrawOblUni = async () => {
    if (this.state.isWithdrawing || this.state.stakeAmount === 0) {
      return;
    }
    this.setState({isWithdrawing: true});

    try {
      let stakeRes = await this.tetraDrachmInstance.methods.withdrawObolUni(this.web3.utils.toWei(this.state.stakeAmount.toString())).send({
        from: this.accounts[0]
      });
        if (stakeRes["status"]) {
            this.setState({isWithdrawing: false, stakeAmount: 0});
            this.getObolStakeAmount();
        }
    } catch (error) {
        this.setState({isStaking: false});
        console.log(error);
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

      console.log(this.web3.eth)

      this.obolUniInstance = new this.web3.eth.Contract(
        obolUni,
        "0xdB8C25B309Df6bd93d361ad19ef1C5cE5A667d6A"
      );

      console.log(this.obolUniInstance);

      // this.tetraDrachmLP = new this.web3.eth.Contract(

      // )


      this.tetraDrachmInstance = new this.web3.eth.Contract(
        TetraDrachm.abi,
        "0x23b7f3a35bda036e3b59a945e441e041e6b11101",
      );

      this.getObolUniStakeAmount();
      this.getTDrachmSupply();
      this.getObolUniAllowance();
      this.getObolUniAmount();
      this.getRewardsAmount();

    //   this.getMyStakeAmount();
    //   this.getObolRewards();

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
          <h1>MINE tetraDRACHM</h1>
            <h3>Create the bridge to the Polkadot network!</h3>

            <div>
                <p>tetraDRACHM is an extension to the DRAC ecosystem that will allow DRAC voters to acquire non ERC20 assets.</p>
            </div>

            <div>
                <p>20% of all minted tetraDRACHM will go to a funding contract.</p>
            </div>

            {/* <div>
                <p>tetraDRACHM is a rarity. The only way to mint more tetraDRACHM is to provide liquidity for Obol. </p>
            </div> */}

            <div>
              <p>Join the OBL/ETH pool on&nbsp;
                 <a target="_blank" rel="noopener noreferrer" href="https://app.uniswap.org/#/add/ETH/0xd2b93f66fd68c5572bfb8ebf45e2bd7968b38113">Uniswap</a>
                , then stake your pool tokens here.</p>
            </div>

            <div className="amount-staked-box">
              <div className="inline-block amount-staked-image">
                <img className="balance-logo-image" src={obolLogo}/>
                /
                <img className="balance-logo-image" src={ethLogo}/>
              </div>
              <div className="inline-block">
                <div className="top-box-desc">Amount in Wallet</div>
                <div className="top-box-val drachma-balance">{this.state.obolUniAmount}</div>
              </div>
              <div className="inline-block">
                <div className="top-box-desc">Amount staked</div>
                <div className="top-box-val drachma-balance">{this.state.stakedAmount}</div>
              </div>
            </div>

            <div className="amount-staked-box">
              <div className="inline-block amount-staked-image">
                <img className="reward-logo-image" src={tDrachmLogo}/>
              </div>
              <div className="inline-block">
                <div className="top-box-desc">tetraDrachm Rewards</div>
                <div className="top-box-val drachma-balance">{this.state.tetraDrachmRewards}</div>
              </div>
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
            <div className="stake-warning">Make sure to always claim mining rewards before staking more!</div>
            {!this.state.miningStarted ? <div className="button stake-button">
                {!this.state.isStaking ? <div>MINING HAS NOT STARTED</div> : null}
            </div> : null}
            {!this.state.isApproved && this.state.miningStarted ? <div className="button stake-button" onClick={this.approveObolUni}>
                {!this.state.isApproving ? <div>APPROVE</div> : null}
                {this.state.isApproving ? <div>APPROVING...</div> : null}
            </div> : null}
            {this.state.miningStarted  ? <div className="button stake-button inliner" onClick={this.getReward}>
                {!this.state.isClaiming ? <div>CLAIM REWARDS</div> : null}
                {this.state.isClaiming ? <div>CLAIMING...</div> : null}
            </div> : null}
            {this.state.isApproved && this.state.miningStarted ? <div className={`button stake-button inliner ${this.state.stakeAmount > 0 && this.state.stakeAmount < this.state.drachmaBalance ? "" : "disabled"}`} onClick={this.stakeObolUni}>
                {!this.state.isStaking ? <div>STEP 2: STAKE</div> : null}
                {this.state.isStaking ? <div>STAKING...</div> : null}
            </div> : null}
            {this.state.miningStarted ? <div className={`button withdraw-button ${this.state.stakeAmount > 0 && this.state.stakeAmount <= this.state.tetraDrachmRewards ? "" : "disabled"}`} onClick={this.withdrawOblUni}>
                {!this.state.isWithdrawing ? <div>WITHDRAW</div> : null}
                {this.state.isWithdrawing ? <div>WITHDRAWING...</div> : null}
            </div> : null}

            <div>
                <h3>Boost your tetraDrachm mining.</h3>
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
            <div className="stake-warning">Make sure to always claim mining rewards before staking more!</div>
            {!this.state.miningStarted ? <div className="button stake-button">
                {!this.state.isStaking ? <div>MINING HAS NOT STARTED</div> : null}
            </div> : null}
            {!this.state.isApproved && this.state.miningStarted ? <div className="button stake-button" onClick={this.approveObolUni}>
                {!this.state.isApproving ? <div>APPROVE</div> : null}
                {this.state.isApproving ? <div>APPROVING...</div> : null}
            </div> : null}
            {this.state.isApproved && this.state.miningStarted ? <div className={`button stake-button inliner ${this.state.stakeAmount > 0 && this.state.stakeAmount < this.state.drachmaBalance ? "" : "disabled"}`} onClick={this.stakeObolUni}>
                {!this.state.isStaking ? <div>STEP 2: STAKE</div> : null}
                {this.state.isStaking ? <div>STAKING...</div> : null}
            </div> : null}
            {this.state.miningStarted ? <div className={`button withdraw-button ${this.state.stakeAmount > 0 && this.state.stakeAmount <= this.state.tetraDrachmRewards ? "" : "disabled"}`} onClick={this.withdrawOblUni}>
                {!this.state.isWithdrawing ? <div>WITHDRAW</div> : null}
                {this.state.isWithdrawing ? <div>WITHDRAWING...</div> : null}
            </div> : null}
        </div>
      </div>
    );
  }
}
