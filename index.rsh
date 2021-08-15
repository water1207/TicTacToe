'reach 0.1';

//const DEADLINE = 60;
const ROWS = 3;
const COLS = 3;
const CELLS = ROWS * COLS;

const b = Array(Bool, 9);
const Board = Object({
  turn:Bool,
  O:b,
  X:b,
  win:Bool
})

const bv = Array.replicate(CELLS,false);
const newBoard = (turn) => ({
  turn: turn,
  O:bv,
  X:bv,
  win: false
})
const cellBoth = (st, i) =>
      (st.X[i] || st.O[i]);
// 这个位置没下过
const validMove = (st, m) => (! cellBoth(st, m));


// 下棋
function step(board,pos){
  // require(validMove(board,pos));
  const ppos = pos % CELLS;
  
  return {
    turn:!board.turn,
    X:board.turn?  board.X.set(ppos,true) : board.X ,
    O:board.turn?  board.O : board.O.set(ppos,true) ,
    win: false
  };
}
function getCell(bb,i){
  if(0<=i && i<CELLS){
    return bb[i];
  }else{
    return false;
  }
}

function getLine(bb,i,len){
  return (
    getCell(bb,i) &&
    getCell(bb,add(i,len)) &&
    getCell(bb,i+len+len));
}

function isWin(bb) {
  return (
    //横
    getLine(bb,0,1) ||
    getLine(bb,3,1) ||
    getLine(bb,6,1) ||
    //竖
    getLine(bb,0,3) ||
    getLine(bb,1,3) ||
    getLine(bb,2,3) ||
    //斜
    getLine(bb,0,4) ||
    getLine(bb,2,2)
  );
}
function allPlaced(board){
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
  return (isWin(board.O) || isWin(board.X) || allPlaced(board));
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
  out: Fun([Board], Null),
  getStep: Fun([Board], UInt),
  informTimeout: Fun([], Null),
  getId: Fun([], UInt),
  getUrl: Fun([], Bytes(128)),
  preview: Fun([UInt, Bytes(128)], Null),
  showEnd: Fun([Board, UInt, Address, Bytes(128)], Null)
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
          interact.out(board)
          const moveA = declassify(interact.getStep(board)); });
        A.publish(moveA)
         .timeout(deadline, () => closeTo(B, informTimeout));

        board = step(board, moveA);
        continue;
      }else {
        commit();

        B.only(() => {
          interact.out(board)
          const moveB = declassify(interact.getStep(board));});
        B.publish(moveB)
         .timeout(deadline, () => closeTo(A, informTimeout));

        board = step(board, moveB);
        continue; } 
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
