import React from 'react';
import fr from '.././fr.js'
const exports = {};

// Player views must be extended.
// It does not have its own Wrapper view.

exports.GetHand = class extends React.Component {
  render() {
    const { parent, playable, hand } = this.props;
    return (
      <div>
        {hand ? 'It was a draw! Pick again.' : ''}
        <br />
        {!playable ? 'Please wait...' : ''}
        <br />
        <button
          disabled={!playable}
          onClick={() => parent.playHand('ROCK')}
        >Rock</button>
        <button
          disabled={!playable}
          onClick={() => parent.playHand('PAPER')}
        >Paper</button>
        <button
          disabled={!playable}
          onClick={() => parent.playHand('SCISSORS')}
        >Scissors</button>
      </div>
    );
  }
}

class Square extends React.Component {
  render() {
    return (
      <button
        className={this.props.old ? "square old_board" : "square"}
        onClick={() => this.props.onClick()}>
        {this.props.value}
      </button>
    );
  }
}

exports.GetStep = class extends React.Component {


  constructor(props) {
    super(props);
    const { parent, board } = this.props;
    this.state = {
      step: -1,
      confirmed: false,
      squares: Array(9).fill(null),
      board: board,
      old_board: board,
      parent: parent,
    }
  }


  cellBoth(board, i) {
    return (board.O[i] || board.X[i]);
  }
  oldState(i) {
    return this.cellBoth(this.state.old_board, i);
  }
  nowState(i) {
    return this.cellBoth(this.state.board, i);
  }
  handleClick(i) {
    if (this.state.confirmed) return

    if (this.state.board.turn && !this.nowState(i)) {
      const board = JSON.parse(JSON.stringify(this.state.old_board));
      board.X[i] = true;
      this.setState({ board: board, step: i })
    } else if (!this.nowState(i)) {
      const board = JSON.parse(JSON.stringify(this.state.old_board));
      board.O[i] = true;
      this.setState({ board: board, step: i })
    }
  }
  clickConfirm() {
    if (!this.state.confirmed) {
      console.log(this.state.step)
      this.setState({ confirmed: true })
    }
    this.state.parent.playStep(this.state.step)
  }

  renderValue(i) {
    if (this.state.board.O[i] || this.state.old_board.O[i]) {
      return "O";
    } else if (this.state.board.X[i] || this.state.old_board.X[i]) {
      return "X";
    } else {
      return null;
    }
  }
  renderSquare(i) {
    return <Square
      value={this.renderValue(i)}
      onClick={() => this.handleClick(i)}
      old={this.oldState(i)}
    />;
  }

  render() {

    return (
      <div className="board">

        {/* <div className="status">{this.state.step}</div> */}
        <div className="board-row">
          {this.renderSquare(0)}
          {this.renderSquare(1)}
          {this.renderSquare(2)}
        </div>

        <div className="board-row">
          {this.renderSquare(3)}
          {this.renderSquare(4)}
          {this.renderSquare(5)}
        </div>
        <div className="board-row">
          {this.renderSquare(6)}
          {this.renderSquare(7)}
          {this.renderSquare(8)}
        </div>
        <div className="confirm_div">
          <button
            className="confirm"
            disabled={this.state.step === -1 || this.state.confirmed ? "disabled" : null}
            onClick={() => this.clickConfirm()}
          >确认</button>
        </div>

      </div>
    );
  }
}

exports.WaitingForResults = class extends React.Component {
  render() {
    return (
      <div>
        Waiting for results...
      </div>
    );
  }
}

exports.Done = class extends React.Component {
  constructor(props) {
    super(props);
    const { parent, outcome, role, nft_id, owner, url} = this.props;
    this.state = {
      step: -1,
      confirmed: true,
      squares: Array(9).fill(null),
      board: outcome,
      old_board: outcome,
      parent: parent,
      first: true,
      role: role,
      nft_id: nft_id,
      owner: owner,
      url: url
    }

  }
  componentDidMount() {
    console.log(this.state.board);
    if (this.state.board.win === true) {
      fr.init();
      fr.draw();
    }
  }

  cellBoth(board, i) {
    return (board.O[i] || board.X[i]);
  }
  oldState(i) {
    return this.cellBoth(this.state.old_board, i);
  }
  nowState(i) {
    return this.cellBoth(this.state.board, i);
  }
  handleClick(i) {
    if (this.state.confirmed) return

    if (this.state.board.turn && !this.nowState(i)) {
      const board = JSON.parse(JSON.stringify(this.state.old_board));
      board.X[i] = true;
      this.setState({ board: board, step: i })
    } else if (!this.nowState(i)) {
      const board = JSON.parse(JSON.stringify(this.state.old_board));
      board.O[i] = true;
      this.setState({ board: board, step: i })
    }
  }
  clickConfirm() {
    if (!this.state.confirmed) {
      console.log(this.state.step)
      this.setState({ confirmed: true })
    }
    this.state.parent.playStep(this.state.step)
  }

  renderValue(i) {
    if (this.state.board.O[i] || this.state.old_board.O[i]) {
      return "O";
    } else if (this.state.board.X[i] || this.state.old_board.X[i]) {
      return "X";
    } else {
      return null;
    }
  }
  renderSquare(i) {
    return <Square
      value={this.renderValue(i)}
      onClick={() => this.handleClick(i)}
      old={this.oldState(i)}
    />;
  }

  render() {
    console.log("state");
    console.log(this.state);
    console.log("id:");
    console.log(this.state.nft_id);
    console.log(this.state.owner)
    return (
      <div>
        {
          this.state.board.win ? (
            <div >
              <div id="canvas"></div>
              <div id="again">
                <h2>Congratulations on winning the game!</h2><br />
                <h2>nft_id:{this.state.nft_id.toString()}</h2>
                <h2>owner:{this.state.owner}</h2>
                <img src={this.state.url} />
                {/* <button className="confirm">play again</button> */}
              </div>
            </div>
          ) : ''
        }


        Thank you for playing. The outcome of this game was:
        <div className="board">
          <div className="board-row">
            {this.renderSquare(0)}
            {this.renderSquare(1)}
            {this.renderSquare(2)}
          </div>

          <div className="board-row">
            {this.renderSquare(3)}
            {this.renderSquare(4)}
            {this.renderSquare(5)}
          </div>
          <div className="board-row">
            {this.renderSquare(6)}
            {this.renderSquare(7)}
            {this.renderSquare(8)}
          </div>
        </div>
      </div>
    );
  }
}

exports.Timeout = class extends React.Component {
  render() {
    return (
      <div>
        There's been a timeout. (Someone took too long.)
      </div>
    );
  }
}

export default exports;