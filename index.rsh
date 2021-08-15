'reach 0.1';

//const DEADLINE = 60;
const ROWS = 3;
const COLS = 3;
const CELLS = ROWS * COLS;

const cells_type = Array(Bool, 9);
const Board_type = Object({
  turn:Bool,
  O:cells_type,
  X:cells_type,
  win:Bool
})

const cells = Array.replicate(CELLS,false); //全是false 长度为9的数组
const newBoard = (turn) => ({   //function 参数true X / O
  turn: turn, 
  O:cells,
  X:cells,
  win: false
})
const cellBoth = (board, i) =>   //board:Board  if true 下过了
      (board.X[i] || board.O[i]);
// 这个位置没下过
const validMove = (board, m) => (! cellBoth(board, m));
// 下的位置合理
const validStep = (step) => (0<=step && step<CELLS);

// 前端下的位置合规
function getValidPlay(interact, board) {
  const step = interact.getStep(board);
  assume(validStep(step));
  assume(validMove(board, step));
  return declassify(step); 
}

// 下棋
function step(board,pos){
  require(validStep(pos));
  require(validMove(board,pos));
  
  return {
    turn:!board.turn,
    X:board.turn?  board.X.set(pos,true) : board.X ,
    O:board.turn?  board.O : board.O.set(pos,true) ,
    win: false
  };
}
function getCell(singleBoard,i){  //Board.X / Borad.O 
  if(0<=i && i<CELLS){
    return singleBoard[i];
  }else{
    return false;
  }
}

function getLine(singleBoard,i,len){  //0 4 8 步长
  return (
    getCell(singleBoard,i) &&
    getCell(singleBoard,add(i,len)) &&
    getCell(singleBoard,i+len+len));
}

function isWin(singleBoard) {
  return (
    //横
    getLine(singleBoard,0,1) ||
    getLine(singleBoard,3,1) ||
    getLine(singleBoard,6,1) ||
    //竖
    getLine(singleBoard,0,3) ||
    getLine(singleBoard,1,3) ||
    getLine(singleBoard,2,3) ||
    //斜
    getLine(singleBoard,0,4) ||
    getLine(singleBoard,2,2)
  );
}
function allPlaced(board){   //是否下满
  return (
    cellBoth(board,0) &&
    cellBoth(board,1) &&
    cellBoth(board,2) &&
    cellBoth(board,3) &&
    cellBoth(board,4) &&
    cellBoth(board,5) &&
    cellBoth(board,6) &&
    cellBoth(board,7) &&
    cellBoth(board,8)
  )
}
function isDone(board){
  return (isWin(board.O) || isWin(board.X) || allPlaced(board));   //是否结束
}
const finalBoardX = (board) => ({
  ...board,
  win: isWin(board.X)
})
const finalBoardO = (board) => ({
  ...board,
  win: isWin(board.O)
})


const Player = {
  ...hasRandom,
  //out: Fun([Board_type], Null),
  getStep: Fun([Board_type], UInt),
  informTimeout: Fun([], Null),
  getId: Fun([], UInt),
  getUrl: Fun([], Bytes(128)),
  preview: Fun([UInt, Bytes(128)], Null),
  showEnd: Fun([Board_type, UInt, Address, Bytes(128)], Null)
};
const Alice = {
  ...Player,
  wager: UInt,
  deadline: UInt, // time delta (blocks/rounds)
}
const Bob = {
  ...Player,
  acceptWager: Fun([UInt], Null)
}
const Nft = 
      { owner: Address,
        url: Bytes(128) };

export const main = Reach.App(
  {}, [Participant('Alice', Alice), Participant('Bob', Bob), View('NFT', Nft)],
  (A, B, vNFT) => {
    const informTimeout = () => {
      each([A, B], () => {
        interact.informTimeout(); }); };

    A.only(() => {
      const wager = declassify(interact.wager);
      const deadline = declassify(interact.deadline);
    });
    A.publish(wager, deadline)
      .pay(wager);
    commit();

    B.only(() => {
      interact.acceptWager(wager); });
    B.pay(wager)
     .timeout(deadline, () => closeTo(A, informTimeout));

    commit();
    A.only(() => {
      const id = declassify(interact.getId());
      const url = declassify(interact.getUrl());
    });
    A.publish(id, url);
    each([A, B], () => {
      interact.preview(id, url);
    });

    var board = newBoard(true);
    invariant(balance() == 2 * wager);
    while(!isDone(board)){
      if(board.turn){
        commit();
        A.only(() => {
          //传入当前棋盘状态，返回点击的格子number
          const Aplay = getValidPlay(interact,board);});
        A.publish(Aplay)
         .timeout(deadline, () => closeTo(B, informTimeout));

        board = step(board, Aplay);   //更新棋盘
        continue;
      }else {
        commit();

        B.only(() => {
          const Bplay = getValidPlay(interact,board);});
        B.publish(Bplay)
         .timeout(deadline, () => closeTo(A, informTimeout));

        board = step(board, Bplay);
        continue; 
      } 
    }
    const [ toA, toB ] =
          (isWin( board.X ) ? [ 2, 0 ]
          : (isWin( board.O ) ? [ 0, 2 ]
          : [ 1, 1 ]));
    
    const owner = isWin( board.X ) ? A : B;
    vNFT.owner.set(owner);  //winner get the NFT
    vNFT.url.set(url);

    transfer(toA * wager).to(A);
    transfer(toB * wager).to(B);
    commit();

    A.only(()=>{
      interact.showEnd(finalBoardX(board), id, owner, url);
    });
    B.only(()=>{
      interact.showEnd(finalBoardO(board), id, owner, url);
    });
  }
);
