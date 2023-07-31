import gleam/map.{Map}
import gleam/result
import gleam/string.{inspect}

pub type Term {
  Var(name: String)
  App(fun: Term, arg: Term)
  Abs(param: String, body: Term)
  Const(value: Bool)
  If(condition: Term, then: Term, else: Term)
  Ann(term: Term, ty: Type)
}

pub type Type {
  BoolT
  Fun(param_type: Type, body_type: Type)
}

pub type Ctx =
  Map(String, Type)

pub fn infer_type(ctx: Ctx, term: Term) -> Result(Type, String) {
  case term {
    Var(name) -> {
      map.get(ctx, name)
      |> result.replace_error("undefined variable: " <> name)
    }
    App(fun, arg) -> {
      case infer_type(ctx, fun) {
        Ok(Fun(param_ty, body_ty)) -> {
          check_type(ctx, arg, param_ty)
          |> result.replace(body_ty)
        }
        Ok(ty) -> Error("expected\n" <> inspect(fun) <> "to be a function, found:\n" <> inspect(ty))
        e -> e
      }
    }
    Abs(_, _) -> Error("functions need to have their types annotated:\n" <> inspect(term))
    Const(True) | Const(False) -> Ok(BoolT)
    If(t1, t2, t3) -> {
      case check_type(ctx, t1, BoolT), infer_type(ctx, t2), infer_type(ctx, t3) {
        Ok(_), Ok(ty2), Ok(ty3) if ty2 == ty3 -> Ok(ty2)
        Ok(_), Ok(ty2), Ok(ty3) if ty2 != ty3 -> Error("both then and else branches must have the same type:\n" <> inspect(term))
        Error(e), _, _ -> Error(e)
        _, Error(e), _ -> Error(e)
        _, _, Error(e) -> Error(e)
      }
    }
    Ann(t, ty) -> check_type(ctx, t, ty)
    _ -> Error("failed to infer the type:\n" <> inspect(term))
  }
}

pub fn check_type(ctx: Ctx, term: Term, ty: Type) -> Result(Type, String) {
  case term, ty {
    Abs(param, body), Fun(param_ty, body_ty) -> {
      map.insert(ctx, param, param_ty)
      |> check_type(body, body_ty)
      |> result.replace(ty)
    }
    _, _ -> {
      case infer_type(ctx, term) {
        Ok(inferred_ty) if inferred_ty == ty -> Ok(ty)
        Ok(inferred_ty) -> Error("type mismatch, expected:\n" <> inspect(term) <> "\nto have the type:\n" <> inspect(ty) <> "\nfound:\n" <> inspect(inferred_ty))
        e -> e
      }
    }
  }
}