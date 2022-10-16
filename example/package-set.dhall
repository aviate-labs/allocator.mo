let Package = { name : Text, version : Text, repo : Text, dependencies : List Text }

let overrides = [
  { name = "allocator"
  , version = "main"
  , repo = "https://github.com/internet-computer/allocator.mo"
  , dependencies = [] : List Text
  }
] : List Package

in  overrides
