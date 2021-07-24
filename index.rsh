'reach 0.1';

const DEADLINE = 120;
const ROWS = 3;
const COLS = 3;
const CELLS = ROWS * COLS;

const b = Array(Bool, 9);
const Board = Object({
  turn:Bool,
  O:b,
  X:b
})

const bv = Array.replicate(CELLS,false);
const newBoard = (turn) => ({
  turn:turn,
  O:bv,
  X:bv
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
    O:board.turn? board.X : board.X.set(ppos,true),
    X:board.turn? board.O.set(ppos,true) : board.O
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



const Player = {
  ...hasRandom,
  out: Fun([Board], Null),
  getStep: Fun([Board], UInt),
  informTimeout: Fun([], Null)
}
const Alice = {
  ...Player,
  wager: UInt
}
const Bob = {
  ...Player,
  acceptWager: Fun([UInt], Null)
}

export const main = Reach.App(
  {}, [Participant('Alice', Alice), Participant('Bob', Bob)],
  (A, B) => {
    const informTimeout = () => {
      each([A, B], () => {
        interact.informTimeout(); }); };

    A.only(() => {
      const wager = declassify(interact.wager); });
    A.publish(wager)
      .pay(wager);
    commit();

    B.only(() => {
      interact.acceptWager(wager); });
    B.pay(wager)
     .timeout(DEADLINE, () => closeTo(A, informTimeout));

    var board = newBoard(true);
    invariant(balance() == 2 * wager);
    while(!isDone(board)){
      if(board.turn){
        commit();
        A.only(() => {
          interact.out(board)
          const moveA = declassify(interact.getStep(board)); });
        A.publish(moveA)
         .timeout(DEADLINE, () => closeTo(B, informTimeout));

        board = step(board, moveA);
        continue;
      }else {
        commit();

        B.only(() => {
          interact.out(board)
          const moveB = declassify(interact.getStep(board));});
        B.publish(moveB)
         .timeout(DEADLINE, () => closeTo(A, informTimeout));

        board = step(board, moveB);
        continue; } 
    }
    const [ toA, toB ] =
          (isWin( board.O ) ? [ 2, 0 ]
          : (isWin( board.X ) ? [ 0, 2 ]
          : [ 1, 1 ]));
    transfer(toA * wager).to(A);
    transfer(toB * wager).to(B);
    commit();

    each([A, B], () => {
      interact.out(board);
    })
  }
);
