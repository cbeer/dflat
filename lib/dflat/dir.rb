module Dflat
  class Dir < ::Dir
    include Namaste::Mixin
    include LockIt::Mixin
  end
end
