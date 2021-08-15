import React from 'react';
import AppViews from './views/AppViews';
import DeployerViews from './views/DeployerViews';
import AttacherViews from './views/AttacherViews';
import {renderDOM, renderView} from './views/render';
import './index.css';
import * as backend from './build/index.main.mjs';
import * as loader from '@reach-sh/stdlib';

// import * as reach from '@reach-sh/stdlib/ETH';
import {loadStdlib} from '@reach-sh/stdlib';
const reach = loadStdlib(process.env);
// const stdlib = loadStdlib(process.env);

const {standardUnit} = reach;
const defaults = {defaultFundAmt: '100', defaultWager: '50', standardUnit};
const randomArrayRef = (arr) =>
  arr[Math.floor(Math.random() * arr.length)];

const urlArr = ['https://ipfs.io/ipfs/QmZEUm71Fky7G2YANJMVyorxzc3xnJjjWy7xpn9tsbxDSP', //Green
          'https://ipfs.io/ipfs/QmahEGV3i9DfNQFcxp4qMFLn67B1k3PymKwjerTZgTJHPf',  //Blue
          'https://ipfs.io/ipfs/QmcgUbHBvUdinB1Gh3cypZZ7k2yJs2kSyrZ2fJ1V3Hd2QM',  //Purple
          'https://ipfs.io/ipfs/QmbgyFoDhNj9oueZgJLpLqXkBTpsMHaihELvinK1VKfCVq'];
    
class App extends React.Component {
  constructor(props) {
    super(props);
    this.state = {view: 'ConnectAccount', ...defaults};
  }
  async componentDidMount() {
    const acc = await reach.getDefaultAccount(); 
    const balAtomic = await reach.balanceOf(acc);
    const bal = reach.formatCurrency(balAtomic, 4);
    this.setState({acc, bal});
    try {
      const faucet = await reach.getFaucet();
      this.setState({view: 'FundAccount', faucet});
    } catch (e) {
      this.setState({view: 'DeployerOrAttacher'});
    }
  }
  async fundAccount(fundAmount) {
    await reach.transfer(this.state.faucet, this.state.acc, reach.parseCurrency(fundAmount));
    this.setState({view: 'DeployerOrAttacher'});
  }
  async skipFundAccount() { this.setState({view: 'DeployerOrAttacher'}); }
  selectAttacher() { this.setState({view: 'Wrapper', ContentView: Attacher, role:'Attacher' }); }
  selectDeployer() { this.setState({view: 'Wrapper', ContentView: Deployer, role:'Deployer'}); }
  render() { return renderView(this, AppViews); }

}
class Player extends React.Component {
  random() { return reach.hasRandom.random(); }
  out(arr) {
    this.setState({view: 'Done', outcome: arr});
  }
  async showEnd(arr, id, owner, url) {
    this.setState({view: 'Done', 
                   outcome: arr, 
                   nft_id: id, 
                   owner: reach.formatAddress(owner),
                   url: url})
  }
  async getStep(board) {
    const step = await new Promise(resolveStep => {
      this.setState({view: 'GetStep', board: board, resolveStep});
    });
    this.setState({view: 'WaitingForResults', step});
    return step;
  }
  playStep(step) {this.state.resolveStep(step)}
  informTimeout() { this.setState({view: 'Timeout'}); }
  getId() {     
    const id = reach.randomUInt();
    console.log(` Alice makes id #${id}`);
    return id; 
  }
  getUrl() {
    const url = randomArrayRef(urlArr);
    console.log(`url: ${url}`);
    return url;
  }
  async preview(id, url) {
    console.log(`nft_id: ${id}, url: ${url}`);
    this.setState({url, nft_id: id})

  }
}

class Deployer extends Player {
  constructor(props) {
    super(props);
    this.state = {view: 'SetWager'};
  }
  setWager(wager) { this.setState({view: 'Deploy', wager}); }
  async deploy() {
    const ctc = this.props.acc.deploy(backend);
    this.setState({view: 'Deploying', ctc});
    this.wager = reach.parseCurrency(this.state.wager); // UInt
    this.deadline = {ETH: 10, ALGO: 100, CFX: 1000}[reach.connector]; // UInt
    backend.Alice(ctc, this);
    const ctcInfoStr = JSON.stringify(await ctc.getInfo(), null, 2);
    this.setState({view: 'WaitingForAttacher', ctcInfoStr});
  }
  render() { return renderView(this, DeployerViews); }
}

class Attacher extends Player {
  constructor(props) {
    super(props);
    this.state = {view: 'Attach'};
  }
  attach(ctcInfoStr) {
    const ctc = this.props.acc.attach(backend, JSON.parse(ctcInfoStr));
    this.setState({view: 'Attaching'});
    backend.Bob(ctc, this);
  }
  async acceptWager(wagerAtomic) { // Fun([UInt], Null)
    const wager = reach.formatCurrency(wagerAtomic, 4);
    return await new Promise(resolveAcceptedP => {
      this.setState({view: 'AcceptTerms', wager, resolveAcceptedP});
    });
  }
  termsAccepted() {
    this.state.resolveAcceptedP();
    this.setState({view: 'WaitingForTurn'});
  }
  render() { return renderView(this, AttacherViews); }
}

renderDOM(<App />);
