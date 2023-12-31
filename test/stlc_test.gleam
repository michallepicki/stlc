import gleeunit
import gleeunit/should
import gleam/map
import stlc.{Abs, Ann, BoolT, Const, Fun, If, Var}

pub fn main() {
  gleeunit.main()
}

pub fn not_test() {
  let term =
    Ann(Abs("b", If(Var("b"), Const(False), Const(True))), Fun(BoolT, BoolT))
  stlc.infer_type(map.new(), term)
  |> should.equal(Ok(Fun(BoolT, BoolT)))
}
