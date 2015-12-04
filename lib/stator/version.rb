module Stator
  MAJOR       = 0
  MINOR       = 1
  PATCH       = 2
  PRERELEASE  = nil

  VERSION = [MAJOR, MINOR, PATCH, PRERELEASE].compact.join('.')
end
